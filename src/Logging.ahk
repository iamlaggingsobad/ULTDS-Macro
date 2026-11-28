; ======================================================================================================================
; Logging: The audit log (file and viewer) and the Debug Console overlay.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

; ---------------------------------------------------------------------------
; Audit log: a persistent record of warnings, errors and recoveries.
; Saved to Logs\audit_log.tsv (survives stopping/reloading the macro).
; View it from the Tools tab -> "Open Audit Log", or from the tray icon menu.
; Levels: INFO, WARN, ERROR, RECOVERED
; ---------------------------------------------------------------------------
AuditLog(level, category, message) {
    global AuditLogDir, AuditLogFile, AuditMaxBytes, AuditLastKey, AuditLastTick, CurrentStrategyFile
    try {
        ; Ignore an identical entry repeated within 2 seconds (keeps tight retry loops readable)
        key := level "|" category "|" message
        if (key = AuditLastKey && A_TickCount - AuditLastTick < 2000)
            return
        AuditLastKey := key
        AuditLastTick := A_TickCount

        if !DirExist(AuditLogDir)
            DirCreate(AuditLogDir)
        if (FileExist(AuditLogFile) && FileGetSize(AuditLogFile) > AuditMaxBytes) {
            try FileMove(AuditLogFile, AuditLogDir "\audit_log.old.tsv", 1)
        }

        strat := ""
        if (CurrentStrategyFile != "")
            SplitPath(CurrentStrategyFile, &strat)

        clean := StrReplace(StrReplace(StrReplace(message, "`r"), "`n", " "), "`t", " ")
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "`t" level "`t" category "`t" clean "`t" strat "`n", AuditLogFile, "UTF-8-RAW")
    }
}

; Called from LogToConsole: anything the macro already reports as a failure/retry/timeout is also audited.
AuditAuto(text) {
    try {
        ; Placement retries are audited explicitly (with attempts and final position) in SpawnTower.
        if RegExMatch(text, "i)placement failed, retrying")
            return
        level := ""
        if RegExMatch(text, "i)\bERROR\b|timed out|reloading|safereload|can't see|cannot see|couldn't|could not|never (found|appeared)|not found|was not detected|refusing|out of tickets|can't be moved")
            level := "ERROR"
        else if RegExMatch(text, "i)failed|retrying|cannot place|no cash|stunned|didn't register|did not register|not enough")
            level := "WARN"
        if (level = "")
            return
        AuditLog(level, AuditCategory(text), text)
    }
}

AuditCategory(text) {
    if RegExMatch(text, "i)clone|hologram")
        return "Clone"
    if RegExMatch(text, "i)reposition|brawler")
        return "Reposition"
    if RegExMatch(text, "i)place|placement")
        return "Placement"
    if RegExMatch(text, "i)upgrade|sell")
        return "Upgrade/Sell"
    if RegExMatch(text, "i)equip")
        return "Equip"
    if RegExMatch(text, "i)party|invite")
        return "Party"
    if RegExMatch(text, "i)ready|timescale|match")
        return "Match start"
    if RegExMatch(text, "i)webhook|screenshot|discord")
        return "Webhook"
    if RegExMatch(text, "i)roblox|lobby|join|map|difficulty|mode")
        return "Join/Lobby"
    if RegExMatch(text, "i)executing step|step")
        return "Strategy step"
    return "General"
}

; Logs unhandled script errors (like "Item has no value") before the normal error dialog appears.
AuditOnError(err, mode) {
    where := ""
    detail := ""
    try where := " | " err.What " (line " err.Line ")"
    try detail := (err.Extra != "") ? " | " err.Extra : ""
    AuditLog("ERROR", "Unhandled error", err.Message detail where)
    return 0
}

ShowAuditLog(*) {
    global AuditGui, AuditLV, AuditFilter, AuditCountTxt, AuditLogDir
    if IsObject(AuditGui) {
        try {
            AuditGui.Show()
            AuditRefresh()
            return
        }
        AuditGui := 0
    }

    AuditGui := Gui("+Resize +MinSize760x420", "Macro Audit Log")
    AuditGui.BackColor := "141416"
    AuditGui.SetFont("s9 cEEEEEE", "Segoe UI")

    AuditGui.Add("Text", "x12 y14 w40", "Show:")
    AuditFilter := AuditGui.Add("DropDownList", "x56 y10 w130 Choose1", ["All", "Errors", "Warnings", "Recoveries", "Info"])
    AuditFilter.OnEvent("Change", AuditRefresh)

    btnRefresh := AuditGui.Add("Button", "x200 y9 w80 h26", "Refresh")
    btnRefresh.OnEvent("Click", AuditRefresh)
    btnFile := AuditGui.Add("Button", "x288 y9 w90 h26", "Open file")
    btnFile.OnEvent("Click", AuditOpenFile)
    btnFolder := AuditGui.Add("Button", "x386 y9 w100 h26", "Open folder")
    btnFolder.OnEvent("Click", AuditOpenFolder)
    btnClear := AuditGui.Add("Button", "x494 y9 w90 h26", "Clear log")
    btnClear.OnEvent("Click", AuditClear)

    AuditCountTxt := AuditGui.Add("Text", "x12 y44 w730 h18", "")
    AuditLV := AuditGui.Add("ListView", "x12 y66 w736 h360 -Multi Grid Background1C1C20 cEEEEEE", ["Time", "Level", "Category", "Message", "Strategy"])
    AuditLV.OnEvent("DoubleClick", AuditRowDetail)

    AuditGui.OnEvent("Size", AuditResize)
    AuditGui.OnEvent("Close", AuditClose)
    AuditGui.Show("w760 h440")
    AuditRefresh()
}

AuditClose(*) {
    global AuditGui
    AuditGui.Hide()
}

AuditResize(thisGui, minMax, w, h) {
    global AuditLV
    if (minMax = -1)
        return
    AuditLV.Move(, , w - 24, h - 78)
}

AuditRefresh(*) {
    global AuditLV, AuditFilter, AuditCountTxt, AuditLogFile
    if !IsObject(AuditLV)
        return

    wanted := ""
    switch AuditFilter.Text {
        case "Errors": wanted := "ERROR"
        case "Warnings": wanted := "WARN"
        case "Recoveries": wanted := "RECOVERED"
        case "Info": wanted := "INFO"
    }

    text := ""
    if FileExist(AuditLogFile) {
        try text := FileRead(AuditLogFile, "UTF-8")
    }

    entries := []
    total := 0, nErr := 0, nWarn := 0, nRec := 0
    for line in StrSplit(text, "`n", "`r") {
        if (line = "")
            continue
        f := StrSplit(line, "`t")
        if (f.Length < 4)
            continue
        total++
        if (f[2] = "ERROR")
            nErr++
        else if (f[2] = "WARN")
            nWarn++
        else if (f[2] = "RECOVERED")
            nRec++
        if (wanted = "" || f[2] = wanted)
            entries.Push(f)
    }

    AuditLV.Opt("-Redraw")
    AuditLV.Delete()
    first := Max(1, entries.Length - 2999)
    idx := entries.Length
    while (idx >= first) {
        f := entries[idx]
        AuditLV.Add("", f[1], f[2], f[3], f[4], (f.Length >= 5) ? f[5] : "")
        idx--
    }
    AuditLV.ModifyCol(1, 130)
    AuditLV.ModifyCol(2, 85)
    AuditLV.ModifyCol(3, 110)
    AuditLV.ModifyCol(4, 420)
    AuditLV.ModifyCol(5, 150)
    AuditLV.Opt("+Redraw")

    AuditCountTxt.Value := total " entries   |   " nErr " errors   |   " nWarn " warnings   |   " nRec " recovered   (newest first, double-click a row for details)"
}

AuditRowDetail(lv, row) {
    if (row < 1)
        return
    MsgBox(lv.GetText(row, 1) "   [" lv.GetText(row, 2) "]   " lv.GetText(row, 3) "`n`n" lv.GetText(row, 4) "`n`nStrategy: " lv.GetText(row, 5), "Audit entry")
}

AuditOpenFile(*) {
    global AuditLogFile
    if FileExist(AuditLogFile)
        Run('notepad.exe "' AuditLogFile '"')
    else
        MsgBox("The audit log is empty so far.", "Audit Log")
}

AuditOpenFolder(*) {
    global AuditLogDir
    if !DirExist(AuditLogDir)
        DirCreate(AuditLogDir)
    Run('explorer.exe "' AuditLogDir '"')
}

AuditClear(*) {
    global AuditLogFile
    if (MsgBox("Delete all audit log entries?", "Audit Log", "YesNo Icon?") = "Yes") {
        try FileDelete(AuditLogFile)
        AuditLog("INFO", "Audit", "Log cleared by user")
        AuditRefresh()
    }
}

ShowDebugConsole() {
    global DebugConsole, OverlayHWND, OverlayBitmap, OverlayGraphics, OverlayPicHWND, OverlaySig
    global OverlayX, OverlayY, OverlayWidth, OverlayHeight
    
    if (DebugConsole != "1" && DebugConsole != 1) {
        return
    }
    if (OverlayHWND && OverlayWindowExists()) {
        return
    }

    OverlayWidth  := Round(A_ScreenWidth  * 0.26)
    OverlayHeight := Round(A_ScreenHeight * 0.185)
    OverlayX      := Round(A_ScreenWidth  * 0.73)
    OverlayY      := Round(A_ScreenHeight * 0.76)

    og := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20 +E0x08000000 +E0x00000008 +LastFound")
    og.BackColor := "000000"
    og.Title     := "DebugOverlay"
    
    global OverlayPicCtrl := og.Add("Picture", "x0 y0 w" OverlayWidth " h" OverlayHeight " +0xE")
    OverlayPicHWND := OverlayPicCtrl.Hwnd
    OverlayHWND    := og.Hwnd
    
    og.Show("x" OverlayX " y" OverlayY " w" OverlayWidth " h" OverlayHeight " NA")
    
    WinSetTransColor("0x000000", "ahk_id " OverlayHWND)

    OverlayBitmap   := Gdip_CreateBitmap(OverlayWidth, OverlayHeight)
    OverlayGraphics := Gdip_GraphicsFromImage(OverlayBitmap)
    Gdip_SetSmoothingMode(OverlayGraphics, 4)

    OverlaySig := ""
    SetTimer(UpdateOverlay, 1000)       ; lets old lines fade away even when nothing new is logged
}

HideDebugConsole() {
    global OverlayHWND, OverlayBitmap, OverlayGraphics, OverlayPicHWND, OverlaySig
    SetTimer(UpdateOverlay, 0)
    OverlaySig := ""
    if (OverlayBitmap) { 
        Gdip_DisposeImage(OverlayBitmap)
        OverlayBitmap := 0 
    }
    if (OverlayGraphics) { 
        Gdip_DeleteGraphics(OverlayGraphics)
        OverlayGraphics := 0 
    }
    CloseOverlayWindow()
    OverlayHWND    := 0
    OverlayPicHWND := 0
}

; AutoHotkey's WinExist / WinClose ignore hidden windows and throw "Target window not found" when the window is
; gone, which used to stop the macro inside SafeReload. These two look the window up by its handle instead, so they
; work whether it is visible, hidden or already closed, and never throw.
OverlayWindowExists() {
    global OverlayHWND
    return (OverlayHWND && DllCall("IsWindow", "Ptr", OverlayHWND)) ? true : false
}

CloseOverlayWindow() {
    global OverlayHWND
    if (OverlayWindowExists())
        DllCall("PostMessage", "Ptr", OverlayHWND, "UInt", 0x10, "Ptr", 0, "Ptr", 0)      ; WM_CLOSE
}

UpdateOverlay() {
    global OverlayBitmap, OverlayGraphics, OverlayPicHWND, OverlayHWND, LogLines, LogTimes, OverlayWidth, OverlayHeight, OverlayLifetime, OverlaySig
    if (!OverlayGraphics) {
        return
    }

    ; Only the newest lines are shown, and only while they are younger than OverlayLifetime seconds (0 = no limit).
    ; A timer calls this once a second so expired lines really disappear.
    maxLinesNow := Floor(OverlayHeight / (12 * 1.4))
    startIndex := LogLines.Length + 1
    Loop Min(maxLinesNow, LogLines.Length) {
        idx := LogLines.Length - A_Index + 1
        if (OverlayLifetime > 0 && A_TickCount - LogTimes[idx] > OverlayLifetime * 1000)
            break
        startIndex := idx
    }
    sig := startIndex "|" LogLines.Length "|" (LogLines.Length ? LogTimes[LogLines.Length] : 0)
    if (sig = OverlaySig)
        return                          ; same lines as last time: nothing to redraw
    OverlaySig := sig       ; with no line left to show, the code below simply draws an empty (transparent) image

    if (IsSet(OverlayGraphics) && OverlayGraphics) {
        if (OverlayGraphics != 0 && OverlayGraphics != "") {
            try {
                Gdip_GraphicsClear(OverlayGraphics, 0x00000000)
            } catch Error as err {
                OverlayGraphics := 0 
                return
            }
        }
    }
    
    fontSize := 12
    fontName := "Consolas", style := 1
    textColor := 0xFFFFFFFF

    hFamilyOverlay := Gdip_FontFamilyCreate(fontName)
    hFontOverlay   := Gdip_FontCreate(hFamilyOverlay, fontSize, style)
    hFormatOverlay := Gdip_StringFormatCreate(0x0000)

    if (!hFormatOverlay || hFormatOverlay == 0 || !hFontOverlay || hFontOverlay == 0) {
        if (hFormatOverlay) => Gdip_DeleteStringFormat(hFormatOverlay)
        if (hFontOverlay) => Gdip_DeleteFont(hFontOverlay)
        if (hFamilyOverlay) => Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    try {
        Gdip_SetStringFormatAlign(hFormatOverlay, 0)
    } catch {
        Gdip_DeleteStringFormat(hFormatOverlay)
        Gdip_DeleteFont(hFontOverlay)
        Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    pBrushTextOverlay := Gdip_BrushCreateSolid(textColor)
    pBrushBgOverlay  := Gdip_BrushCreateSolid(0xFF111111)     ; dark grey bar behind each line (pure black would be see-through)

    if (!pBrushTextOverlay || !pBrushBgOverlay) {
        if (pBrushTextOverlay) => Gdip_DeleteBrush(pBrushTextOverlay)
        if (pBrushBgOverlay) => Gdip_DeleteBrush(pBrushBgOverlay)
        Gdip_DeleteStringFormat(hFormatOverlay)
        Gdip_DeleteFont(hFontOverlay)
        Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    maxLines   := Floor(OverlayHeight / (fontSize * 1.4))
    yPos := 5, maxWidth := OverlayWidth - 20

    wrappedLines := []
    Loop maxLines {
        idx := startIndex + A_Index - 1
        if (idx > LogLines.Length)
            break
        line := LogLines[idx]
        while (StrLen(line) > 0) {
            if (StrLen(line) * fontSize * 0.6 <= maxWidth) { 
                wrappedLines.Push(line)
                break 
            }
            cutPos := Floor(maxWidth / (fontSize * 0.6))
            wrappedLines.Push(SubStr(line, 1, cutPos))
            line := SubStr(line, cutPos + 1)
        }
    }
    while (wrappedLines.Length > maxLines)
        wrappedLines.RemoveAt(1)

    for i, line in wrappedLines {
        Gdip_FillRectangle(OverlayGraphics, pBrushBgOverlay, 5, yPos, OverlayWidth-10, fontSize * 1.4)
        CreateRectF(&RC, 5, yPos, OverlayWidth-5, fontSize * 1.4)
        try {
            Gdip_DrawString(OverlayGraphics, line, hFontOverlay, hFormatOverlay, pBrushTextOverlay, &RC)
        }
        yPos += fontSize * 1.4
    }

    Gdip_DeleteBrush(pBrushTextOverlay)
    Gdip_DeleteBrush(pBrushBgOverlay)
    Gdip_DeleteStringFormat(hFormatOverlay)
    Gdip_DeleteFont(hFontOverlay)
    Gdip_DeleteFontFamily(hFamilyOverlay)

    if (IsSet(OverlayBitmap) && OverlayBitmap) {
        try {
            hBitmap := Gdip_CreateHBITMAPFromBitmap(OverlayBitmap, 0xFF000000)   ; black background = transparent (the default is white)
            SetImage(OverlayPicHWND, hBitmap)
            DeleteObject(hBitmap)
        }
    }
}

LogToConsole(text, SendWebhookInstantly := false, flush := true) {
    global DebugConsole, LogLines, LogTimes, OverlayHWND, WebhookEnabled, WebhookLink, RunningStrategy, AutorunStartTime

    time := FormatTime(, "HH:mm:ss")
    AuditAuto(text)
    formattedText := "[" time "] " text
    LogLines.Push(formattedText)
    LogTimes.Push(A_TickCount)
    while (LogLines.Length > 500) {
        LogLines.RemoveAt(1)
        LogTimes.RemoveAt(1)
    }

    if (OverlayHWND && OverlayWindowExists())
        UpdateOverlay()

    if (WebhookEnabled && WebhookLink != "" && RunningStrategy) {
        runtime := (AutorunStartTime > 0) ? FormatRuntime(AutorunStartTime) : "00:00"
        wText := "[" runtime "] " text
        if (!SendWebhookInstantly && WebhookDebugLogs) {
            SendToWebhook(wText)
        } else if (SendWebhookInstantly) {
            SendToWebhookInstant(wText,,flush)
        }
    }
}
