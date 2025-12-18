; Quick Note Taker Class
; A floating notepad for quick notes with Base64-encoded storage and search
; Features: Multiple notes, search, auto-save, Catppuccin theming

class QuickNoteTaker {
    ; Catppuccin Mocha color palette
    colors := {
        bg: "0x1e1e2e",       ; Background
        mantle: "0x181825",    ; Darker background
        surface0: "0x313244",  ; Surface
        surface1: "0x45475a",  ; Lighter surface
        text: "0xcdd6f4",      ; Main text
        subtext1: "0xbac2de",  ; Dimmed text
        blue: "0x89b4fa",      ; Accent blue
        mauve: "0xcba6f7",     ; Purple
        red: "0xf38ba8",       ; Red
        green: "0xa6e3a1",     ; Green
        yellow: "0xf9e2af",    ; Yellow
        overlay0: "0x6c7086"   ; Overlay
    }
    
    ; Settings
    settings := {
        hotkey: "!+n",        ; Alt+Shift+N
        windowWidth: 500,
        windowHeight: 400,
        alwaysOnTop: true,
        autoSave: true,
        fontSize: 10,
        fontName: "Consolas",
        maxNotes: 100,        ; Maximum number of notes to keep
        exportPath: A_ScriptDir . "\Settings" ; Default export path
    }
    
    ; Internal state
    gui := ""
    textBox := ""
    titleEdit := ""
    searchEdit := ""
    notesList := ""
    statusBar := ""
    isVisible := false
    notesFile := ""
    currentNoteIndex := -1   ; Current note index in array
    notes := []              ; Simple array of notes with {title, content}
    
    ; Constructor
    __New() {
        this.notesFile := A_ScriptDir . "\Settings\quick_notes.dat"
        
        ; Initialize change tracking variables
        this.originalTitle := ""
        this.originalContent := ""
        
        ; Load settings from INI file BEFORE creating GUI so hotkey/exportPath are correct
        this.LoadSettingsFromFile()
        this.CreateGUI()
        
        ; Set default sort dropdown value based on settings
        sortOptions := ["modified", "created", "title", "length"]
        sortIndex := 1  ; Default to "Modified"
        Loop sortOptions.Length {
            if sortOptions[A_Index] = this.settings.sortBy {
                sortIndex := A_Index
                break
            }
        }
        this.sortButton.Choose(sortIndex)
        
        ; Set direction button icon
        this.sortDirectionButton.Text := (this.settings.sortDirection = "asc") ? "↑" : "↓"
        
        this.LoadNotes()
        this.SetupHotkey()
        
        ; Only create new note if no notes exist
        if this.notes.Length = 0 {
            this.CreateNewNote()
        } else {
            ; Load the first note if notes exist
            this.LoadNote(0)
        }
    }
    
    ; ========================================
    ; GUI CREATION
    ; ========================================
    
    CreateGUI() {
        flags := "-MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow"
        if this.settings.alwaysOnTop {
            flags .= " +AlwaysOnTop"
        }
        
        this.gui := Gui(flags, "Quick Notes")
        this.gui.SetFont("s" . this.settings.fontSize, this.settings.fontName)
        this.gui.BackColor := this.colors.bg
        this.gui.OnEvent("Close", (*) => this.Hide())
        this.gui.OnEvent("ContextMenu", (*) => "")  ; Disable right-click context menu
        
        ; Top section - Title and Search in one row
        this.gui.AddText("xm ym w40 c" . this.colors.subtext1, "Title:")
        this.titleEdit := this.gui.AddEdit("x+5 yp-3 w120 h20 Background" . this.colors.surface0 . " c" . this.colors.text)
        this.titleEdit.OnEvent("Change", (*) => this.OnTitleChange())
        this.titleEdit.OnEvent("LoseFocus", (*) => this.OnTitleLoseFocus())
        this.titleEdit.OnEvent("ContextMenu", (*) => "")  ; Disable right-click
        ; We'll handle Enter key with global hotkey when visible
        
        this.gui.AddText("x+10 yp+3 w45 c" . this.colors.subtext1, "Search:")
        this.searchEdit := this.gui.AddEdit("x+5 yp-3 w90 h20 Background" . this.colors.surface0 . " c" . this.colors.text)
        this.searchEdit.OnEvent("Change", (*) => this.OnSearchChange())
        this.searchEdit.OnEvent("ContextMenu", (*) => "")  ; Disable right-click
        
        ; Sort dropdown on same line as search
        this.gui.AddText("x+10 yp+3 w30 c" . this.colors.subtext1, "Sort:")
        this.sortButton := this.gui.AddDropDownList("x+5 yp-3 w85 Background" . this.colors.surface0 . " c" . this.colors.text, ["Modified", "Created", "Title", "Length"])
        this.sortButton.OnEvent("Change", (*) => this.OnSortChange())
        
        ; Direction toggle button
        this.sortDirectionButton := this.gui.AddButton("x+2 yp w25 h20 Background" . this.colors.surface0 . " c" . this.colors.text, "↑")
        this.sortDirectionButton.OnEvent("Click", (*) => this.ToggleSortDirection())
        
        ; Button row - more compact
        this.gui.AddButton("xm y+10 w50 h23 Background" . this.colors.blue . " c" . this.colors.bg, "New").OnEvent("Click", (*) => this.CreateNewNote())
        this.gui.AddButton("x+5 yp w50 h23 Background" . this.colors.green . " c" . this.colors.bg, "Save").OnEvent("Click", (*) => this.SaveCurrentNote())
        this.gui.AddButton("x+5 yp w50 h23 Background" . this.colors.red . " c" . this.colors.bg, "Delete").OnEvent("Click", (*) => this.DeleteCurrentNote())
        this.gui.AddButton("x+5 yp w70 h23 Background" . this.colors.mauve . " c" . this.colors.bg, "Settings").OnEvent("Click", (*) => this.ShowSettings())
        this.gui.AddButton("x+5 yp w90 h23 Background" . this.colors.yellow . " c" . this.colors.bg, "Export All").OnEvent("Click", (*) => this.ExportNotes())
        this.gui.AddButton("x+5 yp w90 h23 Background" . this.colors.blue . " c" . this.colors.bg, "Export Note").OnEvent("Click", (*) => this.ExportCurrentNote())
        
        ; Split layout - Notes list on left, content on right
        this.gui.AddText("xm y+15 w150 c" . this.colors.subtext1, "Notes History:")
        this.gui.AddText("x170 yp w200 c" . this.colors.subtext1, "Note Content:")
        
        ; Main content area - calculate height to minimize gap below boxes
        listHeight := this.settings.windowHeight - 140  ; Reduced from 160 to minimize bottom gap
        this.notesList := this.gui.AddListBox("xm y+5 w150 h" . listHeight . " Background" . this.colors.surface0 . " c" . this.colors.text . " VScroll")
        this.notesList.OnEvent("Change", (*) => this.OnNoteSelect())
        this.notesList.OnEvent("ContextMenu", (*) => "")  ; Disable right-click
        
        textWidth := this.settings.windowWidth - 170
        this.textBox := this.gui.AddEdit("x170 yp w" . textWidth . " h" . listHeight . " VScroll Background" . this.colors.surface0 . " c" . this.colors.text)
        this.textBox.OnEvent("Change", (*) => this.OnTextChange())
        this.textBox.OnEvent("LoseFocus", (*) => this.OnTextLoseFocus())
        this.textBox.OnEvent("ContextMenu", (*) => "")  ; Disable right-click
        
        ; Status bar - positioned closer to boxes with reduced gap
        statusY := this.settings.windowHeight - 20  ; Reduced from 25 to minimize gap
        this.statusBar := this.gui.AddText("xm y" . statusY . " w400 c" . this.colors.subtext1, "Ctrl+S: Save • Ctrl+N: New • Ctrl+Del: Delete Note • Esc: Hide")
        
        ; Position and hide initially
        this.gui.Show("w" . this.settings.windowWidth . " h" . this.settings.windowHeight . " Hide")
        this.CenterWindow()
    }
    
    CenterWindow() {
        ; Center the window on the primary monitor
        MonitorGet(MonitorGetPrimary(), &left, &top, &right, &bottom)
        screenWidth := right - left
        screenHeight := bottom - top
        
        ; Calculate center position
        x := left + (screenWidth - this.settings.windowWidth - 400) // 2
        y := top + (screenHeight - this.settings.windowHeight - 250) // 2
        
        ; Ensure window stays on screen
        if x < left {
            x := left + 50
        }
        if y < top {
            y := top + 50
        }
        
        this.gui.Move(x, y)
    }
    
    ; ========================================
    ; NOTE MANAGEMENT
    ; ========================================
    
    CreateNewNote() {
        ; Save current note if it has content
        if this.currentNoteIndex >= 0 && (this.textBox.Value || this.titleEdit.Value) {
            this.SaveCurrentNote()
        }
        
        ; Reset to new note state
        this.currentNoteIndex := -1
        
        ; Temporarily disable auto-save to prevent loops
        autoSaveState := this.settings.autoSave
        this.settings.autoSave := false
        
        ; Clear the interface
        this.titleEdit.Value := ""
        this.textBox.Value := ""
        
        ; Reset original values for change tracking
        this.originalTitle := ""
        this.originalContent := ""
        
        ; Re-enable auto-save
        this.settings.autoSave := autoSaveState
        
        ; Clear list selection
        this.notesList.Choose(0)
        
        ; Focus on title field
        this.titleEdit.Focus()
    }
    
    SaveCurrentNote() {
        title := this.titleEdit.Value
        content := this.textBox.Value
        
        ; Don't save empty notes
        if !title && !content {
            return
        }
        
        ; Use current date/time as title if none provided
        if !title {
            title := "Note " . FormatTime(A_Now, "yyyy-MM-dd HH:mm")
            this.titleEdit.Value := title
        }
        
        ; Create note object with timestamps
        note := {title: title, content: content}
        
        ; Update existing note or add new one
        if this.currentNoteIndex >= 0 && this.currentNoteIndex < this.notes.Length {
            ; Update existing note - preserve created timestamp, update modified
            existingNote := this.notes[this.currentNoteIndex + 1]
            note.created := existingNote.HasOwnProp("created") ? existingNote.created : A_Now
            note.modified := A_Now
            this.notes[this.currentNoteIndex + 1] := note
        } else {
            ; Add new note - set both timestamps to now
            note.created := A_Now
            note.modified := A_Now
            this.notes.InsertAt(1, note)
            this.currentNoteIndex := 0
        }
        
        ; Limit number of notes
        while this.notes.Length > this.settings.maxNotes {
            this.notes.RemoveAt(this.notes.Length)
        }
        
        this.SaveNotesToFile()
        this.RefreshNotesList()
        
        ; Update original values after save
        this.originalTitle := title
        this.originalContent := content
        
        ; Visual feedback
        this.gui.Title := "Quick Notes - Saved!"
        SetTimer(() => this.gui.Title := "Quick Notes", -1000)
    }
    
    DeleteCurrentNote() {
        if this.currentNoteIndex < 0 || this.currentNoteIndex >= this.notes.Length {
            return
        }
        
        note := this.notes[this.currentNoteIndex + 1]
        result := MsgBox("Delete note '" . note.title . "'?", "Delete Note", "YesNo Icon?")
        
        if result = "Yes" {
            this.notes.RemoveAt(this.currentNoteIndex + 1)
            this.SaveNotesToFile()
            
            ; Clear the current interface
            this.titleEdit.Value := ""
            this.textBox.Value := ""
            this.currentNoteIndex := -1
            
            ; Refresh the list and select first note if any exist
            this.RefreshNotesList()
            
            ; If there are notes left, select the first one, otherwise create new
            if this.notes.Length > 0 {
                this.notesList.Choose(1)
                this.OnNoteSelect()
            } else {
                this.CreateNewNote()
            }
        }
    }
    
    OnNoteSelect() {
        selectedIndex := this.notesList.Value
        if !selectedIndex || selectedIndex < 1 {
            return
        }
        
        ; Save current note before switching, only if changed
        if this.currentNoteIndex >= 0 && (this.textBox.Value || this.titleEdit.Value) {
            currentTitle := this.titleEdit.Value
            currentContent := this.textBox.Value
            titleChanged := currentTitle != this.originalTitle
            contentChanged := currentContent != this.originalContent
            
            if titleChanged || contentChanged {
                this.SaveCurrentNote()
            }
        }
        
        ; Load the selected note by index
        noteIndex := selectedIndex - 1  ; Convert to 0-based index
        if noteIndex >= 0 && noteIndex < this.notes.Length {
            this.LoadNote(noteIndex)
        }
    }
    
    LoadNote(noteIndex) {
        if noteIndex < 0 || noteIndex >= this.notes.Length {
            return
        }
        
        note := this.notes[noteIndex + 1]
        this.currentNoteIndex := noteIndex
        
        ; Temporarily disable auto-save to prevent loops
        autoSaveState := this.settings.autoSave
        this.settings.autoSave := false
        
        ; Update the UI
        this.titleEdit.Value := note.title
        this.textBox.Value := note.content
        
        ; Store original values for change detection
        this.originalTitle := note.title
        this.originalContent := note.content
        
        ; Ensure the correct list item is selected
        this.notesList.Choose(noteIndex + 1)
        
        ; Re-enable auto-save
        this.settings.autoSave := autoSaveState
    }
    
    OnSearchChange() {
        this.RefreshNotesList(this.searchEdit.Value)
    }
    
    RefreshNotesList(searchTerm := "") {
        ; Store currently selected note index to restore selection if possible
        currentSelectionIndex := this.currentNoteIndex
        
        ; Clear the list
        this.notesList.Delete()
        
        ; Add notes to list (filtered by search if provided)
        newSelectionIndex := 0
        itemIndex := 0
        
        Loop this.notes.Length {
            noteIndex := A_Index - 1  ; Convert to 0-based index
            note := this.notes[A_Index]
            
            ; Apply search filter
            if searchTerm {
                searchLower := StrLower(searchTerm)
                if !InStr(StrLower(note.title), searchLower) && !InStr(StrLower(note.content), searchLower) {
                    continue
                }
            }
            
            ; Format list item - show only title
            listText := note.title
            
            this.notesList.Add([listText])
            itemIndex++
            
            ; Track if this was the previously selected item
            if noteIndex = currentSelectionIndex {
                newSelectionIndex := itemIndex
            }
        }
        
        ; Restore selection if the note still exists
        if newSelectionIndex > 0 {
            this.notesList.Choose(newSelectionIndex)
        }
    }
    

    
    OnTitleChange() {
        ; No longer auto-save on every change - only on focus loss
    }
    
    OnTextChange() {
        ; No longer auto-save on every change - only on focus loss  
    }
    
    OnTitleLoseFocus() {
        ; Auto-save when title field loses focus, only if changed
        if this.settings.autoSave {
            currentTitle := this.titleEdit.Value
            currentContent := this.textBox.Value
            
            ; Check if either title or content changed
            titleChanged := !this.HasOwnProp("originalTitle") || currentTitle != this.originalTitle
            contentChanged := !this.HasOwnProp("originalContent") || currentContent != this.originalContent
            
            if titleChanged || contentChanged {
                this.SaveCurrentNote()
            }
        }
    }
    
    OnTextLoseFocus() {
        ; Auto-save when content field loses focus, only if changed
        if this.settings.autoSave {
            currentTitle := this.titleEdit.Value
            currentContent := this.textBox.Value
            
            ; Check if either title or content changed
            titleChanged := !this.HasOwnProp("originalTitle") || currentTitle != this.originalTitle
            contentChanged := !this.HasOwnProp("originalContent") || currentContent != this.originalContent
            
            if titleChanged || contentChanged {
                this.SaveCurrentNote()
            }
        }
    }
    
    ; ========================================
    ; SORTING
    ; ========================================
    
    OnSortChange() {
        ; Map dropdown selection to sort type
        sortTypes := ["modified", "created", "title", "length"]
        selectedIndex := this.sortButton.Value
        
        if selectedIndex >= 1 && selectedIndex <= sortTypes.Length {
            this.settings.sortBy := sortTypes[selectedIndex]
            this.SaveSettingsToFile()
            this.SortNotes()
            this.RefreshNotesList()
        }
    }
    
    ToggleSortDirection() {
        ; Toggle between asc and desc
        this.settings.sortDirection := (this.settings.sortDirection = "asc") ? "desc" : "asc"
        
        ; Update button text
        this.sortDirectionButton.Text := (this.settings.sortDirection = "asc") ? "↑" : "↓"
        
        this.SaveSettingsToFile()
        this.SortNotes()
        this.RefreshNotesList()
    }
    
    SortNotes() {
        if this.notes.Length <= 1 {
            return
        }
        
        ; Store current note title to restore selection after sort
        currentTitle := ""
        if this.currentNoteIndex >= 0 && this.currentNoteIndex < this.notes.Length {
            currentTitle := this.notes[this.currentNoteIndex + 1].title
        }
        
        ; Determine sort direction
        isAsc := (this.settings.sortDirection = "asc")
        
        ; Sort based on current setting
        switch this.settings.sortBy {
            case "modified":
                ; Sort by modified date
                this.notes := this.BubbleSort(this.notes, (a, b) => 
                    isAsc 
                        ? (a.HasOwnProp("modified") ? a.modified : "0") > (b.HasOwnProp("modified") ? b.modified : "0")
                        : (a.HasOwnProp("modified") ? a.modified : "0") < (b.HasOwnProp("modified") ? b.modified : "0")
                )
            case "created":
                ; Sort by created date
                this.notes := this.BubbleSort(this.notes, (a, b) => 
                    isAsc
                        ? (a.HasOwnProp("created") ? a.created : "0") > (b.HasOwnProp("created") ? b.created : "0")
                        : (a.HasOwnProp("created") ? a.created : "0") < (b.HasOwnProp("created") ? b.created : "0")
                )
            case "title":
                ; Sort by title
                this.notes := this.BubbleSort(this.notes, (a, b) => 
                    isAsc
                        ? StrCompare(String(a.title), String(b.title), 0) < 0
                        : StrCompare(String(a.title), String(b.title), 0) > 0
                )
            case "length":
                ; Sort by content length
                this.notes := this.BubbleSort(this.notes, (a, b) => 
                    isAsc
                        ? StrLen(a.content) > StrLen(b.content)
                        : StrLen(a.content) < StrLen(b.content)
                )
        }
        
        ; Restore current note index by finding the note with matching title
        if currentTitle {
            Loop this.notes.Length {
                if this.notes[A_Index].title = currentTitle {
                    this.currentNoteIndex := A_Index - 1
                    break
                }
            }
        }
    }
    
    BubbleSort(arr, compareFunc) {
        ; Simple bubble sort implementation
        n := arr.Length
        if n <= 1 {
            return arr
        }
        
        Loop n - 1 {
            i := A_Index
            Loop n - i {
                j := A_Index
                if !compareFunc(arr[j], arr[j + 1]) {
                    ; Swap elements
                    temp := arr[j]
                    arr[j] := arr[j + 1]
                    arr[j + 1] := temp
                }
            }
        }
        
        return arr
    }
    
    ; ========================================
    ; FILE OPERATIONS (BASE64)
    ; ========================================
    
    LoadNotes() {
        this.notes := []
        
        if !FileExist(this.notesFile) {
            return
        }
        
        try {
            ; Try reading with explicit encoding
            content := FileRead(this.notesFile, "UTF-8")
            if !content {
                return
            }
            
            ; Parse line-based format: TITLE|BASE64_TITLE|CONTENT|BASE64_CONTENT
            content := Trim(content)
            lines := StrSplit(content, "`n", "`r")
            
            for line in lines {
                line := Trim(line)
                if !line || line = "" {
                    continue
                }
                
                ; Parse format: TITLE|base64title|CONTENT|base64content|CREATED|timestamp|MODIFIED|timestamp
                parts := StrSplit(line, "|")
                if parts.Length >= 4 && parts[1] = "TITLE" && parts[3] = "CONTENT" {
                    note := {}
                    note.title := this.Base64Decode(parts[2])
                    note.content := this.Base64Decode(parts[4])
                    
                    ; Load timestamps if available
                    if parts.Length >= 6 && parts[5] = "CREATED" {
                        note.created := parts[6]
                    } else {
                        note.created := A_Now  ; Default to current time
                    }
                    
                    if parts.Length >= 8 && parts[7] = "MODIFIED" {
                        note.modified := parts[8]
                    } else {
                        note.modified := A_Now  ; Default to current time
                    }
                    
                    this.notes.Push(note)
                }
            }
            
            this.SortNotes()
            this.RefreshNotesList()
            
        } catch as err {
            MsgBox("Error loading notes: " . err.Message . "`n`nStarting with empty notes.", "Load Error", "Icon!")
            this.notes := []
        }
    }
    
    SaveNotesToFile() {
        try {
            ; Ensure directory exists
            dir := RegExReplace(this.notesFile, "\\[^\\]*$", "")
            if !DirExist(dir) {
                DirCreate(dir)
            }
            
            ; Convert notes to Base64-encoded format (one note per line)
            ; Format: TITLE|base64title|CONTENT|base64content|CREATED|timestamp|MODIFIED|timestamp
            output := ""
            
            for note in this.notes {
                titleB64 := this.Base64Encode(note.title)
                contentB64 := this.Base64Encode(note.content)
                
                ; Ensure timestamps exist
                if !note.HasOwnProp("created") {
                    note.created := A_Now
                }
                if !note.HasOwnProp("modified") {
                    note.modified := A_Now
                }
                
                output .= "TITLE|" . titleB64 . "|CONTENT|" . contentB64 . "|CREATED|" . note.created . "|MODIFIED|" . note.modified . "`n"
            }
            
            ; Write to file
            if FileExist(this.notesFile) {
                FileDelete(this.notesFile)
            }
            FileAppend(output, this.notesFile, "UTF-8")
            
        } catch as err {
            MsgBox("Error saving notes: " . err.Message, "Save Error", "Icon!")
        }
    }
    
    ; ========================================
    ; BASE64 ENCODING UTILITIES
    ; ========================================
    
    Base64Encode(str) {
        ; Encode string to Base64 using Windows COM
        if !str {
            return ""
        }
        
        try {
            ; Convert string to bytes
            bytes := Buffer(StrPut(str, "UTF-8"))
            StrPut(str, bytes, "UTF-8")
            byteCount := StrPut(str, "UTF-8") - 1  ; Exclude null terminator
            
            ; Use MSXML2.DOMDocument for Base64 encoding
            xml := ComObject("MSXML2.DOMDocument")
            node := xml.createElement("b64")
            node.dataType := "bin.base64"
            
            ; Write bytes to node
            stream := ComObject("ADODB.Stream")
            stream.Type := 1  ; Binary
            stream.Open()
            stream.Write(bytes)
            stream.Position := 0
            node.nodeTypedValue := stream.Read(byteCount)
            stream.Close()
            
            return node.text
        } catch {
            ; Fallback: simple character code encoding
            result := ""
            Loop Parse str {
                if result
                    result .= ","
                result .= Ord(A_LoopField)
            }
            return "FALLBACK:" . result
        }
    }
    
    Base64Decode(encoded) {
        ; Decode Base64 string using Windows COM
        if !encoded {
            return ""
        }
        
        try {
            ; Check for fallback encoding
            if SubStr(encoded, 1, 9) = "FALLBACK:" {
                codes := StrSplit(SubStr(encoded, 10), ",")
                result := ""
                for code in codes {
                    result .= Chr(code)
                }
                return result
            }
            
            ; Use MSXML2.DOMDocument for Base64 decoding
            xml := ComObject("MSXML2.DOMDocument")
            node := xml.createElement("b64")
            node.dataType := "bin.base64"
            node.text := encoded
            
            ; Get decoded bytes
            stream := ComObject("ADODB.Stream")
            stream.Type := 1  ; Binary
            stream.Open()
            stream.Write(node.nodeTypedValue)
            stream.Position := 0
            stream.Type := 2  ; Text
            stream.Charset := "utf-8"
            result := stream.ReadText()
            stream.Close()
            
            return result
        } catch {
            return encoded  ; Return as-is if decoding fails
        }
    }

    ; ========================================
    ; VISIBILITY & HOTKEYS
    ; ========================================
    
    Show() {
        if this.isVisible {
            return
        }
        
        this.isVisible := true
        this.gui.Show()
        this.SetupGUIHotkeys()  ; Enable GUI-specific hotkeys
        
        ; Always focus on search field when opening
        this.searchEdit.Focus()
    }
    
    Hide() {
        if !this.isVisible {
            return
        }
        
        this.isVisible := false
        this.RemoveGUIHotkeys()  ; Disable GUI-specific hotkeys
        this.gui.Hide()
        
        ; Save current note on hide if auto-save is enabled
        if this.settings.autoSave && this.currentNoteIndex >= 0 {
            this.SaveCurrentNote()
        }
    }
    
    Toggle() {
        if this.isVisible {
            this.Hide()
        } else {
            this.Show()
        }
    }
    
    SetupHotkey() {
        try {
            ; Main hotkey to toggle the application
            Hotkey(this.settings.hotkey, (*) => this.Toggle())
            
            ; Set up GUI-specific hotkeys directly on controls
            ; This is more reliable than HotIf conditions
            
        } catch as err {
            ; Ignore hotkey errors
        }
    }
    
    ; Set up additional hotkeys when GUI is shown
    SetupGUIHotkeys() {
        try {
            ; Use a more direct approach - set hotkeys when GUI is active
            ; and remove them when hidden
            Hotkey("Escape", (*) => this.Hide(), "On")
            Hotkey("^s", (*) => this.SaveCurrentNote(), "On")
            Hotkey("^n", (*) => this.CreateNewNote(), "On")
            ; Add Ctrl+Delete to delete current note (so regular Delete works for text editing)
            Hotkey("^Delete", (*) => this.DeleteCurrentNote(), "On")
            ; Add Enter key handler for title field navigation
            Hotkey("Enter", (*) => this.OnEnterPressed(), "On")
        } catch as err {
            ; Ignore hotkey errors
        }
    }
    
    ; Handle Enter key press
    OnEnterPressed() {
        ; Check if title field is currently focused
        try {
            if (this.gui.FocusedCtrl = this.titleEdit) {
                ; Move focus to content box
                this.textBox.Focus()
                return true
            }
        } catch {
            ; Ignore focus checking errors
        }
        return false
    }
    
    ; Remove GUI hotkeys when hidden
    RemoveGUIHotkeys() {
        try {
            Hotkey("Escape", "Off")
            Hotkey("^s", "Off") 
            Hotkey("^n", "Off")
            Hotkey("^Delete", "Off")
            Hotkey("Enter", "Off")
        } catch as err {
            ; Ignore hotkey errors
        }
    }
    
    ; ========================================
    ; SETTINGS
    ; ========================================
    
    ShowSettings() {
        settingsGui := Gui("-Resize -MaximizeBox", "Quick Notes Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        settingsGui.BackColor := this.colors.bg
        
        ; Hotkey setting
        settingsGui.AddText("xm ym w100 c" . this.colors.text, "Hotkey:")
        hotkeyEdit := settingsGui.AddEdit("x+10 yp-3 w250 Background" . this.colors.surface0 . " c" . this.colors.text, this.settings.hotkey)
        
        ; Font settings
        settingsGui.AddText("xm y+20 w100 c" . this.colors.text, "Font Name:")
        fontEdit := settingsGui.AddEdit("x+10 yp-3 w250 Background" . this.colors.surface0 . " c" . this.colors.text, this.settings.fontName)
        
        settingsGui.AddText("xm y+15 w100 c" . this.colors.text, "Font Size:")
        sizeEdit := settingsGui.AddEdit("x+10 yp-3 w250 Background" . this.colors.surface0 . " c" . this.colors.text, this.settings.fontSize)
        
        ; Max notes setting
        settingsGui.AddText("xm y+15 w100 c" . this.colors.text, "Max Notes:")
        maxNotesEdit := settingsGui.AddEdit("x+10 yp-3 w250 Background" . this.colors.surface0 . " c" . this.colors.text, this.settings.maxNotes)

        ; Export path setting
        settingsGui.AddText("xm y+15 w100 c" . this.colors.text, "Export Path:")
        exportPathEdit := settingsGui.AddEdit("x+10 yp-3 w250 Background" . this.colors.surface0 . " c" . this.colors.text, this.settings.exportPath)
        settingsGui.AddButton("x+5 yp w30 Background" . this.colors.mauve . " c" . this.colors.bg, "📂").OnEvent("Click", (*) => (
            selected := DirSelect(exportPathEdit.Value),
            selected ? exportPathEdit.Value := selected : ""
        ))
        
        ; Options
        settingsGui.AddText("xm y+20 c" . this.colors.text, "Options:")
        alwaysOnTopCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.alwaysOnTop ? "1" : "0"), "Always on top")
        autoSaveCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.autoSave ? "1" : "0"), "Auto-save")
        
        ; Info
        settingsGui.AddText("xm y+25 w280 c" . this.colors.subtext1, "Notes are automatically saved as JSON.")
        settingsGui.AddText("xm y+5 w280 c" . this.colors.subtext1, "Current notes: " . this.notes.Length . " | Storage: " . this.notesFile)
        
        ; Buttons
        settingsGui.AddButton("xm y+25 w80 Background" . this.colors.green . " c" . this.colors.bg, "Save").OnEvent("Click", (*) => this.SaveSettings(settingsGui, hotkeyEdit, fontEdit, sizeEdit, maxNotesEdit, alwaysOnTopCheck, autoSaveCheck, exportPathEdit))
        settingsGui.AddButton("x+10 yp w80 Background" . this.colors.red . " c" . this.colors.bg, "Cancel").OnEvent("Click", (*) => settingsGui.Destroy())
        settingsGui.AddButton("x+10 yp w100 Background" . this.colors.yellow . " c" . this.colors.bg, "Export Notes").OnEvent("Click", (*) => this.ExportNotes())
        
        settingsGui.Show("w450 h450")
    }
    
SaveSettings(gui, hotkeyEdit, fontEdit, sizeEdit, maxNotesEdit, alwaysOnTopCheck, autoSaveCheck, exportPathEdit) {
        ; Update export path
        if IsSet(exportPathEdit) {
            this.settings.exportPath := exportPathEdit.Value
        }
        ; Update settings
        oldHotkey := this.settings.hotkey
        this.settings.hotkey := hotkeyEdit.Value
        this.settings.fontName := fontEdit.Value
        this.settings.fontSize := Integer(sizeEdit.Value)
        this.settings.maxNotes := Integer(maxNotesEdit.Value)
        this.settings.alwaysOnTop := alwaysOnTopCheck.Value
        this.settings.autoSave := autoSaveCheck.Value
        
        ; Update hotkey if changed
        if this.settings.hotkey != oldHotkey {
            try {
                if oldHotkey {
                    Hotkey(oldHotkey, "Off")
                }
                this.SetupHotkey()
            } catch as err {
                MsgBox("Error updating hotkey: " . err.Message, "Error", "Icon!")
            }
        }
        
        ; Completely rebuild the GUI to apply font changes
        ; This is the most reliable way to update fonts in AutoHotkey v2
        this.UpdateUIFonts()
        
        ; Clean up old notes if max changed
        if this.notes.Length > this.settings.maxNotes {
            ; Remove excess notes from the end
            while this.notes.Length > this.settings.maxNotes {
                this.notes.RemoveAt(this.notes.Length)
            }
            this.SaveNotesToFile()
            this.RefreshNotesList()
        }
        
        ; Save settings to INI file
        this.SaveSettingsToFile()
        
        ; Save settings to INI file
        this.SaveSettingsToFile()
        
        MsgBox("Settings saved! Your changes will persist between script reloads.", "Settings", "Icon!")
        gui.Destroy()
    }
    
    ExportNotes() {
        try {
            exportDir := this.settings.exportPath
            if !DirExist(exportDir) {
                DirCreate(exportDir)
            }
            
            exportedCount := 0
            
            ; Export each note as a separate file
            for note in this.notes {
                ; Create safe filename from title
                safeTitle := RegExReplace(note.title, "[^a-zA-Z0-9_-]", "_")
                exportFile := exportDir . "\" . safeTitle . ".txt"
                
                ; If file exists, append number
                counter := 1
                while FileExist(exportFile) {
                    exportFile := exportDir . "\" . safeTitle . "_" . counter . ".txt"
                    counter++
                }
                
                FileAppend(note.content, exportFile, "UTF-8")
                exportedCount++
            }
            
            MsgBox("Exported " . exportedCount . " notes to:`n" . exportDir, "Export Complete", "Icon!")
        } catch as err {
            MsgBox("Error exporting notes: " . err.Message, "Export Error", "Icon!")
        }
    }

    ExportCurrentNote() {
        try {
            if this.currentNoteIndex < 0 || this.currentNoteIndex >= this.notes.Length {
                MsgBox("No note selected to export.", "Export Current Note", "Icon!")
                return
            }
            note := this.notes[this.currentNoteIndex + 1]
            safeTitle := RegExReplace(note.title, "[^a-zA-Z0-9_-]", "_")
            exportDir := this.settings.exportPath
            if !DirExist(exportDir) {
                DirCreate(exportDir)
            }
            exportFile := exportDir . "\" . safeTitle . ".txt"
            FileAppend(note.content, exportFile, "UTF-8")
            MsgBox("Current note exported to: " . exportFile, "Export Complete", "Icon!")
        } catch as err {
            MsgBox("Error exporting note: " . err.Message, "Export Error", "Icon!")
        }
    }
    
    ; ========================================
    ; SETTINGS PERSISTENCE
    ; ========================================
    
    ; Save settings to INI file to persist between reloads
    SaveSettingsToFile() {
        try {
            settingsFile := A_ScriptDir . "\Settings\QuickNoteTaker_settings.ini"
            
            ; Save all settings to INI file
            IniWrite(this.settings.hotkey, settingsFile, "Settings", "Hotkey")
            IniWrite(this.settings.fontName, settingsFile, "Settings", "FontName")
            IniWrite(this.settings.fontSize, settingsFile, "Settings", "FontSize")
            IniWrite(this.settings.maxNotes, settingsFile, "Settings", "MaxNotes")
            IniWrite(this.settings.alwaysOnTop ? 1 : 0, settingsFile, "Settings", "AlwaysOnTop")
            IniWrite(this.settings.autoSave ? 1 : 0, settingsFile, "Settings", "AutoSave")
            IniWrite(this.settings.windowWidth, settingsFile, "Settings", "WindowWidth")
            IniWrite(this.settings.windowHeight, settingsFile, "Settings", "WindowHeight")
            IniWrite(this.settings.exportPath, settingsFile, "Settings", "ExportPath")
            
            return true
        } catch as err {
            return false
        }
    }
    
    ; Load settings from INI file
    LoadSettingsFromFile() {
        try {
            settingsFile := A_ScriptDir . "\Settings\QuickNoteTaker_settings.ini"
            
            ; Check if settings file exists
            if !FileExist(settingsFile) {
                return false
            }
            
            ; Load settings with fallbacks to defaults
            this.settings.hotkey := IniRead(settingsFile, "Settings", "Hotkey", this.settings.hotkey)
            this.settings.fontName := IniRead(settingsFile, "Settings", "FontName", this.settings.fontName)
            this.settings.fontSize := Integer(IniRead(settingsFile, "Settings", "FontSize", this.settings.fontSize))
            this.settings.maxNotes := Integer(IniRead(settingsFile, "Settings", "MaxNotes", this.settings.maxNotes))
            this.settings.alwaysOnTop := IniRead(settingsFile, "Settings", "AlwaysOnTop", this.settings.alwaysOnTop) = "1"
            this.settings.autoSave := IniRead(settingsFile, "Settings", "AutoSave", this.settings.autoSave) = "1"
            this.settings.windowWidth := Integer(IniRead(settingsFile, "Settings", "WindowWidth", this.settings.windowWidth))
            this.settings.windowHeight := Integer(IniRead(settingsFile, "Settings", "WindowHeight", this.settings.windowHeight))
            this.settings.exportPath := IniRead(settingsFile, "Settings", "ExportPath", this.settings.exportPath)
            this.settings.sortBy := IniRead(settingsFile, "Settings", "SortBy", "modified")
            this.settings.sortDirection := IniRead(settingsFile, "Settings", "SortDirection", "asc")
            
            return true
        } catch as err {
            return false
        }
    }
    
    ; ========================================
    ; UTILITY
    ; ========================================
    
    ; Helper function to repeat strings
    StrRepeat(str, count) {
        result := ""
        Loop count {
            result .= str
        }
        return result
    }
    
    ; Method to update all UI fonts
    UpdateUIFonts() {
        ; This method ensures all UI elements use the current font settings
        try {
            ; First destroy and recreate the GUI to ensure proper font application
            oldVisible := this.isVisible
            currentNote := this.currentNoteIndex
            
            ; Store current values
            titleValue := this.titleEdit.Value
            textValue := this.textBox.Value
            
            ; Hide current GUI
            if this.isVisible {
                this.gui.Hide()
            }
            
            ; Destroy and recreate GUI with new font settings
            this.gui.Destroy()
            this.CreateGUI()
            
            ; Restore values
            this.titleEdit.Value := titleValue
            this.textBox.Value := textValue
            
            ; Refresh the notes list
            this.RefreshNotesList()
            
            ; Restore visibility
            if oldVisible {
                this.gui.Show()
                this.isVisible := true
            }
            
            ; Restore note selection if there was one
            if currentNote >= 0 && currentNote < this.notes.Length {
                this.LoadNote(currentNote)
            }
            
            return true
        } catch as err {
            MsgBox("Error updating fonts: " . err.Message, "Font Update Error", "Icon!")
            return false
        }
    }
    
}
