; Windows Utilities Manager
; Unified script manager for Catppuccin-themed Windows utilities
; Manages: App Launcher and Explorer Dialog

#Requires AutoHotkey v2.0
#SingleInstance force
SetWorkingDir(A_ScriptDir)

; ========================================
; ========================================
; MAIN UTILITIES MANAGER
; ========================================

class WindowsUtilitiesManager {
    ; Catppuccin Mocha color palette (shared across utilities)
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
        enableAppLauncher: true,
        enableExplorerDialog: true,
        enableQuickNoteTaker: true,
        enableTextExpander: true,
        enableTodoReminder: true,
        enableDebug: true,
        version: "1.0.0"
    }
    
    ; Utility instances
    appLauncher := ""
    explorerDialog := ""
    quickNoteTaker := ""
    textExpander := ""
    todoReminder := ""
    
    ; Constructor
    __New() {
        this.SetupTrayMenu()
        this.InitializeUtilities()
        this.ShowDebug("Windows Utilities Manager initialized")
    }
    
    ; ========================================
    ; INITIALIZATION
    ; ========================================
    
    InitializeUtilities() {
        ; Initialize App Launcher
        if this.settings.enableAppLauncher {
            try {
                this.appLauncher := CatppuccinAppLauncher()
                this.ShowDebug("App Launcher initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize App Launcher: " . err.Message)
                MsgBox("Failed to initialize App Launcher: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize Explorer Dialog
        if this.settings.enableExplorerDialog {
            try {
                this.explorerDialog := FixedExplorerDialogPathSelector(this)
                this.ShowDebug("Explorer Dialog initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize Explorer Dialog: " . err.Message)
                MsgBox("Failed to initialize Explorer Dialog: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize Quick Note Taker
        if this.settings.enableQuickNoteTaker {
            try {
                this.quickNoteTaker := QuickNoteTaker()
                this.ShowDebug("Quick Note Taker initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize Quick Note Taker: " . err.Message)
                MsgBox("Failed to initialize Quick Note Taker: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize Text Expander
        if this.settings.enableTextExpander {
            try {
                this.textExpander := CatppuccinTextExpander()
                this.ShowDebug("Text Expander initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize Text Expander: " . err.Message)
                MsgBox("Failed to initialize Text Expander: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize To-Do & Reminders
        if this.settings.enableTodoReminder {
            try {
                this.todoReminder := CatppuccinTodoReminder(this)
                this.ShowDebug("To-Do & Reminders initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize To-Do & Reminders: " . err.Message)
                MsgBox("Failed to initialize To-Do & Reminders: " . err.Message, "Initialization Error", "Icon!")
            }
        }
    }
    
    ; ========================================
    ; TRAY MENU MANAGEMENT
    ; ========================================
    
    SetupTrayMenu() {
        ; Clear default menu
        A_TrayMenu.Delete()
        
        ; Add utility controls
        A_TrayMenu.Add("🚀 App Launcher", (*) => this.ToggleAppLauncher())
        A_TrayMenu.Add("📝 Quick Notes", (*) => this.ToggleQuickNotes())
        A_TrayMenu.Add("📋 To-Do & Reminders", (*) => this.ToggleTodoReminder())
        A_TrayMenu.Add()  ; Separator
        
        ; Explorer Dialog submenu
        explorerMenu := Menu()
        explorerMenu.Add("⚙️ Explorer Settings", (*) => this.ShowExplorerSettings())
        A_TrayMenu.Add("📁 Explorer Dialog", explorerMenu)
        
        ; Text Expander submenu
        expanderMenu := Menu()
        expanderMenu.Add("📝 Edit Shortcuts", (*) => this.EditTextExpanderShortcuts())
        expanderMenu.Add("⚙️ Expander Settings", (*) => this.ShowTextExpanderSettings())
        expanderMenu.Add("🔄 Toggle Expansion", (*) => this.ToggleTextExpander())
        A_TrayMenu.Add("✨ Text Expander", expanderMenu)
        A_TrayMenu.Add()  ; Separator
        
        ; Add utility management
        A_TrayMenu.Add("⚙️ Manager Settings", (*) => this.ShowSettings())
        A_TrayMenu.Add("🔄 Reload All", (*) => this.ReloadAll())
        A_TrayMenu.Add("📊 Show Status", (*) => this.ShowStatus())
        A_TrayMenu.Add()  ; Separator
        
        ; Add help and exit
        A_TrayMenu.Add("❓ Help", (*) => this.ShowHelp())
        A_TrayMenu.Add("❌ Exit", (*) => this.ExitApp())
        
        ; Set default action (double-click tray icon)
        A_TrayMenu.Default := "🚀 App Launcher"
        
        ; Set custom tray tip
        A_IconTip := "Windows Utilities Manager`nApp Launcher • Explorer Dialog • Quick Notes • Text Expander • To-Do & Reminders"
    }
    
    ; ========================================
    ; UTILITY ACTIONS
    ; ========================================
    
    ToggleAppLauncher() {
        if this.appLauncher {
            this.appLauncher.Toggle()
        } else {
            MsgBox("App Launcher is not available.", "Error", "Icon!")
        }
    }
    
    ToggleQuickNotes() {
        if this.quickNoteTaker {
            this.quickNoteTaker.Toggle()
        } else {
            MsgBox("Quick Note Taker is not available.", "Error", "Icon!")
        }
    }
    
    ToggleTodoReminder() {
        if this.todoReminder {
            this.todoReminder.Toggle()
        } else {
            MsgBox("To-Do & Reminders is not available.", "Error", "Icon!")
        }
    }
    
    EditTextExpanderShortcuts() {
        if this.textExpander {
            this.textExpander.OpenINIFile()
        } else {
            MsgBox("Text Expander is not available.", "Error", "Icon!")
        }
    }
    
    ShowTextExpanderSettings() {
        if this.textExpander {
            this.textExpander.ShowSettings()
        } else {
            MsgBox("Text Expander is not available.", "Error", "Icon!")
        }
    }
    
    ToggleTextExpander() {
        if this.textExpander {
            this.textExpander.ToggleEnabled()
            this.UpdateTrayMenu()  ; Update menu to reflect new status
        } else {
            MsgBox("Text Expander is not available.", "Error", "Icon!")
        }
    }
    
    UpdateTrayMenu() {
        ; Update the tray menu to reflect current text expander status
        if this.textExpander {
            expanderMenu := Menu()
            expanderMenu.Add("📝 Edit Shortcuts", (*) => this.EditTextExpanderShortcuts())
            expanderMenu.Add("⚙️ Expander Settings", (*) => this.ShowTextExpanderSettings())
            
            ; Update toggle text based on current state
            toggleText := this.textExpander.isEnabled ? "⏸️ Disable Expansion" : "▶️ Enable Expansion"
            expanderMenu.Add(toggleText, (*) => this.ToggleTextExpander())
            
            ; Replace the existing menu
            A_TrayMenu.Delete("✨ Text Expander")
            A_TrayMenu.Insert("⚙️ Manager Settings", "✨ Text Expander", expanderMenu)
        }
    }
    
    ShowExplorerSettings() {
        if this.explorerDialog {
            this.explorerDialog.ShowSettingsGUI()
        } else {
            MsgBox("Explorer Dialog is not available.", "Error", "Icon!")
        }
    }
    
    ShowSettings() {
        ; Create a simple settings GUI
        settingsGui := Gui("+Resize -MaximizeBox", "Windows Utilities Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        settingsGui.BackColor := this.colors.bg
        
        ; Utility toggles
        settingsGui.AddText("xm ym c" . this.colors.text, "Enabled Utilities:")
        appLauncherCheck := settingsGui.AddCheckbox("xm y+10 c" . this.colors.text . " Checked" . (this.settings.enableAppLauncher ? "1" : "0"), "App Launcher (Win+Space)")
        explorerCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.enableExplorerDialog ? "1" : "0"), "Explorer Dialog (Middle-click)")
        quickNotesCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.enableQuickNoteTaker ? "1" : "0"), "Quick Note Taker (Ctrl+Shift+N)")
        textExpanderCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.enableTextExpander ? "1" : "0"), "Text Expander (@@, addr, etc.)")
        todoReminderCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.enableTodoReminder ? "1" : "0"), "To-Do & Reminders (Alt+Shift+T)")
        
        settingsGui.AddText("xm y+20 c" . this.colors.text, "Debug:")
        debugCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.enableDebug ? "1" : "0"), "Enable debug logging")
        
        ; Buttons
        settingsGui.AddButton("xm y+30 w80 h30", "Save").OnEvent("Click", (*) => this.SaveSettings(settingsGui, appLauncherCheck, explorerCheck, quickNotesCheck, textExpanderCheck, todoReminderCheck, debugCheck))
        settingsGui.AddButton("x+10 w80 h30", "Cancel").OnEvent("Click", (*) => settingsGui.Destroy())
        
        settingsGui.Show("w400 h300")
    }
    
    SaveSettings(gui, appCheck, explorerCheck, quickNotesCheck, textExpanderCheck, todoReminderCheck, debugCheck) {
        this.settings.enableAppLauncher := appCheck.Value
        this.settings.enableExplorerDialog := explorerCheck.Value
        this.settings.enableQuickNoteTaker := quickNotesCheck.Value
        this.settings.enableTextExpander := textExpanderCheck.Value
        this.settings.enableTodoReminder := todoReminderCheck.Value
        this.settings.enableDebug := debugCheck.Value
        
        MsgBox("Settings saved!`nRestart the script to apply changes.", "Settings", "Icon!")
        gui.Destroy()
    }
    
    ShowStatus() {
        status := "Windows Utilities Manager v" . this.settings.version . "`n`n"
        status .= "🚀 App Launcher: " . (this.appLauncher ? "✅ Active" : "❌ Inactive") . "`n"
        status .= "📁 Explorer Dialog: " . (this.explorerDialog ? "✅ Active" : "❌ Inactive") . "`n"
        status .= "📝 Quick Notes: " . (this.quickNoteTaker ? "✅ Active" : "❌ Inactive") . "`n"
        status .= "📋 To-Do & Reminders: " . (this.todoReminder ? "✅ Active" : "❌ Inactive") . "`n"
        
        ; Check actual enabled state of text expander
        textExpanderStatus := "❌ Inactive"
        if this.textExpander {
            if this.textExpander.isEnabled {
                textExpanderStatus := "✅ Active"
            } else {
                textExpanderStatus := "⏸️ Disabled"
            }
        }
        status .= "✨ Text Expander: " . textExpanderStatus . "`n`n"
        
        if this.appLauncher {
            status .= "Apps loaded: " . this.appLauncher.apps.Length . "`n"
        }
        
        status .= "Debug logging: " . (this.settings.enableDebug ? "Enabled" : "Disabled") . "`n"
        
        MsgBox(status, "Utilities Status", "Icon!")
    }
    
    ShowHelp() {
        help := "Windows Utilities Manager`n`n"
        help .= "🚀 App Launcher:`n"
        help .= "• Win+Space: Open app launcher`n"
        help .= "• Type to search, Enter to launch`n"
        help .= "• Arrow keys or Tab to navigate`n`n"
        help .= "📁 Explorer Dialog:`n"
        help .= "• Middle-click in file dialogs`n"
        help .= "• Quick access to common paths`n"
        help .= "• Browse and navigate easily`n`n"
        help .= "� Quick Notes:`n"
        help .= "• Ctrl+Shift+N: Open floating notepad`n"
        help .= "• Auto-save and always accessible`n"
        help .= "• Perfect for quick thoughts`n`n"
        help .= "✨ Text Expander:`n"
        help .= "• @@ → your email address`n"
        help .= "• addr → your full address`n"
        help .= "• date → current date`n"
        help .= "• Manage custom shortcuts in tray menu`n`n"
        help .= "�💡 Tip: Double-click tray icon for quick launcher access"
        
        MsgBox(help, "Help", "Icon!")
    }
    
    ReloadAll() {
        this.ShowDebug("Reloading all utilities...")
        Reload
    }
    
    ExitApp() {
        this.ShowDebug("Exiting Windows Utilities Manager")
        ExitApp
    }
    
    ; ========================================
    ; UTILITY
    ; ========================================
    
    ShowDebug(message) {
        if !this.settings.enableDebug {
            return
        }
        
        OutputDebug("[UtilitiesManager] " . message)
        try {
            FileAppend(A_Now . " - [Manager] " . message . "`n", A_ScriptDir . "\utilities_debug.log")
        } catch {
            ; Ignore file errors
        }
    }
}

; ========================================
; INCLUDE UTILITY CLASSES
; ========================================

; Include App Launcher class
#Include "Classes\AppLauncher_Class.ahk"

; Include Explorer Dialog class  
#Include "Classes\ExplorerDialog_Class.ahk"

; Include Quick Note Taker class
#Include "Classes\QuickNoteTaker_Class.ahk"

; Include Text Expander class
#Include "Classes\TextExpander_Class.ahk"

; Include To-Do & Reminders class
#Include "Classes\Todo_Class.ahk"

; ========================================
; INITIALIZATION
; ========================================

; Create global manager instance with error handling
global UtilitiesManager := ""
try {
    UtilitiesManager := WindowsUtilitiesManager()
} catch as err {
    MsgBox("Error initializing Windows Utilities Manager:`n`n" . err.Message . "`n`nSome features may not work properly.", "Initialization Error", "Icon!")
}

; ========================================
; GLOBAL HOTKEYS
; ========================================

; Toggle Text Expander on/off
^+e:: {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        UtilitiesManager.ToggleTextExpander()
    } else {
        MsgBox("Utilities Manager not properly initialized.", "Error", "Icon!")
    }
}

; Toggle To-Do & Reminders
!+t:: {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        UtilitiesManager.ToggleTodoReminder()
    } else {
        MsgBox("Utilities Manager not properly initialized.", "Error", "Icon!")
    }
}

; Show startup notification
TrayTip("Windows Utilities Manager", "All utilities loaded successfully!`n🚀 Win+Space: App Launcher`n📁 Middle-click: Explorer Dialog`n📝 Ctrl+Shift+N: Quick Notes`n📋 Alt+Shift+T: To-Do & Reminders`n✨ Ctrl+Shift+E: Toggle Text Expander`n💬 Type @@@, addr, date to expand", "Icon!")
SetTimer(() => TrayTip(), -5000)