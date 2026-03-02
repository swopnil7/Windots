; To-Do Manager Class
; Features: Tasks, priorities, due dates, notifications, persistence

class TodoReminder {
    ; Properties
    parentManager := ""
    isVisible := false
    gui := ""
    tasksList := ""
    addTaskEdit := ""
    priorityDropdown := ""
    dueDateEdit := ""
    filterDropdown := ""
    
    ; Settings and data
    settings := {
        windowWidth: 800,
        windowHeight: 600,
        autoSave: true,
        reminderInterval: 300000,
        showNotifications: true,
        playSound: true,
        alwaysOnTop: false,
        windowX: -1,
        windowY: -1,
        sortBy: "priority", ; priority, date, alphabetical
        filterBy: "all", ; all, pending, completed, overdue
        lastSortColumn: 1 ; Track which column is being sorted (1-5)
    }
    
    tasks := []
    reminderTimer := ""
    remindedTasks := Map()  ; Track which tasks have already been reminded about to prevent spam
    
    ; Constructor
    __New(parentManager := "") {
        this.parentManager := parentManager
        this.LoadSettings()
        this.LoadTasks()
        this.CreateGUI()
        this.SetupReminderTimer()
        this.CheckOverdueTasks()
        this.ScheduleAllReminders()  ; Schedule any existing reminders
    }
    
    ; Get colors from parent manager or use defaults
    GetColors() {
        if this.parentManager && this.parentManager.colors {
            return this.parentManager.colors
        }
        ; Fallback Catppuccin Mocha colors
        return {
            bg: "0x1e1e2e",
            mantle: "0x181825",
            surface0: "0x313244",
            surface1: "0x45475a",
            text: "0xcdd6f4",
            subtext1: "0xbac2de",
            blue: "0x89b4fa",
            mauve: "0xcba6f7",
            red: "0xf38ba8",
            green: "0xa6e3a1",
            yellow: "0xf9e2af",
            overlay0: "0x6c7086"
        }
    }
    
    ; ========================================
    ; GUI CREATION
    ; ========================================
    
    CreateGUI() {
        colors := this.GetColors()
        
        ; Use same window flags as QuickNoteTaker for consistency
        flags := "-MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow"
        if this.settings.alwaysOnTop {
            flags .= " +AlwaysOnTop"
        }
        
        this.gui := Gui(flags, "📝 To-Do")
        this.gui.SetFont("s10", "Segoe UI")
        this.gui.BackColor := colors.bg
        this.gui.OnEvent("Close", this.Hide.Bind(this))
        this.gui.OnEvent("ContextMenu", (*) => "")  ; Disable right-click context menu
        
        ; Add task section - Row 1: Task text and Due date
        this.gui.AddText("xm ym c" . colors.text, "➕ New Task:")
        this.addTaskEdit := this.gui.AddEdit("x+10 yp-3 w300 h23 Background" . colors.surface0 . " c" . colors.text)
        this.addTaskEdit.OnEvent("Change", this.OnTaskTextChange.Bind(this))
        
        this.gui.AddText("x+15 yp+3 c" . colors.subtext1, "Due:")
        this.dueDateEdit := this.gui.AddEdit("x+5 yp-3 w115 h23 Background" . colors.surface0 . " c" . colors.text . " ReadOnly", "")
        this.dueDateEdit.ToolTip := "Click the calendar button to select a date"
        calendarBtn := this.gui.AddButton("x+2 yp w25 h23 Background" . colors.blue . " c" . colors.bg, "📅")
        calendarBtn.OnEvent("Click", this.ShowCalendar.Bind(this))
        clearDateBtn := this.gui.AddButton("x+2 yp w25 h23 Background" . colors.red . " c" . colors.bg, "❌")
        clearDateBtn.OnEvent("Click", this.ClearDueDate.Bind(this))
        
        ; Row 2: Priority, Recurring, and Add button
        this.gui.AddText("xm y+10 c" . colors.subtext1, "Priority:")
        this.priorityDropdown := this.gui.AddDropDownList("x+5 yp-3 w105 Background" . colors.surface0 . " c" . colors.text, ["🔴 High", "🟡 Medium", "🟢 Low"])
        this.priorityDropdown.Choose(2) ; Default to Medium
        
        this.gui.AddText("x+15 yp+3 c" . colors.subtext1, "Recurs:")
        this.recurringDropdown := this.gui.AddDropDownList("x+5 yp-3 w90 Background" . colors.surface0 . " c" . colors.text, ["None", "Daily", "Weekly", "Monthly"])
        this.recurringDropdown.Choose(1)
        
        ; Add button
        addBtn := this.gui.AddButton("x+15 yp w80 h23 Background" . colors.green . " c" . colors.bg, "Add Task")
        addBtn.OnEvent("Click", this.AddTaskFromButton.Bind(this))
        
        ; Tasks list with filter
        this.gui.AddText("xm y+20 c" . colors.text, "📋 Tasks:")
        
        this.gui.AddText("x+320 yp c" . colors.subtext1, "Filter:")
        this.filterDropdown := this.gui.AddDropDownList("x+5 yp-3 w100 Background" . colors.surface0 . " c" . colors.text, ["All Tasks", "Pending", "Completed", "Overdue"])
        this.filterDropdown.Choose(1)
        this.filterDropdown.OnEvent("Change", this.FilterTasks.Bind(this))
        
        ; ListView height for 10-12 rows: approximately 25px per row + header
        listHeight := 405  ; Shows about 12 rows
        ; Calculate ListView width dynamically based on window width (leave 50px margin total)
        listWidth := this.settings.windowWidth - 25
        ; Add more styling options to ListView for better header appearance (removed NoSortHdr to enable column sorting)
        this.tasksList := this.gui.AddListView("xm y+5 w" . listWidth . " h" . listHeight . " Background" . colors.surface0 . " c" . colors.text . " -Multi Grid Checked", ["Priority", "Task", "Due Date", "Days Left", "Created"])
        this.tasksList.SetFont("s10", "Segoe UI Emoji")  ; Use Segoe UI Emoji for better emoji rendering
        this.tasksList.OnEvent("ItemCheck", this.OnTaskCheck.Bind(this))
        this.tasksList.OnEvent("DoubleClick", this.EditSelectedTask.Bind(this))
        this.tasksList.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))
        this.tasksList.OnEvent("ColClick", this.OnColumnClick.Bind(this))
        
        ; Bottom action buttons
        this.gui.AddButton("xm y+15 w80 h30 Background" . colors.red . " c" . colors.bg, "🗑️ Delete").OnEvent("Click", this.DeleteSelectedTask.Bind(this))
        this.gui.AddButton("x+5 yp w70 h30 Background" . colors.blue . " c" . colors.bg, "✏️ Edit").OnEvent("Click", this.EditSelectedTask.Bind(this))
        this.gui.AddButton("x+5 yp w125 h30 Background" . colors.mauve . " c" . colors.bg, "🔔 Set Reminder").OnEvent("Click", this.SetReminder.Bind(this))
        this.gui.AddButton("x+5 yp w70 h30 Background" . colors.green . " c" . colors.bg, "📊 Stats").OnEvent("Click", this.ShowStats.Bind(this))
        this.gui.AddButton("x+5 yp w80 h30 Background" . colors.overlay0 . " c" . colors.bg, "⚙️ Settings").OnEvent("Click", this.ShowSettings.Bind(this))
        
        ; Status bar (positioned closer to buttons, no border for compact appearance)
        ; Calculate status bar width dynamically based on window width (same as ListView)
        statusBarWidth := this.settings.windowWidth - 50
        this.statusBar := this.gui.AddText("xm y+10 w" . statusBarWidth . " h20 c" . colors.subtext1 . " VCenter", "Ready | Total: 0 | Pending: 0 | Completed: 0")
        
        ; Load saved position
        if this.settings.windowX >= 0 && this.settings.windowY >= 0 {
            this.gui.Show("x" . this.settings.windowX . " y" . this.settings.windowY . " w" . this.settings.windowWidth . " h" . this.settings.windowHeight . " Hide")
        } else {
            this.gui.Show("w" . this.settings.windowWidth . " h" . this.settings.windowHeight . " Hide")
        }
        
        this.RefreshTasksList()
        this.StyleListViewHeader()
    }
    
    ; Style the ListView header with dark background and border
    StyleListViewHeader() {
        try {
            colors := this.GetColors()
            
            ; Get the ListView's window handle
            lvHwnd := this.tasksList.Hwnd
            
            ; Get the header control handle
            headerHwnd := DllCall("SendMessage", "Ptr", lvHwnd, "UInt", 0x101F, "Ptr", 0, "Ptr", 0, "Ptr") ; LVM_GETHEADER
            
            if (headerHwnd) {
                ; Method 1: Try to set header background using Windows themes
                ; Enable visual styles for header
                DllCall("uxtheme\SetWindowTheme", "Ptr", headerHwnd, "Str", "DarkMode_Explorer", "Str", "")
                
                ; Method 2: Set custom colors using Windows API
                ; Convert colors from hex to RGB (Windows API expects BGR format)
                darkHeaderColor := 0x45475a  ; colors.surface1 - darker background
                textColor := 0xFFFFFF       ; white text for contrast
                
                ; Set header background color (this may not work on all Windows versions)
                DllCall("SendMessage", "Ptr", headerHwnd, "UInt", 0x2000 + 6, "Ptr", darkHeaderColor, "Ptr", 0) ; HDM_SETBKCOLOR
                DllCall("SendMessage", "Ptr", headerHwnd, "UInt", 0x2000 + 4, "Ptr", textColor, "Ptr", 0) ; HDM_SETTEXTCOLOR
                
                ; Method 3: Add extended window styles for better appearance
                currentExStyle := DllCall("GetWindowLongPtr", "Ptr", headerHwnd, "Int", -20, "Ptr") ; GWL_EXSTYLE
                newExStyle := currentExStyle | 0x200  ; WS_EX_CLIENTEDGE for border
                DllCall("SetWindowLongPtr", "Ptr", headerHwnd, "Int", -20, "Ptr", newExStyle)
                
                ; Method 4: Ensure ListView has grid lines to separate header from content
                currentLvStyle := DllCall("GetWindowLongPtr", "Ptr", lvHwnd, "Int", -16, "Ptr") ; GWL_STYLE
                newLvStyle := currentLvStyle | 0x1  ; LVS_SINGLESEL for better appearance
                DllCall("SetWindowLongPtr", "Ptr", lvHwnd, "Int", -16, "Ptr", newLvStyle)
                
                ; Set extended ListView styles for better grid appearance
                DllCall("SendMessage", "Ptr", lvHwnd, "UInt", 0x1000 + 54, "Ptr", 0x1, "Ptr", 0x1, "Ptr") ; LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_GRIDLINES
                
                ; Force redraw
                DllCall("InvalidateRect", "Ptr", headerHwnd, "Ptr", 0, "Int", 1)
                DllCall("UpdateWindow", "Ptr", headerHwnd)
                DllCall("InvalidateRect", "Ptr", lvHwnd, "Ptr", 0, "Int", 1)
                
                ; Alternative method: Set the font to make headers more prominent
                ; Create a bold font for headers
                hFont := DllCall("CreateFont", "Int", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 700, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "Str", "Segoe UI")
                if (hFont) {
                    DllCall("SendMessage", "Ptr", headerHwnd, "UInt", 0x30, "Ptr", hFont, "Ptr", 0) ; WM_SETFONT
                }
            }
        } catch Error as e {
            ; Silently ignore header styling errors - not critical for functionality
        }
    }
    
    ; ========================================
    ; TASK MANAGEMENT
    ; ========================================
    
    AddTask(taskText := "", priority := "", dueDate := "") {
        ; Handle case where taskText might be passed as a control object
        if IsObject(taskText) {
            taskText := ""
        }
        
        if !taskText {
            taskText := Trim(this.addTaskEdit.Text)
        }
        if !taskText {
            return
        }
        
        if !priority {
            priority := this.priorityDropdown.Text
        }
        if !dueDate {
            dueDate := Trim(this.dueDateEdit.Text)
        }
        
        ; Get recurring setting
        recurringOptions := ["none", "daily", "weekly", "monthly"]
        recurring := recurringOptions[this.recurringDropdown.Value]
        
        ; Parse the formatted date from the calendar picker
        parsedDate := ""
        if dueDate {
            ; If it's already in display format (MM/DD/YYYY), convert to internal format
            if RegExMatch(dueDate, "^(\d{1,2})/(\d{1,2})/(\d{4})$", &match) {
                month := Format("{:02d}", Integer(match[1]))
                day := Format("{:02d}", Integer(match[2]))
                year := match[3]
                parsedDate := year . month . day . "000000"
            } else {
                parsedDate := this.ParseDate(dueDate)
            }
        }
        
        task := {
            id: this.GenerateTaskId(),
            text: taskText,
            priority: priority,
            dueDate: parsedDate,
            completed: false,
            created: A_Now,
            reminder: "",
            recurring: recurring
        }
        
        this.tasks.Push(task)
        this.SaveTasks()
        this.RefreshTasksList()
        this.UpdateStatusBar()
        
        ; Clear input fields
        this.addTaskEdit.Text := ""
        this.dueDateEdit.Text := ""
        this.priorityDropdown.Choose(2)
        this.recurringDropdown.Choose(1)
        
        this.ShowDebug("Added task: " . taskText)
    }
    
    CreateRecurringTask(originalTask) {
        ; Calculate new due date based on recurring type
        newDueDate := ""
        if originalTask.dueDate {
            currentDate := originalTask.dueDate
            
            ; Extract date components (format: YYYYMMDDHHMMSS)
            year := SubStr(currentDate, 1, 4)
            month := SubStr(currentDate, 5, 2)
            day := SubStr(currentDate, 7, 2)
            
            switch originalTask.recurring {
                case "daily":
                    newDueDate := DateAdd(currentDate, 1, "days")
                case "weekly":
                    newDueDate := DateAdd(currentDate, 7, "days")
                case "monthly":
                    newDueDate := DateAdd(currentDate, 1, "months")
            }
        } else {
            ; If no due date, set based on today
            switch originalTask.recurring {
                case "daily":
                    newDueDate := DateAdd(A_Now, 1, "days")
                case "weekly":
                    newDueDate := DateAdd(A_Now, 7, "days")
                case "monthly":
                    newDueDate := DateAdd(A_Now, 1, "months")
            }
        }
        
        ; Create new recurring task
        newTask := {
            id: this.GenerateTaskId(),
            text: originalTask.text,
            priority: originalTask.priority,
            dueDate: newDueDate,
            completed: false,
            created: A_Now,
            reminder: "",
            recurring: originalTask.recurring
        }
        
        this.tasks.Push(newTask)
        this.ShowDebug("Created recurring task: " . originalTask.text . " for " . this.FormatDate(newDueDate))
    }
    
    DeleteSelectedTask(*) {
        selected := this.tasksList.GetNext()
        if !selected {
            colors := this.GetColors()
            themedGui := Gui("+Owner" . (this.gui ? this.gui.Hwnd : "") . " -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "📝 To-Do")
            themedGui.SetFont("s10", "Segoe UI")
            themedGui.BackColor := colors.bg
            themedGui.AddText("xm ym w260 c" . colors.text, "Please select a task to delete.")
            okBtn := themedGui.AddButton("xm y+15 w80 h28 Background" . colors.blue . " c" . colors.bg, "OK")
            okBtn.OnEvent("Click", (*) => themedGui.Destroy())
            themedGui.OnEvent("Close", (*) => themedGui.Destroy())
            themedGui.OnEvent("Escape", (*) => themedGui.Destroy())
            themedGui.Show("w280 h110")
            return
        }
        
        result := MsgBox("Are you sure you want to delete this task?", "Confirm Delete", "YesNo Icon?")
        
        if result = "Yes" {
            ; Find the corresponding task in our filtered list
            filteredTasks := this.GetFilteredTasks()
            this.SortTasksArray(filteredTasks)
            
            if selected <= filteredTasks.Length {
                targetTask := filteredTasks[selected]
                
                ; Find and remove task from main tasks array
                for i, task in this.tasks {
                    if task.id = targetTask.id {
                        this.tasks.RemoveAt(i)
                        break
                    }
                }
                this.SaveTasks()
                this.RefreshTasksList()
                this.UpdateStatusBar()
            }
        }
    }
    
    OnTaskCheck(listView, itemIndex, *) {
        ; Find the corresponding task in our filtered list
        filteredTasks := this.GetFilteredTasks()
        this.SortTasksArray(filteredTasks)
        
        if itemIndex <= filteredTasks.Length {
            ; Find the task in the main tasks array
            targetTask := filteredTasks[itemIndex]
            for i, task in this.tasks {
                if task.id = targetTask.id {
                    ; Toggle completion status
                    isChecked := this.tasksList.GetNext(itemIndex - 1, "Checked") = itemIndex
                    this.tasks[i].completed := isChecked
                    
                    ; If completed and recurring, create new task
                    if isChecked && task.HasOwnProp("recurring") && task.recurring != "none" {
                        this.CreateRecurringTask(task)
                    }
                    
                    this.SaveTasks()
                    this.RefreshTasksList()
                    this.UpdateStatusBar()
                    break
                }
            }
        }
    }
    
    ; Handle column header clicks for sorting
    OnColumnClick(listView, colNum, *) {
        ; Map column numbers to sort types
        sortMap := Map(
            1, "priority",     ; Priority column
            2, "alphabetical", ; Task column
            3, "date",         ; Due Date column
            4, "date",         ; Days Left column (same as due date)
            5, "created"       ; Created column
        )
        
        if sortMap.Has(colNum) {
            this.settings.sortBy := sortMap[colNum]
            this.settings.lastSortColumn := colNum
            this.UpdateColumnHeaders()
            this.RefreshTasksList()
        }
    }
    
    ; Update column headers to show sort indicator
    UpdateColumnHeaders() {
        ; This will be called before RefreshTasksList which updates the headers
        ; No action needed here as RefreshTasksList handles it
    }
    
    EditSelectedTask(*) {
        selected := this.tasksList.GetNext()
        if !selected {
            colors := this.GetColors()
            themedGui := Gui("+Owner" . (this.gui ? this.gui.Hwnd : "") . " -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "📝 To-Do")
            themedGui.SetFont("s10", "Segoe UI")
            themedGui.BackColor := colors.bg
            themedGui.AddText("xm ym w260 c" . colors.text, "Please select a task to edit.")
            okBtn := themedGui.AddButton("xm y+15 w80 h28 Background" . colors.blue . " c" . colors.bg, "OK")
            okBtn.OnEvent("Click", (*) => themedGui.Destroy())
            themedGui.OnEvent("Escape", (*) => themedGui.Destroy())
            themedGui.Show("w280 h110")
            return
        }
        
        ; Find the corresponding task in our filtered list
        filteredTasks := this.GetFilteredTasks()
        this.SortTasksArray(filteredTasks)
        
        if selected <= filteredTasks.Length {
            targetTask := filteredTasks[selected]
            
            ; Find the task index in the main tasks array
            for i, task in this.tasks {
                if task.id = targetTask.id {
                    this.ShowEditTaskDialog(task, i)
                    break
                }
            }
        }
    }
    
    ShowEditTaskDialog(task, index) {
        colors := this.GetColors()
        
        editGui := Gui("+Owner" . this.gui.Hwnd . " -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "✏️ Edit Task")
        editGui.SetFont("s10", "Segoe UI")
        editGui.BackColor := colors.bg
        editGui.OnEvent("Escape", (*) => editGui.Destroy())
        
        editGui.AddText("xm ym c" . colors.text, "Task:")
        taskEdit := editGui.AddEdit("xm y+5 w200 h23 Background" . colors.surface0 . " c" . colors.text, task.text)
        
        editGui.AddText("xm y+15 c" . colors.text, "Priority:")
        priorityDD := editGui.AddDropDownList("xm y+5 w120 Background" . colors.surface0 . " c" . colors.text, ["🔴 High", "🟡 Medium", "🟢 Low"])
        priorityIndex := 2
        if task.priority {
            priorities := ["🔴 High", "🟡 Medium", "🟢 Low"]
            for i, priority in priorities {
                if priority = task.priority {
                    priorityIndex := i
                    break
                }
            }
        }
        priorityDD.Choose(priorityIndex)
        
        editGui.AddText("xm y+15 c" . colors.text, "Due Date:")
        dueDateEdit := editGui.AddEdit("xm y+5 w120 h23 Background" . colors.surface0 . " c" . colors.text . " ReadOnly", this.FormatDate(task.dueDate))
        editCalendarBtn := editGui.AddButton("x+5 yp w30 h23 Background" . colors.blue . " c" . colors.bg, "📅")
        editClearBtn := editGui.AddButton("x+5 yp w30 h23 Background" . colors.red . " c" . colors.bg, "❌")
        
        editCalendarBtn.OnEvent("Click", this.ShowEditCalendar.Bind(this, dueDateEdit))
        editClearBtn.OnEvent("Click", this.ClearEditDate.Bind(this, dueDateEdit))
        
        saveBtn := editGui.AddButton("xm y+25 w90 h30 Background" . colors.green . " c" . colors.bg, "💾 Save")
        cancelBtn := editGui.AddButton("x+10 yp w90 h30 Background" . colors.red . " c" . colors.bg, "❌ Cancel")
        
        saveBtn.OnEvent("Click", this.SaveEditedTaskWrapper.Bind(this, editGui, taskEdit, priorityDD, dueDateEdit, index))
        cancelBtn.OnEvent("Click", this.CloseEditDialog.Bind(this, editGui))
        
        editGui.Show("w220")
    }
    
    SaveEditedTask(editGui, taskEdit, priorityDD, dueDateEdit, index) {
        this.tasks[index].text := Trim(taskEdit.Text)
        this.tasks[index].priority := priorityDD.Text
        
        ; Parse the due date from the calendar picker format
        dueDateText := Trim(dueDateEdit.Text)
        if dueDateText {
            ; If it's in display format (MM/DD/YYYY), convert to internal format
            if RegExMatch(dueDateText, "^(\d{1,2})/(\d{1,2})/(\d{4})$", &match) {
                month := Format("{:02d}", Integer(match[1]))
                day := Format("{:02d}", Integer(match[2]))
                year := match[3]
                this.tasks[index].dueDate := year . month . day . "000000"
            } else {
                this.tasks[index].dueDate := this.ParseDate(dueDateText)
            }
        } else {
            this.tasks[index].dueDate := ""
        }
        
        this.SaveTasks()
        this.RefreshTasksList()
        this.UpdateStatusBar()
        editGui.Destroy()
    }
    
    ; Wrapper method to match expected signature for event handler
    SaveEditedTaskWrapper(editGui, taskEdit, priorityDD, dueDateEdit, index, *) {
        this.SaveEditedTask(editGui, taskEdit, priorityDD, dueDateEdit, index)
    }
    
    ; Close edit dialog
    CloseEditDialog(editGui, *) {
        editGui.Destroy()
    }
    
    ; Sort change event handler
    OnSortChange(sortDropdown, *) {
        selected := sortDropdown.Text
        switch selected {
            case "Priority":
                this.SortTasks("priority")
            case "Due Date":
                this.SortTasks("due date")
            case "Alphabetical":
                this.SortTasks("alphabetical")
        }
    }
    
    ; Quick add methods
    QuickAddCall(*) {
        this.QuickAddTask("Call", "🟡 Medium")
    }
    
    QuickAddEmail(*) {
        this.QuickAddTask("Email", "🟡 Medium")
    }
    
    QuickAddBuy(*) {
        this.QuickAddTask("Buy", "🟢 Low")
    }
    
    QuickAddMeeting(*) {
        this.QuickAddTask("Meeting", "🔴 High")
    }
    
    ; Wrapper method for Add button click event
    AddTaskFromButton(*) {
        this.AddTask("", "", "")
    }

    ; ========================================
    ; DISPLAY AND FILTERING
    ; ========================================
    
    RefreshTasksList() {
        this.tasksList.Delete()
        
        ; Update column headers with sort indicator
        baseHeaders := ["Priority", "Task", "Due Date", "Days Left", "Created"]
        sortCol := this.settings.HasOwnProp("lastSortColumn") ? this.settings.lastSortColumn : 1
        
        Loop 5 {
            headerText := baseHeaders[A_Index]
            if A_Index = sortCol {
                headerText .= " ▼"
            }
            this.tasksList.ModifyCol(A_Index, , headerText)
        }
        
        filteredTasks := this.GetFilteredTasks()
        this.SortTasksArray(filteredTasks)
        
        for task in filteredTasks {
            dueDateStr := task.dueDate ? this.FormatDate(task.dueDate) : ""
            daysLeftStr := (task.dueDate && !task.completed) ? this.GetDaysLeft(task.dueDate) : ""
            createdStr := this.FormatDate(task.created)
            
            ; Extract priority text without emoji for better rendering
            priorityDisplay := task.priority
            if InStr(task.priority, "High")
                priorityDisplay := "🔴 High"
            else if InStr(task.priority, "Medium")
                priorityDisplay := "🟡 Medium"
            else if InStr(task.priority, "Low")
                priorityDisplay := "🟢 Low"
            
            ; Add recurring indicator to task text
            taskDisplay := task.text
            if task.HasOwnProp("recurring") && task.recurring != "none" {
                taskDisplay := "🔄 " . taskDisplay
            }
            
            ; Add row: Columns are Priority, Task, Due Date, Days Left, Created
            row := this.tasksList.Add("", priorityDisplay, taskDisplay, dueDateStr, daysLeftStr, createdStr)
            
            ; Set checkbox state separately
            if task.completed {
                this.tasksList.Modify(row, "Check")
            }
            
            ; Color code overdue tasks
            if task.dueDate && !task.completed && this.IsOverdue(task.dueDate) {
                colors := this.GetColors()
                ; Note: AutoHotkey v2 ListView doesn't support easy row coloring, could use custom drawing
            }
        }
        
        ; Calculate column widths proportionally based on ListView width
        listWidth := this.settings.windowWidth - 25
        this.tasksList.ModifyCol(1, Round(listWidth * 0.15))   ; Priority - 14% (105px at 750px width)
        this.tasksList.ModifyCol(2, Round(listWidth * 0.40 - 4))   ; Task - 45% (338px) - more space for task text
        this.tasksList.ModifyCol(3, Round(listWidth * 0.15))   ; Due Date - 16% (120px)
        this.tasksList.ModifyCol(4, Round(listWidth * 0.15))   ; Days Left - 10% (75px)
        this.tasksList.ModifyCol(5, Round(listWidth * 0.15))   ; Created - 15% (112px)
        
        ; Re-apply header styling after refresh
        this.StyleListViewHeader()
        
        ; Update status bar after refreshing the list
        this.UpdateStatusBar()
    }
    
    GetFilteredTasks() {
        filter := this.filterDropdown.Text
        filtered := []
        
        for task in this.tasks {
            switch filter {
                case "All Tasks":
                    filtered.Push(task)
                case "Pending":
                    if !task.completed {
                        filtered.Push(task)
                    }
                case "Completed":
                    if task.completed {
                        filtered.Push(task)
                    }
                case "Overdue":
                    if !task.completed && task.dueDate && this.IsOverdue(task.dueDate) {
                        filtered.Push(task)
                    }
            }
        }
        
        return filtered
    }
    
    FilterTasks(*) {
        this.RefreshTasksList()
        this.UpdateStatusBar()
    }
    
    SortTasks(sortBy) {
        this.settings.sortBy := StrLower(sortBy)
        this.RefreshTasksList()
    }
    
    SortTasksArray(tasksArray) {
        if tasksArray.Length <= 1 {
            return
        }
        
        ; For date-related sorting, separate completed and incomplete tasks
        if this.settings.sortBy = "date" || this.settings.sortBy = "due date" || this.settings.sortBy = "created" {
            incompleteTasks := []
            completedTasks := []
            
            ; Separate tasks by completion status
            for task in tasksArray {
                if task.completed {
                    completedTasks.Push(task)
                } else {
                    incompleteTasks.Push(task)
                }
            }
            
            ; Sort each group
            if this.settings.sortBy = "created" {
                this.BubbleSort(incompleteTasks, (a, b) => this.CompareDates(a.created, b.created))
                this.BubbleSort(completedTasks, (a, b) => this.CompareDates(a.created, b.created))
            } else {
                this.BubbleSort(incompleteTasks, (a, b) => this.CompareDates(a.dueDate, b.dueDate))
                this.BubbleSort(completedTasks, (a, b) => this.CompareDates(a.dueDate, b.dueDate))
            }
            
            ; Clear and rebuild array with incomplete first, completed last
            tasksArray.Length := 0
            for task in incompleteTasks {
                tasksArray.Push(task)
            }
            for task in completedTasks {
                tasksArray.Push(task)
            }
        } else {
            ; For non-date sorting, use normal sorting
            switch this.settings.sortBy {
                case "priority":
                    this.BubbleSort(tasksArray, (a, b) => this.ComparePriority(a.priority, b.priority))
                case "alphabetical":
                    this.BubbleSort(tasksArray, (a, b) => StrCompare(a.text, b.text, false))
            }
        }
    }
    
    ; Bubble sort implementation for task arrays
    BubbleSort(arr, compareFunc) {
        n := arr.Length
        Loop n - 1 {
            i := A_Index
            Loop n - i {
                j := A_Index
                if compareFunc(arr[j], arr[j+1]) > 0 {
                    temp := arr[j]
                    arr[j] := arr[j+1]
                    arr[j+1] := temp
                }
            }
        }
    }
    
    ; ========================================
    ; REMINDERS AND NOTIFICATIONS
    ; ========================================
    
    SetupReminderTimer() {
        if this.settings.reminderInterval > 0 {
            this.reminderTimer := SetTimer(() => this.CheckReminders(), this.settings.reminderInterval)
        }
    }
    
    CheckReminders() {
        if !this.settings.showNotifications {
            return
        }
        
        now := A_Now
        currentHour := SubStr(now, 1, 10)  ; Get current date and hour (YYYYMMDDHH)
        
        for task in this.tasks {
            if !task.completed && task.dueDate && this.IsNearDue(task.dueDate, now) {
                ; Create a unique key for this task and 2-hour period
                ; Use integer division to group hours into 2-hour blocks (0-1, 2-3, 4-5, etc.)
                hour := Integer(SubStr(now, 9, 2))
                hourBlock := (hour // 2) * 2  ; Groups: 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
                reminderKey := task.id . "_" . SubStr(now, 1, 8) . "_" . Format("{:02d}", hourBlock)
                
                ; Only show reminder if we haven't already reminded about this task in this 2-hour period
                if !this.remindedTasks.Has(reminderKey) {
                    this.ShowReminderNotification(task)
                    ; Mark this task as reminded for this 2-hour period
                    this.remindedTasks[reminderKey] := true
                }
            }
        }
        
        ; Clean up old reminder entries (keep only entries from the last 48 hours)
        currentDate := SubStr(now, 1, 8)
        yesterdayDate := SubStr(DateAdd(now, -1, "days"), 1, 8)
        keysToRemove := []
        for key, value in this.remindedTasks {
            ; Keep only entries from today or yesterday
            if !InStr(key, "_" . currentDate) && !InStr(key, "_" . yesterdayDate) {
                keysToRemove.Push(key)
            }
        }
        for key in keysToRemove {
            this.remindedTasks.Delete(key)
        }
    }
    
    CheckOverdueTasks() {
        overdueCount := 0
        for task in this.tasks {
            if !task.completed && task.dueDate && this.IsOverdue(task.dueDate) {
                overdueCount++
            }
        }
        
        if overdueCount > 0 {
            TrayTip("📝 To-Do Reminder", overdueCount . " task(s) are overdue!", "Icon!")
        }
    }
    
    ShowReminderNotification(task) {
        message := "Task due soon: " . task.text
        if task.dueDate {
            message .= "`nDue: " . this.FormatDate(task.dueDate)
        }
        
        TrayTip("🔔 Task Reminder", message, "Icon!")
        
        if this.settings.playSound {
            SoundPlay("*48") ; Asterisk sound
        }
    }
    
    SetReminder(*) {
        selected := this.tasksList.GetNext()
        if !selected {
            colors := this.GetColors()
            themedGui := Gui("+Owner" . (this.gui ? this.gui.Hwnd : "") . " -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "📝 To-Do")
            themedGui.SetFont("s10", "Segoe UI")
            themedGui.BackColor := colors.bg
            themedGui.AddText("xm ym w260 c" . colors.text, "Please select a task to set a reminder for.")
            okBtn := themedGui.AddButton("xm y+15 w80 h28 Background" . colors.blue . " c" . colors.bg, "OK")
            okBtn.OnEvent("Click", (*) => themedGui.Destroy())
            themedGui.OnEvent("Escape", (*) => themedGui.Destroy())
            themedGui.Show("w280 h110")
            return
        }
        
        ; Find the corresponding task in our filtered list
        filteredTasks := this.GetFilteredTasks()
        this.SortTasksArray(filteredTasks)
        
        if selected > filteredTasks.Length {
            MsgBox("Invalid task selection.", "Error", "Icon!")
            return
        }
        
        targetTask := filteredTasks[selected]
        
        ; Find the task in the main tasks array
        taskIndex := 0
        for i, task in this.tasks {
            if task.id = targetTask.id {
                taskIndex := i
                break
            }
        }
        
        if !taskIndex {
            MsgBox("Task not found.", "Error", "Icon!")
            return
        }
        
        ; Show themed reminder dialog
        this.ShowReminderDialog(this.tasks[taskIndex], taskIndex)
    }
    
    ; Show themed reminder dialog
    ShowReminderDialog(task, taskIndex) {
        colors := this.GetColors()
        
        reminderGui := Gui("+Owner" . this.gui.Hwnd . " -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "🔔 Set Reminder")
        reminderGui.SetFont("s10", "Segoe UI")
        reminderGui.BackColor := colors.bg
        reminderGui.OnEvent("Escape", (*) => reminderGui.Destroy())
        
        ; Task info section
        reminderGui.AddText("xm ym w400 c" . colors.text . " Section", "🔔 Set Reminder")
        reminderGui.SetFont("s10 Bold")
        reminderGui.AddText("xm y+5 w400 c" . colors.mauve, "Task: " . task.text)
        reminderGui.SetFont("s10 Norm")
        
        ; Current reminder status
        if task.reminder {
            currentReminder := this.FormatDate(task.reminder)
            reminderGui.AddText("xm y+10 w400 c" . colors.yellow, "⏰ Current reminder: " . currentReminder)
        } else {
            reminderGui.AddText("xm y+10 w400 c" . colors.subtext1, "📅 No reminder set")
        }
        
        ; Separator
        reminderGui.AddText("xm y+15 w400 h1 Background" . colors.overlay0)
        
        ; Time input section
        reminderGui.AddText("xm y+15 c" . colors.text, "⏰ Reminder Time:")
        reminderGui.AddText("xm y+5 c" . colors.subtext1, "Enter when you want to be reminded:")
        
        ; Time input field
        timeEdit := reminderGui.AddEdit("xm y+10 w200 h25 Background" . colors.surface0 . " c" . colors.text, "")
        timeEdit.ToolTip := "Examples: 5 min, 1 hour, 2 days"
        
        ; Quick time buttons
        reminderGui.AddText("xm y+15 c" . colors.text, "⚡ Quick Select:")
        fiveMinBtn := reminderGui.AddButton("xm y+5 w70 h25 Background" . colors.blue . " c" . colors.bg, "5 min")
        thirtyMinBtn := reminderGui.AddButton("x+5 yp w70 h25 Background" . colors.blue . " c" . colors.bg, "30 min")
        oneHourBtn := reminderGui.AddButton("x+5 yp w70 h25 Background" . colors.green . " c" . colors.bg, "1 hour")
        twoHoursBtn := reminderGui.AddButton("x+5 yp w70 h25 Background" . colors.green . " c" . colors.bg, "2 hours")
        
        oneDayBtn := reminderGui.AddButton("xm y+5 w70 h25 Background" . colors.mauve . " c" . colors.bg, "1 day")
        threeDaysBtn := reminderGui.AddButton("x+5 yp w70 h25 Background" . colors.mauve . " c" . colors.bg, "3 days")
        oneWeekBtn := reminderGui.AddButton("x+5 yp w70 h25 Background" . colors.yellow . " c" . colors.bg, "1 week")
        clearBtn := reminderGui.AddButton("x+5 yp w70 h25 Background" . colors.red . " c" . colors.bg, "Clear")
        
        ; Examples section
        reminderGui.AddText("xm y+15 c" . colors.subtext1, "💡 Examples:")
        reminderGui.AddText("xm y+5 c" . colors.subtext1, "• 5 min, 30 minutes")
        reminderGui.AddText("xm y+5 c" . colors.subtext1, "• 1 hour, 2 hours")
        reminderGui.AddText("xm y+5 c" . colors.subtext1, "• 1 day, 3 days")
        reminderGui.AddText("xm y+5 c" . colors.subtext1, "• 1 week, 2 weeks")
        
        ; Action buttons
        setBtn := reminderGui.AddButton("xm y+25 w110 h35 Background" . colors.green . " c" . colors.bg, "✅ Set Reminder")
        cancelBtn := reminderGui.AddButton("x+10 yp w100 h35 Background" . colors.red . " c" . colors.bg, "❌ Cancel")
        
        ; Quick time button events
        fiveMinBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "5 min"))
        thirtyMinBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "30 min"))
        oneHourBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "1 hour"))
        twoHoursBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "2 hours"))
        oneDayBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "1 day"))
        threeDaysBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "3 days"))
        oneWeekBtn.OnEvent("Click", this.SetQuickReminderTime.Bind(this, timeEdit, "1 week"))
        clearBtn.OnEvent("Click", this.ClearReminderTime.Bind(this, timeEdit))
        
        ; Action button events
        setBtn.OnEvent("Click", this.ProcessReminderDialog.Bind(this, reminderGui, timeEdit, taskIndex))
        cancelBtn.OnEvent("Click", this.CloseReminderDialog.Bind(this, reminderGui))
        
        reminderGui.Show("w420 h470")
    }
    
    ; Set quick reminder time
    SetQuickReminderTime(timeEdit, timeText, *) {
        timeEdit.Text := timeText
    }
    
    ; Clear reminder time
    ClearReminderTime(timeEdit, *) {
        timeEdit.Text := ""
    }
    
    ; Process reminder dialog
    ProcessReminderDialog(reminderGui, timeEdit, taskIndex, *) {
        timeValue := Trim(timeEdit.Text)
        
        if !timeValue {
            ; Clear the reminder if no time is specified
            this.tasks[taskIndex].reminder := ""
            this.SaveTasks()
            reminderGui.Destroy()
            MsgBox("✅ Reminder cleared for task!", "Reminder Cleared", "Icon!")
            return
        }
        
        reminderTime := this.ParseReminderTime(timeValue)
        if reminderTime > 0 {
            ; Calculate the reminder timestamp
            reminderTimestamp := DateAdd(A_Now, reminderTime, "seconds")
            this.tasks[taskIndex].reminder := reminderTimestamp
            
            ; Save the updated task
            this.SaveTasks()
            
            ; Schedule the reminder
            this.ScheduleTaskReminder(this.tasks[taskIndex])
            
            ; Format the reminder time for display
            reminderDisplay := this.FormatReminderTime(reminderTime)
            reminderGui.Destroy()
            MsgBox("✅ Reminder set for " . reminderDisplay . " from now!`n`nTask: " . this.tasks[taskIndex].text, "Reminder Set", "Icon!")
        } else {
            MsgBox("❌ Invalid time format. Please use formats like:`n• 5 min`n• 1 hour`n• 2 days", "Invalid Input", "Icon!")
        }
    }
    
    ; Close reminder dialog
    CloseReminderDialog(reminderGui, *) {
        reminderGui.Destroy()
    }

    ; ========================================
    ; UTILITY FUNCTIONS
    ; ========================================
    
    ParseDate(dateStr) {
        if !dateStr {
            return ""
        }
        
        ; Handle MM/DD and MM/DD/YYYY formats
        if RegExMatch(dateStr, "^(\d{1,2})/(\d{1,2})(?:/(\d{4}))?$", &match) {
            month := Format("{:02d}", Integer(match[1]))
            day := Format("{:02d}", Integer(match[2]))
            year := match[3] ? match[3] : A_Year
            
            return year . month . day . "000000"
        }
        
        return dateStr ; Return as-is if not recognized format
    }
    
    FormatDate(dateStr) {
        if !dateStr || StrLen(dateStr) < 8 {
            return dateStr
        }
        
        year := SubStr(dateStr, 1, 4)
        month := SubStr(dateStr, 5, 2)
        day := SubStr(dateStr, 7, 2)
        
        return month . "/" . day . "/" . year
    }
    
    IsOverdue(dueDate) {
        if !dueDate {
            return false
        }
        return dueDate < A_Now
    }
    
    IsNearDue(dueDate, currentTime) {
        if !dueDate {
            return false
        }
        
        ; Check if due within next 24 hours
        timeDiff := DateDiff(dueDate, currentTime, "hours")
        return timeDiff <= 24 && timeDiff > 0
    }
    
    ComparePriority(p1, p2) {
        priorityValues := Map("🔴 High", 1, "🟡 Medium", 2, "🟢 Low", 3)
        return priorityValues.Get(p1, 3) - priorityValues.Get(p2, 3)
    }
    
    CompareDates(d1, d2) {
        if !d1 && !d2 {
            return 0
        }
        if !d1 {
            return 1
        }
        if !d2 {
            return -1
        }
        return StrCompare(d1, d2)
    }
    
    GenerateTaskId() {
        return A_Now . Random(1000, 9999)
    }
    
    ; Calculate days left until due date
    GetDaysLeft(dueDate) {
        if !dueDate {
            return ""
        }
        
        ; Convert dates to comparable format
        today := A_Now
        todayDate := SubStr(today, 1, 8) . "000000"  ; Just the date part
        
        if dueDate < todayDate {
            days := DateDiff(todayDate, dueDate, "days")
            return "⚠️ " . days . " overdue"
        } else if dueDate = todayDate {
            return "📅 Today"
        } else {
            days := DateDiff(dueDate, todayDate, "days")
            if days = 1 {
                return "⏰ Tomorrow"
            } else if days <= 7 {
                return "🔔 " . days . " days"
            } else {
                return days . " days"
            }
        }
    }
    
    ; Show calendar picker dialog
    ShowCalendar(*) {
        colors := this.GetColors()
        
        calendarGui := Gui("+Owner" . this.gui.Hwnd . " +ToolWindow -Caption", "")
        calendarGui.SetFont("s10", "Segoe UI")
        calendarGui.BackColor := colors.bg
        calendarGui.OnEvent("Escape", this.CloseCalendarDialog.Bind(this, calendarGui))
        
        ; Calendar control
        calendar := calendarGui.AddMonthCal("xm ym")
        
        selectBtn := calendarGui.AddButton("xm y+4 w55 h24 Background" . colors.green . " c" . colors.bg, "Ok")
        cancelBtn := calendarGui.AddButton("x+4 yp w55 h24 Background" . colors.red . " c" . colors.bg, "X")
        
        selectBtn.OnEvent("Click", this.SelectCalendarDate.Bind(this, calendarGui, calendar))
        cancelBtn.OnEvent("Click", this.CloseCalendarDialog.Bind(this, calendarGui))
        
        calendarGui.Show("w230 h205")
    }
    
    ; Set quick date (today, tomorrow, next week)
    SetQuickDate(calendarGui, calendar, days, *) {
        targetDate := DateAdd(A_Now, days, "days")
        
        calendar.Value := targetDate
    }
    
    ; Select date from calendar
    SelectCalendarDate(calendarGui, calendar, *) {
        selectedDate := calendar.Value
        
        ; selectedDate is in YYYYMMDDHHMMSS format, extract date part
        year := SubStr(selectedDate, 1, 4)
        month := SubStr(selectedDate, 5, 2)
        day := SubStr(selectedDate, 7, 2)
        
        ; Format as YYYYMMDD000000
        formattedDate := year . month . day . "000000"
        
        ; Update the due date edit field
        this.dueDateEdit.Text := this.FormatDate(formattedDate)
        
        calendarGui.Destroy()
    }
    
    ; Clear due date
    ClearDueDate(*) {
        this.dueDateEdit.Text := ""
    }
    
    ; Calendar methods for edit dialog
    ShowEditCalendar(dueDateEdit, *) {
        colors := this.GetColors()
        
        calendarGui := Gui("+Owner" . this.gui.Hwnd . " +ToolWindow -Caption", "")
        calendarGui.SetFont("s10", "Segoe UI")
        calendarGui.BackColor := colors.bg
        calendarGui.OnEvent("Escape", this.CloseCalendarDialog.Bind(this, calendarGui))
        
        ; Calendar control
        calendar := calendarGui.AddMonthCal("xm ym")
        
        selectBtn := calendarGui.AddButton("xm y+4 w55 h24 Background" . colors.green . " c" . colors.bg, "Ok")
        cancelBtn := calendarGui.AddButton("x+4 yp w55 h24 Background" . colors.red . " c" . colors.bg, "X")
        
        selectBtn.OnEvent("Click", this.SelectEditCalendarDate.Bind(this, calendarGui, calendar, dueDateEdit))
        cancelBtn.OnEvent("Click", this.CloseCalendarDialog.Bind(this, calendarGui))
        
        calendarGui.Show("w240 h195")
    }
    
    ; Set quick date for edit dialog
    SetEditQuickDate(calendarGui, calendar, dueDateEdit, days, *) {
        targetDate := DateAdd(A_Now, days, "days")
        
        ; Set calendar to the target date (Value expects YYYYMMDDHHMMSS format)
        calendar.Value := targetDate
    }
    
    ; Select date from calendar for edit dialog
    SelectEditCalendarDate(calendarGui, calendar, dueDateEdit, *) {
        selectedDate := calendar.Value
        
        ; selectedDate is in YYYYMMDDHHMMSS format, extract date part
        year := SubStr(selectedDate, 1, 4)
        month := SubStr(selectedDate, 5, 2)
        day := SubStr(selectedDate, 7, 2)
        
        ; Format as YYYYMMDD000000
        formattedDate := year . month . day . "000000"
        
        ; Update the due date edit field
        dueDateEdit.Text := this.FormatDate(formattedDate)
        
        calendarGui.Destroy()
    }
    
    ; Clear edit date
    ClearEditDate(dueDateEdit, *) {
        dueDateEdit.Text := ""
    }
    
    ; Close calendar dialog
    CloseCalendarDialog(calendarGui, *) {
        calendarGui.Destroy()
    }
    
    UpdateStatusBar() {
        total := this.tasks.Length
        completed := 0
        pending := 0
        
        for task in this.tasks {
            if task.completed {
                completed++
            } else {
                pending++
            }
        }
        
        statusText := "Ready | Total: " . total . " | Pending: " . pending . " | Completed: " . completed
        
        ; Update status bar using the stored reference
        try {
            if HasProp(this, "statusBar") && this.statusBar {
                this.statusBar.Text := statusText
            }
        } catch {
            ; Ignore if status bar doesn't exist
        }
    }
    
    ; ========================================
    ; SETTINGS AND PERSISTENCE
    ; ========================================
    
    LoadSettings() {
        settingsFile := A_ScriptDir . "\Settings\todo_settings.ini"
        if FileExist(settingsFile) {
            try {
                this.settings.windowWidth := IniRead(settingsFile, "Window", "Width", 800)
                this.settings.windowHeight := IniRead(settingsFile, "Window", "Height", 900)
                this.settings.windowX := IniRead(settingsFile, "Window", "X", -1)
                this.settings.windowY := IniRead(settingsFile, "Window", "Y", -1)
                this.settings.alwaysOnTop := IniRead(settingsFile, "Window", "AlwaysOnTop", "false") = "true"
                this.settings.autoSave := IniRead(settingsFile, "General", "AutoSave", "true") = "true"
                this.settings.reminderInterval := IniRead(settingsFile, "Reminders", "Interval", 300000)
                this.settings.showNotifications := IniRead(settingsFile, "Reminders", "ShowNotifications", "true") = "true"
                this.settings.playSound := IniRead(settingsFile, "Reminders", "PlaySound", "true") = "true"
                this.settings.sortBy := IniRead(settingsFile, "Display", "SortBy", "priority")
                this.settings.filterBy := IniRead(settingsFile, "Display", "FilterBy", "all")
            } catch {
                ; Use defaults if settings can't be loaded
            }
        }
    }
    
    SaveSettings() {
        settingsFile := A_ScriptDir . "\Settings\todo_settings.ini"
        settingsDir := A_ScriptDir . "\Settings"
        
        if !DirExist(settingsDir) {
            DirCreate(settingsDir)
        }
        
        try {
            ; Get current window position only
            this.gui.GetPos(&x, &y, &w, &h)
            
            ; Save the configured width/height from settings, not actual window size
            IniWrite(this.settings.windowWidth, settingsFile, "Window", "Width")
            IniWrite(this.settings.windowHeight, settingsFile, "Window", "Height")
            IniWrite(x, settingsFile, "Window", "X")
            IniWrite(y, settingsFile, "Window", "Y")
            IniWrite(this.settings.alwaysOnTop ? "true" : "false", settingsFile, "Window", "AlwaysOnTop")
            IniWrite(this.settings.autoSave ? "true" : "false", settingsFile, "General", "AutoSave")
            IniWrite(this.settings.reminderInterval, settingsFile, "Reminders", "Interval")
            IniWrite(this.settings.showNotifications ? "true" : "false", settingsFile, "Reminders", "ShowNotifications")
            IniWrite(this.settings.playSound ? "true" : "false", settingsFile, "Reminders", "PlaySound")
            IniWrite(this.settings.sortBy, settingsFile, "Display", "SortBy")
            IniWrite(this.settings.filterBy, settingsFile, "Display", "FilterBy")
        } catch {
            ; Ignore save errors
        }
    }
    
    LoadTasks() {
        tasksFile := A_ScriptDir . "\Settings\todo_tasks.ini"
        if FileExist(tasksFile) {
            try {
                taskCount := IniRead(tasksFile, "General", "Count", "0")
                this.tasks := []
                
                Loop Integer(taskCount) {
                    task := {
                        id: IniRead(tasksFile, "Task" . A_Index, "ID", ""),
                        text: IniRead(tasksFile, "Task" . A_Index, "Text", ""),
                        priority: IniRead(tasksFile, "Task" . A_Index, "Priority", "🟡 Medium"),
                        dueDate: IniRead(tasksFile, "Task" . A_Index, "DueDate", ""),
                        completed: IniRead(tasksFile, "Task" . A_Index, "Completed", "false") = "true",
                        created: IniRead(tasksFile, "Task" . A_Index, "Created", A_Now),
                        reminder: IniRead(tasksFile, "Task" . A_Index, "Reminder", ""),
                        recurring: IniRead(tasksFile, "Task" . A_Index, "Recurring", "none")
                    }
                    if task.text {  ; Only add tasks with valid text
                        this.tasks.Push(task)
                    }
                }
            } catch {
                this.tasks := []
            }
        }
    }
    
    SaveTasks() {
        if !this.settings.autoSave {
            return
        }
        
        tasksFile := A_ScriptDir . "\Settings\todo_tasks.ini"
        settingsDir := A_ScriptDir . "\Settings"
        
        if !DirExist(settingsDir) {
            DirCreate(settingsDir)
        }
        
        try {
            ; Clear existing task data
            if FileExist(tasksFile) {
                FileDelete(tasksFile)
            }
            
            ; Write task count
            IniWrite(this.tasks.Length, tasksFile, "General", "Count")
            
            ; Write each task
            for i, task in this.tasks {
                IniWrite(task.id, tasksFile, "Task" . i, "ID")
                IniWrite(task.text, tasksFile, "Task" . i, "Text")
                IniWrite(task.priority, tasksFile, "Task" . i, "Priority")
                IniWrite(task.dueDate, tasksFile, "Task" . i, "DueDate")
                IniWrite(task.completed ? "true" : "false", tasksFile, "Task" . i, "Completed")
                IniWrite(task.created, tasksFile, "Task" . i, "Created")
                IniWrite(task.reminder, tasksFile, "Task" . i, "Reminder")
                IniWrite(task.HasOwnProp("recurring") ? task.recurring : "none", tasksFile, "Task" . i, "Recurring")
            }
        } catch {
            ; Ignore save errors
        }
    }
    
    ; ========================================
    ; GUI EVENTS AND INTERFACE
    ; ========================================
    
    Toggle() {
        if this.isVisible {
            this.Hide()
        } else {
            this.Show()
        }
    }
    
    Show() {
        if this.gui {
            ; Set window size and center it on first show
            if this.settings.windowX >= 0 && this.settings.windowY >= 0 {
                ; Use saved position if valid
                this.gui.Show("x" . this.settings.windowX . " y" . this.settings.windowY . " w" . this.settings.windowWidth . " h" . this.settings.windowHeight)
            } else {
                ; Center on screen for first show
                this.gui.Show("w" . this.settings.windowWidth . " h" . this.settings.windowHeight . " Center")
            }
            this.isVisible := true
            this.SetupGUIHotkeys()  ; Enable Escape key
            this.RefreshTasksList()
        }
    }
    
    Hide(*) {
        if this.gui {
            this.SaveSettings()
            this.RemoveGUIHotkeys()  ; Disable Escape key
            this.gui.Hide()
            this.isVisible := false
        }
    }
    
    ; Set up GUI-specific hotkeys when shown
    SetupGUIHotkeys() {
        try {
            Hotkey("Escape", (*) => this.Hide(), "On")
        } catch as err {
            ; Ignore hotkey errors
        }
    }
    
    ; Remove GUI hotkeys when hidden
    RemoveGUIHotkeys() {
        try {
            Hotkey("Escape", "Off")
        } catch as err {
            ; Ignore hotkey errors
        }
    }
    
    OnTaskTextChange(editObj, *) {
        ; Could implement real-time suggestions or validation
        ; Parameters: editObj - the edit control that changed
    }
    
    ShowContextMenu(*) {
        ; Right-click context menu for tasks
        colors := this.GetColors()
        contextMenu := Menu()
        contextMenu.Add("✏️ Edit Task", this.EditSelectedTask.Bind(this))
        contextMenu.Add("🗑️ Delete Task", this.DeleteSelectedTask.Bind(this))
        contextMenu.Add()
        contextMenu.Add("🔔 Set Reminder", this.SetReminder.Bind(this))
        contextMenu.Add("📋 Copy Task", this.CopySelectedTask.Bind(this))
        contextMenu.Show()
    }
    
    CopySelectedTask(*) {
        selected := this.tasksList.GetNext()
        if selected && selected <= this.tasks.Length {
            task := this.tasks[selected]
            A_Clipboard := task.text
            TrayTip("📋 Copied", "Task copied to clipboard", "Icon!")
        }
    }
    
    ShowStats(*) {
        colors := this.GetColors()
        total := this.tasks.Length
        completed := 0
        pending := 0
        overdue := 0
        highPriority := 0
        mediumPriority := 0
        lowPriority := 0
        
        for task in this.tasks {
            if task.completed {
                completed++
            } else {
                pending++
                if task.dueDate && this.IsOverdue(task.dueDate) {
                    overdue++
                }
            }
            
            switch task.priority {
                case "🔴 High":
                    highPriority++
                case "🟡 Medium":
                    mediumPriority++
                case "🟢 Low":
                    lowPriority++
            }
        }
        
        completionRate := total > 0 ? Round((completed / total) * 100, 1) : 0
        
        ; Create a professional stats GUI
        statsGui := Gui("+Owner" . this.gui.Hwnd . " -MaximizeBox -MinimizeBox", "📊 Task Statistics")
        statsGui.SetFont("s10", "Segoe UI")
        statsGui.BackColor := colors.bg
        statsGui.OnEvent("Escape", (*) => statsGui.Destroy())
        
        ; Header
        statsGui.AddText("xm ym w400 Center c" . colors.text . " Section", "📊 Task Statistics")
        statsGui.SetFont("s12 Bold")
        statsGui.AddText("xm y+5 w400 Center c" . colors.mauve, "Overview")
        statsGui.SetFont("s10 Norm")
        
        ; Main stats in a nice layout
        statsGui.AddText("xm y+15 c" . colors.text, "📋 Total Tasks:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.green, total)
        
        statsGui.SetFont("s10 Norm")
        statsGui.AddText("xm y+8 c" . colors.text, "✅ Completed:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.green, completed)
        
        statsGui.SetFont("s10 Norm")
        statsGui.AddText("xm y+8 c" . colors.text, "⏳ Pending:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.yellow, pending)
        
        statsGui.SetFont("s10 Norm")
        statsGui.AddText("xm y+8 c" . colors.text, "🔥 Overdue:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.red, overdue)
        
        ; Separator
        statsGui.AddText("xm y+15 w400 h1 Background" . colors.overlay0)
        
        ; Priority breakdown
        statsGui.SetFont("s12 Bold")
        statsGui.AddText("xm y+10 w400 Center c" . colors.mauve, "Priority Breakdown")
        statsGui.SetFont("s10 Norm")
        
        statsGui.AddText("xm y+15 c" . colors.text, "🔴 High Priority:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.red, highPriority)
        
        statsGui.SetFont("s10 Norm")
        statsGui.AddText("xm y+8 c" . colors.text, "🟡 Medium Priority:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.yellow, mediumPriority)
        
        statsGui.SetFont("s10 Norm")
        statsGui.AddText("xm y+8 c" . colors.text, "🟢 Low Priority:")
        statsGui.SetFont("s10 Bold")
        statsGui.AddText("x+10 yp w100 Right c" . colors.green, lowPriority)
        
        ; Separator
        statsGui.AddText("xm y+15 w400 h1 Background" . colors.overlay0)
        
        ; Completion rate with visual indicator
        statsGui.SetFont("s12 Bold")
        statsGui.AddText("xm y+10 w400 Center c" . colors.mauve, "Completion Rate")
        statsGui.SetFont("s16 Bold")
        completionColor := completionRate >= 80 ? colors.green : (completionRate >= 50 ? colors.yellow : colors.red)
        statsGui.AddText("xm y+10 w400 Center c" . completionColor, completionRate . "%")
        statsGui.SetFont("s10 Norm")
        
        ; Progress bar visualization
        barWidth := Round((completionRate / 100) * 380)
        if barWidth > 0 {
            statsGui.AddText("xm y+15 w" . barWidth . " h8 Background" . colors.green)
        }
        if barWidth < 380 {
            statsGui.AddText("x+0 yp w" . (380 - barWidth) . " h8 Background" . colors.surface1)
        }
        
        ; Close button
        closeBtn := statsGui.AddButton("xm y+25 w100 h30 Background" . colors.blue . " c" . colors.bg, "✅ Close")
        closeBtn.OnEvent("Click", (*) => statsGui.Destroy())
        
        statsGui.Show("w420 h420")
    }
    
    ShowSettings(*) {
        colors := this.GetColors()
        
        settingsGui := Gui("+Owner" . this.gui.Hwnd . " -MaximizeBox -MinimizeBox +LastFound -SysMenu +ToolWindow", "⚙️ To-Do Settings")
        settingsGui.SetFont("s10", "Segoe UI")
        settingsGui.BackColor := colors.bg
        settingsGui.OnEvent("Escape", (*) => settingsGui.Destroy())
        
        ; Reminder settings
        settingsGui.AddText("xm ym c" . colors.text, "🔔 Reminder Settings:")
        notificationCheck := settingsGui.AddCheckbox("xm y+10 c" . colors.text . " Checked" . (this.settings.showNotifications ? "1" : "0"), "Show reminder notifications")
        soundCheck := settingsGui.AddCheckbox("xm y+5 c" . colors.text . " Checked" . (this.settings.playSound ? "1" : "0"), "Play sound with reminders")
        
        settingsGui.AddText("xm y+20 c" . colors.text, "Reminder check interval (minutes):")
        intervalEdit := settingsGui.AddEdit("xm y+5 w100 Background" . colors.surface0 . " c" . colors.text, this.settings.reminderInterval // 60000)
        
        ; General settings
        settingsGui.AddText("xm y+20 c" . colors.text, "💾 General Settings:")
        autoSaveCheck := settingsGui.AddCheckbox("xm y+10 c" . colors.text . " Checked" . (this.settings.autoSave ? "1" : "0"), "Auto-save tasks")
        alwaysOnTopCheck := settingsGui.AddCheckbox("xm y+5 c" . colors.text . " Checked" . (this.settings.alwaysOnTop ? "1" : "0"), "Always on top")
        
        ; Buttons
        saveBtn := settingsGui.AddButton("xm y+30 w80 h30 Background" . colors.green . " c" . colors.bg, "💾 Save")
        cancelBtn := settingsGui.AddButton("x+10 yp w80 h30 Background" . colors.red . " c" . colors.bg, "❌ Cancel")
        
        saveBtn.OnEvent("Click", this.SaveSettingsWrapper.Bind(this, settingsGui, notificationCheck, soundCheck, intervalEdit, autoSaveCheck, alwaysOnTopCheck))
        cancelBtn.OnEvent("Click", this.CloseSettingsDialog.Bind(this, settingsGui))
        
        settingsGui.Show()
    }
    
    SaveSettingsFromGUI(gui, notificationCheck, soundCheck, intervalEdit, autoSaveCheck, alwaysOnTopCheck) {
        this.settings.showNotifications := notificationCheck.Value
        this.settings.playSound := soundCheck.Value
        this.settings.reminderInterval := Integer(intervalEdit.Text) * 60000 ; Convert to milliseconds
        this.settings.autoSave := autoSaveCheck.Value
        this.settings.alwaysOnTop := alwaysOnTopCheck.Value
        
        this.SaveSettings()
        
        ; Restart reminder timer with new interval
        if this.reminderTimer {
            SetTimer(this.reminderTimer, 0) ; Disable
        }
        this.SetupReminderTimer()
        
        ; Apply always on top setting immediately
        if this.settings.alwaysOnTop {
            WinSetAlwaysOnTop(1, this.gui.Hwnd)
        } else {
            WinSetAlwaysOnTop(0, this.gui.Hwnd)
        }
        
        MsgBox("✅ Settings saved successfully!", "Settings", "Icon!")
        gui.Destroy()
    }
    
    ; Wrapper methods for settings dialog events
    SaveSettingsWrapper(settingsGui, notificationCheck, soundCheck, intervalEdit, autoSaveCheck, alwaysOnTopCheck, *) {
        this.SaveSettingsFromGUI(settingsGui, notificationCheck, soundCheck, intervalEdit, autoSaveCheck, alwaysOnTopCheck)
    }
    
    CloseSettingsDialog(settingsGui, *) {
        settingsGui.Destroy()
    }
    
    ShowDebug(message) {
        if this.parentManager && this.parentManager.ShowDebug {
            this.parentManager.ShowDebug("TodoReminder: " . message)
        }
    }
    
    ; Parse reminder time from user input like "5 min", "1 hour", "2 days"
    ParseReminderTime(timeStr) {
        timeStr := StrLower(Trim(timeStr))
        
        ; Remove extra spaces and normalize
        timeStr := RegExReplace(timeStr, "\s+", " ")
        
        ; Parse different time formats
        if RegExMatch(timeStr, "^(\d+)\s*(min|minute|minutes)$", &match) {
            return Integer(match[1]) * 60  ; Convert to seconds
        } else if RegExMatch(timeStr, "^(\d+)\s*(h|hr|hour|hours)$", &match) {
            return Integer(match[1]) * 3600  ; Convert to seconds
        } else if RegExMatch(timeStr, "^(\d+)\s*(d|day|days)$", &match) {
            return Integer(match[1]) * 86400  ; Convert to seconds
        } else if RegExMatch(timeStr, "^(\d+)\s*(w|week|weeks)$", &match) {
            return Integer(match[1]) * 604800  ; Convert to seconds (7 days)
        } else if RegExMatch(timeStr, "^(\d+)\s*(s|sec|second|seconds)$", &match) {
            return Integer(match[1])  ; Already in seconds
        } else if RegExMatch(timeStr, "^(\d+)$", &match) {
            ; If just a number, assume minutes
            return Integer(match[1]) * 60
        }
        
        return 0  ; Invalid format
    }
    
    ; Format reminder time for display
    FormatReminderTime(seconds) {
        if seconds < 60 {
            return seconds . " second" . (seconds = 1 ? "" : "s")
        } else if seconds < 3600 {
            minutes := Round(seconds / 60)
            return minutes . " minute" . (minutes = 1 ? "" : "s")
        } else if seconds < 86400 {
            hours := Round(seconds / 3600)
            return hours . " hour" . (hours = 1 ? "" : "s")
        } else if seconds < 604800 {
            days := Round(seconds / 86400)
            return days . " day" . (days = 1 ? "" : "s")
        } else {
            weeks := Round(seconds / 604800)
            return weeks . " week" . (weeks = 1 ? "" : "s")
        }
    }
    
    ; Schedule a reminder for a specific task
    ScheduleTaskReminder(task) {
        if !task.reminder {
            return
        }
        
        ; Calculate time until reminder
        now := A_Now
        reminderTime := task.reminder
        timeDiff := DateDiff(reminderTime, now, "seconds")
        
        if timeDiff <= 0 {
            ; Reminder time has already passed, show immediately
            this.ShowTaskReminder(task)
            return
        }
        
        ; Convert to milliseconds for SetTimer
        timerInterval := timeDiff * 1000
        
        ; Create a unique timer for this task
        timerFunc := () => this.ShowTaskReminder(task)
        SetTimer(timerFunc, -timerInterval)  ; Negative value means run once
        
        this.ShowDebug("Scheduled reminder for task '" . task.text . "' in " . this.FormatReminderTime(timeDiff))
    }
    
    ; Show the actual reminder notification
    ShowTaskReminder(task) {
        if !task {
            return
        }
        
        ; Ensure we have the task text
        taskText := task.text ? task.text : "Unknown Task"
        
        message := "🔔 REMINDER: " . taskText
        if task.dueDate {
            message .= "`n📅 Due: " . this.FormatDate(task.dueDate)
        }
        
        ; Show tray tip notification with clear title
        TrayTip("⏰ Task Reminder", message, "Icon!")
        
        ; Play sound if enabled
        if this.settings.playSound {
            SoundPlay("*64")  ; Exclamation sound
        }
        
        ; Show a more prominent dialog with task name in title
        result := MsgBox(message . "`n`nMark as completed?", "🔔 Reminder: " . taskText, "YesNo Icon!")
        
        if result = "Yes" {
            ; Mark task as completed
            for i, t in this.tasks {
                if t.id = task.id {
                    this.tasks[i].completed := true
                    this.tasks[i].reminder := ""  ; Clear reminder
                    this.SaveTasks()
                    this.RefreshTasksList()
                    this.UpdateStatusBar()
                    break
                }
            }
        } else {
            ; Clear the reminder since it was shown
            for i, t in this.tasks {
                if t.id = task.id {
                    this.tasks[i].reminder := ""
                    this.SaveTasks()
                    break
                }
            }
        }
    }
    
    ; Schedule all existing reminders on startup
    ScheduleAllReminders() {
        for task in this.tasks {
            if task.reminder {
                this.ScheduleTaskReminder(task)
            }
        }
    }
}
