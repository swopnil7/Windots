; Fixed Explorer Dialog Path Selector Class
; This is a complete rewrite with improved implementation
; Source: Based on ThioJoe's script but rewritten for better reliability

; Try to include the RemoteTreeView library
try {
    #Include "..\Lib\RemoteTreeView.ahk"
} catch {
    ; Library not found - some features won't work but script will still run
}

; ========================================
; EXPLORER DIALOG CLASS
; ========================================

class ExplorerDialog {
    ; Properties
    parentManager := ""
    isInitialized := false
    boundMenuHandler := ""
    
    ; Settings
    settings := {
        hotkey: "MButton",
        favoritePaths: [],
        recentFolders: [],
        maxRecentFolders: 20,
        enableDebug: true,
        activePrefix: "► ",
        inactivePrefix: "    "
    }
    
    ; Constructor - takes parent manager reference
    __New(parentManager := "") {
        this.parentManager := parentManager
        this.boundMenuHandler := this.ShowPathMenu.Bind(this)
        this.LoadSettings()
        this.isInitialized := true
    }
    
    ; ========================================
    ; SETTINGS MANAGEMENT
    ; ========================================
    
    LoadSettings() {
        settingsFile := A_ScriptDir "\Settings\explorer_settings.ini"
        if FileExist(settingsFile) {
            try {
                this.settings.hotkey := IniRead(settingsFile, "Settings", "Hotkey", "MButton")
                this.settings.enableDebug := IniRead(settingsFile, "Settings", "EnableDebug", "0") = "1"
                
                ; Load favorite paths
                this.settings.favoritePaths := []
                favCount := Integer(IniRead(settingsFile, "Favorites", "Count", "0"))
                Loop favCount {
                    path := IniRead(settingsFile, "Favorites", "Path" . A_Index, "")
                    if path {
                        this.settings.favoritePaths.Push(path)
                    }
                }
                
                ; Load recent folders
                this.settings.recentFolders := []
                recentCount := Integer(IniRead(settingsFile, "Recent", "Count", "0"))
                Loop recentCount {
                    path := IniRead(settingsFile, "Recent", "Path" . A_Index, "")
                    if path {
                        this.settings.recentFolders.Push(path)
                    }
                }
            } catch as err {
                ; Silent error handling
            }
        }
    }
    
    SaveSettings(showMessage := true) {
        settingsFile := A_ScriptDir "\Settings\explorer_settings.ini"
        settingsDir := A_ScriptDir "\Settings"
        
        ; Create directory if it doesn't exist
        if !DirExist(settingsDir) {
            DirCreate(settingsDir)
        }
        
        try {
            IniWrite(this.settings.enableDebug ? "1" : "0", settingsFile, "Settings", "EnableDebug")
            
            ; Save favorite paths
            IniWrite(this.settings.favoritePaths.Length, settingsFile, "Favorites", "Count")
            Loop this.settings.favoritePaths.Length {
                IniWrite(this.settings.favoritePaths[A_Index], settingsFile, "Favorites", "Path" . A_Index)
            }
            
            ; Save recent folders
            IniWrite(this.settings.recentFolders.Length, settingsFile, "Recent", "Count")
            Loop this.settings.recentFolders.Length {
                IniWrite(this.settings.recentFolders[A_Index], settingsFile, "Recent", "Path" . A_Index)
            }
            
            if showMessage {
                MsgBox("✅ Settings saved successfully!", "⚙️ Settings", "Icon!")
            }
        } catch as err {
            if showMessage {
                MsgBox("❌ Error saving settings: " . err.Message, "⚠️ Error", "Icon!")
            }
        }
    }
    
    ; ========================================
    ; HOTKEY MANAGEMENT
    ; ========================================
    
    SetupHotkey() {
        try {
            if this.settings.hotkey {
                Hotkey(this.settings.hotkey, this.boundMenuHandler, "On")
            }
        } catch as err {
            MsgBox("❌ Error setting up hotkey '" . this.settings.hotkey . "': " . err.Message, "⌨️ Hotkey Error", "Icon!")
        }
    }
    
    UpdateHotkey(newHotkey) {
        ; Remove old hotkey
        try {
            if this.settings.hotkey {
                Hotkey(this.settings.hotkey, "Off")
            }
        } catch {
            ; Ignore errors when removing old hotkey
        }
        
        ; Set new hotkey
        this.settings.hotkey := newHotkey
        this.SetupHotkey()
    }
    
    ; ========================================
    ; PATH COLLECTION
    ; ========================================
    
    GetExplorerPaths() {
        paths := []
        try {
            shell := ComObject("Shell.Application")
            windows := shell.Windows
            
            for window in windows {
                try {
                    if window && window.Document && window.Document.Folder {
                        path := window.Document.Folder.Self.Path
                        if path && DirExist(path) {
                            paths.Push({
                                path: path,
                                hwnd: window.HWND,
                                isActive: true ; Simplified for now
                            })
                        }
                    }
                } catch {
                    continue ; Skip this window
                }
            }
        } catch as err {
            ; Silent error handling
        }
        return paths
    }
    
    ; ========================================
    ; MENU DISPLAY
    ; ========================================
    
    ShowPathMenu(*) {
        ; Get window under cursor
        MouseGetPos(, , &windowID)
        if !windowID {
            return
        }
        try {
            windowClass := WinGetClass("ahk_id " . windowID)
        } catch {
            return
        }
        ; Allow menu for dialogs, consoles, Java dialogs, and Explorer windows
        if !(windowClass ~= "i)^(#32770|ConsoleWindowClass|CASCADIA_HOSTING_WINDOW_CLASS|WindowsTerminalPaneWindow|SunAwtDialog|CabinetWClass|ExplorerWClass)$") {
            return
        }
        
        ; Collect all available items
        recentItems := []
        favoriteItems := []
        explorerItems := []
        
        ; Get recent folders (exclude those already in favorites)
        for path in this.settings.recentFolders {
            isDuplicate := false
            for favPath in this.settings.favoritePaths {
                if path = favPath {
                    isDuplicate := true
                    break
                }
            }
            if !isDuplicate {
                recentItems.Push(path)
            }
        }
        
        ; Get favorites
        for path in this.settings.favoritePaths {
            favoriteItems.Push(path)
        }
        
        ; Get Explorer windows
        explorerPaths := this.GetExplorerPaths()
        for pathObj in explorerPaths {
            explorerItems.Push(pathObj)
        }
        
        ; Simple distribution: Favorites (all), Explorer (all), Recent (max 4)
        favoriteShow := favoriteItems.Length
        explorerShow := explorerItems.Length
        recentShow := Min(recentItems.Length, 4)
        
        ; Create menu
        pathMenu := Menu()
        itemCount := 0
        
        ; Add favorites FIRST for visibility
        if favoriteShow > 0 {
            pathMenu.Add("⭐ Favorites", (*) => "")
            pathMenu.Disable("⭐ Favorites")
            itemCount++
            
            Loop favoriteShow {
                path := favoriteItems[A_Index]
                displayText := this.settings.inactivePrefix . path
                capturedPath := path
                pathMenu.Add(displayText, ((p) => (item, pos, menu) => this.NavigateToPath(p, windowID, windowClass))(capturedPath))
                itemCount++
            }
            
            pathMenu.Add()
            itemCount++
        }
        
        ; Add recent folders
        if recentShow > 0 {
            pathMenu.Add("🕒 Recent Folders", (*) => "")
            pathMenu.Disable("🕒 Recent Folders")
            itemCount++
            
            Loop recentShow {
                path := recentItems[A_Index]
                displayText := this.settings.inactivePrefix . path
                capturedPath := path
                pathMenu.Add(displayText, ((p) => (item, pos, menu) => this.NavigateToPath(p, windowID, windowClass))(capturedPath))
                itemCount++
            }
            
            pathMenu.Add()
            itemCount++
        }
        
        ; Add Explorer windows
        if explorerShow > 0 {
            pathMenu.Add("🖥️ Explorer Windows", (*) => "")
            pathMenu.Disable("🖥️ Explorer Windows")
            itemCount++
            
            Loop explorerShow {
                pathObj := explorerItems[A_Index]
                prefix := pathObj.isActive ? this.settings.activePrefix : this.settings.inactivePrefix
                displayText := prefix . pathObj.path
                capturedPath := pathObj.path
                pathMenu.Add(displayText, ((p) => (item, pos, menu) => this.NavigateToPath(p, windowID, windowClass))(capturedPath))
                itemCount++
            }
            
            pathMenu.Add()
            itemCount++
        }
        
        ; Add clipboard path if valid
        if DirExist(A_Clipboard) {
            if itemCount > 0 {
                pathMenu.Add()
                itemCount++
            }
            pathMenu.Add("📋 From Clipboard", (*) => "")
            pathMenu.Disable("📋 From Clipboard")
            displayText := this.settings.inactivePrefix . A_Clipboard
            ; Capture clipboard path value in closure
            capturedClipboardPath := A_Clipboard
            pathMenu.Add(displayText, ((p) => (item, pos, menu) => this.NavigateToPath(p, windowID, windowClass))(capturedClipboardPath))
            itemCount += 2
        }
        
        ; Show menu or message
        if itemCount > 0 {
            pathMenu.Show()
        } else {
            ToolTip("❌ No paths available")
            SetTimer(() => ToolTip(), -2000)
        }
    }
    
    ; ========================================
    ; NAVIGATION
    ; ========================================
    
    NavigateToPath(path, windowID, windowClass) {
        ; Validate inputs
        if !path || !windowID || !windowClass {
            return
        }
        ; Check if path exists
        if !DirExist(path) {
            MsgBox("❌ Path does not exist: " . path, "⚠️ Error", "Icon!")
            return
        }
        
        ; Track this folder usage
        this.TrackFolderUsage(path)
        
        ; Activate the target window
        try {
            WinActivate("ahk_id " . windowID)
            Sleep(100) ; Give it time to activate
        } catch {
            return
        }
        ; Verify window is still valid
        try {
            currentClass := WinGetClass("ahk_id " . windowID)
            if currentClass != windowClass {
                return
            }
        } catch {
            return
        }
        ; Handle different window types
        switch windowClass {
            case "ConsoleWindowClass", "CASCADIA_HOSTING_WINDOW_CLASS":
                this.NavigateConsole(path)
            case "SunAwtDialog":
                this.NavigateJavaDialog(path)
            case "CabinetWClass", "ExplorerWClass":
                this.NavigateExplorerWindow(path, windowID)
            default:
                this.NavigateStandardDialog(path, windowID)
        }
    }

    ; ========================================
    ; FOLDER TRACKING
    ; ========================================
    
    TrackFolderUsage(path) {
        if !path || !DirExist(path) {
            return
        }
        
        ; Add to recent folders
        ; Remove if already exists
        for i, folder in this.settings.recentFolders {
            if folder = path {
                this.settings.recentFolders.RemoveAt(i)
                break
            }
        }
        
        ; Add to beginning
        this.settings.recentFolders.InsertAt(1, path)
        
        ; Trim to max
        while this.settings.recentFolders.Length > this.settings.maxRecentFolders {
            this.settings.recentFolders.Pop()
        }
        
        ; Save settings silently
        this.SaveSettings(false)
    }

    NavigateExplorerWindow(path, windowID) {
        ; Activate the window and use F4 to focus the address bar, then enter the path
        try {
            WinActivate("ahk_id " . windowID)
            Sleep(100)
            ; Use F4 to focus the address bar (works in Explorer windows)
            SendInput("{F4}")
            Sleep(100)
            SendInput("^a") ; Ctrl+A to select all
            Sleep(50)
            SendInput(path)
            Sleep(50)
            SendInput("{Enter}")
            ; Fallback: if path did not change, try clicking address bar
            ; Optionally, you can add ControlClick or UIA automation here if needed
        } catch {
            MsgBox("❌ Failed to navigate Explorer window.", "⚠️ Error", "Icon!")
        }
    }
    
    NavigateConsole(path) {
        SendInput("{Esc}pushd `"" . path . "`"{Enter}")
    }
    
    NavigateJavaDialog(path) {
        ; Java dialogs need special handling
        SendInput("!n") ; Alt+N to focus name field
        Sleep(50)
        SendInput("^a") ; Select all
        Sleep(50)
        SendInput(path . "\")
        Sleep(50)
        SendInput("{Enter}")
        Sleep(50)
        SendInput("^a{Delete}") ; Clear the field
    }
    
    NavigateStandardDialog(path, windowID) {
        ; Try address bar method first (modern dialogs)
        if this.TryNavigateAddressBar(path, windowID) {
            return
        }
        
        ; Fall back to edit control method (legacy dialogs)
        this.TryNavigateEditControl(path, windowID)
    }
    
    TryNavigateAddressBar(path, windowID) {
        try {
            ; Try to find the address bar edit control directly (usually Edit2 or Edit3)
            editControls := []
            WinGetControls := WinGetControls("ahk_id " . windowID)
            for ctrl in StrSplit(WinGetControls, "\n") {
                if (ctrl ~= "^Edit[2-9]$") {
                    editControls.Push(ctrl)
                }
            }
            for ctrl in editControls {
                ; Try to focus and set text
                ControlFocus(ctrl, "ahk_id " . windowID)
                Sleep(100)
                ControlSetText("", ctrl, "ahk_id " . windowID)
                Sleep(100)
                ControlSetText(path, ctrl, "ahk_id " . windowID)
                Sleep(100)
                ControlSend("{Enter}", ctrl, "ahk_id " . windowID)
                Sleep(200)
                ; Optionally, return focus to filename box if it exists
                try {
                    ControlFocus("Edit1", "ahk_id " . windowID)
                } catch {
                }
                return true
            }
            return false
        } catch as err {
            return false
        }
    }
    
    TryNavigateEditControl(path, windowID) {
        try {
            ; Find the filename edit control
            edit1Hwnd := ControlGetHwnd("Edit1", "ahk_id " . windowID)
            if !edit1Hwnd {
                return false
            }
            
            ; Save original text
            originalText := ControlGetText("Edit1", "ahk_id " . windowID)
            
            ; Focus the control first
            ControlFocus("Edit1", "ahk_id " . windowID)
            Sleep(100)
            
            ; Clear and set path using a more direct method
            ControlSetText(path, "Edit1", "ahk_id " . windowID)
            Sleep(100)
            
            ; Instead of PostMessage, try using keyboard shortcut
            ControlSend("{Enter}", "Edit1", "ahk_id " . windowID)
            Sleep(200)
            
            ; Check if navigation was successful
            currentText := ControlGetText("Edit1", "ahk_id " . windowID)
            
            ; If the path was accepted (field cleared or changed), restore original filename
            if currentText = "" || currentText = path {
                ControlSetText(originalText, "Edit1", "ahk_id " . windowID)
            }
            
            return true
            
        } catch as err {
            return false
        }
    }
    
    ; ========================================
    ; GUI WINDOWS
    ; ========================================
    
    ShowSettingsGUI() {
        local myWindow, debugCheck, favEdit
        
        ; Catppuccin Mocha colors for settings window
        colors := {
            bg: "0x1e1e2e",
            surface0: "0x313244",
            text: "0xcdd6f4",
            subtext1: "0xbac2de",
            green: "0xa6e3a1",
            red: "0xf38ba8",
            blue: "0x89b4fa",
            mauve: "0xcba6f7"
        }
        
        myWindow := Gui("+Resize", "⚙️ Path Selector Settings")
        myWindow.SetFont("s10", "Segoe UI")
        myWindow.BackColor := colors.bg
        
        ; Debug mode
        debugCheck := myWindow.AddCheckbox("xm ym c" . colors.text, "🔧 Enable Debug Mode")
        debugCheck.Value := this.settings.enableDebug
        
        ; Favorites section
        myWindow.AddText("xm y+20 c" . colors.text, "⭐ Favorite Paths:")
        myWindow.AddText("xm y+5 c" . colors.subtext1, "📝 Enter one path per line:")
        
        ; Create edit control with current favorites
        favText := ""
        for path in this.settings.favoritePaths {
            favText .= path . "`n"
        }
        
        favEdit := myWindow.AddEdit("xm y+5 w400 h150 VScroll Background" . colors.surface0 . " c" . colors.text, Trim(favText, "`n"))
        
        ; Buttons
        myWindow.AddButton("xm y+10 w80 Background" . colors.green . " c" . colors.bg, "💾 Save").OnEvent("Click", (*) => this.SaveSettingsFromGUI(myWindow, debugCheck, favEdit))
        myWindow.AddButton("x+10 yp w80 Background" . colors.red . " c" . colors.bg, "❌ Cancel").OnEvent("Click", (*) => myWindow.Destroy())
        myWindow.AddButton("x+10 yp w110 Background" . colors.blue . " c" . colors.bg, "➕ Add Current").OnEvent("Click", (*) => this.AddCurrentPath(favEdit))
        myWindow.AddButton("x+10 yp w80 Background" . colors.mauve . " c" . colors.bg, "📂 Browse").OnEvent("Click", (*) => this.BrowseFavoritePath(favEdit))
        
        myWindow.Show()
    }
    
    SaveSettingsFromGUI(myWindow, debugCheck, favEdit) {
        this.settings.enableDebug := debugCheck.Value
        
        ; Save favorites from the edit control
        text := favEdit.Value
        lines := StrSplit(text, "`n")
        
        this.settings.favoritePaths := []
        for line in lines {
            line := Trim(line)
            if line && DirExist(line) {
                this.settings.favoritePaths.Push(line)
            }
        }
        
        this.SaveSettings()
        myWindow.Destroy()
    }
    
    AddCurrentPath(editControl) {
        ; Try to get current path from active Explorer window
        try {
            shell := ComObject("Shell.Application")
            windows := shell.Windows
            
            ; First try to find the active window
            activeHwnd := WinGetID("A")
            
            for window in windows {
                try {
                    if window && window.Document && window.Document.Folder {
                        hwnd := window.HWND
                        ; Check if this is the active window
                        if hwnd = activeHwnd {
                            path := window.Document.Folder.Self.Path
                            if path && DirExist(path) {
                                current := editControl.Value
                                if current {
                                    editControl.Value := current . "`n" . path
                                } else {
                                    editControl.Value := path
                                }
                                return
                            }
                        }
                    }
                } catch {
                    continue
                }
            }
            
            ; If no active Explorer window found, try to find any Explorer window
            for window in windows {
                try {
                    if window && window.Document && window.Document.Folder {
                        path := window.Document.Folder.Self.Path
                        if path && DirExist(path) {
                            current := editControl.Value
                            if current {
                                editControl.Value := current . "`n" . path
                            } else {
                                editControl.Value := path
                            }
                            return
                        }
                    }
                } catch {
                    continue
                }
            }
        } catch {
            ; Ignore
        }
        
        MsgBox("❌ No active Explorer window found", "➕ Add Current Path", "Icon!")
    }
    
    BrowseFavoritePath(editControl) {
        ; Open folder selection dialog
        folder := DirSelect("*", 3, "📂 Select a folder to add to favorites")
        if folder {
            current := editControl.Value
            if current {
                editControl.Value := current . "`n" . folder
            } else {
                editControl.Value := folder
            }
        }
    }

    ; ========================================
    ; UTILITY
    ; ========================================
    
    ShowDebug(message) {
        if this.parentManager && this.parentManager.ShowDebug {
            this.parentManager.ShowDebug("ExplorerDialog: " . message)
        } else if this.settings.enableDebug {
            ; Fallback debug if no parent manager
            ToolTip("🔧 DEBUG: " . message, 100, 100)
            SetTimer(() => ToolTip(), -5000)
            OutputDebug(message)
            FileAppend(A_Now . " - " . message . "`n", A_ScriptDir . "\debug.log")
        }
    }
}
