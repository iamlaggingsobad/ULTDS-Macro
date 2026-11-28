; ======================================================================================================================
; StratInfo: The strategy Info window: view and edit title, author, description and modifiers.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

StratInfo_Close(*) {
    global StratInfoGui, StratInfoTiles, StratInfoTipShown, StratInfoTipLast, StratInfoBitmaps
    global StratInfoPath, StratInfoEdit, StratInfoModTiles, StratInfoHead, StratInfoEditPic, StratInfoSavePic, StratInfoLower, StratInfoDescScroll
    SetTimer(StratInfo_Hover, 0)
    try OnMessage(0x0201, StratInfo_Click, 0)
    try OnMessage(0x020A, StratInfo_Wheel, 0)
    StratInfoDescScroll := false
    try ToolTip(, , , 19)
    StratInfoTipShown := "", StratInfoTipLast := ""
    StratInfoTiles := [], StratInfoModTiles := [], StratInfoLower := []
    StratInfoPath := "", StratInfoEdit := false
    StratInfoHead := 0, StratInfoEditPic := 0, StratInfoSavePic := 0
    if (StratInfoGui) {
        try StratInfoGui.Destroy()
        StratInfoGui := 0
    }
    for hbm in StratInfoBitmaps
        try DeleteObject(hbm)
    StratInfoBitmaps := []
}

; Mouse clicks inside the Info window. Handled here (not with per-control Click events) so the X and the drag bar
; always respond, whichever control is under the cursor. Click the X (top right) to close; drag the top bar to move.
StratInfo_Click(wParam, lParam, msg, hwnd) {
    global StratInfoGui, StratInfoW, StratInfoPath, StratInfoEdit, StratInfoMods, StratInfoModTiles, StratInfoEditRect, StratInfoSaveRect
    global StratInfoFooter, StratInfoSpecial
    if (!StratInfoGui)
        return
    try {
        if (DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr") != StratInfoGui.Hwnd)
            return
    } catch {
        return
    }
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "Ptr", pt)
    DllCall("ScreenToClient", "Ptr", StratInfoGui.Hwnd, "Ptr", pt)
    x := NumGet(pt, 0, "Int"), y := NumGet(pt, 4, "Int")
    ; Edit / Cancel button in the top bar (checked before the drag bar, which it sits on)
    if (StratInfoPath != "" && StratInfo_Hit(StratInfoEditRect, x, y)) {
        StratInfo_SetEdit(!StratInfoEdit)
        return 1
    }
    if (y >= 0 && y < 38) {
        if (x >= StratInfoW - 42) {
            SetTimer(StratInfo_Close, -1)
        } else {
            PostMessage(0xA1, 2, , , StratInfoGui)
        }
        return 1
    }
    if (StratInfoDescScroll && !StratInfoEdit && StratInfo_DescClick(x, y))
        return 1
    if (StratInfoPath = "")
        return
    if (!StratInfoEdit)
        return
    if (StratInfo_Hit(StratInfoSaveRect, x, y)) {
        StratInfo_SaveAll()
        return 1
    }
    ; while editing, a click on a modifier square turns it on or off
    for tile in StratInfoModTiles {
        if (StratInfo_Hit([tile.x, tile.y, tile.w, tile.h], x, y)) {
            if (StratInfoSpecial) {
                ; failsafe: special game modes have fixed rewards and cannot use modifiers
                StratInfoFooter.Text := "Special game modes have fixed rewards, so modifiers can't be added."
                StratInfo_Redraw()
                return 1
            }
            if (StratInfoMods.Has(tile.code))
                StratInfoMods.Delete(tile.code)
            else
                StratInfoMods[tile.code] := true
            StratInfo_SetTile(tile, StratInfoMods.Has(tile.code))
            StratInfo_UpdateBonus()
            StratInfo_Redraw()
            return 1
        }
    }
}

StratInfo_Hit(r, x, y) {
    return x >= r[1] && x < r[1] + r[3] && y >= r[2] && y < r[2] + r[4]
}

StratInfo_Redraw() {
    global StratInfoGui
    if (StratInfoGui)
        DllCall("RedrawWindow", "Ptr", StratInfoGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)   ; invalidate + erase + children + update now
}

; Shows a modifier square in its on (colour icon, bright plate) or off (grayscale icon, dark plate) look.
StratInfo_SetTile(tile, isOn) {
    if (tile.plateOn)
        tile.plate.Value := "HBITMAP:*" (isOn ? tile.plateOn : tile.plateOff)
    ctrl := tile.icon ? tile.icon : tile.plate
    ctrl.Value := "HBITMAP:*" (isOn ? tile.bmpOn : tile.bmpOff)
}

; Switches edit mode on or off (Edit button in the top bar). In edit mode the title, author and description become
; edit boxes, the modifier squares can be clicked and a Save button appears. Switching it off throws away unsaved changes.
StratInfo_SetEdit(on) {
    global StratInfoGui, StratInfoW, StratInfoEdit, StratInfoMods, StratInfoModsOrig, StratInfoModTiles, StratInfoHead
    global StratInfoEditPic, StratInfoEditBmps, StratInfoOrig, StratInfoFooter
    global StratInfoTitleTxt, StratInfoAuthorTxt, StratInfoByLbl, StratInfoTitleEdit, StratInfoAuthorEdit, StratInfoDescEdit
    global StratInfoTitleFrame, StratInfoAuthorFrame, StratInfoSpecial
    if (!StratInfoGui)
        return
    StratInfoEdit := on
    if (!on) {
        StratInfoMods := StratInfoModsOrig.Clone()
        for tile in StratInfoModTiles
            StratInfo_SetTile(tile, StratInfoMods.Has(tile.code))
        StratInfoTitleEdit.Value := StratInfoOrig["title"]
        StratInfoAuthorEdit.Value := StratInfoOrig["author"]
        StratInfoDescEdit.Value := StratInfoOrig["desc"]
    }
    StratInfoHead.Text := on ? (StratInfoSpecial ? "MODIFIERS  -  NOT IN SPECIAL MODES" : "MODIFIERS  -  CLICK TO TOGGLE") : "MODIFIERS"
    StratInfo_UpdateBonus()
    StratInfoFooter.Text := StratInfo_Note()
    StratInfoEditPic.Value := "HBITMAP:*" StratInfoEditBmps[on ? 2 : 1]
    StratInfoTitleTxt.Visible := !on
    StratInfoAuthorTxt.Visible := !on
    for c in [StratInfoTitleFrame, StratInfoTitleEdit, StratInfoByLbl, StratInfoAuthorFrame, StratInfoAuthorEdit]
        c.Visible := on
    h := StratInfo_Layout()
    StratInfoGui.Show("w" StratInfoW " h" h " NA")
    StratInfo_Redraw()
    if (on) {
        try WinActivate("ahk_id " StratInfoGui.Hwnd)
        try StratInfoTitleEdit.Focus()
    }
}

; Places everything below the modifiers for the current mode and returns the window height.
StratInfo_Layout() {
    global StratInfoW, StratInfoEdit, StratInfoPath, StratInfoLowerY, StratInfoDescHead, StratInfoDescTxt
    global StratInfoDescH, StratInfoHasDesc, StratInfoDescFrame, StratInfoDescEdit, StratInfoSavePic, StratInfoSaveRect, StratInfoFooter
    global StratInfoDescScroll, StratInfoDescView, StratInfoDescTrack, StratInfoDescThumb, StratInfoDescViewY
    pad := 22, innerW := StratInfoW - pad * 2
    y := StratInfoLowerY
    canEdit := (StratInfoPath != "")
    showView := false
    if (canEdit && StratInfoEdit) {
        StratInfoDescHead.Visible := true
        StratInfoDescHead.Move(, y)
        StratInfoDescTxt.Visible := false
        StratInfoDescFrame.Move(, y + 19)
        StratInfoDescFrame.Visible := true
        StratInfoDescEdit.Move(, y + 20)
        StratInfoDescEdit.Visible := true
        y += 20 + 96 + 16
        StratInfoSavePic.Move(, y - 6)
        StratInfoSavePic.Visible := true
        StratInfoSaveRect := [pad, y, innerW, 32]
        y += 32 + 18
    } else {
        if (canEdit) {
            StratInfoDescFrame.Visible := false
            StratInfoDescEdit.Visible := false
            StratInfoSavePic.Visible := false
        }
        if (StratInfoHasDesc) {
            StratInfoDescHead.Visible := true
            StratInfoDescHead.Move(, y)
            if (StratInfoDescScroll) {
                ; long description: read-only viewport + scroll bar
                showView := true
                StratInfoDescTxt.Visible := false
                StratInfoDescViewY := y + 20
                StratInfoDescView.Move(, y + 20)
                StratInfoDescTrack.Move(, y + 20)
                StratInfo_DescSync()
            } else {
                StratInfoDescTxt.Visible := true
                StratInfoDescTxt.Move(, y + 20)
            }
            y += 20 + StratInfoDescH + 18
        } else {
            StratInfoDescHead.Visible := false
            StratInfoDescTxt.Visible := false
        }
    }
    StratInfoDescView.Visible := showView
    StratInfoDescTrack.Visible := showView
    StratInfoDescThumb.Visible := showView
    StratInfoFooter.Move(, y)
    y += 16 + pad
    return y
}

; Decides whether the description needs the scroll bar (more than StratInfoDescVis lines) and prepares the viewport.
; text uses `n for line breaks. Sets StratInfoDescScroll and StratInfoDescH (the height the description needs).
StratInfo_DescSetup(text) {
    global StratInfoW, StratInfoDescVis, StratInfoDescLineH, StratInfoDescView, StratInfoDescThumb, StratInfoDescScroll
    global StratInfoDescTotal, StratInfoDescThumbH, StratInfoDescH, StratInfoBitmaps
    innerW := StratInfoW - 44
    h := (text != "") ? StratInfo_MeasureH(text, innerW, "s9 w400") : 0
    vh := StratInfoDescLineH * StratInfoDescVis
    StratInfoDescScroll := false
    StratInfoDescH := h
    if (text = "" || h <= vh + 2)
        return
    StratInfoDescView.Value := StrReplace(text, "`n", "`r`n")
    total := SendMessage(0xBA, 0, 0, StratInfoDescView)      ; EM_GETLINECOUNT (lines as wrapped in the viewport)
    if (total <= StratInfoDescVis)
        return
    StratInfoDescScroll := true
    StratInfoDescTotal := total
    StratInfoDescH := vh
    StratInfoDescThumbH := Max(30, Round(vh * StratInfoDescVis / total))
    hThumb := CreateScrollThumb(6, StratInfoDescThumbH, 3, "0xFF6EA7FF", "0xff4076ce", "0xd4d4d4")
    StratInfoBitmaps.Push(hThumb)
    StratInfoDescThumb.Value := "HBITMAP:*" hThumb
    StratInfoDescThumb.Move(, , 6, StratInfoDescThumbH)
}

; Puts the scroll thumb where the viewport currently is.
StratInfo_DescSync() {
    global StratInfoDescVis, StratInfoDescLineH, StratInfoDescView, StratInfoDescThumb, StratInfoDescTotal, StratInfoDescThumbH, StratInfoDescViewY
    first := SendMessage(0xCE, 0, 0, StratInfoDescView)      ; EM_GETFIRSTVISIBLELINE
    maxFirst := Max(1, StratInfoDescTotal - StratInfoDescVis)
    trackH := StratInfoDescLineH * StratInfoDescVis
    frac := Max(0, Min(1, first / maxFirst))
    StratInfoDescThumb.Move(, StratInfoDescViewY + Round(frac * (trackH - StratInfoDescThumbH)))
}

; Scrolls the description to the given first line (0 = top).
StratInfo_DescScrollTo(line) {
    global StratInfoGui, StratInfoDescScroll, StratInfoDescView, StratInfoDescTotal, StratInfoDescVis
    if (!StratInfoGui || !StratInfoDescScroll)
        return
    first := SendMessage(0xCE, 0, 0, StratInfoDescView)
    target := Max(0, Min(StratInfoDescTotal - StratInfoDescVis, line))
    if (target = first)
        return
    SendMessage(0xB6, 0, target - first, StratInfoDescView)  ; EM_LINESCROLL
    StratInfo_DescSync()
    StratInfo_Redraw()
}

StratInfo_DescScroll(lines) {
    global StratInfoDescView
    StratInfo_DescScrollTo(SendMessage(0xCE, 0, 0, StratInfoDescView) + lines)
}

; Click on the description's scroll bar: drag the thumb, or click the track to page up / down.
StratInfo_DescClick(x, y) {
    global StratInfoGui, StratInfoW, StratInfoDescVis, StratInfoDescLineH, StratInfoDescThumb, StratInfoDescThumbH
    global StratInfoDescTotal, StratInfoDescViewY
    trackX := 22 + (StratInfoW - 44) - 6
    trackH := StratInfoDescLineH * StratInfoDescVis
    if (x < trackX - 4 || x > trackX + 10 || y < StratInfoDescViewY || y > StratInfoDescViewY + trackH)
        return false
    StratInfoDescThumb.GetPos(, &thumbY)
    if (y >= thumbY && y <= thumbY + StratInfoDescThumbH) {
        grab := y - thumbY
        maxFirst := Max(1, StratInfoDescTotal - StratInfoDescVis)
        pt := Buffer(8, 0)
        while (GetKeyState("LButton", "P") && StratInfoGui) {
            DllCall("GetCursorPos", "Ptr", pt)
            DllCall("ScreenToClient", "Ptr", StratInfoGui.Hwnd, "Ptr", pt)
            cy := NumGet(pt, 4, "Int")
            frac := Max(0, Min(1, (cy - grab - StratInfoDescViewY) / Max(1, trackH - StratInfoDescThumbH)))
            StratInfo_DescScrollTo(Round(frac * maxFirst))
            Sleep(15)
        }
    } else {
        StratInfo_DescScroll(y < thumbY ? -StratInfoDescVis : StratInfoDescVis)
    }
    return true
}

; Mouse wheel over the description scrolls it (3 lines per notch).
StratInfo_Wheel(wp, lp, msg, hwnd) {
    global StratInfoGui, StratInfoW, StratInfoEdit, StratInfoDescScroll, StratInfoDescVis, StratInfoDescLineH, StratInfoDescViewY
    if (!StratInfoGui || !StratInfoDescScroll || StratInfoEdit)
        return
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "Ptr", pt)
    under := DllCall("WindowFromPoint", "Int64", NumGet(pt, 0, "Int64"), "Ptr")
    if (!under || DllCall("GetAncestor", "Ptr", under, "UInt", 2, "Ptr") != StratInfoGui.Hwnd)
        return
    DllCall("ScreenToClient", "Ptr", StratInfoGui.Hwnd, "Ptr", pt)
    x := NumGet(pt, 0, "Int"), y := NumGet(pt, 4, "Int")
    if (x < 22 || x > StratInfoW - 22 || y < StratInfoDescViewY || y > StratInfoDescViewY + StratInfoDescLineH * StratInfoDescVis)
        return
    StratInfo_DescScroll(((wp >> 16) & 0xFFFF) > 0x7FFF ? 3 : -3)
    return 0
}

; Writes the edited title / author / description and the modifier set into the strat file.
; (Description line breaks are stored as a literal \n; modifiers: standard ones in list order, then any unknown
; entries that were already in the file, unchanged.)
StratInfo_SaveAll() {
    global StratInfoPath, StratInfoMods, StratInfoModsOrig, StratInfoExtras, StratInfoOrig, StratInfoFooter, StratInfoW
    global StratInfoTitleEdit, StratInfoAuthorEdit, StratInfoDescEdit, StratInfoTitleTxt, StratInfoAuthorTxt
    global StratInfoDescTxt, StratInfoDescH, StratInfoHasDesc, StratInfoTitleH, StratInfoModTiles, StratInfoSpecial
    path := StratInfoPath
    innerW := StratInfoW - 44

    ; failsafe: special game modes cannot have modifiers, so any that are in the file are removed
    if (StratInfoSpecial) {
        StratInfoMods := Map()
        StratInfoExtras := []
        for tile in StratInfoModTiles
            StratInfo_SetTile(tile, false)
    }

    parts := []
    for m in ModifierList() {
        if (StratInfoMods.Has(m[2]))
            parts.Push(m[2])
    }
    for e in StratInfoExtras
        parts.Push(e)
    modStr := ""
    for idx, c in parts
        modStr .= (idx = 1 ? "" : ", ") c

    title := Trim(StratInfoTitleEdit.Value)
    author := Trim(StratInfoAuthorEdit.Value)
    descEdit := Trim(StratInfoDescEdit.Value, " `t`r`n")
    descFile := StrReplace(StrReplace(descEdit, "`r`n", "\n"), "`n", "\n")

    ok := SaveModifiersToStrategyFile(path, modStr)
    if (ok)
        ok := StratInfo_WriteKey(path, "title", title)
    if (ok)
        ok := StratInfo_WriteKey(path, "author", author)
    if (ok)
        ok := StratInfo_WriteKey(path, "desc", descFile)
    if (!ok) {
        StratInfoFooter.Text := "Could not save - is the strategy file read-only or open in another program?"
        StratInfo_Redraw()
        return
    }

    StratInfoModsOrig := StratInfoMods.Clone()
    StratInfoOrig := Map("title", title, "author", author, "desc", descEdit)
    SplitPath(path, , , , &stem)
    StratInfoTitleTxt.Value := StratInfo_Fit(title != "" ? title : stem, innerW, "s14 w700", StratInfoTitleH)
    StratInfoAuthorTxt.Value := "by " (author != "" ? author : "Unknown")
    descView := StrReplace(descEdit, "`r`n", "`n")
    StratInfoDescTxt.Value := descView
    StratInfoHasDesc := (descEdit != "")
    StratInfo_DescSetup(descView)
    StratInfo_SetEdit(false)
    StratLib_UpdateCard(path, title, author, descFile)
    StratInfoFooter.Text := "Saved to the strategy file and the library."
    StratInfo_Redraw()
}

StratInfo_WriteKey(path, key, val) {
    try {
        if (val = "") {
            if (IniRead(path, "Info", key, "") != "")
                IniDelete(path, "Info", key)
        } else {
            IniWrite(val, path, "Info", key)
        }
        return true
    } catch {
        return false
    }
}

; "REWARDS +NN%": the reward bonus of the active modifiers (they stack, but Glass / Exploding / Limitation / Committed /
; Speedy / Flying together are capped at +50%, shown as "(CAP)"). Green when above 0.
; Special game modes have fixed rewards, and modifiers only give a bonus on wins, so those show a grey note instead.
StratInfo_UpdateBonus() {
    global StratInfoMods, StratInfoBonusTxt, StratInfoSpecial, StratInfoResult
    if (!IsObject(StratInfoBonusTxt))
        return
    if (StratInfoSpecial) {
        StratInfoBonusTxt.SetFont("c6F7785")
        StratInfoBonusTxt.Value := "REWARDS  FIXED"
        return
    }
    if (StratInfoResult = "lose") {
        StratInfoBonusTxt.SetFont("c6F7785")
        StratInfoBonusTxt.Value := "REWARDS  NO BONUS"
        return
    }
    codes := []
    for code, on in StratInfoMods
        codes.Push(code)
    total := ModifierBonusFromCodes(codes)
    StratInfoBonusTxt.SetFont(total > 0 ? "c5BD98C" : "c6F7785")
    StratInfoBonusTxt.Value := "REWARDS  +" total "%" (ModifierCapReached(codes) ? "  (CAP)" : "")      ; (CAP): the +50% limit is cutting some off
}

StratInfo_Note() => "Use the pencil button on the card to edit the rest of this strategy."

StratInfo_Escape(*) {
    global StratInfoEdit
    if (StratInfoEdit)
        StratInfo_SetEdit(false)
    else
        StratInfo_Close()
}

; grey hint text shown inside an empty edit box
StratInfo_Cue(ctrl, text) {
    try DllCall("SendMessage", "Ptr", ctrl.Hwnd, "UInt", 0x1501, "Ptr", 1, "WStr", text)
}

; height a text needs at the given width and font (measured with a throw-away window that is never shown)
StratInfo_MeasureH(text, w, fontOpts) {
    mg := Gui()
    mg.MarginX := 0, mg.MarginY := 0
    mg.SetFont(fontOpts, "Segoe UI")
    tmp := mg.Add("Text", "x0 y0 w" w, text)
    tmp.GetPos(, , , &h)
    mg.Destroy()
    return h
}

; shortens text with "..." until it fits into maxH (so a long title cannot spill over the controls below it)
StratInfo_Fit(text, w, fontOpts, maxH) {
    if (StratInfo_MeasureH(text, w, fontOpts) <= maxH + 4)
        return text
    cut := text
    while (StrLen(cut) > 4) {
        cut := SubStr(cut, 1, StrLen(cut) - 3)
        if (StratInfo_MeasureH(cut "...", w, fontOpts) <= maxH + 4)
            return cut "..."
    }
    return cut
}

; Shows the unit's name as a tooltip while the mouse rests on one of the unit squares.
StratInfo_Hover() {
    global StratInfoGui, StratInfoTiles, StratInfoTipShown, StratInfoTipSince, StratInfoTipLast
    if (!StratInfoGui) {
        SetTimer(StratInfo_Hover, 0)
        return
    }
    name := ""
    try {
        MouseGetPos(, , &winHwnd)
        if (winHwnd = StratInfoGui.Hwnd) {
            pt := Buffer(8, 0)
            DllCall("GetCursorPos", "Ptr", pt)
            DllCall("ScreenToClient", "Ptr", StratInfoGui.Hwnd, "Ptr", pt)
            mx := NumGet(pt, 0, "Int"), my := NumGet(pt, 4, "Int")
            for tile in StratInfoTiles {
                if (mx >= tile["x"] && mx < tile["x"] + tile["w"] && my >= tile["y"] && my < tile["y"] + tile["h"]) {
                    name := tile["name"]
                    break
                }
            }
        }
    }
    if (name != StratInfoTipLast) {
        StratInfoTipLast := name
        StratInfoTipSince := A_TickCount
        if (StratInfoTipShown != "") {
            ToolTip(, , , 19)
            StratInfoTipShown := ""
        }
    }
    if (name != "" && StratInfoTipShown != name && A_TickCount - StratInfoTipSince >= 120) {
        ToolTip(name, , , 19)
        StratInfoTipShown := name
    }
}

; Loads an icon file and returns an HBITMAP of exactly size x size pixels (transparent background), scaled with
; high-quality bicubic filtering and kept in proportion. A Picture control that scales an image itself looks blocky;
; handing it a bitmap that is already the right size keeps the icon sharp. Returns 0 when the file cannot be read.
StratInfo_IconBitmap(path, size, gray := false) {
    pSrc := Gdip_CreateBitmapFromFile(path)
    if (!pSrc)
        return 0
    Gdip_GetImageDimensions(pSrc, &iw, &ih)
    if (iw < 1 || ih < 1) {
        Gdip_DisposeImage(pSrc)
        return 0
    }
    scale := Min(size / iw, size / ih)
    dw := Max(1, Round(iw * scale)), dh := Max(1, Round(ih * scale))
    dx := (size - dw) // 2, dy := (size - dh) // 2
    hbm := CreateDIBSection(size, size)
    hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm)
    G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetInterpolationMode(G, 7)     ; high-quality bicubic
    Gdip_SetSmoothingMode(G, 4)
    Gdip_SetPixelOffsetMode(G, 2)       ; high quality, avoids a half-pixel shift at the edges
    ; gray = true draws the icon in grayscale (used for modifiers that are switched off)
    grayMatrix := "0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1"
    if (gray)
        Gdip_DrawImage(G, pSrc, dx, dy, dw, dh, 0, 0, iw, ih, grayMatrix)
    else
        Gdip_DrawImage(G, pSrc, dx, dy, dw, dh, 0, 0, iw, ih)
    Gdip_DeleteGraphics(G)
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    Gdip_DisposeImage(pSrc)
    return hbm
}

; The Required Towers section: always five equally spaced squares, drawn like the library's icon plates (rounded, soft
; shadow, light-to-dark gradient). Every square uses the same plain dark plate (no rarity colour); a filled square shows
; the tower's icon (or its initials when no icon file exists); hover a square for the tower's name. Advances y.
StratInfo_Units(g, raw, &y, pad, innerW) {
    global StratInfoTiles, StratInfoBitmaps
    g.SetFont("s8 w700 c6F7785", "Segoe UI")
    g.Add("Text", "x" pad " y" y " w" innerW " h14 +BackgroundTrans", "REQUIRED TOWERS")
    y += 22
    items := []
    for tok in StrSplit(RegExReplace(raw, "[;|]", ","), ",", " `t") {
        if (tok != "")
            items.Push(tok)
    }
    n := 5, gap := 8
    sz := (innerW - gap * (n - 1)) // n
    x0 := pad + (innerW - (sz * n + gap * (n - 1))) // 2
    ; the bitmaps carry a 6px shadow margin on every side, so they are drawn 12px larger and placed 6px up/left
    hEmpty := CreateGradientButton(sz + 12, sz + 12, 10, "0xff2f353f", "0xff15171b", "0xff000000", "0x232c3a50", "", "Segoe UI", 10, 1)
    StratInfoBitmaps.Push(hEmpty)
    hFilled := CreateGradientButton(sz + 12, sz + 12, 10, "0xff2f353f", "0xff15171b", "0x40000000", "0x5dffffff", "", "Segoe UI", 10, 1)
    StratInfoBitmaps.Push(hFilled)
    Loop n {
        i := A_Index
        tx := x0 + (i - 1) * (sz + gap)
        if (i > items.Length) {
            g.Add("Picture", "x" (tx - 6) " y" (y - 6) " w" (sz + 12) " h" (sz + 12) " +BackgroundTrans", "HBITMAP:*" hEmpty)
            continue
        }
        name := TowerDisplayName(items[i])
        img := TowerIconPath(name)
        if (img != "") {
            hTile := hFilled
        } else {
            hTile := CreateGradientButton(sz + 12, sz + 12, 10, "0xff2f353f", "0xff15171b", "0x40000000", "0x5dffffff", TowerInitials(name), "Segoe UI", 16, 1, "0xFFB8BEC8")
            StratInfoBitmaps.Push(hTile)
        }
        g.Add("Picture", "x" (tx - 6) " y" (y - 6) " w" (sz + 12) " h" (sz + 12) " +BackgroundTrans", "HBITMAP:*" hTile)
        if (img != "") {
            isz := sz - 8
            hIcon := StratInfo_IconBitmap(img, isz)
            if (hIcon) {
                StratInfoBitmaps.Push(hIcon)
                g.Add("Picture", "x" (tx + 4) " y" (y + 4) " w" isz " h" isz " +BackgroundTrans", "HBITMAP:*" hIcon)
            } else {
                g.Add("Picture", "x" (tx + 4) " y" (y + 4) " w" isz " h" isz " +BackgroundTrans", img)
            }
        }
        StratInfoTiles.Push(Map("x", tx, "y", y, "w", sz, "h", sz, "name", name))
    }
    y += sz + 20
}

; The Modifiers section: all 12 modifiers as 6 x 2 equally spaced squares. A modifier the strat uses is shown in
; colour on a brighter plate, one it does not use is shown in grayscale on a darker plate (some icons, like Fog, look
; the same in colour and grayscale, so the plate colour is what tells on from off). Icons come from Resources\Images\ModifierIcons\ (the square shows
; the modifier's short code until the file exists). Hover a square for its name. With canEdit, an Edit button next to
; the heading lets the user click squares to turn modifiers on or off, and a Save changes button writes them to the
; strat file. Advances y.
StratInfo_Modifiers(g, raw, &y, pad, innerW, canEdit) {
    global StratInfoTiles, StratInfoBitmaps, StratInfoMods, StratInfoModsOrig, StratInfoExtras, StratInfoModTiles, StratInfoBonusTxt
    global StratInfoHead, StratInfoEditPic, StratInfoSavePic, StratInfoEditBmps, StratInfoEditRect, StratInfoSaveRect
    g.SetFont("s8 w700 c6F7785", "Segoe UI")
    StratInfoHead := g.Add("Text", "x" pad " y" y " w" (innerW - 150) " h14 Background121212", "MODIFIERS")
    g.SetFont("s9 w700 c6F7785", "Segoe UI")
    StratInfoBonusTxt := g.Add("Text", "x" (pad + innerW - 150) " y" (y - 2) " w150 h18 Right Background121212", "REWARDS  +0%")
    y += 22

    ; which modifiers the strat has: standard ones by code, anything else is kept as written when saving
    known := Map()
    for m in ModifierList()
        known[m[2]] := true
    StratInfoMods := Map(), StratInfoExtras := [], StratInfoModTiles := []
    for tok in StrSplit(RegExReplace(raw, "[;|]", ","), ",", " `t") {
        if (tok = "" || StrLower(tok) = "none")
            continue
        c := NormalizeModifierToken(tok)
        if (known.Has(c))
            StratInfoMods[c] := true
        else
            StratInfoExtras.Push(tok)
    }
    StratInfoModsOrig := StratInfoMods.Clone()

    cols := 6, rows := 2, gap := 8
    sz := (innerW - gap * (cols - 1)) // cols
    x0 := pad + (innerW - (sz * cols + gap * (cols - 1))) // 2
    ; the bitmaps carry a 6px shadow margin on every side, so they are drawn 12px larger and placed 6px up/left
    onTop := "0xff5d7396", onBottom := "0xff33425f", onStroke := "0x80ffffff"        ; on: brighter
    offTop := "0xff1b1e23", offBottom := "0xff0d0e10", offStroke := "0x14ffffff"     ; off: darker
    hPlateOn := CreateGradientButton(sz + 12, sz + 12, 10, onTop, onBottom, "0x40000000", onStroke, "", "Segoe UI", 10, 1)
    hPlateOff := CreateGradientButton(sz + 12, sz + 12, 10, offTop, offBottom, "0x40000000", offStroke, "", "Segoe UI", 10, 1)
    StratInfoBitmaps.Push(hPlateOn, hPlateOff)
    for idx, m in ModifierList() {
        isOn := StratInfoMods.Has(m[2])
        tx := x0 + Mod(idx - 1, cols) * (sz + gap)
        ty := y + ((idx - 1) // cols) * (sz + gap)
        tile := {x: tx, y: ty, w: sz, h: sz, code: m[2], plate: 0, icon: 0, bmpOn: 0, bmpOff: 0, plateOn: 0, plateOff: 0}
        imgOn := ModifierIconPath(m[1], false)
        imgOff := ModifierIconPath(m[1], true)
        bOn := 0, bOff := 0
        if (imgOn != "") {
            bOn := StratInfo_IconBitmap(imgOn, sz - 8, false)
            bOff := StratInfo_IconBitmap(imgOff, sz - 8, !InStr(imgOff, "_Gray.png"))   ; no _Gray file: grayscale on the fly
        }
        if (bOn && bOff) {
            StratInfoBitmaps.Push(bOn, bOff)
            tile.bmpOn := bOn, tile.bmpOff := bOff
            tile.plateOn := hPlateOn, tile.plateOff := hPlateOff
            tile.plate := g.Add("Picture", "x" (tx - 6) " y" (ty - 6) " w" (sz + 12) " h" (sz + 12) " +BackgroundTrans", "HBITMAP:*" (isOn ? hPlateOn : hPlateOff))
            tile.icon := g.Add("Picture", "x" (tx + 4) " y" (ty + 4) " w" (sz - 8) " h" (sz - 8) " +BackgroundTrans", "HBITMAP:*" (isOn ? bOn : bOff))
        } else {
            ; no icon yet: the plate shows the modifier's short code (white on the bright plate when on, grey on the dark plate when off)
            tile.bmpOn := CreateGradientButton(sz + 12, sz + 12, 10, onTop, onBottom, "0x40000000", onStroke, StrUpper(m[2]), "Segoe UI", 11, 1, "0xFFFFFFFF")
            tile.bmpOff := CreateGradientButton(sz + 12, sz + 12, 10, offTop, offBottom, "0x40000000", offStroke, StrUpper(m[2]), "Segoe UI", 11, 1, "0xFF6F7785")
            StratInfoBitmaps.Push(tile.bmpOn, tile.bmpOff)
            tile.plate := g.Add("Picture", "x" (tx - 6) " y" (ty - 6) " w" (sz + 12) " h" (sz + 12) " +BackgroundTrans", "HBITMAP:*" (isOn ? tile.bmpOn : tile.bmpOff))
        }
        StratInfoModTiles.Push(tile)
        StratInfoTiles.Push(Map("x", tx, "y", ty, "w", sz, "h", sz, "name", m[3] "  (+" ModifierBonus(m[2]) "%)"))
    }
    y += rows * sz + (rows - 1) * gap
    StratInfo_UpdateBonus()
    y += 20
}

; The Info window: a dark, borderless window in the macro's style (no Windows message box, so no system sound).
; Drag the top bar to move it; close it with the X or Escape. Hover a unit square to see the unit's name.
StratInfo(title := "Unknown strat", author := "", towers := "", mods := "", desc := "", accent := "3A86FF", path := "") {
    global StratInfoGui
    StratInfo_Close()
    global StratInfoW, StratInfoTiles, StratInfoPath, StratInfoEdit, StratInfoLower, StratInfoBaseH, StratInfoBitmaps
    global StratInfoEditPic, StratInfoEditBmps, StratInfoEditRect, StratInfoSavePic, StratInfoSaveRect
    global StratInfoTitleTxt, StratInfoAuthorTxt, StratInfoByLbl, StratInfoTitleH, StratInfoTitleEdit, StratInfoAuthorEdit, StratInfoDescEdit
    global StratInfoTitleFrame, StratInfoAuthorFrame, StratInfoDescFrame, StratInfoDescHead, StratInfoDescTxt, StratInfoDescH
    global StratInfoHasDesc, StratInfoLowerY, StratInfoFooter, StratInfoOrig
    global StratInfoDescView, StratInfoDescTrack, StratInfoDescThumb, StratInfoDescLineH, StratInfoDescVis
    W := 460, pad := 22, innerW := W - pad * 2
    StratInfoW := W
    StratInfoTiles := []
    StratInfoPath := path, StratInfoEdit := false
    g := Gui("-Caption +Border +Owner" MainGui.Hwnd)
    StratInfoGui := g
    g.BackColor := "121212"
    g.MarginX := 0, g.MarginY := 0

    ; top bar (drag to move) with title and close button
    ; (clicks on the bar and the X are handled by StratInfo_Click)
    g.Add("Text", "x0 y0 w" W " h38 Background0A0A0A", "")
    g.SetFont("s10 w600 cFFFFFF", "Segoe UI")
    g.Add("Text", "x" pad " y0 w300 h38 +0x200 +BackgroundTrans", "Strategy Info")
    g.SetFont("s11 w400 cB8BEC8", "Segoe UI")
    g.Add("Text", "x" (W - 42) " y0 w42 h38 +0x200 Center Background0A0A0A", Chr(0x2715))

    ; Edit / Cancel button in the top bar (clicks are handled by StratInfo_Click)
    if (path != "") {
        hEdit := CreateGradientButton(76, 36, 6, "0xFF3B7BD1", "0xFF1F4A8A", "0x40000000", "0x5dffffff", "Edit", "Segoe UI", 9, 1)
        hCancel := CreateGradientButton(76, 36, 6, "0xff3a404c", "0xff1d2026", "0x40000000", "0x5dffffff", "Cancel", "Segoe UI", 9, 1)
        StratInfoBitmaps.Push(hEdit, hCancel)
        StratInfoEditBmps := [hEdit, hCancel]
        ex := W - 42 - 14 - 64, ey := 7
        StratInfoEditPic := g.Add("Picture", "x" (ex - 6) " y" (ey - 6) " w76 h36 +BackgroundTrans", "HBITMAP:*" hEdit)
        StratInfoEditRect := [ex, ey, 64, 24]
    }

    ; accent strip under the bar
    g.Add("Text", "x0 y38 w" W " h2 Background" accent, "")

    y := 58
    canEdit := (path != "")
    rawTitle := "", rawAuthor := "", rawDesc := ""
    if (canEdit) {
        rawTitle := IniRead(path, "Info", "title", "")
        rawAuthor := IniRead(path, "Info", "author", "")
        rawDesc := StrReplace(IniRead(path, "Info", "desc", ""), "\n", "`r`n")
    }
    StratInfoOrig := Map("title", rawTitle, "author", rawAuthor, "desc", rawDesc)

    ; title (+ edit box shown in edit mode)
    g.SetFont("s14 w700 cFFFFFF", "Segoe UI")
    t := g.Add("Text", "x" pad " y" y " w" innerW " +BackgroundTrans", title)
    t.GetPos(, , , &th)
    StratInfoTitleTxt := t, StratInfoTitleH := th
    if (canEdit) {
        StratInfoTitleFrame := g.Add("Text", "x" (pad - 1) " y" (y - 2) " w" (innerW + 2) " h" (th + 4) " Background3A404C Hidden", "")
        StratInfoTitleEdit := g.Add("Edit", "x" pad " y" (y - 1) " w" innerW " h" (th + 2) " -E0x200 -VScroll Limit100 Background1B1E23 Hidden", rawTitle)
        StratInfo_Cue(StratInfoTitleEdit, "Strategy name")
    }
    y += th + 2

    ; author (+ edit box shown in edit mode)
    g.SetFont("s9 w400 c8A93A3", "Segoe UI")
    StratInfoAuthorTxt := g.Add("Text", "x" pad " y" y " w" innerW " h18 +BackgroundTrans", author != "" ? "by " author : "")
    if (canEdit) {
        StratInfoByLbl := g.Add("Text", "x" pad " y" (y + 1) " w20 h18 +BackgroundTrans Hidden", "by")
        StratInfoAuthorFrame := g.Add("Text", "x" (pad + 21) " y" (y - 2) " w" (innerW - 21) " h24 Background3A404C Hidden", "")
        g.SetFont("s9 w400 cFFFFFF", "Segoe UI")
        StratInfoAuthorEdit := g.Add("Edit", "x" (pad + 22) " y" (y - 1) " w" (innerW - 23) " h22 -E0x200 -VScroll Limit60 Background1B1E23 Hidden", rawAuthor)
        StratInfo_Cue(StratInfoAuthorEdit, "Unknown")
    }
    y += (author != "" || canEdit) ? 28 : 10

    StratInfo_Units(g, towers, &y, pad, innerW)
    StratInfo_Modifiers(g, mods, &y, pad, innerW, path != "")
    ; description, footer and the Save button: placed for the current mode by StratInfo_Layout
    StratInfoLowerY := y
    StratInfoHasDesc := (desc != "")
    g.SetFont("s8 w700 c6F7785", "Segoe UI")
    StratInfoDescHead := g.Add("Text", "x" pad " y" y " w" innerW " h14 +BackgroundTrans", "DESCRIPTION")
    g.SetFont("s9 w400 cC5CBD3", "Segoe UI")
    StratInfoDescTxt := g.Add("Text", "x" pad " y" (y + 20) " w" innerW " +BackgroundTrans", StrReplace(desc, "\n", "`n"))
    ; viewport used instead of the text above when the description is longer than StratInfoDescVis lines:
    ; a read-only edit box without its own scroll bar, plus a scroll bar drawn like the library's (6px track + blue thumb)
    StratInfoDescView := g.Add("Edit", "x" pad " y" y " w" (innerW - 14) " h60 Multi ReadOnly -VScroll -E0x200 -Tabstop Background121212 Hidden", "A`r`nA")
    SendMessage(0xD3, 3, 0, StratInfoDescView)               ; EM_SETMARGINS: no inner margins, so it lines up with the other text
    p0 := SendMessage(0xD6, 0, 0, StratInfoDescView)         ; EM_POSFROMCHAR: where line 1 and line 2 start -> the edit's real line height
    p1 := SendMessage(0xD6, 3, 0, StratInfoDescView)
    lineH := ((p1 >> 16) & 0xFFFF) - ((p0 >> 16) & 0xFFFF)
    if (lineH < 8 || lineH > 40)
        lineH := Max(12, StratInfo_MeasureH("A`nA", innerW, "s9 w400") - StratInfo_MeasureH("A", innerW, "s9 w400"))
    StratInfoDescLineH := lineH
    StratInfoDescView.Value := ""
    StratInfoDescView.Move(, , , lineH * StratInfoDescVis)
    hTrack := CreateScrollThumb(6, lineH * StratInfoDescVis, 3, "0xff000000", "0xff000000", "0x000000")
    hThumb0 := CreateScrollThumb(6, 30, 3, "0xFF6EA7FF", "0xff4076ce", "0xd4d4d4")
    StratInfoBitmaps.Push(hTrack, hThumb0)
    StratInfoDescTrack := g.Add("Picture", "x" (pad + innerW - 6) " y" y " w6 h" (lineH * StratInfoDescVis) " +BackgroundTrans Hidden", "HBITMAP:*" hTrack)
    StratInfoDescThumb := g.Add("Picture", "x" (pad + innerW - 6) " y" y " w6 h30 +BackgroundTrans Hidden", "HBITMAP:*" hThumb0)
    StratInfo_DescSetup(StrReplace(desc, "\n", "`n"))
    if (canEdit) {
        StratInfoDescFrame := g.Add("Text", "x" (pad - 1) " y" (y + 19) " w" (innerW + 2) " h98 Background3A404C Hidden", "")
        g.SetFont("s9 w400 cFFFFFF", "Segoe UI")
        StratInfoDescEdit := g.Add("Edit", "x" pad " y" (y + 20) " w" innerW " h96 Multi +VScroll -E0x200 Background1B1E23 Hidden", rawDesc)
        hSave := CreateGradientButton(innerW + 12, 44, 8, "0xFF147A6E", "0xFF214B75", "0x40000000", "0x5dffffff", "Save changes", "Segoe UI", 11, 1)
        StratInfoBitmaps.Push(hSave)
        StratInfoSavePic := g.Add("Picture", "x" (pad - 6) " y" y " w" (innerW + 12) " h44 +BackgroundTrans Hidden", "HBITMAP:*" hSave)
    }
    g.SetFont("s8 w400 c6F7785", "Segoe UI")
    StratInfoFooter := g.Add("Text", "x" pad " y" y " w" innerW " h16 +BackgroundTrans", StratInfo_Note())
    y := StratInfo_Layout()
    StratInfoBaseH := y

    g.OnEvent("Escape", StratInfo_Escape)
    g.OnEvent("Close", StratInfo_Close)
    OnMessage(0x0201, StratInfo_Click)
    OnMessage(0x020A, StratInfo_Wheel)
    SetTimer(StratInfo_Hover, 30)

    ; centre it over the macro window
    try {
        MainGui.GetPos(&mx, &my, &mw, &mh)
        g.Show("Hide w" W " h" y)
        g.GetPos(, , &gw, &gh)
        g.Show("x" (mx + (mw - gw) // 2) " y" (my + (mh - gh) // 2) " w" W " h" y)
    } catch {
        g.Show("w" W " h" y)
    }
}

; Writes the modifiers= line of a strategy file. Returns true when it was saved.
SaveModifiersToStrategyFile(path, modStr) {
    if (path = "" || !FileExist(path))
        return false
    try {
        IniWrite(modStr, path, "Settings", "modifiers")
        AuditLog("INFO", "Library", "Saved modifiers to " path ": " modStr)      ; audit file only, not the on-screen Debug Console
        return true
    } catch {
        return false
    }
}
