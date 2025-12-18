; Catppuccin App Launcher Class
; A Rofi-inspired application launcher for Windows
; Features: Fuzzy search, keyboard navigation, themed UI

; ========================================
; APP LAUNCHER CLASS
; ========================================

class CatppuccinAppLauncher {
    ; Catppuccin Mocha color palette
    colors := {
        bg: "0x1e1e2e",       ; Background
        mantle: "0x181825",    ; Darker background
        surface0: "0x313244",  ; Surface
        surface1: "0x585b70",  ; Lighter surface (more vibrant)
        surface2: "0x6c7086",  ; Even lighter surface for hover
        text: "0xcdd6f4",      ; Main text
        subtext1: "0xbac2de",  ; Dimmed text
        subtext0: "0xa6adc8",  ; More dimmed text
        blue: "0x89b4fa",      ; Accent blue
        mauve: "0xcba6f7",     ; Purple
        red: "0xf38ba8",       ; Red
        green: "0xa6e3a1",     ; Green
        yellow: "0xf9e2af",    ; Yellow
        peach: "0xfab387",     ; Orange/peach
        pink: "0xf5c2e7",      ; Pink
        lavender: "0xb4befe",  ; Light blue/lavender
        overlay0: "0x6c7086",  ; Overlay
        overlay1: "0x7f849c",  ; Lighter overlay
        overlay2: "0x9399b2"   ; Even lighter overlay
    }
    
    ; Settings
    settings := {
        hotkey: "LWin & Space",
        maxResults: 10,
        windowWidth: 600,
        windowHeight: 400,
        enableIcons: true,
        fuzzySearch: true,
        showPath: true
    }
    
    ; Internal state
    apps := []
    filteredApps := []
    selectedIndex := 1
    isVisible := false
    gui := ""
    searchBox := ""
    listBox := ""
    statusText := ""
    focusTimer := ""
    
    ; Constructor
    __New() {
        this.LoadApps()
        this.CreateGUI()
        this.SetupHotkey()
    }
    
    ; ========================================
    ; APP DISCOVERY
    ; ========================================
    
    LoadApps() {
        this.apps := []
        
        ; Scan common application directories
        this.ScanDirectory(A_ProgramFiles)
        this.ScanDirectory(A_ProgramFiles . " (x86)")
        this.ScanDirectory(A_AppData . "\Microsoft\Windows\Start Menu\Programs")
        this.ScanDirectory(EnvGet("ProgramData") . "\Microsoft\Windows\Start Menu\Programs")
        
        ; Add Windows built-in apps
        this.AddBuiltInApps()
        
        ; Sort alphabetically
        this.apps := this.SortApps(this.apps)
        this.filteredApps := this.apps.Clone()
    }
    
    ScanDirectory(dir) {
        if !DirExist(dir) {
            return
        }
        
        try {
            ; Scan for .exe files
            Loop Files, dir . "\*.exe", "R" {
                if this.IsValidApp(A_LoopFileFullPath) {
                    this.apps.Push({
                        name: A_LoopFileName,
                        displayName: StrReplace(A_LoopFileName, ".exe", ""),
                        path: A_LoopFileFullPath,
                        type: "exe"
                    })
                }
            }
            
            ; Scan for .lnk files (shortcuts)
            Loop Files, dir . "\*.lnk", "R" {
                try {
                    target := this.GetShortcutTarget(A_LoopFileFullPath)
                    if target && this.IsValidApp(target) {
                        this.apps.Push({
                            name: A_LoopFileName,
                            displayName: StrReplace(A_LoopFileName, ".lnk", ""),
                            path: A_LoopFileFullPath,
                            target: target,
                            type: "lnk"
                        })
                    }
                } catch {
                    continue
                }
            }
        } catch as err {
            ; Silent error handling
        }
    }
    
    IsValidApp(path) {
        ; Skip system files and unwanted applications
        excludePatterns := [
            "unins", "uninst", "uninstall", "setup", "install", 
            "update", "crash", "error", "debug", "temp"
        ]
        
        fileName := StrLower(FileGetName(path))
        for pattern in excludePatterns {
            if InStr(fileName, pattern) {
                return false
            }
        }
        
        return FileExist(path) && FileGetSize(path) > 1024 ; At least 1KB
    }
    
    GetShortcutTarget(lnkPath) {
        try {
            shell := ComObject("WScript.Shell")
            shortcut := shell.CreateShortcut(lnkPath)
            return shortcut.TargetPath
        } catch {
            return ""
        }
    }
    
    AddBuiltInApps() {
        builtInApps := [
            {name: "Calculator", displayName: "Calculator", path: "calc.exe", type: "builtin"},
            {name: "Notepad", displayName: "Notepad", path: "notepad.exe", type: "builtin"},
            {name: "Paint", displayName: "Paint", path: "mspaint.exe", type: "builtin"},
            {name: "Command Prompt", displayName: "Command Prompt", path: "cmd.exe", type: "builtin"},
            {name: "PowerShell", displayName: "PowerShell", path: "powershell.exe", type: "builtin"},
            {name: "Task Manager", displayName: "Task Manager", path: "taskmgr.exe", type: "builtin"},
            {name: "Registry Editor", displayName: "Registry Editor", path: "regedit.exe", type: "builtin"},
            {name: "Control Panel", displayName: "Control Panel", path: "control.exe", type: "builtin"}
        ]
        
        for app in builtInApps {
            this.apps.Push(app)
        }
    }
    
    SortApps(appList) {
        ; Simple bubble sort by display name
        n := appList.Length
        for i in Range(1, n-1) {
            for j in Range(1, n-i) {
                if StrCompare(appList[j].displayName, appList[j+1].displayName, 1) > 0 {
                    temp := appList[j]
                    appList[j] := appList[j+1]
                    appList[j+1] := temp
                }
            }
        }
        return appList
    }
    
    ; ========================================
    ; GUI CREATION
    ; ========================================
    
    CreateGUI() {
        this.gui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "🚀 App Launcher")
        this.gui.SetFont("s11", "Segoe UI")
        this.gui.BackColor := this.colors.bg
        this.gui.OnEvent("Close", (*) => this.Hide())
        this.gui.OnEvent("Escape", (*) => this.Hide())
        
    ; Search box
        this.gui.AddText("xm ym w" . (this.settings.windowWidth - 20) . " c" . this.colors.lavender, "Type to search applications...")
        this.searchBox := this.gui.AddEdit("xm y+5 w" . (this.settings.windowWidth - 20) . " h30 Background" . this.colors.surface1 . " c" . this.colors.text)
        this.searchBox.OnEvent("Change", (*) => this.OnSearchChange())
        
        ; Results list
        this.listBox := this.gui.AddListBox("xm y+10 w" . (this.settings.windowWidth - 20) . " h" . (this.settings.windowHeight - 100) . " Background" . this.colors.surface0 . " c" . this.colors.text . " VScroll")
        this.listBox.OnEvent("DoubleClick", (*) => this.HandleDoubleClick())
        this.listBox.OnEvent("Change", (*) => this.OnListSelection())
        
        ; Status bar
        this.statusText := this.gui.AddText("xm y+10 w" . (this.settings.windowWidth - 20) . " h20 c" . this.colors.blue, "")
        
        ; Set up keyboard navigation
        this.SetupKeyboardNavigation()
        
        ; Apply enhanced styling
        this.ApplyEnhancedStyling()
        
        ; Position window in center of screen
        this.gui.Show("w" . this.settings.windowWidth . " h" . this.settings.windowHeight . " Hide")
        this.CenterWindow()
        
        ; Apply enhanced styling
        this.ApplyEnhancedStyling()
    }
    
    CenterWindow() {
        ; Get screen dimensions
        MonitorGet(MonitorGetPrimary(), &left, &top, &right, &bottom)
        screenWidth := right - left
        screenHeight := bottom - top
        
        ; Calculate position - moved to the left side of screen
        x := (screenWidth - this.settings.windowWidth) // 3 + 50  ; Position at 1/4 from left edge + ~2-3cm
        y := (screenHeight - this.settings.windowHeight) // 3 ; Slightly above center
        
        this.gui.Move(x, y)
    }
    
    SetupKeyboardNavigation() {
        ; Set up hotkeys for navigation
        this.gui.OnEvent("Size", (*) => this.OnResize())
        
        ; Use simple global hotkeys that will be active when the launcher is shown
        ; We'll check if the launcher is visible in each hotkey handler
    }
    
    ; Method to set up hotkeys when launcher is shown
    EnableHotkeys() {
        try {
            Hotkey("Enter", (*) => this.HandleEnter(), "On")
            Hotkey("^Enter", (*) => this.HandleCtrlEnter(), "On")
            Hotkey("Escape", (*) => this.HandleEscape(), "On") 
            Hotkey("Up", (*) => this.HandleUp(), "On")
            Hotkey("Down", (*) => this.HandleDown(), "On")
            Hotkey("Tab", (*) => this.HandleTab(), "On")
        } catch {
            ; Ignore errors if hotkeys are already registered
        }
    }
    
    ; Method to disable hotkeys when launcher is hidden
    DisableHotkeys() {
        try {
            Hotkey("Enter", "Off")
            Hotkey("^Enter", "Off")
            Hotkey("Escape", "Off")
            Hotkey("Up", "Off")
            Hotkey("Down", "Off")
            Hotkey("Tab", "Off")
        } catch {
            ; Ignore errors
        }
    }
    
    ; Hotkey handlers that check if launcher is active
    HandleEnter() {
        if this.isVisible && WinActive(this.gui.Hwnd) {
            this.LaunchSelected()
        }
    }
    
    HandleCtrlEnter() {
        if this.isVisible && WinActive(this.gui.Hwnd) {
            this.OpenSelectedDirectory()
        }
    }
    
    HandleEscape() {
        if this.isVisible && WinActive(this.gui.Hwnd) {
            this.Hide()
        }
    }
    
    HandleUp() {
        if this.isVisible && WinActive(this.gui.Hwnd) {
            this.NavigateUp()
        }
    }
    
    HandleDown() {
        if this.isVisible && WinActive(this.gui.Hwnd) {
            this.NavigateDown()
        }
    }
    
    HandleTab() {
        if this.isVisible && WinActive(this.gui.Hwnd) {
            this.NavigateDown()
        }
    }
    
    ; ========================================
    ; SEARCH & FILTERING
    ; ========================================
    
    OnSearchChange() {
        query := this.searchBox.Value
        this.FilterApps(query)
        this.UpdateList()
        this.selectedIndex := 1
        this.UpdateSelection()
    }
    
    OnListSelection() {
        ; Update selectedIndex when user clicks on an item
        this.selectedIndex := this.listBox.Value
    }
    
    HandleDoubleClick() {
        if GetKeyState("Ctrl", "P") {
            this.OpenSelectedDirectory()
        } else {
            this.LaunchSelected()
        }
    }
    
    FilterApps(query) {
        if !query {
            this.filteredApps := this.apps.Clone()
            return
        }
        
        this.filteredApps := []
        query := StrLower(query)
        
        for app in this.apps {
            if this.settings.fuzzySearch ? this.FuzzyMatch(StrLower(app.displayName), query) : InStr(StrLower(app.displayName), query) {
                this.filteredApps.Push(app)
            }
        }
        
        ; Limit results
        if this.filteredApps.Length > this.settings.maxResults {
            this.filteredApps.Length := this.settings.maxResults
        }
    }
    
    FuzzyMatch(text, query) {
        if !query {
            return true
        }
        
        textIndex := 1
        for queryChar in StrSplit(query) {
            found := false
            while textIndex <= StrLen(text) {
                if SubStr(text, textIndex, 1) == queryChar {
                    found := true
                    textIndex++
                    break
                }
                textIndex++
            }
            if !found {
                return false
            }
        }
        return true
    }
    
    UpdateList() {
        ; Clear existing items
        try {
            this.listBox.Delete()  ; Delete all items at once
        } catch {
            ; Ignore errors
        }
        
        ; Add filtered apps with enhanced visual formatting
        for app in this.filteredApps {
            displayText := app.displayName
            if this.settings.showPath && app.HasOwnProp("target") {
                displayText .= " → " . FileGetName(app.target)
            }
            
            ; Add visual indicator based on app type
            switch app.type {
                case "builtin":
                    displayText := "⚙️ " . displayText
                case "exe":
                    displayText := "📁 " . displayText
                case "lnk":
                    displayText := "🔗 " . displayText
            }
            
            this.listBox.Add([displayText])
        }
        
        ; Update status with enhanced styling
        count := this.filteredApps.Length
        this.statusText.Text := "🔍 " . count . " application" . (count != 1 ? "s" : "") . " found"
    }
    
    ; ========================================
    ; NAVIGATION
    ; ========================================
    
    NavigateUp() {
        if this.selectedIndex > 1 {
            this.selectedIndex--
            this.UpdateSelection()
        }
    }
    
    NavigateDown() {
        if this.selectedIndex < this.filteredApps.Length {
            this.selectedIndex++
            this.UpdateSelection()
        }
    }
    
    UpdateSelection() {
        if this.selectedIndex >= 1 && this.selectedIndex <= this.filteredApps.Length {
            this.listBox.Choose(this.selectedIndex)
        }
    }
    
    ; ========================================
    ; LAUNCHING
    ; ========================================
    
    LaunchSelected() {
        ; Get the currently selected item from the listbox
        selectedListIndex := this.listBox.Value
        if selectedListIndex < 1 || selectedListIndex > this.filteredApps.Length {
            return
        }
        
        app := this.filteredApps[selectedListIndex]
        this.LaunchApp(app)
        this.Hide()
    }
    
    LaunchApp(app) {
        try {
            switch app.type {
                case "exe":
                    Run('"' . app.path . '"')
                case "lnk":
                    Run('"' . app.path . '"')
                case "builtin":
                    Run(app.path)
            }
        } catch as err {
            MsgBox("Failed to launch " . app.displayName . "`n" . err.Message, "Launch Error", "Icon!")
        }
    }
    
    OpenSelectedDirectory() {
        ; Get the currently selected item from the listbox
        selectedListIndex := this.listBox.Value
        if selectedListIndex < 1 || selectedListIndex > this.filteredApps.Length {
            return
        }
        
        app := this.filteredApps[selectedListIndex]
        this.OpenContainingFolder(app)
        this.Hide()
    }
    
    OpenContainingFolder(app) {
        try {
            ; Determine the actual file path
            filePath := ""
            
            switch app.type {
                case "exe":
                    filePath := app.path
                case "lnk":
                    ; For shortcuts, use the target if available, otherwise the shortcut itself
                    filePath := app.HasOwnProp("target") && app.target ? app.target : app.path
                case "builtin":
                    ; For built-in apps, try to find the executable
                    if InStr(app.path, "shell:")
                        return  ; Can't open directory for shell: commands
                    filePath := app.path
            }
            
            if filePath && FileExist(filePath) {
                ; Open Explorer and select the file
                Run('explorer.exe /select,"' . filePath . '"')
            }
        } catch as err {
            MsgBox("Failed to open directory for " . app.displayName . "`n" . err.Message, "Directory Error", "Icon!")
        }
    }
    
    ; ========================================
    ; VISIBILITY
    ; ========================================
    
    Show() {
        if this.isVisible {
            return
        }
        
        this.isVisible := true
        this.searchBox.Value := ""
        this.FilterApps("")
        this.UpdateList()
        this.selectedIndex := 1
        this.UpdateSelection()
        
        this.gui.Show()
        this.searchBox.Focus()
        this.EnableHotkeys()
        
        ; Start focus checking timer for auto-close
        this.StartFocusTimer()
    }
    
    Hide() {
        if !this.isVisible {
            return
        }
        
        this.isVisible := false
        this.gui.Hide()
        this.DisableHotkeys()
        
        ; Stop focus checking timer
        this.StopFocusTimer()
    }
    
    Toggle() {
        if this.isVisible {
            this.Hide()
        } else {
            this.Show()
        }
    }
    
    ; ========================================
    ; HOTKEY MANAGEMENT
    ; ========================================
    
    SetupHotkey() {
        try {
            Hotkey(this.settings.hotkey, (*) => this.Toggle())
        } catch as err {
            MsgBox("Error setting up hotkey '" . this.settings.hotkey . "': " . err.Message, "Hotkey Error", "Icon!")
        }
    }
    
    ; ========================================
    ; EVENTS
    ; ========================================
    
    OnResize() {
        ; Handle window resize if needed
    }
    
    ; Focus checking for auto-close functionality
    StartFocusTimer() {
        ; Stop any existing timer first
        this.StopFocusTimer()
        
        ; Create a new timer that checks focus every 250ms
        this.focusTimer := () => this.CheckFocus()
        SetTimer(this.focusTimer, 250)
    }
    
    StopFocusTimer() {
        ; Stop the focus checking timer if it exists
        if this.focusTimer {
            SetTimer(this.focusTimer, 0)
            this.focusTimer := ""
        }
    }
    
    CheckFocus() {
        ; Auto-close if launcher is visible but not active
        if this.isVisible && !WinActive(this.gui.Hwnd) {
            this.Hide()
        }
    }
    
    ; ========================================
    ; UTILITY
    ; ========================================
    
    ; Enhanced styling for better visual appeal
    ApplyEnhancedStyling() {
        ; Set focus and hover colors for better interaction feedback
        try {
            ; Apply custom styling to controls for better visual hierarchy
            this.searchBox.SetFont("s12 Bold", "Segoe UI")
            
            ; Make the listbox more visually appealing
            this.listBox.SetFont("s10", "Segoe UI")
            
            ; Enhance status text
            this.statusText.SetFont("s9", "Segoe UI")
        } catch {
            ; Ignore styling errors
        }
    }
}

; ========================================
; UTILITY FUNCTIONS
; ========================================

Range(start, end) {
    result := []
    loop end - start + 1 {
        result.Push(start + A_Index - 1)
    }
    return result
}

FileGetName(path) {
    SplitPath(path, &name)
    return name
}
