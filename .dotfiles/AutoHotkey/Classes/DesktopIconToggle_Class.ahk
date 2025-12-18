DesktopIconToggle_ToggleIcons() {
    ; Store the currently active window
    activeWindow := WinGetID("A")
    
    ; Show desktop first (Win+D)
    Send("#d")
    Sleep 300
    
    ; Focus desktop by activating Progman/WorkerW window
    try {
        WinActivate("ahk_class Progman")
    } catch {
        try {
            WinActivate("ahk_class WorkerW")
        }
    }
    Sleep 200
    
    ; Now open context menu with Shift+F10
    Send("+{F10}")
    Sleep 400
    
    ; Navigate to View -> Show desktop icons
    Send("v")       ; V = View
    Sleep 250       ; Wait for submenu
    Send("d")       ; D = Show desktop icons
    Sleep 200
    
    ; Show desktop again to restore windows
    Send("#d")
    Sleep 300
    
    ; Restore the previously active window
    try {
        WinActivate("ahk_id " activeWindow)
    }
}