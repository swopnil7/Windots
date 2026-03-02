; Windows Utilities Manager

#Requires AutoHotkey v2.0
#SingleInstance force
SetWorkingDir(A_ScriptDir)

; ========================================
; ========================================
; MAIN UTILITIES MANAGER
; ========================================

class WindowsUtilitiesManager {
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
        enableExplorerDialog: true,
        enableQuickNoteTaker: true,
        enableTextExpander: true,
        enableTodoReminder: true,
        enableDebug: true,
        version: "1.0.0",
        hotkeys: {
            quickNotes: "!+n",       ; Alt+Shift+N
            todoReminder: "!+t",     ; Alt+Shift+T
            textExpander: "^+e",     ; Ctrl+Shift+E
            desktopIcons: "^#i",     ; Ctrl+Win+I
            explorerDialog: "^MButton",  ; Ctrl+Middle Mouse Button
            suspendHotkeys: "^#p",   ; Ctrl+Win+P
            reloadAll: "^+!r"        ; Ctrl+Shift+Alt+R
        }
    }
    
    ; Hotkey state
    hotkeysSuspended := false
    
    ; Utility instances
    explorerDialog := ""
    quickNoteTaker := ""
    textExpander := ""
    todoReminder := ""
    
    ; Constructor
    __New() {
        this.LoadSettings()
        this.SetupTrayMenu()
        this.InitializeUtilities()
        this.ShowDebug("Windows Utilities Manager initialized")
    }
    
    ; ========================================
    ; INITIALIZATION
    ; ========================================
    
    LoadSettings() {
        settingsFile := A_ScriptDir . "\Settings\manager_settings.ini"
        if FileExist(settingsFile) {
            try {
                ; Load utilities enable/disable settings
                this.settings.enableExplorerDialog := IniRead(settingsFile, "Utilities", "EnableExplorerDialog", "1") = "1"
                this.settings.enableQuickNoteTaker := IniRead(settingsFile, "Utilities", "EnableQuickNoteTaker", "1") = "1"
                this.settings.enableTextExpander := IniRead(settingsFile, "Utilities", "EnableTextExpander", "1") = "1"
                this.settings.enableTodoReminder := IniRead(settingsFile, "Utilities", "EnableTodoReminder", "1") = "1"
                this.settings.enableDebug := IniRead(settingsFile, "Utilities", "EnableDebug", "1") = "1"
                
                ; Load hotkeys
                this.settings.hotkeys.quickNotes := IniRead(settingsFile, "Hotkeys", "QuickNotes", "!+n")
                this.settings.hotkeys.todoReminder := IniRead(settingsFile, "Hotkeys", "TodoReminder", "!+t")
                this.settings.hotkeys.textExpander := IniRead(settingsFile, "Hotkeys", "TextExpander", "^+e")
                this.settings.hotkeys.desktopIcons := IniRead(settingsFile, "Hotkeys", "DesktopIconToggle", "^#i")
                this.settings.hotkeys.explorerDialog := IniRead(settingsFile, "Hotkeys", "ExplorerDialog", "^MButton")
                this.settings.hotkeys.suspendHotkeys := IniRead(settingsFile, "Hotkeys", "SuspendAll", "^#p")
                this.settings.hotkeys.reloadAll := IniRead(settingsFile, "Hotkeys", "ReloadAll", "^+!r")
            } catch as err {
                this.ShowDebug("Failed to load settings from INI: " . err.Message)
            }
        }
    }
    
    InitializeUtilities() {
        ; Initialize Explorer Dialog
        if this.settings.enableExplorerDialog {
            try {
                this.explorerDialog := ExplorerDialog(this)
                this.ShowDebug("Explorer Dialog initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize Explorer Dialog: " . err.Message)
                MsgBox("Failed to initialize Explorer Dialog: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize Quick Note Taker
        if this.settings.enableQuickNoteTaker {
            try {
                this.quickNoteTaker := QuickNoteTaker(this)
                this.ShowDebug("Quick Note Taker initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize Quick Note Taker: " . err.Message)
                MsgBox("Failed to initialize Quick Note Taker: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize Text Expander
        if this.settings.enableTextExpander {
            try {
                this.textExpander := TextExpander(this)
                this.ShowDebug("Text Expander initialized")
            } catch as err {
                this.ShowDebug("Failed to initialize Text Expander: " . err.Message)
                MsgBox("Failed to initialize Text Expander: " . err.Message, "Initialization Error", "Icon!")
            }
        }
        
        ; Initialize To-Do & Reminders
        if this.settings.enableTodoReminder {
            try {
                this.todoReminder := TodoReminder(this)
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
        A_TrayMenu.Add("� Quick Notes", (*) => this.ToggleQuickNotes())
        A_TrayMenu.Add("📋 To-Do", (*) => this.ToggleTodoReminder())
        A_TrayMenu.Add("🖥️ Icon Toggle", (*) => DesktopIconToggle())
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
        
        ; Add hotkey suspension toggle
        A_TrayMenu.Add("⏸️ Suspend All Hotkeys", (*) => this.ToggleSuspendHotkeys())
        A_TrayMenu.Add()  ; Separator
        
        ; Add utility management
        A_TrayMenu.Add("⚙️ Manager Settings", (*) => this.ShowSettings())
        A_TrayMenu.Add("🔄 Reload All", (*) => this.ReloadAll())
        A_TrayMenu.Add("📊 Show Status", (*) => this.ShowStatus())
        A_TrayMenu.Add()  ; Separator
        
        ; Add help and exit
        A_TrayMenu.Add("❓ Help", (*) => this.ShowHelp())
        A_TrayMenu.Add("❌ Exit", (*) => this.ExitApp())
        
        ; Set custom tray tip
        A_IconTip := "Windows Utilities Manager"
    }
    
    ; ========================================
    ; UTILITY ACTIONS
    ; ========================================
    
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
    
    ToggleSuspendHotkeys() {
        this.hotkeysSuspended := !this.hotkeysSuspended
        Suspend(this.hotkeysSuspended ? 1 : 0)
        this.UpdateSuspendStatus()
    }
    
    UpdateSuspendStatus() {
        statusText := this.hotkeysSuspended ? "suspended" : "resumed"
        icon := this.hotkeysSuspended ? "⏸️" : "▶️"
        menuText := this.hotkeysSuspended ? "▶️ Resume All Hotkeys" : "⏸️ Suspend All Hotkeys"
        
        ; Update tray menu text
        try {
            A_TrayMenu.Rename(this.hotkeysSuspended ? "⏸️ Suspend All Hotkeys" : "▶️ Resume All Hotkeys", menuText)
        }
        
        TrayTip("Hotkeys " . statusText, "All hotkeys have been " . statusText . ".`nPress Ctrl+Win+P to toggle.", "Icon!")
        SetTimer(() => TrayTip(), -3000)
        
        this.ShowDebug("Hotkeys " . statusText)
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
        settingsGui := Gui("-MaximizeBox -MinimizeBox -SysMenu +ToolWindow", "Windows Utilities Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        settingsGui.BackColor := this.colors.bg
        
        settingsGui.OnEvent("Escape", (*) => settingsGui.Destroy())
        
        settingsGui.AddText("xm ym c" . this.colors.text, "Enabled Utilities:")
        explorerCheck := settingsGui.AddCheckbox("xm y+5 c" . this.colors.text . " Checked" . (this.settings.enableExplorerDialog ? "1" : "0"), "Explorer Dialog")
        quickNotesCheck := settingsGui.AddCheckbox("xm y+3 c" . this.colors.text . " Checked" . (this.settings.enableQuickNoteTaker ? "1" : "0"), "Quick Notes")
        textExpanderCheck := settingsGui.AddCheckbox("xm y+3 c" . this.colors.text . " Checked" . (this.settings.enableTextExpander ? "1" : "0"), "Text Expander")
        todoReminderCheck := settingsGui.AddCheckbox("xm y+3 c" . this.colors.text . " Checked" . (this.settings.enableTodoReminder ? "1" : "0"), "To-Do & Reminders")
        
        settingsGui.AddText("xm y+10 c" . this.colors.text, "Debug:")
        debugCheck := settingsGui.AddCheckbox("xm y+3 c" . this.colors.text . " Checked" . (this.settings.enableDebug ? "1" : "0"), "Enable debug logging")
        
        settingsGui.AddText("xm y+15 c" . this.colors.text, "Keybindings:")
        
        settingsGui.AddText("xm y+8 c" . this.colors.subtext1, "Quick Notes:")
        quickNotesEdit := settingsGui.AddEdit("xm y+2 w150 h22 Background" . this.colors.surface0 . " c" . this.colors.text, this.FormatHotkey(this.settings.hotkeys.quickNotes))
        
        settingsGui.AddText("xm y+6 c" . this.colors.subtext1, "To-Do Manager:")
        todoEdit := settingsGui.AddEdit("xm y+2 w150 h22 Background" . this.colors.surface0 . " c" . this.colors.text, this.FormatHotkey(this.settings.hotkeys.todoReminder))
        
        settingsGui.AddText("xm y+6 c" . this.colors.subtext1, "Text Expander:")
        textExpanderEdit := settingsGui.AddEdit("xm y+2 w150 h22 Background" . this.colors.surface0 . " c" . this.colors.text, this.FormatHotkey(this.settings.hotkeys.textExpander))
        
        settingsGui.AddText("xm y+6 c" . this.colors.subtext1, "Desktop Icons:")
        iconToggleEdit := settingsGui.AddEdit("xm y+2 w150 h22 Background" . this.colors.surface0 . " c" . this.colors.text, this.FormatHotkey(this.settings.hotkeys.desktopIcons))
        
        settingsGui.AddText("xm y+6 c" . this.colors.subtext1, "Explorer Dialog:")
        explorerEdit := settingsGui.AddEdit("xm y+2 w150 h22 Background" . this.colors.surface0 . " c" . this.colors.text, this.FormatHotkey(this.settings.hotkeys.explorerDialog))
        
        settingsGui.AddButton("xm y+15 w70 h25", "Save").OnEvent("Click", (*) => this.SaveSettings(settingsGui, explorerCheck, quickNotesCheck, textExpanderCheck, todoReminderCheck, debugCheck, quickNotesEdit, todoEdit, textExpanderEdit, iconToggleEdit, explorerEdit))
        settingsGui.AddButton("x+5 w70 h25", "Cancel").OnEvent("Click", (*) => settingsGui.Destroy())
        
        settingsGui.Show("w170 h500")
    }
    
    SaveSettings(gui, explorerCheck, quickNotesCheck, textExpanderCheck, todoReminderCheck, debugCheck, quickNotesEdit := "", todoEdit := "", textExpanderEdit := "", iconToggleEdit := "", explorerEdit := "") {
        this.settings.enableExplorerDialog := explorerCheck.Value
        this.settings.enableQuickNoteTaker := quickNotesCheck.Value
        this.settings.enableTextExpander := textExpanderCheck.Value
        this.settings.enableTodoReminder := todoReminderCheck.Value
        this.settings.enableDebug := debugCheck.Value
        
        if quickNotesEdit && quickNotesEdit.Value {
            this.settings.hotkeys.quickNotes := this.ParseHotkey(quickNotesEdit.Value)
        }
        if todoEdit && todoEdit.Value {
            this.settings.hotkeys.todoReminder := this.ParseHotkey(todoEdit.Value)
        }
        if textExpanderEdit && textExpanderEdit.Value {
            this.settings.hotkeys.textExpander := this.ParseHotkey(textExpanderEdit.Value)
        }
        if iconToggleEdit && iconToggleEdit.Value {
            this.settings.hotkeys.desktopIcons := this.ParseHotkey(iconToggleEdit.Value)
        }
        if explorerEdit && explorerEdit.Value {
            this.settings.hotkeys.explorerDialog := this.ParseHotkey(explorerEdit.Value)
        }
        
        MsgBox("Settings saved!`nRestart the script to apply changes.", "Settings", "Icon!")
        gui.Destroy()
    }
    
    ; ========================================
    ; KEYBINDING UTILITIES
    ; ========================================
    
    ; Convert AHK hotkey format (^+e) to human-readable format (ctrl+shift+e)
    FormatHotkey(hotkeyStr) {
        human := ""
        pos := 1
        
        ; Process each modifier character in order
        while pos <= StrLen(hotkeyStr) {
            char := SubStr(hotkeyStr, pos, 1)
            if char = "^" {
                human .= "ctrl+"
            } else if char = "+" {
                human .= "shift+"
            } else if char = "!" {
                human .= "alt+"
            } else if char = "#" {
                human .= "win+"
            } else {
                break  ; Rest is the key
            }
            pos++
        }
        
        ; Add the remaining key part in lowercase
        if pos <= StrLen(hotkeyStr) {
            human .= StrLower(SubStr(hotkeyStr, pos))
        }
        
        return human
    }
    
    ; Convert human-readable format (ctrl+shift+e) to AHK format (^+e)
    ParseHotkey(humanStr) {
        ahkFormat := ""
        humanStr := StrLower(Trim(humanStr))
        
        ; Split by + and process each part
        parts := StrSplit(humanStr, "+")
        key := ""
        
        for part in parts {
            part := Trim(part)
            
            if part = "ctrl" {
                ahkFormat .= "^"
            } else if part = "shift" {
                ahkFormat .= "+"
            } else if part = "alt" {
                ahkFormat .= "!"
            } else if part = "win" {
                ahkFormat .= "#"
            } else {
                key := part
            }
        }
        
        ; Add the key in uppercase
        ahkFormat .= StrUpper(key)
        
        return ahkFormat
    }
    
    ; ========================================
    ; STATUS AND HELP
    ; ========================================
    
    ShowStatus() {
        status := "Windows Utilities Manager v" . this.settings.version . "`n`n"
        status .= " Explorer Dialog: " . (this.explorerDialog ? "✅ Active" : "❌ Inactive") . "`n"
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
        
        status .= "Debug logging: " . (this.settings.enableDebug ? "Enabled" : "Disabled") . "`n"
        
        MsgBox(status, "Utilities Status", "Icon!")
    }
    
    ShowHelp() {
        help := "Windows Utilities Manager`n`n"
        help .= " Explorer Dialog:`n"
        help .= "• Middle-click in file dialogs`n"
        help .= "• Quick access to common paths`n"
        help .= "• Browse and navigate easily`n`n"
        help .= "📝 Quick Notes:`n"
        help .= "• Alt+Shift+N: Open floating notepad`n"
        help .= "• Ctrl+S: Save current note`n"
        help .= "• Ctrl+N: Create new note`n"
        help .= "• Auto-save and always accessible`n`n"
        help .= "📋 To-Do & Reminders:`n"
        help .= "• Alt+Shift+T: Open To-Do manager`n"
        help .= "• Manage tasks and reminders`n`n"
        help .= "✨ Text Expander:`n"
        help .= "• Ctrl+Shift+E: Toggle expansion on/off`n"
        help .= "• Manage custom shortcuts to expand`n`n"
        help .= "🖥️ Desktop Icons:`n"
        help .= "• Ctrl+Win+I: Toggle desktop icons visibility`n`n"
        help .= "⏸️ Suspend All Hotkeys:`n"
        help .= "• Ctrl+Win+P: Suspend/Resume all hotkeys`n"
        help .= "• Use to prevent AHK from intercepting shortcuts`n`n"
        help .= "💡 Tip: Double-click tray icon for quick To-Do access"
        
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

; Include Explorer Dialog class  
#Include "Classes\ExplorerDialog_Class.ahk"

; Include Quick Note Taker class
#Include "Classes\QuickNoteTaker_Class.ahk"

; Include Text Expander class
#Include "Classes\TextExpander_Class.ahk"

; Include To-Do & Reminders class
#Include "Classes\Todo_Class.ahk"

; Include Desktop Icon Toggle class
#Include "Classes\DesktopIconToggle_Class.ahk"

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


; Toggle Text Expander on/off
^+e:: {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        UtilitiesManager.ToggleTextExpander()
    } else {
        MsgBox("Utilities Manager not properly initialized.", "Error", "Icon!")
    }
}

; Toggle Quick Notes (Alt+Shift+N, or from settings)
DynamicQuickNotesHotkey() {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        UtilitiesManager.ToggleQuickNotes()
    } else {
        MsgBox("Utilities Manager not properly initialized.", "Error", "Icon!")
    }
}

; Assign the hotkey from settings at startup
try {
    Hotkey(UtilitiesManager.settings.hotkeys.quickNotes, (*) => DynamicQuickNotesHotkey())
} catch as err {
    MsgBox("Failed to register Quick Notes hotkey (" . UtilitiesManager.settings.hotkeys.quickNotes . "):`n" . err.Message, "Hotkey Error", "Icon!")
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

; Toggle Desktop Icons
^#i::DesktopIconToggle()

; Reload All (Ctrl+Shift+Alt+R, or from settings)
DynamicReloadAllHotkey() {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        UtilitiesManager.ReloadAll()
    } else {
        Reload
    }
}

try {
    Hotkey(UtilitiesManager.settings.hotkeys.reloadAll, (*) => DynamicReloadAllHotkey())
} catch as err {
    MsgBox("Failed to register Reload All hotkey (" . UtilitiesManager.settings.hotkeys.reloadAll . "):`n" . err.Message, "Hotkey Error", "Icon!")
}

; Toggle Explorer Dialog (Ctrl+MButton, or from settings)
DynamicExplorerDialogHotkey() {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        if UtilitiesManager.explorerDialog {
            UtilitiesManager.explorerDialog.ShowPathMenu()
        } else {
            MsgBox("Explorer Dialog is not available.", "Error", "Icon!")
        }
    } else {
        MsgBox("Utilities Manager not properly initialized.", "Error", "Icon!")
    }
}

try {
    Hotkey(UtilitiesManager.settings.hotkeys.explorerDialog, (*) => DynamicExplorerDialogHotkey())
} catch as err {
    MsgBox("Failed to register Explorer Dialog hotkey (" . UtilitiesManager.settings.hotkeys.explorerDialog . "):`n" . err.Message, "Hotkey Error", "Icon!")
}

; Show startup notification
TrayTip("Windows Utilities Manager", "All utilities loaded successfully!`n Middle-click: Explorer Dialog`n📝 Alt+Shift+N: Quick Notes`n📋 Alt+Shift+T: To-Do & Reminders`n✨ Ctrl+Shift+E: Toggle Text Expander`n🖥️ Ctrl+Win+I: Toggle Desktop Icons`n⏸️ Ctrl+Win+P: Suspend All Hotkeys`n💬 Type @@@, addr, date to expand", "Icon!")
SetTimer(() => TrayTip(), -5000)

; Create Ctrl+Win+P hotkey that works even when suspended (placed after Suspend call)
#SuspendExempt
^#p:: {
    global UtilitiesManager
    if UtilitiesManager && IsObject(UtilitiesManager) {
        UtilitiesManager.ToggleSuspendHotkeys()
    } else {
        Suspend(-1)
        TrayTip("Hotkeys " . (A_IsSuspended ? "suspended" : "resumed"), "Hotkeys have been " . (A_IsSuspended ? "suspended" : "resumed") . ".", "Icon!")
        SetTimer(() => TrayTip(), -3000)
    }
}
#SuspendExempt False