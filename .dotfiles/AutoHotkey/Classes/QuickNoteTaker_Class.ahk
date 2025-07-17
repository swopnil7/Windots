; Quick Note Taker Class
; A floating notepad for quick notes with simple JSON storage and search
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
        this.notesFile := A_ScriptDir . "\Settings\quick_notes.json"
        ; Load settings from INI file BEFORE creating GUI so hotkey/exportPath are correct
        this.LoadSettingsFromFile()
        this.CreateGUI()
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
        this.gui.AddText("xm ym w100 c" . this.colors.subtext1, "Title:")
        this.titleEdit := this.gui.AddEdit("x+5 yp-3 w120 h20 Background" . this.colors.surface0 . " c" . this.colors.text)
        this.titleEdit.OnEvent("Change", (*) => this.OnTitleChange())
        this.titleEdit.OnEvent("LoseFocus", (*) => this.OnTitleLoseFocus())
        this.titleEdit.OnEvent("ContextMenu", (*) => "")  ; Disable right-click
        ; We'll handle Enter key with global hotkey when visible
        
        this.gui.AddText("x+10 yp+3 w45 c" . this.colors.subtext1, "Search:")
        this.searchEdit := this.gui.AddEdit("x+5 yp-3 w100 h20 Background" . this.colors.surface0 . " c" . this.colors.text)
        this.searchEdit.OnEvent("Change", (*) => this.OnSearchChange())
        this.searchEdit.OnEvent("ContextMenu", (*) => "")  ; Disable right-click
        
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
        this.statusBar := this.gui.AddText("xm y" . statusY . " w300 c" . this.colors.subtext1, "Ctrl+S: Save • Ctrl+N: New • Esc: Hide")
        
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
        
        ; Create note object
        note := {title: title, content: content}
        
        ; Update existing note or add new one
        if this.currentNoteIndex >= 0 && this.currentNoteIndex < this.notes.Length {
            ; Update existing note
            this.notes[this.currentNoteIndex + 1] := note
        } else {
            ; Add new note to beginning of array
            this.notes.InsertAt(1, note)
            this.currentNoteIndex := 0
        }
        
        ; Limit number of notes
        while this.notes.Length > this.settings.maxNotes {
            this.notes.RemoveAt(this.notes.Length)
        }
        
        this.SaveNotesToFile()
        this.RefreshNotesList()
        
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
        
        ; Save current note before switching
        if this.currentNoteIndex >= 0 && (this.textBox.Value || this.titleEdit.Value) {
            this.SaveCurrentNote()
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
        ; Auto-save when title field loses focus
        if this.settings.autoSave {
            this.SaveCurrentNote()
        }
    }
    
    OnTextLoseFocus() {
        ; Auto-save when content field loses focus
        if this.settings.autoSave {
            this.SaveCurrentNote()
        }
    }
    
    ; ========================================
    ; FILE OPERATIONS (JSON)
    ; ========================================
    
    LoadNotes() {
        this.notes := []
        
        if !FileExist(this.notesFile) {
            return
        }
        
        try {
            ; Try reading with explicit encoding
            content := FileRead(this.notesFile, "UTF-8-RAW")
            if !content {
                return
            }
            
            ; Remove BOM if present
            if SubStr(content, 1, 3) = Chr(0xEF) . Chr(0xBB) . Chr(0xBF) {
                content := SubStr(content, 4)
            }
            
            ; Simple JSON parsing
            content := Trim(content)
            if SubStr(content, 1, 1) = "[" && SubStr(content, -1) = "]" {
                ; Extract note objects
                objContent := SubStr(content, 2, StrLen(content) - 2)
                objects := this.SplitJSONObjects(objContent)
                
                for objStr in objects {
                    note := this.ParseJSONObject(objStr)
                    if note && note.HasOwnProp("title") {
                        this.notes.Push(note)
                    }
                }
            }
            
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
            
            ; Convert notes to JSON - use format that's easier to parse for AHK
            jsonStr := "["
            
            for i, note in this.notes {
                if i > 1 {
                    jsonStr .= ","
                }
                
                ; Build JSON object with concatenation that AHK handles better
                jsonStr .= "`n  {"
                jsonStr .= "`n    " . Chr(34) . "title" . Chr(34) . ": " . Chr(34) . this.EscapeJSON(note.title) . Chr(34) . ","
                jsonStr .= "`n    " . Chr(34) . "content" . Chr(34) . ": " . Chr(34) . this.EscapeJSON(note.content) . Chr(34)
                jsonStr .= "`n  }"
            }
            
            jsonStr .= "`n]"
            
            ; Write to file
            if FileExist(this.notesFile) {
                FileDelete(this.notesFile)
            }
            FileAppend(jsonStr, this.notesFile, "UTF-8")
            
        } catch as err {
            MsgBox("Error saving notes: " . err.Message, "Save Error", "Icon!")
        }
    }
    
    ; ========================================
    ; JSON UTILITIES
    ; ========================================
    
    JoinArray(arr, separator) {
        result := ""
        for i, item in arr {
            if i > 1 {
                result .= separator
            }
            result .= item
        }
        return result
    }
    
    SplitJSONObjects(content) {
        ; Split JSON objects in array
        objects := []
        braceDepth := 0
        current := ""
        inString := false
        escaped := false
        i := 1
        
        while i <= StrLen(content) {
            char := SubStr(content, i, 1)
            
            if escaped {
                current .= char
                escaped := false
                i++
                continue
            }
            
            if char = "\" && inString {
                current .= char
                escaped := true
                i++
                continue
            }
            
            if char = '"' {
                inString := !inString
                current .= char
                i++
                continue
            }
            
            if !inString {
                if char = "{" {
                    braceDepth++
                    current .= char
                } else if char = "}" {
                    braceDepth--
                    current .= char
                    
                    if braceDepth = 0 && Trim(current) {
                        ; Complete object found
                        objects.Push(Trim(current))
                        current := ""
                    }
                } else if char = "," && braceDepth = 0 {
                    ; Skip commas between objects at top level
                    ; Don't add to current
                } else {
                    current .= char
                }
            } else {
                current .= char
            }
            i++
        }
        
        ; Add final object if exists and complete
        if Trim(current) && braceDepth = 0 {
            objects.Push(Trim(current))
        }
        
        return objects
    }
    
    ParseJSONObject(objStr) {
        ; Parse a single JSON object for title and content
        objStr := Trim(objStr)
        
        if !objStr || !RegExMatch(objStr, "^\s*\{[\s\S]*\}\s*$") {
            return ""
        }
        
        note := {}
        
        ; Extract title
        if RegExMatch(objStr, '"title"\s*:\s*"([^"]*(?:\\.[^"]*)*)"', &match) {
            note.title := this.UnescapeJSON(match[1])
        }
        
        ; Extract content (handle multiline)
        if RegExMatch(objStr, '"content"\s*:\s*"([^"]*(?:\\.[^"]*)*)"', &match) {
            note.content := this.UnescapeJSON(match[1])
        }
        
        return note
    }
    
    EscapeJSON(str) {
        ; Simple JSON string escaping
        if !str {
            return ""
        }
        
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\\n")
        str := StrReplace(str, "`r", "\\r")
        str := StrReplace(str, "`t", "\\t")
        
        return str
    }
    
    UnescapeJSON(str) {
        ; Simple JSON string unescaping
        str := StrReplace(str, "\\n", "`n")
        str := StrReplace(str, "\\r", "`r")
        str := StrReplace(str, "\\t", "`t")
        str := StrReplace(str, '\"', '"')
        str := StrReplace(str, "\\", "\")
        
        return str
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
        
        ; Focus on title field if we have a new note, otherwise content
        if !this.titleEdit.Value && !this.textBox.Value {
            this.titleEdit.Focus()
        } else {
            this.textBox.Focus()
        }
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
            ; Add Delete key to delete current note
            Hotkey("Delete", (*) => this.OnDeleteKeyPressed(), "On")
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
    
    ; Handle Delete key press
    OnDeleteKeyPressed() {
        ; Only delete if we have a valid current note
        if this.currentNoteIndex >= 0 && this.currentNoteIndex < this.notes.Length {
            this.DeleteCurrentNote()
        }
    }
    
    ; Remove GUI hotkeys when hidden
    RemoveGUIHotkeys() {
        try {
            Hotkey("Escape", "Off")
            Hotkey("^s", "Off") 
            Hotkey("^n", "Off")
            Hotkey("Delete", "Off") ; Also turn off Delete key
            Hotkey("Enter", "Off")  ; Also turn off Enter key
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
            exportFile := exportDir . "\quick_notes_export_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".txt"
            exportContent := "Quick Notes Export - " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n"
            exportContent .= "=" . this.StrRepeat("=", 50) . "`n`n"
            ; Export each note
            for note in this.notes {
                exportContent .= "Title: " . note.title . "`n"
                exportContent .= this.StrRepeat("-", 40) . "`n"
                exportContent .= note.content . "`n`n"
                exportContent .= this.StrRepeat("=", 50) . "`n`n"
            }
            FileAppend(exportContent, exportFile, "UTF-8")
            MsgBox("Notes exported to: " . exportFile, "Export Complete", "Icon!")
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
