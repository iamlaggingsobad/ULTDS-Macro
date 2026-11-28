; ======================================================================================================================
; Window: The main window: tabs, dragging, hover effects, links, help popups and the tool launchers.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

WM_LBUTTONDOWN_Drag(wParam, lParam, msg, hwnd) {
    global MainGui
    If (MainGui) {
        if (hwnd != MainGui.Hwnd) {
            return
        }
    }
    mouseY := lParam >> 16
    if (mouseY >= 42)
        return

    PostMessage(0xA1, 2, , , "ahk_id " MainGui.Hwnd)
}

RemoveInitialFocus() {
    if !WinActive("ahk_id " MainGui.Hwnd)
        return
    ControlFocus(GuiTitleCtrl, "ahk_id " MainGui.Hwnd)
}

SelectTab(ctrl, *) {
    global CurrentTab, TabCtrl, TabLine, HoverTab
    idx := 0
    Loop HoverTab.Length {
        if (TabCtrl[A_Index] = ctrl) {
            idx := A_Index
            break
        }
    }
    if (!idx)
        return
    newTab := "Tab" idx
    if (newTab = CurrentTab)
        return
    
    oldIdx := Integer(SubStr(CurrentTab, 4))
    TabCtrl[oldIdx].SetFont("c888888")
    HideAllTabContent()
    
    CurrentTab := newTab
    TabCtrl[idx].SetFont("cFFFFFF")
    
    
    newX := 20 + (idx - 1) * 90
    TabLine.Move(newX, , 80)
    
    ShowTabContent(newTab)
}

Hoverwatchdog(*) {
    static hClose := 0, hMin := 0, hMain := 0, hChild := 0
    static hoverClose := false, hoverMin := false, hoverTabs := []
    loop HoverTab.Length {
        hoverTabs.Push(false)
    }
    static activeHoverHwnd := 0
    static activeGradHwnd := 0 
    static tipText := "", tipShown := "", tipSince := 0
    
    if (!hMain)
        hMain := MainGui.Hwnd
        
    if (!hChild && IsSet(ChildGui))
        hChild := ChildGui.Hwnd
    
    oldMode := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&screenX, &screenY, &mouseWin, &mouseCtrl, 2)
    CoordMode("Mouse", oldMode)
    
    try {
        WinGetPos(&mX, &mY,,, "ahk_id " hMain)
        mouseX := screenX - mX
        mouseY := screenY - mY
    } catch {
        mouseX := 0
        mouseY := 0
    }
    
    if (mouseWin != hMain && mouseWin != hChild) {
        Loop HoverTab.Length {
            if (hoverTabs[A_Index]) {
                HoverTab[A_Index].Visible := false
                if (CurrentTab != "Tab" A_Index)
                    TabCtrl[A_Index].SetFont("c888888")
                hoverTabs[A_Index] := false
            }
        }
        if (hoverClose) { 
            BtnClose.SetFont("cFFFFFF")
            hoverClose := false 
        }
        if (hoverMin) { 
            BtnMin.SetFont("cFFFFFF")
            hoverMin := false 
        }
        
        if (activeHoverHwnd != 0 && IsSet(HoverEffect)) {
            for ctrl in HoverEffect {
                if (ctrl.Hwnd = activeHoverHwnd) {
                    if RegExMatch(ctrl.name, "i)Title") {
                        ctrl.Opt("BackgroundTrans")
                        ctrl.SetFont("c3A86FF Norm")
                    } else {
                        ctrl.Opt("Background0E0E0F")
                        ctrl.SetFont("cFFFFFF Norm")
                    }
                    ctrl.Redraw()
                    break
                }
            }
            activeHoverHwnd := 0
        }
        
        if (activeGradHwnd != 0 && IsSet(GradientButtons)) {
            for ctrl in GradientButtons {
                if (ctrl.Hwnd = activeGradHwnd) {
                    if (HasProp(ctrl, "PicControl"))
                        ctrl.PicControl.Value := "HBITMAP:*" ctrl.ImgNormal
                    ctrl.Redraw()
                    break
                }
            }
            activeGradHwnd := 0
        }
        ; mouse is over another window: hide any icon tooltip too
        if (tipShown != "") {
            ToolTip(, , , 20)
            tipShown := ""
        }
        tipText := ""
        return
    }
    
    if (!hClose) {
        hClose := BtnClose.Hwnd
        hMin := BtnMin.Hwnd
    }
    
    if (mouseCtrl = hClose) {
        if (!hoverClose) { 
            BtnClose.SetFont("cFF4D4D")
            hoverClose := true 
        }
    } else if (hoverClose) { 
        BtnClose.SetFont("cFFFFFF")
        hoverClose := false 
    }

    if (mouseCtrl = hMin) {
        if (!hoverMin) { 
            BtnMin.SetFont("c3A86FF")
            hoverMin := true 
        }
    } else if (hoverMin) { 
        BtnMin.SetFont("cFFFFFF")
        hoverMin := false 
    }
    
    Loop HoverTab.Length {
        hTab := TabCtrl[A_Index].Hwnd
        if (mouseCtrl = hTab) {
            if (!hoverTabs[A_Index]) {
                HoverTab[A_Index].Visible := true
                TabCtrl[A_Index].SetFont("cFFFFFF")
                hoverTabs[A_Index] := true
            }
        } else if (hoverTabs[A_Index]) {
            if (CurrentTab != "Tab" A_Index) {
                HoverTab[A_Index].Visible := false
                TabCtrl[A_Index].SetFont("c888888")
            } else {
                HoverTab[A_Index].Visible := false
            }
            hoverTabs[A_Index] := false
        }
    }

    if (IsSet(HoverEffect)) {
        matchedAny := false
        for ctrl in HoverEffect {
            if (!ctrl.Visible)
                continue
            ctrl.GetPos(&cX, &cY, &cW, &cH)
            if (mouseX >= cX && mouseX <= cX + cW && mouseY >= cY && mouseY <= cY + cH) {
                matchedAny := true
                if (activeHoverHwnd != ctrl.Hwnd) {
                    if (activeHoverHwnd != 0) {
                        for oldCtrl in HoverEffect {
                            if (oldCtrl.Hwnd = activeHoverHwnd) {
                                if RegExMatch(oldCtrl.name, "i)title") {
                                    oldCtrl.Opt("BackgroundTrans")
                                    oldCtrl.SetFont("c3A86FF Norm")
                                } else {
                                    oldCtrl.Opt("Background0E0E0F")
                                    oldCtrl.SetFont("cFFFFFF Norm")
                                }
                                oldCtrl.Redraw()
                                break
                            }
                        }
                    }
                    ctrl.Opt("Background222222")
                    ctrl.SetFont("c3A86FF Bold")
                    ctrl.Redraw()
                    activeHoverHwnd := ctrl.Hwnd
                }
                break
            }
        }
        if (!matchedAny && activeHoverHwnd != 0) {
            for ctrl in HoverEffect {
                if (ctrl.Hwnd = activeHoverHwnd) {
                    if RegExMatch(ctrl.name, "i)title") {
                        ctrl.Opt("BackgroundTrans")
                        ctrl.SetFont("c3A86FF Norm")
                    } else {
                        ctrl.Opt("Background0E0E0F")
                        ctrl.SetFont("cFFFFFF Norm")
                    }
                    ctrl.Redraw()
                    break
                }
            }
            activeHoverHwnd := 0
        }
    }

    
    if (IsSet(GradientButtons) && hChild) {
        matchedGrad := false
        
        try {
            WinGetPos(&chX, &chY,,, "ahk_id " hChild)
            childMouseX := screenX - chX
            childMouseY := screenY - chY
        } catch {
            childMouseX := 0
            childMouseY := 0
        }
        
        for ctrl in GradientButtons {
            if (!ctrl.Visible)
                continue

            ctrl.GetPos(&cX, &cY, &cW, &cH)
            
            if (childMouseX >= cX && childMouseX <= cX + cW && childMouseY >= cY && childMouseY <= cY + cH) {
                matchedGrad := true
                if (activeGradHwnd != ctrl.Hwnd) {
                    
                    if (activeGradHwnd != 0) {
                        for oldCtrl in GradientButtons {
                            if (oldCtrl.Hwnd = activeGradHwnd) {
                                if (HasProp(oldCtrl, "PicControl"))
                                    oldCtrl.PicControl.Value := "HBITMAP:*" oldCtrl.ImgNormal
                                oldCtrl.Redraw()
                                break
                            }
                        }
                    }
                    
                    if (HasProp(ctrl, "PicControl")) {
                        ctrl.PicControl.Value := "HBITMAP:*" ctrl.ImgHover
                    }
                    ctrl.Redraw()
                    activeGradHwnd := ctrl.Hwnd
                }
                break
            }
        }
         
        if (!matchedGrad && activeGradHwnd != 0) {
            for ctrl in GradientButtons {
                if (ctrl.Hwnd = activeGradHwnd) {
                    if (HasProp(ctrl, "PicControl"))
                        ctrl.PicControl.Value := "HBITMAP:*" ctrl.ImgNormal
                    ctrl.Redraw()
                    break
                }
            }
            activeGradHwnd := 0
        }
    }

    ; tooltips for the icon plates in the library: show after the mouse rests on a plate for a moment
    if (IsSet(StratTips) && hChild && DllCall("IsWindowVisible", "Ptr", hChild)) {
        newTip := ""
        try {
            MouseGetPos(, , &underHwnd)
            if (DllCall("GetAncestor", "Ptr", underHwnd, "UInt", 2, "Ptr") = hMain) {
                WinGetPos(&tipWX, &tipWY, &tipWW, &tipWH, "ahk_id " hChild)
                tipMX := screenX - tipWX, tipMY := screenY - tipWY
                if (tipMX >= 0 && tipMX < tipWW && tipMY >= 0 && tipMY < tipWH) {
                    for tipC in StratTips {
                        tipC.GetPos(&tcX, &tcY, &tcW, &tcH)
                        if (tipMX >= tcX && tipMX < tcX + tcW && tipMY >= tcY && tipMY < tcY + tcH) {
                            newTip := tipC.Tip
                            break
                        }
                    }
                }
            }
        }
        if (newTip != tipText) {
            tipText := newTip
            tipSince := A_TickCount
            if (tipShown != "") {
                ToolTip(, , , 20)
                tipShown := ""
            }
        }
        if (tipText != "" && tipShown != tipText && A_TickCount - tipSince >= 250) {
            ToolTip(tipText, , , 20)
            tipShown := tipText
        }
    } else if (tipShown != "") {
        ToolTip(, , , 20)
        tipShown := ""
        tipText := ""
    }
}

HideAllTabContent() {
    global ChildGui, MainGui, SystemHwnds
    for hwnd, ctrl in MainGui {
        if (SystemHwnds.Has(hwnd))
            continue

        try {
            ctrl.Visible := false
        }
    }
    ChildGui.Hide()
}

ShowTabContent(tab) {
    global ChildGui
    if (tab = "Tab1") {
        for ctrl in [Tab1_Section1, Tab1_Line1, Tab1_Lbl1, Strategy1Ctrl, Tab1_Btn1, Tab1_Btn2,
                     Tab1_Lbl2, Strategy2Ctrl, Tab1_Btn3, Tab1_Btn4, RotateStrategiesCtrl, AutoEquipCtrl, Tab1_Lbl3, TimeScaleModeCtrl, Tab1_Section2, Tab1_Line2,
                     Tab1_AddBtn, Tab1_FolderBtn, Tab1_RefreshBtn,
                     Tab1_Start, Tab1_Stop]
            ctrl.Visible := true
        TimeScaleModeCtrl.Text := TimeScaleMode
        EnableStratRotation()
        ShowChildGui()
    } else if (tab = "Tab2") {
        for ctrl in [Tab2_Title, Tab2_Line1, Tab2_Lbl1, RecMapsD, Tab2_Lbl2, RecDiffCtrl,
                     Tab2_Lbl3, RecModifiersCtrl, Tab2_Info2, Tab2_Lbl4, RecTowersCtrl, Tab2_Info1,
                     Tab2_Line2, Tab2_Line3, RecAutoChainCtrl, RecAutoCaravanCtrl, RecAutoDropCtrl,
                     RecAutoSkipCtrl, RecAbilitySpamCtrl, Tab2_Info, RecMoveCtrl, DIRECTIONTEXTCtrl, RecMoveDirCtrl,
                     Tab2_Txt4, RecMoveDurCtrl, Tab2_Btn1, Tab2_Btn2]
            ctrl.Visible := true
    } else if (tab = "Tab3") {
        for ctrl in TAB3
            ctrl.Visible := true
    } else if (tab = "Tab4") {
        for ctrl in DiscordWebhookTab
            ctrl.Visible := true
        tab4_Title.Text := "Discord Webhook"
        EnableWebhookLink2()
} else if (tab = "Tab5") {
        for ctrl in [Tab5_Section1, Tab5_Line1, Tab5_Lbl1, ChainKeyCtrl,
                     Tab5_Lbl2, BeatKeyCtrl, Tab5_Lbl3, CaravanKeyCtrl,
                     Tab5_Lbl44, RaiseDeadKeyCtrl, Tab5_Lbl55, Tab5_Lbl56, HologramKeyCtrl, RepoKeyCtrl,
                     Tab5_Lbl99, Tab5_LblUPG, Tab5_LblUPGBTM, CancelPlacementKeyCtrl, UpgradeTowerGCtrl, UpgradeTowerGBCtrl, Tab1_Lbl4, UpgradeDelayCtrl,
                     Tab5_Section2, Tab5_Line2, Tab5_Help6,
                     UseRestartBtnCtrl, Tab5_Help4, UsePlayAgainBtnCtrl, Tab5_Help5,
                     CheckTheMapCtrl, UseNumbersForHotbarCtrl, UseUpgradeHCtrl, Tab5_Help7, Tab5_Help11, Tab5_Help12, PotatoModeCtrl, DebugConsoleCtrl,
                     Tab5_Section3, Tab5_Line3, PlcTowerTEXT, UpgTowerTEXT, AlignCamTEXT,
                     DjTrackTEXT, SellTowTEXT, DelRecTEXT, RecInputsTEXT,
                     HoloTEXT, RaiseDeadTEXT,
                     PlaceTowerKeyCtrl, UpgradeTowerKeyCtrl, AlignCameraKeyCtrl,
                     ChangeDJTrackKeyCtrl, SellTowerKeyCtrl, DeleteTowerRecordingKeyCtrl,
                     RecordInputsKeyCtrl, HoloKeyCtrl, ChangeTargetsCTRL,
                     CollectPlaytimeRewardsCtrl, AutoCloseChatCtrl,
                     Tab5_Line4, Tab5_Lbl4, VipLinkCtrl, UseVipServerCtrl, AlwaysOnTopCtrl, LegacyModeCtrl, Tab5_Btn1,
                     MouseSpeedLbl, MouseSpeedTxt, MouseSpeedUpDown,
                     MouseDelayLbl, MouseDelayTxt, MouseDelayUpDown, KeyDelayLbl, KeyDelayTxt, KeyDelayUpDown]
            ctrl.Visible := true

        
        ChainKeyCtrl.Value := ChainKey
        BeatKeyCtrl.Value := BeatKey
        CaravanKeyCtrl.Value := CaravanKey
        RaiseDeadKeyCtrl.Value := RaiseDeadKey     
        HologramKeyCtrl.Value := HologramKey
        RepoKeyCtrl.Value := RepoKey       
        CancelPlacementKeyCtrl.Value := CancelPlacementKey
        AlignCameraKeyCtrl.Value := AlignCameraKey
        PlaceTowerKeyCtrl.Value := PlaceTowerKey
        UpgradeTowerKeyCtrl.Value := UpgradeTowerKey
        SellTowerKeyCtrl.Value := SellTowerKey
        DeleteTowerRecordingKeyCtrl.Value := DeleteTowerRecordingKey
        ChangeDJTrackKeyCtrl.Value := ChangeDJTrackKey
        RecordInputsKeyCtrl.Value := RecordInputsKey
        HoloKeyCtrl.Value := HoloKey
        ChangeTargetsCTRL.Value := ChangeTargetsKey
        TimeScaleModeCtrl.Text := TimeScaleMode
        
        MouseSpeedUpDown.Value := DefaultMouseSpeed
        MouseSpeedTxt.Value := DefaultMouseSpeed
        MouseDelayUpDown.Value := MouseDelay
        MouseDelayTxt.Value := MouseDelay
        KeyDelayUpDown.Value := KeyDelay
        KeyDelayTxt.Value := KeyDelay
        UpgradeDelayCtrl.Value := UpgradeDelay

    } else if (tab = "Tab6") {
        for ctrl in [Tools_Section, Tools_Section_Line, Tools_Info, Auto_COA, Auto_Spin, Auto_Consum, Tools_AuditBtn, Tools_AuditInfo]
            ctrl.Visible := true
    }
}

ShowChildGui() {
    global ChildGui, FrameX, FrameY, FrameW, FrameH, MainGui
    ChildGui.Show("x" FrameX " y" FrameY " w" FrameW " h" FrameH)
}

MoveWindow(ctrl, *) {
    PostMessage(0xA1, 2, , , MainGui)
}

MinimizeWindow(ctrl, *) {
    MainGui.Minimize()
}

CloseWindow(ctrl, *) {
    ExitApp()
}

DiscordLink(ctrl, *) {
    Run("https://discord.gg/DQnc2JDJtr")
}

githubLink(ctrl, *) {
    Run("https://github.com/DarksenDev/tds-macro")
}

YouTubeLink(ctrl, *) {
    Run("https://www.youtube.com/@darksenn")
}

HelpRestartBtn(*) {
    ModernMsgBox("Info", "If this setting is ON, the macro will use the restart button when you lose.`n`nIt's recommended to turn it OFF if you are using a win strategy and your macro sometimes appears on the wrong map.", "OK")
}

HelpPlayAgainBtn(*) {
    ModernMsgBox("Info", "If this setting is ON, the macro will use the play again button when you win.", "OK")
}

HelpAutoCameraCorrection(*) {
    ModernMsgBox("Info", "The macro will use tds keybind when upgrading the tower.`n`nIt's recommended to turn it ON.", "OK")
}

HelpBrawler(*) {
    ModernMsgBox("Info", "To record brawler reposition, press CTRL+your keybind", "OK")
}

HelpRaise(*) {
    ModernMsgBox("Info", "To record raise the dead, press CTRL+your keybind", "OK")
}

HelpCheckTheMap(*) {
    ModernMsgBox("Info", "When you join the map, the macro will check is it in the correct map or not. If no, it reloads.`n`nIt's recommended to turn it ON.", "OK")
}

RunAutoAbTool(*) {
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\auto_coa.ahk" ')
    } else {
        Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\auto_coa.ahk" ')
    }
}

RunAutoSpinTool(*) {
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\auto_spin.ahk" ')
    } else {
        Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\auto_spin.ahk" ')
    }
}

RunAutoConsumableTool(*) {
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\auto_open_consumable.ahk" ')
    } else {
        Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\auto_open_consumable.ahk" ')
    }
}
