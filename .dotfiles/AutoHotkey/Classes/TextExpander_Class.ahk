; Text Expander Class
; Auto-expand text shortcuts with Catppuccin-themed management
; Features: Custom shortcuts, instant expansion, easy management

class CatppuccinTextExpander {
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
        enabled: true,
        triggerKey: "Space",  ; Key that triggers expansion
        caseSensitive: false,
        showNotifications: false
    }
    
    ; Default shortcuts
    shortcuts := Map(
    )
    
    ; Internal state
    shortcutsFile := ""
    isEnabled := true
    
    ; Constructor
    __New() {
        this.shortcutsFile := A_ScriptDir . "\Settings\text_shortcuts.ini"
        this.LoadShortcuts()
        
        ; Set initial state from settings
        this.isEnabled := this.settings.enabled
        
        ; Always set up hotstrings initially
        this.SetupHotstrings()
        
        ; Then enable/disable them based on settings
        if !this.isEnabled {
            this.DisableAllHotstrings()
        }
    }
    
    ; ========================================
    ; SHORTCUT MANAGEMENT
    ; ========================================
    
    LoadShortcuts() {
        if FileExist(this.shortcutsFile) {
            try {
                ; Read custom shortcuts from INI file
                Loop Read, this.shortcutsFile {
                    if InStr(A_LoopReadLine, "=") {
                        parts := StrSplit(A_LoopReadLine, "=", , 2)
                        if parts.Length = 2 {
                            shortcut := Trim(parts[1])
                            expansion := Trim(parts[2])
                            ; Replace \n with actual newlines
                            expansion := StrReplace(expansion, "\n", "`n")
                            this.shortcuts[shortcut] := expansion
                        }
                    }
                }
            } catch as err {
                ; Silent error handling
            }
        } else {
            ; Save default shortcuts
            this.SaveShortcuts()
        }
    }
    
    SaveShortcuts() {
        try {
            content := "; Text Expander Shortcuts`n"
            content .= "; Format: shortcut=expansion`n"
            content .= "; Use \n for line breaks`n`n"
            
            for shortcut, expansion in this.shortcuts {
                ; Replace newlines with \n for storage
                storageExpansion := StrReplace(expansion, "`n", "\n")
                content .= shortcut . "=" . storageExpansion . "`n"
            }
            
            ; Ensure the directory exists
            dir := RegExReplace(this.shortcutsFile, "\\[^\\]*$", "")
            if !DirExist(dir) {
                DirCreate(dir)
            }
            
            ; Write the file (this will overwrite if it exists)
            if FileExist(this.shortcutsFile) {
                FileDelete(this.shortcutsFile)
            }
            FileAppend(content, this.shortcutsFile, "UTF-8")
        } catch as err {
            ; Silent error handling
        }
    }
    
    SetupHotstrings() {
        ; Set up hotstrings for each shortcut
        for shortcut, expansion in this.shortcuts {
            try {
                ; Create hotstring with options
                options := ":"
                if !this.settings.caseSensitive {
                    options .= "C0"  ; Case insensitive
                }
                options .= "*"  ; No ending character required
                options .= ":"
                
                ; Create the hotstring - capture shortcut in closure properly
                currentShortcut := shortcut  ; Capture the current value
                Hotstring(options . shortcut, ((sc) => (*) => this.ExpandText(sc))(currentShortcut))
            } catch as err {
                ; Silent error handling
            }
        }
    }
    
    ExpandText(shortcut) {
        ; Get the expansion
        expansion := this.shortcuts[shortcut]
        
        ; Handle dynamic expansions
        if shortcut = "date" {
            expansion := FormatTime(, "yyyy-MM-dd")
        } else if shortcut = "time" {
            expansion := FormatTime(, "HH:mm:ss")
        }
        
        ; Send backspaces to clear the shortcut
        Send("{Backspace " . StrLen(shortcut) . "}")
        
        ; Send the expansion
        Send(expansion)
        
        ; Show notification if enabled
        if this.settings.showNotifications {
            TrayTip("Text Expanded", shortcut . " → " . (StrLen(expansion) > 30 ? SubStr(expansion, 1, 30) . "..." : expansion), "Icon!")
            SetTimer(() => TrayTip(), -2000)
        }
    }
    
    ; ========================================
    ; CONTROL
    ; ========================================
    
    ; Open the INI file directly for manual editing
    OpenINIFile() {
        if FileExist(this.shortcutsFile) {
            try {
                Run("notepad.exe `"" . this.shortcutsFile . "`"")
            } catch {
                ; Try with default program
                try {
                    Run(this.shortcutsFile)
                } catch {
                    MsgBox("Could not open file. Path: " . this.shortcutsFile, "Error", "Icon!")
                }
            }
        } else {
            ; Create the file with some default content
            this.SaveShortcuts()
            MsgBox("Created shortcuts file. Opening in Notepad...", "File Created", "Icon!")
            try {
                Run("notepad.exe `"" . this.shortcutsFile . "`"")
            } catch {
                MsgBox("Could not open Notepad. File saved at: " . this.shortcutsFile, "Error", "Icon!")
            }
        }
    }
    
    ToggleEnabled(enabled := "") {
        if enabled != "" {
            this.isEnabled := enabled
        } else {
            this.isEnabled := !this.isEnabled
        }
        
        ; Actually enable/disable all hotstrings
        if this.isEnabled {
            this.EnableAllHotstrings()
        } else {
            this.DisableAllHotstrings()
        }
        
        status := this.isEnabled ? "enabled" : "disabled"
        
        if this.settings.showNotifications {
            TrayTip("Text Expander", "Text expansion " . status, "Icon!")
            SetTimer(() => TrayTip(), -2000)
        }
    }
    
    EnableAllHotstrings() {
        ; Enable all hotstrings
        for shortcut, expansion in this.shortcuts {
            try {
                options := ":"
                if !this.settings.caseSensitive {
                    options .= "C0"  ; Case insensitive
                }
                options .= "*"  ; No ending character required
                options .= ":"
                
                ; Enable the hotstring
                Hotstring(options . shortcut, , "On")
            } catch as err {
                ; Silent error handling
            }
        }
    }
    
    DisableAllHotstrings() {
        ; Disable all hotstrings completely
        for shortcut, expansion in this.shortcuts {
            try {
                options := ":"
                if !this.settings.caseSensitive {
                    options .= "C0"  ; Case insensitive
                }
                options .= "*"  ; No ending character required
                options .= ":"
                
                ; Disable the hotstring completely
                Hotstring(options . shortcut, , "Off")
            } catch as err {
                ; Silent error handling
            }
        }
    }
    
    ; ========================================
    ; SETTINGS
    ; ========================================
    
    ShowSettings() {
        settingsGui := Gui("+Resize -MaximizeBox", "Text Expander Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        settingsGui.BackColor := this.colors.bg
        
        ; Status display
        settingsGui.AddText("xm ym c" . this.colors.text, "Status: " . (this.isEnabled ? "Enabled" : "Disabled") . " (Use Ctrl+Shift+E to toggle)")
        
        ; Options
        settingsGui.AddText("xm y+20 c" . this.colors.text, "Options:")
        caseSensitiveCheck := settingsGui.AddCheckbox("xm y+10 c" . this.colors.text . " Checked" . (this.settings.caseSensitive ? "1" : "0"), "Case sensitive shortcuts")
        notificationsCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.showNotifications ? "1" : "0"), "Show expansion notifications")
        
        ; Buttons
        settingsGui.AddButton("xm y+30 w80 Background" . this.colors.green . " c" . this.colors.bg, "Save").OnEvent("Click", (*) => this.SaveExpanderSettings(settingsGui, caseSensitiveCheck, notificationsCheck))
        settingsGui.AddButton("x+10 yp w80 Background" . this.colors.red . " c" . this.colors.bg, "Cancel").OnEvent("Click", (*) => settingsGui.Destroy())
        
        settingsGui.Show("w300 h200")
    }
    
    SaveExpanderSettings(gui, caseSensitiveCheck, notificationsCheck) {
        this.settings.caseSensitive := caseSensitiveCheck.Value
        this.settings.showNotifications := notificationsCheck.Value
        
        ; Save the settings
        this.SaveSettings()
        
        MsgBox("Settings saved!", "Settings", "Icon!")
        gui.Destroy()
    }
    
    SaveSettings() {
        ; Settings are saved in the shortcuts file as comments for now
        ; In a more complex implementation, we could use a separate settings file
    }
    
    ; ========================================
    ; UTILITY
    ; ========================================
}
