#SingleInstance force
#Requires AutoHotkey v2.0

; Modified by ThioJoe
; https://github.com/ThioJoe/AHK-RemoteTreeView-V2

class RemoteTreeView
{
    ; Authors:
    ; rbrtryn (Initial script) (http://www.autohotkey.com/board/topic/84310-class-remote-treeview/)
    ; JnLlnd (https://www.autohotkey.com/boards/viewtopic.php?f=5&t=4998#p29502)
    ; just me
    ; Ahk_user (Conversion to V2)

    ; Constants for TreeView controls
        WC_TREEVIEW := "SysTreeView32"
        ; Messages =============================================================================================================
        TVM_CREATEDRAGIMAGE := 0x1112    ; (TV_FIRST + 18)
        TVM_DELETEITEM := 0x1101    ; (TV_FIRST + 1)
        TVM_EDITLABELA := 0x110E    ; (TV_FIRST + 14)
        TVM_EDITLABELW := 0x1141    ; (TV_FIRST + 65)
        TVM_ENDEDITLABELNOW := 0x1116    ; (TV_FIRST + 22)
        TVM_ENSUREVISIBLE := 0x1114    ; (TV_FIRST + 20)
        TVM_EXPAND := 0x1102    ; (TV_FIRST + 2)
        TVM_GETBKCOLOR := 0x112F    ; (TV_FIRST + 31)
        TVM_GETCOUNT := 0x1105    ; (TV_FIRST + 5)
        TVM_GETEDITCONTROL := 0x110F    ; (TV_FIRST + 15)
        TVM_GETEXTENDEDSTYLE := 0x112D    ; (TV_FIRST + 45)
        TVM_GETIMAGELIST := 0x1108    ; (TV_FIRST + 8)
        TVM_GETINDENT := 0x1106    ; (TV_FIRST + 6)
        TVM_GETINSERTMARKCOLOR := 0x1126    ; (TV_FIRST + 38)
        TVM_GETISEARCHSTRINGA := 0x1117    ; (TV_FIRST + 23)
        TVM_GETISEARCHSTRINGW := 0x1140    ; (TV_FIRST + 64)
        TVM_GETITEMA := 0x110C    ; (TV_FIRST + 12)
        TVM_GETITEMHEIGHT := 0x111C    ; (TV_FIRST + 28)
        TVM_GETITEMPARTRECT := 0x1148    ; (TV_FIRST + 72) ; >= Vista
        TVM_GETITEMRECT := 0x1104    ; (TV_FIRST + 4)
        TVM_GETITEMSTATE := 0x1127    ; (TV_FIRST + 39)
        TVM_GETITEMW := 0x113E    ; (TV_FIRST + 62)
        TVM_GETLINECOLOR := 0x1129    ; (TV_FIRST + 41)
        TVM_GETNEXTITEM := 0x110A    ; (TV_FIRST + 10)
        TVM_GETSCROLLTIME := 0x1122    ; (TV_FIRST + 34)
        TVM_GETSELECTEDCOUNT := 0x1146    ; (TV_FIRST + 70) ; >= Vista
        TVM_GETTEXTCOLOR := 0x1120    ; (TV_FIRST + 32)
        TVM_GETTOOLTIPS := 0x1119    ; (TV_FIRST + 25)
        TVM_GETUNICODEFORMAT := 0x2006    ; (CCM_FIRST + 6) CCM_GETUNICODEFORMAT
        TVM_GETVISIBLECOUNT := 0x1110    ; (TV_FIRST + 16)
        TVM_HITTEST := 0x1111    ; (TV_FIRST + 17)
        TVM_INSERTITEMA := 0x1100    ; (TV_FIRST + 0)
        TVM_INSERTITEMW := 0x1142    ; (TV_FIRST + 50)
        TVM_MAPACCIDTOHTREEITEM := 0x112A    ; (TV_FIRST + 42)
        TVM_MAPHTREEITEMTOACCID := 0x112B    ; (TV_FIRST + 43)
        TVM_SELECTITEM := 0x110B    ; (TV_FIRST + 11)
        TVM_SETAUTOSCROLLINFO := 0x113B    ; (TV_FIRST + 59)
        TVM_SETBKCOLOR := 0x111D    ; (TV_FIRST + 29)
        TVM_SETEXTENDEDSTYLE := 0x112C    ; (TV_FIRST + 44)
        TVM_SETIMAGELIST := 0x1109    ; (TV_FIRST + 9)
        TVM_SETINDENT := 0x1107    ; (TV_FIRST + 7)
        TVM_SETINSERTMARK := 0x111A    ; (TV_FIRST + 26)
        TVM_SETINSERTMARKCOLOR := 0x1125    ; (TV_FIRST + 37)
        TVM_SETITEMA := 0x110D    ; (TV_FIRST + 13)
        TVM_SETITEMHEIGHT := 0x111B    ; (TV_FIRST + 27)
        TVM_SETITEMW := 0x113F    ; (TV_FIRST + 63)
        TVM_SETLINECOLOR := 0x1128    ; (TV_FIRST + 40)
        TVM_SETSCROLLTIME := 0x1121    ; (TV_FIRST + 33)
        TVM_SETTEXTCOLOR := 0x111E    ; (TV_FIRST + 30)
        TVM_SETTOOLTIPS := 0x1118    ; (TV_FIRST + 24)
        TVM_SETUNICODEFORMAT := 0x2005    ; (CCM_FIRST + 5) ; CCM_SETUNICODEFORMAT
        TVM_SHOWINFOTIP := 0x1147    ; (TV_FIRST + 71) ; >= Vista
        TVM_SORTCHILDREN := 0x1113    ; (TV_FIRST + 19)
        TVM_SORTCHILDRENCB := 0x1115    ; (TV_FIRST + 21)
        ; Notifications ========================================================================================================
        TVN_ASYNCDRAW := -420    ; (TVN_FIRST - 20) >= Vista
        TVN_BEGINDRAGA := -427    ; (TVN_FIRST - 7)
        TVN_BEGINDRAGW := -456    ; (TVN_FIRST - 56)
        TVN_BEGINLABELEDITA := -410    ; (TVN_FIRST - 10)
        TVN_BEGINLABELEDITW := -456    ; (TVN_FIRST - 59)
        TVN_BEGINRDRAGA := -408    ; (TVN_FIRST - 8)
        TVN_BEGINRDRAGW := -457    ; (TVN_FIRST - 57)
        TVN_DELETEITEMA := -409    ; (TVN_FIRST - 9)
        TVN_DELETEITEMW := -458    ; (TVN_FIRST - 58)
        TVN_ENDLABELEDITA := -411    ; (TVN_FIRST - 11)
        TVN_ENDLABELEDITW := -460    ; (TVN_FIRST - 60)
        TVN_GETDISPINFOA := -403    ; (TVN_FIRST - 3)
        TVN_GETDISPINFOW := -452    ; (TVN_FIRST - 52)
        TVN_GETINFOTIPA := -412    ; (TVN_FIRST - 13)
        TVN_GETINFOTIPW := -414    ; (TVN_FIRST - 14)
        TVN_ITEMCHANGEDA := -418    ; (TVN_FIRST - 18) ; >= Vista
        TVN_ITEMCHANGEDW := -419    ; (TVN_FIRST - 19) ; >= Vista
        TVN_ITEMCHANGINGA := -416    ; (TVN_FIRST - 16) ; >= Vista
        TVN_ITEMCHANGINGW := -417    ; (TVN_FIRST - 17) ; >= Vista
        TVN_ITEMEXPANDEDA := -406    ; (TVN_FIRST - 6)
        TVN_ITEMEXPANDEDW := -455    ; (TVN_FIRST - 55)
        TVN_ITEMEXPANDINGA := -405    ; (TVN_FIRST - 5)
        TVN_ITEMEXPANDINGW := -454    ; (TVN_FIRST - 54)
        TVN_KEYDOWN := -412    ; (TVN_FIRST - 12)
        TVN_SELCHANGEDA := -402    ; (TVN_FIRST - 2)
        TVN_SELCHANGEDW := -451    ; (TVN_FIRST - 51)
        TVN_SELCHANGINGA := -401    ; (TVN_FIRST - 1)
        TVN_SELCHANGINGW := -450    ; (TVN_FIRST - 50)
        TVN_SETDISPINFOA := -404    ; (TVN_FIRST - 4)
        TVN_SETDISPINFOW := -453    ; (TVN_FIRST - 53)
        TVN_SINGLEEXPAND := -415    ; (TVN_FIRST - 15)
        ; Styles ===============================================================================================================
        TVS_CHECKBOXES := 0x0100
        TVS_DISABLEDRAGDROP := 0x0010
        TVS_EDITLABELS := 0x0008
        TVS_FULLROWSELECT := 0x1000
        TVS_HASBUTTONS := 0x0001
        TVS_HASLINES := 0x0002
        TVS_INFOTIP := 0x0800
        TVS_LINESATROOT := 0x0004
        TVS_NOHSCROLL := 0x8000    ; TVS_NOSCROLL overrides this
        TVS_NONEVENHEIGHT := 0x4000
        TVS_NOSCROLL := 0x2000
        TVS_NOTOOLTIPS := 0x0080
        TVS_RTLREADING := 0x0040
        TVS_SHOWSELALWAYS := 0x0020
        TVS_SINGLEEXPAND := 0x0400
        TVS_TRACKSELECT := 0x0200
        ; Exstyles =============================================================================================================
        TVS_EX_AUTOHSCROLL := 0x0020    ; >= Vista
        TVS_EX_DIMMEDCHECKBOXES := 0x0200    ; >= Vista
        TVS_EX_DOUBLEBUFFER := 0x0004    ; >= Vista
        TVS_EX_DRAWIMAGEASYNC := 0x0400    ; >= Vista
        TVS_EX_EXCLUSIONCHECKBOXES := 0x0100    ; >= Vista
        TVS_EX_FADEINOUTEXPANDOS := 0x0040    ; >= Vista
        TVS_EX_MULTISELECT := 0x0002    ; >= Vista - Not supported. Do not use.
        TVS_EX_NOINDENTSTATE := 0x0008    ; >= Vista
        TVS_EX_NOSINGLECOLLAPSE := 0x0001    ; >= Vista - Intended for internal use; not recommended for use in applications.
        TVS_EX_PARTIALCHECKBOXES := 0x0080    ; >= Vista
        TVS_EX_RICHTOOLTIP := 0x0010    ; >= Vista
        ; Others ===============================================================================================================
        ; Item flags
        TVIF_CHILDREN := 0x0040
        TVIF_DI_SETITEM := 0x1000
        TVIF_EXPANDEDIMAGE := 0x0200    ; >= Vista
        TVIF_HANDLE := 0x0010
        TVIF_IMAGE := 0x0002
        TVIF_INTEGRAL := 0x0080
        TVIF_PARAM := 0x0004
        TVIF_SELECTEDIMAGE := 0x0020
        TVIF_STATE := 0x0008
        TVIF_STATEEX := 0x0100    ; >= Vista
        TVIF_TEXT := 0x0001
        ; Item states
        TVIS_BOLD := 0x0010
        TVIS_CUT := 0x0004
        TVIS_DROPHILITED := 0x0008
        TVIS_EXPANDED := 0x0020
        TVIS_EXPANDEDONCE := 0x0040
        TVIS_EXPANDPARTIAL := 0x0080
        TVIS_OVERLAYMASK := 0x0F00
        TVIS_SELECTED := 0x0002
        TVIS_STATEIMAGEMASK := 0xF000
        TVIS_USERMASK := 0xF000
        ; TVITEMEX uStateEx
        TVIS_EX_ALL := 0x0002    ; not documented
        TVIS_EX_DISABLED := 0x0002    ; >= Vista
        TVIS_EX_FLAT := 0x0001
        ; TVINSERTSTRUCT hInsertAfter
        TVI_FIRST := -65535    ; (-0x0FFFF)
        TVI_LAST := -65534    ; (-0x0FFFE)
        TVI_ROOT := -65536    ; (-0x10000)
        TVI_SORT := -65533    ; (-0x0FFFD)
        ; TVM_EXPAND wParam
        TVE_COLLAPSE := 0x0001
        TVE_COLLAPSERESET := 0x8000
        TVE_EXPAND := 0x0002
        TVE_EXPANDPARTIAL := 0x4000
        TVE_TOGGLE := 0x0003
        ; TVM_GETIMAGELIST wParam
        TVSIL_NORMAL := 0
        TVSIL_STATE := 2
        ; TVM_GETNEXTITEM wParam
        TVGN_CARET := 0x0009
        TVGN_CHILD := 0x0004
        TVGN_DROPHILITE := 0x0008
        TVGN_FIRSTVISIBLE := 0x0005
        TVGN_LASTVISIBLE := 0x000A
        TVGN_NEXT := 0x0001
        TVGN_NEXTSELECTED := 0x000B    ; >= Vista (MSDN)
        TVGN_NEXTVISIBLE := 0x0006
        TVGN_PARENT := 0x0003
        TVGN_PREVIOUS := 0x0002
        TVGN_PREVIOUSVISIBLE := 0x0007
        TVGN_ROOT := 0x0000
        ; TVM_SELECTITEM wParam
        TVSI_NOSINGLEEXPAND := 0x8000    ; Should not conflict with TVGN flags.
        ; TVHITTESTINFO flags
        TVHT_ABOVE := 0x0100
        TVHT_BELOW := 0x0200
        TVHT_NOWHERE := 0x0001
        TVHT_ONITEMBUTTON := 0x0010
        TVHT_ONITEMICON := 0x0002
        TVHT_ONITEMINDENT := 0x0008
        TVHT_ONITEMLABEL := 0x0004
        TVHT_ONITEMRIGHT := 0x0020
        TVHT_ONITEMSTATEICON := 0x0040
        TVHT_TOLEFT := 0x0800
        TVHT_TORIGHT := 0x0400
        TVHT_ONITEM := 0x0046    ; (TVHT_ONITEMICON | TVHT_ONITEMLABEL | TVHT_ONITEMSTATEICON)
        ; TVGETITEMPARTRECTINFO partID (>= Vista)
        TVGIPR_BUTTON := 0x0001
        ; NMTREEVIEW action
        TVC_BYKEYBOARD := 0x0002
        TVC_BYMOUSE := 0x0001
        TVC_UNKNOWN := 0x0000
        ; TVN_SINGLEEXPAND return codes
        TVNRET_DEFAULT := 0
        TVNRET_SKIPOLD := 1
        TVNRET_SKIPNEW := 2
        ; ======================================================================================================================

        PAGE_NOACCESS := 0x01
        PAGE_READONLY := 0x02
        PAGE_READWRITE := 0x04
        PAGE_WRITECOPY := 0x08
        PAGE_EXECUTE := 0x10
        PAGE_EXECUTE_READ := 0x20
        PAGE_EXECUTE_READWRITE := 0x40
        PAGE_EXECUTE_WRITECOPY := 0x80
        PAGE_GUARD := 0x100
        PAGE_NOCACHE := 0x200
        PAGE_WRITECOMBINE := 0x400
        MEM_COMMIT := 0x1000
        MEM_RESERVE := 0x2000
        MEM_DECOMMIT := 0x4000
        MEM_RELEASE := 0x8000
        MEM_FREE := 0x10000
        MEM_PRIVATE := 0x20000
        MEM_MAPPED := 0x40000
        MEM_RESET := 0x80000
        MEM_TOP_DOWN := 0x100000
        MEM_WRITE_WATCH := 0x200000
        MEM_PHYSICAL := 0x400000
        MEM_ROTATE := 0x800000
        MEM_LARGE_PAGES := 0x20000000
        MEM_4MB_PAGES := 0x80000000

        PROCESS_TERMINATE := (0x0001)
        PROCESS_CREATE_THREAD := (0x0002)
        PROCESS_SET_SESSIONID := (0x0004)
        PROCESS_VM_OPERATION := (0x0008)
        PROCESS_VM_READ := (0x0010)
        PROCESS_VM_WRITE := (0x0020)
        PROCESS_DUP_HANDLE := (0x0040)
        PROCESS_CREATE_PROCESS := (0x0080)
        PROCESS_SET_QUOTA := (0x0100)
        PROCESS_SET_INFORMATION := (0x0200)
        PROCESS_QUERY_INFORMATION := (0x0400)
        PROCESS_SUSPEND_RESUME := (0x0800)
        PROCESS_QUERY_LIMITED_INFORMATION := (0x1000)

    ;----------------------------------------------------------------------------------------------
    ; Method: __New
    ;         Stores the TreeView's Control HWnd in the object for later use
    ;
    ; Parameters:
    ;         TVHwnd            - HWND of the TreeView control
    ;
    ; Returns:
    ;         Nothing
    ;
    __New(TVHwnd){
        this.TVHwnd := TVHwnd
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: SetSelection
    ;         Makes the given item selected and expanded. Optionally scrolls the
    ;         TreeView so the item is visible.
    ;
    ; Parameters:
    ;         pItem                - Handle to the item you wish selected
    ;         defaultAction     - Determines of the default action is activated
    ;                         true : Send an Enter (default)
    ;                         false : do noting
    ;
    ; Returns:
    ;         TRUE if successful, or FALSE otherwise
    ;
    SetSelection(pItem, defaultAction := true) {
        ; ORI SendMessage TVM_SELECTITEM, TVGN_CARET|TVSI_NOSINGLEEXPAND, pItem, , % "ahk_id " this.TVHwnd
        result := SendMessage(this.TVM_SELECTITEM, this.TVGN_CARET, pItem, , "ahk_id " this.TVHwnd)
        if (defaultAction){
            Controlsend("{Enter}", this.TVHwnd)
        }
        return result
        ; return SendMessage(this.TVM_SELECTITEM, this.TVGN_FIRSTVISIBLE, pItem, , "ahk_id " this.TVHwnd) ; Seemed not to work
    }
    ;----------------------------------------------------------------------------------------------
    ; Method: SetSelectionByText
    ;         Makes the given item selected and expanded. Optionally scrolls the
    ;         TreeView so the item is visible.
    ;
    ; Parameters:
    ;         text                - Text of the item you wish selected
    ;         defaultAction     - Determines of the default action is activated
    ;                               true : Send an Enter (default)
    ;                               false : do noting
    ;         index                - Index of item if you do not want to use the first item
    ;
    ; Returns:
    ;         TRUE if successful, or FALSE otherwise
    ;
    SetSelectionByText(text, defaultAction := true, index := 1) {
        ; hItem := "0"    ; Causes the loop's first iteration to start the search at the top of the tree.
        hItem := this.GetHandleByText(text, index)
        if hItem{
            return this.SetSelection(hItem, defaultAction)
        }
        return false
    }
    ;----------------------------------------------------------------------------------------------
    ; Method: GetHandleByText
    ;         Retrieves the currently item with a specific text
    ;
    ; Parameters:
    ;         text            - Text of the item
    ;         index            - Index of item if you do not want to use the first item
    ;
    ; Returns:
    ;         Handle of Item
    ;
    GetHandleByText(Text, index := 1) {
        hItem := "0"    ; Causes the loop's first iteration to start the search at the top of the tree.
        i := 0
        Loop {
            hItem := this.GetNext(hItem, "Full")
            if !hItem{ ; No more items in tree.
                return false
            }
            if (this.GetText(hItem)=Text){
                i++
                if (index = i){
                    return hItem
                }
            }
        }
        return false
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: GetSelection
    ;         Retrieves the currently selected item
    ;
    ; Parameters:
    ;         None
    ;
    ; Returns:
    ;         Handle to the selected item if successful, Null otherwise.
    ;
    GetSelection() {
        return SendMessage(this.TVM_GETNEXTITEM, this.TVGN_CARET, 0, , "ahk_id " this.TVHwnd)
    }
    ;----------------------------------------------------------------------------------------------
    ; Method: GetSelectionText
    ;         Retrieves the currently selected text
    ;
    ; Parameters:
    ;         None
    ;
    ; Returns:
    ;         text of the selected item if successful, Null otherwise.
    ;
    GetSelectionText() {
        return this.GetText(this.GetSelection())
    }
    ;----------------------------------------------------------------------------------------------
    ; Method: GetRoot
    ;         Retrieves the root item of the treeview
    ;
    ; Parameters:
    ;         None
    ;
    ; Returns:
    ;         Handle to the topmost or very first item of the tree-view control
    ;         if successful, NULL otherwise.
    ;
    GetRoot() {
        return SendMessage(this.TVM_GETNEXTITEM, this.TVGN_ROOT, 0, , "ahk_id " this.TVHwnd)
    }
    ;----------------------------------------------------------------------------------------------
    ; Method: GetParent
    ;         Retrieves an item's parent
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Handle to the parent of the specified item. Returns
    ;         NULL if the item being retrieved is the root node of the tree.
    ;
    GetParent(pItem) {
        return SendMessage(this.TVM_GETNEXTITEM, this.TVGN_PARENT, pItem, , "ahk_id " this.TVHwnd)
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: GetChild
    ;         Retrieves an item's first child
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Handle to the first Child of the specified item, NULL otherwise.
    ;
    GetChild(pItem) {
        return SendMessage(this.TVM_GETNEXTITEM, this.TVGN_CHILD, pItem, , "ahk_id " this.TVHwnd)
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: GetNext
    ;         Returns the handle of the sibling below the specified item (or 0 if none).
    ;
    ; Parameters:
    ;         pItem            - (Optional) Handle to the item
    ;
    ;         flag          - (Optional) "FULL" or "F"
    ;
    ; Returns:
    ;         This method has the following modes:
    ;              1. When all parameters are omitted, it returns the handle
    ;                 of the first/top item in the TreeView (or 0 if none).
    ;
    ;              2. When the only first parameter (pItem) is present, it returns the
    ;                 handle of the sibling below the specified item (or 0 if none).
    ;                 If the first parameter is 0, it returns the handle of the first/top
    ;                 item in the TreeView (or 0 if none).
    ;
    ;              3. When the second parameter is "Full" or "F", the first time GetNext()
    ;                 is called the hItem passed is considered the "root" of a sub-tree that
    ;                 will be transversed in a depth first manner. No nodes except the
    ;                 decendents of that "root" will be visited. To traverse the entire tree,
    ;                 including the real root, pass zero in the first call.
    ;
    ;                 When all descendants have benn visited, the method returns zero.
    ;
    ; Example:
    ;                hItem = 0  ; Start the search at the top of the tree.
    ;                Loop
    ;                {
    ;                    hItem := MyTV.GetNext(hItem, "Full")
    ;                    if not hItem  ; No more items in tree.
    ;                        break
    ;                    ItemText := MyTV.GetText(hItem)
    ;                    MsgBox The next Item is %hItem%, whose text is "%ItemText%".
    ;                }
    ;
    GetNext(pItem := 0, flag := ""){
        static Root := -1

        if (RegExMatch(flag, "i)^\s*(F|Full)\s*$")) {
            if (Root = -1) {
                Root := pItem
            }
            ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_CHILD, pItem, , "ahk_id " this.TVHwnd)
            if (ErrorLevel = 0) {
                ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_NEXT, pItem, , "ahk_id " this.TVHwnd)
                if (ErrorLevel = 0) {
                    Loop {
                        ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_PARENT, pItem, , "ahk_id " this.TVHwnd)
                        if (ErrorLevel = Root) {
                            Root := -1
                            return 0
                        }
                        pItem := ErrorLevel
                        ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_NEXT, pItem, , "ahk_id " this.TVHwnd)
                    } until ErrorLevel
                }
            }
            return ErrorLevel
        }

        Root := -1
        if (!pItem)
            ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_ROOT, 0, , "ahk_id " this.TVHwnd)
        else
            ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_NEXT, pItem, , "ahk_id " this.TVHwnd)
        return ErrorLevel
    }
    ;----------------------------------------------------------------------------------------------
    ; Method: GetPrev
    ;         Returns the handle of the sibling above the specified item (or 0 if none).
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Handle of the sibling above the specified item (or 0 if none).
    ;
    GetPrev(pItem){
        ErrorLevel := SendMessage(this.TVM_GETNEXTITEM, this.TVGN_PREVIOUS, pItem, , "ahk_id " this.TVHwnd)
        return ErrorLevel
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: Expand
    ;         Expands or collapses the specified tree node
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ;         flag            - Determines whether the node is expanded or collapsed.
    ;                         true : expand the node (default)
    ;                         false : collapse the node
    ;
    ;
    ; Returns:
    ;         Nonzero if the operation was successful, or zero otherwise.
    ;
    Expand(pItem, DoExpand := true){
        flag := DoExpand ? this.TVE_EXPAND : this.TVE_COLLAPSE
        return SendMessage(this.TVM_EXPAND, flag, pItem, , "ahk_id " this.TVHwnd)
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: Check
    ;         Changes the state of a treeview item's check box
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ;         fCheck        - If true, check the node
    ;                         If false, uncheck the node
    ;
    ;         Force            - If true (default), prevents this method from failing due to
    ;                         the node having an invalid initial state. See IsChecked
    ;                         method for more info.
    ;
    ; Returns:
    ;         Returns true if if successful, otherwise false
    ;
    ; Remarks:
    ;         This method makes pItem the current selection.
    ;
    Check(pItem, fCheck, Force := true){
        SavedDelay := A_KeyDelay
        SetKeyDelay(30)

        CurrentState := this.IsChecked(pItem, false)
        if (CurrentState = -1)
            if (Force) {
                ControlSend("{Space}", , "ahk_id " this.TVHwnd)
                CurrentState := this.IsChecked(pItem, false)
            }
            else
                return false

        if (CurrentState and not fCheck) or (not CurrentState and fCheck )
            ControlSend("{Space}", , "ahk_id " this.TVHwnd)

        SetKeyDelay(SavedDelay)
        return true
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: GetText
    ;         Retrieves the text/name of the specified node
    ;
    ; Parameters:
    ;         pItem         - Handle to the item
    ;
    ; Returns:
    ;         The text/name of the specified Item. If the text is longer than 127, only
    ;         the first 127 characters are retrieved.
    ;
    ; Fix from just me (http://ahkscript.org/boards/viewtopic.php?f=5&t=4998#p29339)
    ;
    GetText(pItem){
        this.TVM_GETITEM := 1 ? this.TVM_GETITEMW : this.TVM_GETITEMA

        ProcessId := WinGetpid("ahk_id " this.TVHwnd)
        hProcess := this.OpenProcess(this.PROCESS_VM_OPERATION|this.PROCESS_VM_READ
                               |this.PROCESS_VM_WRITE|this.PROCESS_QUERY_INFORMATION                               , false, ProcessId)

        ; Try to determine the bitness of the remote tree-view's process
        ProcessIs32Bit := A_PtrSize = 8 ? False : True
        If (A_Is64bitOS) && DllCall("Kernel32.dll\IsWow64Process", "Ptr", hProcess, "int*", &WOW64:=true)
            ProcessIs32Bit := WOW64

        Size := ProcessIs32Bit ?  60 : 80 ; Size of a TVITEMEX structure

        _tvi := this.VirtualAllocEx(hProcess, 0, Size, this.MEM_COMMIT, this.PAGE_READWRITE)
        _txt := this.VirtualAllocEx(hProcess, 0, 256,  this.MEM_COMMIT, this.PAGE_READWRITE)

        ; TVITEMEX Structure
        tvi := Buffer(Size, 0) ; V1toV2: if 'tvi' is a UTF-16 string, use 'VarSetStrCapacity(&tvi, Size)'
        NumPut("UInt", this.TVIF_TEXT|this.TVIF_HANDLE, tvi, 0)
        If (ProcessIs32Bit){
            NumPut("UInt", pItem, tvi, 4)
            NumPut("UInt", _txt, tvi, 16)
            NumPut("UInt", 127, tvi, 20)
        }
        Else{
            NumPut("UInt64", pItem, tvi, 8)
            NumPut("UInt64", _txt, tvi, 24)
            NumPut("UInt", 127, tvi, 32)
        }

        txt := Buffer(256, 0) ; V1toV2: if 'txt' is a UTF-16 string, use 'VarSetStrCapacity(&txt, 256)'
        this.WriteProcessMemory(hProcess, _tvi, tvi, Size)
        SendMessage(this.TVM_GETITEM, 0, _tvi, , "ahk_id " this.TVHwnd)
        this.ReadProcessMemory(hProcess, _txt, txt, 256)

        this.VirtualFreeEx(hProcess, _txt, 0, this.MEM_RELEASE)
        this.VirtualFreeEx(hProcess, _tvi, 0, this.MEM_RELEASE)
        this.CloseHandle(hProcess)

        return StrGet(txt)
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: EditLabel
    ;         Begins in-place editing of the specified item's text, replacing the text of the
    ;         item with a single-line edit control containing the text. This method implicitly
    ;         selects and focuses the specified item.
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Returns the handle to the edit control used to edit the item text if successful,
    ;         or NULL otherwise. When the user completes or cancels editing, the edit control
    ;         is destroyed and the handle is no longer valid.
    ;
    EditLabel(pItem){
        this.TVM_EDITLABEL := 1 ? this.TVM_EDITLABELW : this.TVM_EDITLABELA
        return SendMessage(this.TVM_EDITLABEL, 0, pItem, , "ahk_id " this.TVHwnd)
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: GetCount
    ;         Returns the total number of expanded items in the control
    ;
    ; Parameters:
    ;         None
    ;
    ; Returns:
    ;         Returns the total number of expanded items in the control
    ;
    GetCount(){
        return SendMessage(this.TVM_GETCOUNT, 0, 0, , "ahk_id " this.TVHwnd)
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: IsChecked
    ;         Retrieves an item's checked status
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ;         force            - If true (default), forces the node to return a valid state.
    ;                         Since this involves toggling the state of the check box, it
    ;                         can have undesired side effects. Make this false to disable
    ;                         this feature.
    ; Returns:
    ;         Returns 1 if the item is checked, 0 if unchecked.
    ;
    ;         Returns -1 if the checkbox state cannot be determined because no checkbox
    ;         image is currently associated with the node and Force is false.
    ;
    ; Remarks:
    ;         Due to a "feature" of Windows, a checkbox can be displayed even if no checkbox image
    ;         is associated with the node. It is important to either check the actual value returned
    ;         or make the Force parameter true.
    ;
    ;         This method makes pItem the current selection.
    ;
    IsChecked(pItem, force := true){
        SavedDelay := A_KeyDelay
        SetKeyDelay(30)

        this.SetSelection(pItem, false) ; Set defaultAction to false to prevent sending Enter
        ErrorLevel := SendMessage(this.TVM_GETITEMSTATE, pItem, 0, , "ahk_id " this.TVHwnd)
        State := ((ErrorLevel & this.TVIS_STATEIMAGEMASK) >> 12) - 1

        if (State = -1 and force) {
            ControlSend("{Space 2}", , "ahk_id " this.TVHwnd)
            ErrorLevel := SendMessage(this.TVM_GETITEMSTATE, pItem, 0, , "ahk_id " this.TVHwnd)
            State := ((ErrorLevel & this.TVIS_STATEIMAGEMASK) >> 12) - 1
        }

        SetKeyDelay(SavedDelay)
        return State
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: IsBold
    ;         Check if a node is in bold font
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Returns true if the item is in bold, false otherwise.
    ;
    IsBold(pItem){
        ErrorLevel := SendMessage(this.TVM_GETITEMSTATE, pItem, 0, , "ahk_id " this.TVHwnd)
        return (ErrorLevel & this.TVIS_BOLD) >> 4
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: IsExpanded
    ;         Check if a node has children and is expanded
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Returns true if the item has children and is expanded, false otherwise.
    ;
    IsExpanded(pItem){
        ErrorLevel := SendMessage(this.TVM_GETITEMSTATE, pItem, 0, , "ahk_id " this.TVHwnd)
        return (ErrorLevel & this.TVIS_EXPANDED) >> 5
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: IsSelected
    ;         Check if a node is Selected
    ;
    ; Parameters:
    ;         pItem            - Handle to the item
    ;
    ; Returns:
    ;         Returns true if the item is selected, false otherwise.
    ;
    IsSelected(pItem){
        ErrorLevel := SendMessage(this.TVM_GETITEMSTATE, pItem, 0, , "ahk_id " this.TVHwnd)
        return (ErrorLevel & this.TVIS_SELECTED) >> 1
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: GetControlText
    ;     Returns a text representation of the control content, indented with tabs.
    ;
    ; Parameters:
    ;         Level         - (Optional) Indention level
    ;         pItem   - (Optional) Handle to the starting item
    ;
    ; Returns:
    ;         A text representation of the control content

    GetControlContent(Level:=0, pItem:=0, includeCheckboxes:=false){
        passed := false
        ControlText := ""

        loop {
            pItem := SendMessage(this.TVM_GETNEXTITEM, passed ? this.TVGN_NEXT : this.TVGN_CHILD , pItem, ,  "ahk_id " this.TVHwnd)
            if(pItem != 0){

                loop Level {
                    ControlText .= "`t"
                }

                ; If includeCheckboxes is true, get and include the checked status
                if (includeCheckboxes) {
                    ; Get the checked status of the item
                    Checked := this.IsChecked(pItem, false)
                    if (Checked = 1)
                        statusText := "[X] "
                    else if (Checked = 0)
                        statusText := "[ ] "
                    else
                        ; Seems that checkboxes are marked with dashes for cases where it can't get status - Meaning partial group checked
                        statusText := "[-] "
                } else {
                    statusText := ""  ; Do not include status
                }

                ; Include the status (if any) in the output
                ControlText .= statusText this.GetText(pItem) "`n"

                NextLevel := Level+1

                ; Pass includeCheckboxes parameter in the recursive call
                ControlText .= this.GetControlContent(NextLevel, pItem, includeCheckboxes)
                passed := true
            } else {
                break
            }
        }
        return ControlText
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: Wait
    ;     Waits untill the TreeView is loaded
    ;
    ; Parameters:
    ;         Level         - (Optional) Indention level
    ;         pItem   - (Optional) Handle to the starting item
    ;
    ; Returns:
    ;         The number of items
    Wait(DelayMs:=300){
        NumItems := -1
        Loop {
            ErrorLevel := SendMessage(0x1105, 0, 0, , "ahk_id " this.TVHwnd)    ; 0x1105 is TVM_GETCOUNT
            if (ErrorLevel != 0)
                if (ErrorLevel != NumItems)
                    NumItems := ErrorLevel
                else
                    break
            Sleep(DelayMs)
        }
        return ErrorLevel
    }

    ; The following Methods are general, but put inside the class to prevent them to conflict with other libraries

    ;----------------------------------------------------------------------------------------------
    ; Method: OpenProcess
    ;         Opens an existing local process object.
    ;
    ; Parameters:
    ;         DesiredAccess - The desired access to the process object.
    ;
    ;         InheritHandle - If this value is TRUE, processes created by this process will inherit
    ;                         the handle. Otherwise, the processes do not inherit this handle.
    ;
    ;         ProcessId     - The Process ID of the local process to be opened.
    ;
    ; Returns:
    ;         If the function succeeds, the return value is an open handle to the specified process.
    ;         If the function fails, the return value is NULL.
    ;
    OpenProcess(DesiredAccess, InheritHandle, ProcessId){
        return DllCall("OpenProcess"
                        , "Int", DesiredAccess
                        , "Int", InheritHandle
                        , "Int", ProcessId
                        , "Ptr")
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: CloseHandle
    ;         Closes an open object handle.
    ;
    ; Parameters:
    ;         hObject       - A valid handle to an open object
    ;
    ; Returns:
    ;         If the function succeeds, the return value is nonzero.
    ;         If the function fails, the return value is zero.
    ;
    CloseHandle(hObject){
        return DllCall("CloseHandle"
                        , "Ptr", hObject
                        , "Int")
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: VirtualAllocEx
    ;         Reserves or commits a region of memory within the virtual address space of the
    ;         specified process, and specifies the NUMA node for the physical memory.
    ;
    ; Parameters:
    ;         hProcess      - A valid handle to an open object. The handle must have the
    ;                         PROCESS_VM_OPERATION access right.
    ;
    ;         Address       - The pointer that specifies a desired starting address for the region
    ;                         of pages that you want to allocate.
    ;
    ;                         If you are reserving memory, the function rounds this address down to
    ;                         the nearest multiple of the allocation granularity.
    ;
    ;                         If you are committing memory that is already reserved, the function rounds
    ;                         this address down to the nearest page boundary. To determine the size of a
    ;                         page and the allocation granularity on the host computer, use the GetSystemInfo
    ;                         function.
    ;
    ;                         If Address is NULL, the function determines where to allocate the region.
    ;
    ;         Size          - The size of the region of memory to be allocated, in bytes.
    ;
    ;         AllocationType - The type of memory allocation. This parameter must contain ONE of the
    ;                          following values:
    ;                                MEM_COMMIT
    ;                                MEM_RESERVE
    ;                                MEM_RESET
    ;
    ;         ProtectType   - The memory protection for the region of pages to be allocated. If the
    ;                         pages are being committed, you can specify any one of the memory protection
    ;                         constants:
    ;                                 PAGE_NOACCESS
    ;                                 PAGE_READONLY
    ;                                 PAGE_READWRITE
    ;                                 PAGE_WRITECOPY
    ;                                 PAGE_EXECUTE
    ;                                 PAGE_EXECUTE_READ
    ;                                 PAGE_EXECUTE_READWRITE
    ;                                 PAGE_EXECUTE_WRITECOPY
    ;
    ; Returns:
    ;         If the function succeeds, the return value is the base address of the allocated region of pages.
    ;         If the function fails, the return value is NULL.
    ;
    VirtualAllocEx(hProcess, Address, Size, AllocationType, ProtectType){
        return DllCall("VirtualAllocEx"
                    , "Ptr", hProcess
                    , "Ptr", Address
                    , "UInt", Size
                    , "UInt", AllocationType
                    , "UInt", ProtectType
                    , "Ptr")
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: VirtualFreeEx
    ;         Releases, decommits, or releases and decommits a region of memory within the
    ;         virtual address space of a specified process
    ;
    ; Parameters:
    ;         hProcess      - A valid handle to an open object. The handle must have the
    ;                         PROCESS_VM_OPERATION access right.
    ;
    ;         Address       - The pointer that specifies a desired starting address for the region
    ;                         to be freed. If the dwFreeType parameter is MEM_RELEASE, lpAddress
    ;                         must be the base address returned by the VirtualAllocEx function when
    ;                         the region is reserved.
    ;
    ;         Size          - The size of the region of memory to be allocated, in bytes.
    ;
    ;                         If the FreeType parameter is MEM_RELEASE, dwSize must be 0 (zero). The function
    ;                         frees the entire region that is reserved in the initial allocation call to
    ;                         VirtualAllocEx.
    ;
    ;                         If FreeType is MEM_DECOMMIT, the function decommits all memory pages that
    ;                         contain one or more bytes in the range from the Address parameter to
    ;                         (lpAddress+dwSize). This means, for example, that a 2-byte region of memory
    ;                         that straddles a page boundary causes both pages to be decommitted. If Address
    ;                         is the base address returned by VirtualAllocEx and dwSize is 0 (zero), the
    ;                         function decommits the entire region that is allocated by VirtualAllocEx. After
    ;                         that, the entire region is in the reserved state.
    ;
    ;         FreeType      - The type of free operation. This parameter can be one of the following values:
    ;                                MEM_DECOMMIT
    ;                                MEM_RELEASE
    ;
    ; Returns:
    ;         If the function succeeds, the return value is a nonzero value.
    ;         If the function fails, the return value is 0 (zero).
    ;
    VirtualFreeEx(hProcess, Address, Size, FType){
        return DllCall("VirtualFreeEx"
                        , "Ptr", hProcess
                        , "Ptr", Address
                        , "UInt", Size
                        , "UInt", FType
                        , "Int")
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: WriteProcessMemory
    ;         Writes data to an area of memory in a specified process. The entire area to be written
    ;         to must be accessible or the operation fails
    ;
    ; Parameters:
    ;         hProcess      - A valid handle to an open object. The handle must have the
    ;                         PROCESS_VM_WRITE and PROCESS_VM_OPERATION access right.
    ;
    ;         BaseAddress   - A pointer to the base address in the specified process to which data
    ;                         is written. Before data transfer occurs, the system verifies that all
    ;                         data in the base address and memory of the specified size is accessible
    ;                         for write access, and if it is not accessible, the function fails.
    ;
    ;         Buffer        - A pointer to the buffer that contains data to be written in the address
    ;                         space of the specified process.
    ;
    ;         Size          - The number of bytes to be written to the specified process.
    ;
    ;         NumberOfBytesWritten
    ;                       - A pointer to a variable that receives the number of bytes transferred
    ;                         into the specified process. This parameter is optional. If NumberOfBytesWritten
    ;                         is NULL, the parameter is ignored.
    ;
    ; Returns:
    ;         If the function succeeds, the return value is a nonzero value.
    ;         If the function fails, the return value is 0 (zero).
    ;
    WriteProcessMemory(hProcess, BaseAddress, Buffer, Size, &NumberOfBytesWritten := 0){
        return DllCall("WriteProcessMemory"
                        , "Ptr", hProcess
                        , "Ptr", BaseAddress
                        , "Ptr", Buffer
                        , "Uint", Size
                        , "UInt*", NumberOfBytesWritten
                        , "Int")
    }

    ;----------------------------------------------------------------------------------------------
    ; Method: ReadProcessMemory
    ;         Reads data from an area of memory in a specified process. The entire area to be read
    ;         must be accessible or the operation fails
    ;
    ; Parameters:
    ;         hProcess      - A valid handle to an open object. The handle must have the
    ;                         PROCESS_VM_READ access right.
    ;
    ;         BaseAddress   - A pointer to the base address in the specified process from which to
    ;                         read. Before any data transfer occurs, the system verifies that all data
    ;                         in the base address and memory of the specified size is accessible for read
    ;                         access, and if it is not accessible the function fails.
    ;
    ;         Buffer        - A pointer to a buffer that receives the contents from the address space
    ;                         of the specified process.
    ;
    ;         Size          - The number of bytes to be read from the specified process.
    ;
    ;         NumberOfBytesWritten
    ;                       - A pointer to a variable that receives the number of bytes transferred
    ;                         into the specified buffer. If lpNumberOfBytesRead is NULL, the parameter
    ;                         is ignored.
    ;
    ; Returns:
    ;         If the function succeeds, the return value is a nonzero value.
    ;         If the function fails, the return value is 0 (zero).
    ;
    ReadProcessMemory(hProcess, BaseAddress, Buffer, Size, &NumberOfBytesRead := 0){
        return DllCall("ReadProcessMemory"
                        , "Ptr", hProcess
                        , "Ptr", BaseAddress
                        , "Ptr", Buffer
                        , "UInt", Size
                        , "UInt*", NumberOfBytesRead
                        , "Int")
    }
}
