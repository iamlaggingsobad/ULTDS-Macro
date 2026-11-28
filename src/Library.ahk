; ======================================================================================================================
; Library: The strategy library on the Main tab: cards, order, Load / Add / Remove, live reward updates.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

; kind = "coins" or "gems"; looks for Resources/Images/<kind>_<size>.png.
; An empty size (currency not supported) uses the greyed-out <kind>_none.png.
StratRewardIcon(kind, size) {
    static warned := Map()
    iconPath := "Resources/Images/" kind "_" (size != "" ? size : "none") ".png"
    if FileExist(iconPath)
        return iconPath
    if !warned.Has(iconPath) {
        warned[iconPath] := true
        LogToConsole("Missing resource file: " iconPath, "Error", 0x1010)
    }
    return ""
}

; ===== Strategy library: add / open folder / refresh / remove ============================
; Your own strategies live in the Strategies folder next to Main.ahk. Strategies you recorded
; (the Recordings folder) are listed too. The list is built when the app starts, so after a
; change the app reloads itself (settings are saved, so nothing is lost).
StratLib_Busy() {
    global RunningStrategy
    if (RunningStrategy) {
        MsgBox("Stop the macro first (F2), then change the strategy list.", "Strategy Library", 0x1040)
        return true
    }
    return false
}

StratLib_Add(*) {
    global MyStratsDir
    if StratLib_Busy()
        return
    files := FileSelect("M3", , "Add strategy file(s)", "Strategy (*.strat)")
    if !IsObject(files) || files.Length = 0
        return
    if !DirExist(MyStratsDir)
        DirCreate(MyStratsDir)
    added := 0
    for f in files {
        SplitPath(f, &name, &dir, , &stem)
        if (dir = MyStratsDir)
            continue
        target := MyStratsDir "\" name
        n := 1
        while (FileExist(target) && n < 500) {
            n += 1
            target := MyStratsDir "\" stem " (" n ").strat"
        }
        try {
            FileCopy(f, target)
            added += 1
        }
    }
    if (added > 0)
        Reload()
    else
        MsgBox("No strategy was added.", "Strategy Library", 0x1040)
}

StratLib_OpenFolder(*) {
    global MyStratsDir
    if !DirExist(MyStratsDir)
        DirCreate(MyStratsDir)
    Run('explorer.exe "' MyStratsDir '"')
}

StratLib_Refresh(*) {
    if StratLib_Busy()
        return
    Reload()
}

; ----- list order ---------------------------------------------------------------------------
; The order is stored in state.ini ([Library] Order = path|path|...). Anything not in it yet is appended.
StratLib_ApplyOrder(list) {
    global StateFile
    saved := IniRead(StateFile, "Library", "Order", "")
    if (saved = "" || list.Length < 2)
        return
    rank := Map()
    for i, p in StrSplit(saved, "|")
        if (p != "" && !rank.Has(StrLower(p)))
            rank[StrLower(p)] := i
    ; stable insertion sort by saved rank (unknown paths rank last, keeping their original order)
    n := list.Length
    keyOf := (st) => rank.Has(StrLower(st.path)) ? rank[StrLower(st.path)] : 1000000
    Loop n - 1 {
        i := A_Index + 1
        cur := list[i], k := keyOf(cur), j := i - 1
        while (j >= 1 && keyOf(list[j]) > k) {
            list[j + 1] := list[j]
            j -= 1
        }
        list[j + 1] := cur
    }
}

; Shows the active or the dimmed version of a card's arrows for its position in the list.
StratLib_SetArrows(rec, idx, total) {
    canUp := idx > 1, canDown := idx < total
    rec.up.pic.Visible := canUp
    rec.up.hit.Visible := canUp
    rec.up.off.Visible := !canUp
    rec.down.pic.Visible := canDown
    rec.down.hit.Visible := canDown
    rec.down.off.Visible := !canDown
}

; Scrolls the library to newPos (same as the scroll bar / mouse wheel does).
StratLib_ScrollTo(newPos) {
    global ChildGui, CurrentScrollPos, ContentH, FrameH, SliderH, Slider
    maxScroll := ContentH - FrameH
    if (maxScroll <= 0)
        return
    newPos := Max(0, Min(newPos, maxScroll))
    if (newPos = CurrentScrollPos)
        return
    DllCall("ScrollWindow", "Ptr", ChildGui.Hwnd, "Int", 0, "Int", CurrentScrollPos - newPos, "Ptr", 0, "Ptr", 0)
    CurrentScrollPos := newPos
    Slider.Move(, Round((newPos / maxScroll) * (FrameH - SliderH)))
    DllCall("UpdateWindow", "Ptr", ChildGui.Hwnd)
}

; Moves a card one place up (dir = -1) or down (dir = 1), live: the two cards just swap places on screen.
StratLib_Move(path, dir, *) {
    global LoadedStrats, StratCards, StateFile, ChildGui, CardH, Gap, FrameH, CurrentScrollPos
    pos := 0
    for i, st in LoadedStrats
        if (st.path = path)
            pos := i
    newPos := pos + dir
    if (pos = 0 || newPos < 1 || newPos > LoadedStrats.Length)
        return

    ; swap the two cards in the data
    tmp := LoadedStrats[pos], LoadedStrats[pos] := LoadedStrats[newPos], LoadedStrats[newPos] := tmp
    tmp := StratCards[pos], StratCards[pos] := StratCards[newPos], StratCards[newPos] := tmp

    ; ...and on screen: the clicked card (now at newPos) moves one slot, the other one moves back
    dy := dir * (CardH + Gap)
    for pair in [[StratCards[newPos], dy], [StratCards[pos], -dy]] {
        for c in pair[1].ctrls {
            c.GetPos(&cx, &cy)
            c.Move(cx, cy + pair[2])
        }
    }
    StratLib_SetArrows(StratCards[newPos], newPos, LoadedStrats.Length)
    StratLib_SetArrows(StratCards[pos], pos, LoadedStrats.Length)

    ; keep the moved card in view
    topY := 999999
    for c in StratCards[newPos].ctrls {
        c.GetPos(, &cy)
        topY := Min(topY, cy)      ; the card's frame is its topmost control
    }
    if (topY < 0)
        StratLib_ScrollTo(CurrentScrollPos + topY - 15)
    else if (topY + CardH > FrameH)
        StratLib_ScrollTo(CurrentScrollPos + (topY + CardH - FrameH) + 15)

    DllCall("RedrawWindow", "Ptr", ChildGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)

    order := ""
    for st in LoadedStrats
        order .= (order = "" ? "" : "|") st.path
    IniWrite(order, StateFile, "Library", "Order")
}

; Tooltip of a reward plate, e.g. "Large coins", "Large coins - wave 12" for a loss, or when map scaling / modifiers
; changed the number "Large coins - map 125%, modifiers +10%".
RewardTipText(kind, v, rw) {
    text := (kind = "exp") ? "Tower EXP" : ((v.size = "" ? "No" : StrUpper(SubStr(v.size, 1, 1)) SubStr(v.size, 2)) " " kind)
    parts := ""
    if (rw.computed && !rw.win && rw.wave != "")
        parts := "wave " rw.wave
    if (v.changed) {
        if (v.scale != 100)                               ; only where the map scaled this reward
            parts .= (parts != "" ? ", " : "") "map " v.scale "%"
        if (rw.bonus > 0)
            parts .= (parts != "" ? ", " : "") "modifiers +" rw.bonus "%"
    }
    if (parts != "")
        text .= " - " parts
    return text
}

; Shows a strat's rewards on its library card (coins / gems / exp numbers, the coin / gem icon size and the tooltips).
;   ComputeRewards works the rewards out (a win from the game mode, map and modifiers, a loss from the wave it reaches);
;   nothing is ever written to the strat file. When the calculated number differs from the original reward, the
;   original is shown small and grey with a red streak through it and the new number sits under it in the normal
;   colour. Rewards with an unknown amount ("?") or 0 are shown as they are.
StratLib_ApplyRewards(rec) {
    rw := ComputeRewards(rec.strat)
    for kind, r in rec.rewards {
        v := rw.%kind%
        both := (v.changed && v.orig != "" && v.orig > 0)
        r.main.Value := v.text
        r.main.Visible := !both
        r.old.Visible := both
        r.strike.Visible := both
        r.boosted.Visible := both

        ; a bigger or smaller amount can need a different icon size
        if (kind != "exp" && IsObject(r.icon)) {
            path := StratRewardIcon(kind, v.size)
            if (path != "" && path != r.iconPath) {
                r.icon.Value := "*w48 *h48 " path
                r.iconPath := path
            }
        }
        if (IsObject(r.tip))
            r.tip.Tip := RewardTipText(kind, v, rw)

        if (!both)
            continue
        r.old.Value := v.orig
        r.boosted.Value := v.amount
        hbm := CreateStreakBitmap(r.w, 13, StrLen(v.orig) * 6 + 6)
        r.strike.Value := "HBITMAP:*" hbm
        if (r.hbm)
            DllCall("DeleteObject", "Ptr", r.hbm)
        r.hbm := hbm
    }
}

; Shows a strat's edited title / author / description (and the rewards its new modifiers give) on its library card straight away (no Refresh needed).
StratLib_UpdateCard(path, title, author, desc) {
    global StratCards, ChildGui
    for rec in StratCards {
        if (rec.strat.path != path)
            continue
        rec.strat.title := title
        rec.strat.author := author
        rec.strat.desc := desc
        rec.title.Value := title != "" ? title : (rec.strat.stem != "" ? rec.strat.stem : "Unknown Strat")
        rec.strat.modifiers := IniRead(path, "Settings", "modifiers", "")
        StratLib_ApplyRewards(rec)
        break
    }
    DllCall("RedrawWindow", "Ptr", ChildGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)
}

; Highlights the library card of the strategy that is loaded for playback (CurrentStrategyFile, which changes when you
; press Load and when strategy rotation swaps strategies; before anything has been loaded it is the strategy in slot 1).
; The card's frame picture is swapped for the bright one, and the previously active card gets its normal frame back.
StratLib_UpdateActive() {
    global StratCards, ChildGui, CurrentStrategyFile, Strategy1Path
    if (!IsSet(StratCards) || !IsSet(ChildGui))
        return
    active := CurrentStrategyFile != "" ? CurrentStrategyFile : Strategy1Path
    key := StrLower(StrReplace(active, "/", "\"))
    changed := false
    for rec in StratCards {
        on := (key != "" && StrLower(StrReplace(rec.strat.path, "/", "\")) = key)
        if (on = rec.active)
            continue
        rec.active := on
        rec.frame.Value := "HBITMAP:*" (on ? rec.hFrameOn : rec.hFrame)
        changed := true
    }
    if (changed)
        DllCall("RedrawWindow", "Ptr", ChildGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)
}

; Opens a strat file for editing. The choice is remembered in settings ([Options] StratEditor = notepad | folder).
; First use asks: Yes = Notepad, No = open the strategy's folder with the file selected, so you can open it with
; any program you like. chooseNew = true (right-click / Shift+click) asks again. Changes show after Refresh.
StratLib_Edit(path, chooseNew := false, *) {
    global SettingsFile
    if !FileExist(path) {
        MsgBox("This strategy file no longer exists. Press Refresh to update the library.", "Edit strategy", 0x1040)
        return
    }
    mode := IniRead(SettingsFile, "Options", "StratEditor", "")
    if (mode != "notepad" && mode != "folder")
        mode := ""
    if (chooseNew || mode = "") {
        ans := MsgBox("Open strategy files with Notepad?`n`nYes = Notepad`nNo = open the strategies folder instead`n`n(Right-click the pencil any time to change this.)", "Edit strategy", 0x23)
        if (ans = "Cancel")
            return
        mode := (ans = "Yes") ? "notepad" : "folder"
        IniWrite(mode, SettingsFile, "Options", "StratEditor")
    }
    try {
        if (mode = "notepad")
            Run('notepad.exe "' path '"')
        else
            Run('explorer.exe /select,"' path '"')
    } catch {
        MsgBox("Could not open the file or folder.", "Edit strategy", 0x1010)
    }
}

StratLib_Remove(path, title, *) {
    global Strategy1Ctrl, Strategy2Ctrl
    if StratLib_Busy()
        return
    if (MsgBox("Are you sure you want to remove this strategy?`n`n" title "`n`nThe file is moved to a _removed folder next to it, so you can restore it by moving it back.", "Confirm remove", 0x134) != "Yes")
        return
    SplitPath(path, &name, &dir, , &stem)
    trash := dir "\_removed"
    try DirCreate(trash)
    target := trash "\" name
    n := 1
    while (FileExist(target) && n < 500) {
        n += 1
        target := trash "\" stem " (" n ").strat"
    }
    try FileMove(path, target)
    if FileExist(path) {
        MsgBox("The file could not be removed. It may be open in another program.", "Remove strategy", 0x1010)
        return
    }
    if (Strategy1Ctrl.Value = path)
        ClearStrat1(0)
    if (Strategy2Ctrl.Value = path)
        ClearStrat2(0)
    Reload()
}

DownloadStrat(ctrl, *) {
    nm := ctrl.StratFile 
    
    downloadedStrat := HasProp(ctrl, "StratPath") ? ctrl.StratPath : A_WorkingDir "\Resources\Strats" (SubStr(nm, 1, 1) = "\" ? nm : "\" nm)

    if (Strategy1Ctrl.Value = "") {
    Strategy1Ctrl.Value := downloadedStrat
    Strategy1Path := downloadedStrat
    IniWrite(downloadedStrat, SettingsFile, "Options", "Strategy1")
    } else if (Strategy2Ctrl.Value = "" && Strategy2Ctrl.Visible) {
        Strategy2Ctrl.Value := downloadedStrat
        Strategy2Path := downloadedStrat
        IniWrite(downloadedStrat, SettingsFile, "Options", "Strategy2")
    } else {
        Strategy1Ctrl.Value := downloadedStrat
        Strategy1Path := downloadedStrat
        IniWrite(downloadedStrat, SettingsFile, "Options", "Strategy1")
    }
    
    LoadStrategyFile(downloadedStrat)
}

OnMouseWheel(wp, lp, msg, hwnd) {
    global ChildHwnd, ChildGui
    MouseGetPos(, , &maxH, &ctrlH, 2)

    parentH := (ctrlH != "") ? DllCall("GetParent", "Ptr", ctrlH, "Ptr") : 0
    ch := ChildGui.Hwnd
    
    if (maxH = ch || ctrlH = ch || parentH = ch) {
        
        dir := ((wp >> 16) & 0xFFFF) > 0x7FFF ? 1 : 0
        Loop 3 {
            
            SendMessage(0x0115, dir, 0, , "ahk_id " ch)
        }
    }
}

OnScroll(wp, lp, msg, hwnd) {
    global ChildGui, CurrentScrollPos, ContentH, FrameH, SliderH, Slider
    ch := ChildGui.Hwnd
    if (hwnd != ch)
        return
    action := wp & 0xFFFF
    if (action = 0) {
        newPos := CurrentScrollPos - 3
    } else if (action = 1) {
        newPos := CurrentScrollPos + 3
    } else {
        return
    }
    maxScroll := ContentH - FrameH
    newPos := Max(0, Min(newPos, maxScroll))
    if (newPos != CurrentScrollPos) {
        DllCall("ScrollWindow", "Ptr", hwnd, "Int", 0, "Int", CurrentScrollPos - newPos, "Ptr", 0, "Ptr", 0)
        CurrentScrollPos := newPos
        
        availableTrackSpace := FrameH - SliderH

        sliderVisualY := Round((newPos / maxScroll) * availableTrackSpace)
        
        Slider.Move(, sliderVisualY)
        
        DllCall("UpdateWindow", "Ptr", hwnd)
    }
}

; Opens the Info window for a strat, reading its current values from the file.
StratLib_ShowInfo(path, stem := "") {
    global StratInfoSpecial, StratInfoResult
    if !FileExist(path) {
        StratInfo("Strategy not found", "", "", "", "This strategy file no longer exists. Press Refresh to update the library.", "E5484D")
        return
    }
    title := IniRead(path, "Info", "title", "")
    author := IniRead(path, "Info", "author", "")
    towers := IniRead(path, "Settings", "requiredTowers", "")
    mods := IniRead(path, "Settings", "modifiers", "")
    desc := IniRead(path, "Info", "desc", "")
    mode := IniRead(path, "Settings", "difficulty", "")
    accent := mode != "" ? ModeColorHex(SpecialModeName(mode) != "" ? SpecialModeName(mode) : mode) : "3A86FF"
    StratInfoSpecial := (mode != "" && SpecialModeName(mode) != "")
    StratInfoResult := RewardResult(IniRead(path, "Info", "result", ""))
    StratInfo(title != "" ? title : stem, author != "" ? author : "Unknown", towers, mods, desc, accent, path)
}
