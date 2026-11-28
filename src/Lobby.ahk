; ======================================================================================================================
; Lobby: Everything around the lobby and the match: Roblox start / stop, joining, parties, ready, restart, reconnect, daily rewards.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

LowerGraphics() {
    ActivateRoblox()
    SendEvent("{SC02A down}")
    Loop 10 {
        SendEvent("{SC044}")
        Sleep(20)
    }
    SendEvent("{SC02A up}")
}

EquipTowers(towers) {
    getRobloxPos(,,&rw,&rh)

    LogToConsole("Equipping towers: " towers)

    savedCloseX := 0
    savedCloseY := 0

    closeChat()
    Sleep(600)

    maxAttempts := 3
    openedMenu := false

    Loop maxAttempts {
        itemsClicked := false
        StartTime := A_TickCount
        W := Round(rw * 0.3)
        H := rh - 0

        Loop {
            resItems := AdvancedImageSearch("Resources\items.png", 0, 0, W, H)
            if (resItems.status == "success" && resItems.score > 0.56) {
                fx := resItems.x
                fy := resItems.y
                MouseMove(fx, fy + ScaleY(7), A_DefaultMouseSpeed + 1)
                Sleep(100)
                MouseClick()
                itemsClicked := true
                break
            } 
            if (A_TickCount - StartTime > 5000) {
                break
            }
            Sleep(500)
        }

        if (!itemsClicked) {
            continue
        }

        Sleep(800)

        StartTime := A_TickCount
        X1 := Round(rw * 0.2)
        Y1 := 0
        W_close := Round(rw * 1) - X1
        H_close := Round(rh * 0.4) - Y1

        Loop {
            resclose := AdvancedImageSearch("Resources\close_items.png", X1, Y1, W_close, H_close)

            if (resclose.status == "success" && resclose.score >= 0.85) {
                openedMenu := true
                savedCloseX := resclose.x
                savedCloseY := resclose.y
                break
            } 
            if (A_TickCount - StartTime > 4000) {
                break
            }
            Sleep(500)
        }

        if (openedMenu) {
            break
        }
    }

    if (!openedMenu) {
        LogToConsole("Failed to equip towers! The macro can't see the towers menu! Reloading...", true, false)
        Sleep(400)
        SafeReload()
        return
    }

    srchX := ScaleX(484)
    srchY := ScaleY(229)

    StartTime := A_TickCount
    Loop {
        resBar := AdvancedImageSearch("Resources\searchbar_items.png", 0,0,Round(rh*0.5),Round(rh*0.5))
        if (resBar.status == "success" && resBar.score > 0.67) {
            srchX := resBar.x+30
            srchY := resBar.y
            break
        }
        if (A_TickCount - StartTime > 4000)
            break
        Sleep(400)
    }

    Click(srchX, srchY)
    Sleep(150)
    if (A_KeyDelay < 5) {
    SendInput("Sniper")
    } else {
        SendText("Sniper")
    }
    Sleep(400)
    Click(srchX+10, ScaleY(409))
    Sleep(500)

    X := Round(rw * 0.61)
    Y := ScaleY(830)
    X1 := Round(rw * 0.4)
    Y1 := Round(rh * 0.4)
    W := Round(rw * 0.9) - X1
    H := rh - Y1

    StartTime := A_TickCount
    Loop {
        getRobloxPos(,,&w,&h)
        baseScale := h / 1009

        resAlign := AdvancedImageSearch("Resources\equip.png", X1, Y1, W, H, 0.5 * baseScale, 2, 0.025)

        if (resAlign.status == "success" && resAlign.score > 0.4) {
            Y := resAlign.y+ScaleY(110)
        }

        offset := -30
        baseY := Y

        MouseMove(X, Y+ ScaleY(offset))

        oldMode := A_SendMode
        oldDelay := A_MouseDelay
        SendMode("Input")
        SetMouseDelay(0)

        while (offset <= 30) {
            cY := baseY + ScaleY(offset)

            MouseClick("Left", X, cY)

            offset += 5
            Sleep 5
        }
        SendMode(oldMode)
        SetMouseDelay(oldDelay)

        Sleep(600)
        failCount := 0
        
        InnerStart := A_TickCount
        Loop {
            X1 := Round(rw * 0.4)
            Y1 := Round(rh * 0.5)
            W := Round(rw * 0.9) - X1
            H := rh - Y1

            getRobloxPos(,,&w,&h)
            baseScale := Round(h / 1009)

            resUnequip := AdvancedImageSearch("Resources\unequip.png", X1, Y1, W, H, 0.3 * baseScale, 1.4, 0.025)
            if (resUnequip.status == "success" && resUnequip.score > 0.63) {
                if (PixelSearch(&uX, &uY, resUnequip.x-ScaleX(40), resUnequip.y-ScaleY(25), resUnequip.x+ScaleX(40), resUnequip.y+ScaleY(25), 0x7A797A, 5)) {
                    Click(resUnequip.x, resUnequip.y)
                    Sleep 20
                    MouseMove(resUnequip.x, resUnequip.y-ScaleY(80))
                    failCount := 0
                    break
                } else {
                    failCount++
                    if (failCount >= 5) {
                        break 2
                    }
                    Sleep(200)
                    continue
                }
            } else {
                failCount++
                if (failCount >= 3) {
                    break 2
                }
            }
            if (A_TickCount - InnerStart > 3000)
                break
            Sleep(200)
        }
        Sleep(400)
    }
    
    Loop Parse, towers, ","
    {
        ActivateRoblox()
        tower := Trim(A_LoopField)

        goldtower := RegExMatch(tower, "i)\b(Golden|G\.|G)\b") ? true : false
        regulartower := RegExMatch(tower, "i)\b(Regular|R\.|R)\b") ? true : false

        towerToEnter := RegExReplace(tower, "i)\b(Golden|G\.|G|Regular|R\.|R)\b\s*|\.")
        towerToEnter := Trim(towerToEnter) 

        Click(srchX, srchY)
        Sleep(150)

        kdelay := A_KeyDelay
        changedDelay := false
        if (A_KeyDelay < 5) {
        SendInput(towerToEnter)
        } else {
            SendText(towerToEnter)
        }
        Sleep(500)
        Click(srchX+10, ScaleY(409))
        Sleep(500)

        X1 := Round(rw * 0.4)
        Y1 := Round(rh * 0.5)
        W := Round(rw * 0.9) - X1
        H := rh - Y1

        TowerStart := A_TickCount
        Loop {
            getRobloxPos(,,&w,&h)
            baseScale := h / 1009

            resEquip := AdvancedImageSearch("Resources\equip.png", X1, Y1, W, H, 0.5 * baseScale, 1.4, 0.025)

            if (resEquip.status == "success" && resEquip.score > 0.4) {
                If (PixelSearch(&eX, &eY, resEquip.x-40, resEquip.y-25, resEquip.x+40, resEquip.y+25, 0x45DC4A, 7)) {
                    Click(resEquip.x, resEquip.y)
                    
                    if (goldtower) {
                        GoldStart := A_TickCount
                        Loop {
                            resGolden := AdvancedImageSearch("Resources\notgolden.png", X1, Y1, W, H) 
                            if (resGolden.status == "success" && resGolden.score > 0.55) {
                                If (PixelSearch(&eX, &eY, resGolden.x-40, resGolden.y-25, resGolden.x+40, resGolden.y+25, 0x1E1E1E, 4)) {
                                    Click(resGolden.x, resGolden.y)
                                    Sleep(300)
                                    break
                                }
                            }
                            if (A_TickCount - GoldStart > 1000)
                                break
                            Sleep(400)
                        }
                    }
                    
                    if (regulartower) {
                        RegStart := A_TickCount
                        Loop {
                            resGolden := AdvancedImageSearch("Resources\golden.png", X1, Y1, W, H, 0.4, 2) 
                            if (resGolden.status == "success" && resGolden.score > 0.55) {
                                If (PixelSearch(&eX, &eY, resGolden.x-40, resGolden.y-25, resGolden.x+40, resGolden.y+25, 0xFFC11F, 8)) {
                                    Click(resGolden.x, resGolden.y)
                                    Sleep(300)
                                    break
                                }
                            }
                            if (A_TickCount - RegStart > 1000)
                                break
                            Sleep(400)
                        }
                    }
                    break
                }
                Sleep(100)
            }
            if (A_TickCount - TowerStart > 5000)
                break
            Sleep(400)
        }
        Sleep(400)
    }
    X1 := Round(rw * 0.2)
    Y1 := 0
    W := Round(rw * 1) - X1
    H := Round(rh * 0.4) - Y1
    resclose := AdvancedImageSearch("Resources\close_items.png", X1, Y1, W, H)

    If (resclose.status = "success" && resclose.score >= 0.85) {
        Click(resclose.x, resclose.y)
    } else if (savedCloseX != 0 && savedCloseY != 0) {
        Click(savedCloseX, savedCloseY)
    }
    
    LogToConsole("Successfully equipped towers: " towers, true, false)
    IniWrite(1, StateFile, "State", "Equipped")
}

; Search both Restart button images and return the better match.
BestRestartResult(w, h) {
    a := AdvancedImageSearch("Resources\Restart.png", 0, h * 0.5, w, h * 0.5, 0.5, 1.5)
    b := AdvancedImageSearch("Resources\Restart2.png", 0, h * 0.5, w, h * 0.5, 0.5, 1.5)
    return (a.score > b.score) ? a : b
}

; Click a results-screen button (Restart / Play Again) exactly as before, then check that the
; button went away. If it is still on screen, click it again (up to 3 tries in total).
; Returns true once the button is gone.
ClickResultButton(res, finder, label) {
    Loop 3 {
        attempt := A_Index
        if (attempt > 1)
            ActivateRoblox()
        Click(res.x, res.y)
        Loop 6 {
            Sleep(250)
            fresh := finder.Call()
            if !(fresh.status = "success" && fresh.score > 0.64) {
                if (attempt > 1)
                    LogToConsole(label " button clicked (attempt " attempt ")")
                return true
            }
        }
        LogToConsole(label " click did not register (attempt " attempt "/3), clicking again...")
        res := fresh
    }
    return false
}

CheckRestart() {
    global IsRestarting, difficulty, UseRestartBtn, UsePlayAgainBtn, CollectPlaytimeRewards, requiredTowers, AutoEquip

    shouldCollectRewards := (CollectPlaytimeRewards = "1" || CollectPlaytimeRewards = 1) && CheckDailyRewardTime() && (AutorunStartTime = 0 || (A_TickCount - AutorunStartTime) > 300000)
    shouldEquip := !Number(IniRead(StateFile, "State", "Equipped", 0))

    if (shouldCollectRewards && !MultiplayerEnabled) {
        LogToConsole("Navigating to lobby to check playtime rewards...", true, false)
        IsRestarting := false

        closeRoblox_ := true
        if (GetRobloxHWND()){
            ActivateRoblox()
            getRobloxPos(,,&w,&h)
            Loop 2 {
                play_btn := AdvancedImageSearch("Resources/Play.png", Round(w * 0.25), Round(h * 0.66), Round(w * 0.75), Round(h * 0.34))
                if (play_btn.status = "success" && play_btn.score > 0.65) {
                    closeRoblox_ := false
                    break
                } 
                Sleep 150
            }
        }
        
        if (closeRoblox_) {
            CloseRoblox()
            RunRoblox()
        }

        if (shouldEquip && AutoEquip) {
            EquipTowers(requiredTowers)
        }
        JoinGame()
        return
    }

    KillSubmacros()

    if GetRobloxHWND() {
        ActivateRoblox()
        Sleep(1500)
        ActivateRoblox()
        SendEvent("{" CancelPlacementKey "}")
        getRobloxPos(,, &w, &h)
        
        resRevive := AdvancedImageSearch("Resources\use_revive_ticket.png", w * 0.2, h * 0.2, w * 0.6, h * 0.7)

        if (resRevive.status == "success" && resRevive.score > 0.7) {
            resCancel := AdvancedImageSearch("Resources\cancel.png", w * 0.2, h * 0.2, w * 0.6, h * 0.7)
            
            if (resCancel.status == "success" && resCancel.score > 0.7) {
                ActivateRoblox()
                Click(resCancel.x, resCancel.y)
                Sleep 250
            }
        }

        if (UseRestartBtn = "1" || UseRestartBtn = 1) {
            resRestart := AdvancedImageSearch("Resources\Restart.png", 0, h * 0.5, w, h * 0.5, 0.5, 1.5)
            resRestart2 := AdvancedImageSearch("Resources\Restart2.png", 0, h * 0.5, w, h * 0.5, 0.5, 1.5)

            if ((resRestart.status == "success" && resRestart.score > 0.64) || (resRestart2.status == "success" && resRestart2.score > 0.64)) {
                if (MultiplayerEnabled && PlayerRole = "Host") {
                    Sleep 5000
                }

                res := resRestart.score > resRestart2.score ? resRestart : resRestart2
                restartFinder := () => BestRestartResult(w, h)
                IsRestarting := true
                LogToConsole("Restarting the match")
                if !(MultiplayerEnabled) { 
                    ClickResultButton(res, restartFinder, "Restart")
                } else {
                    totalPartyMembers := 0
                    Loop Parse, PartyMembers, "," {
                        member := Trim(A_LoopField)
                        if (member = "") {
                            continue
                        }
                        totalPartyMembers++
                    }
                    if totalPartyMembers = 2 || totalPartyMembers = 3 {
                        if PlayerRole != "Host" {
                            ClickResultButton(res, restartFinder, "Restart")
                        }
                    } else {
                        if PlayerRole = "Host" {
                            ClickResultButton(res, restartFinder, "Restart")
                        }
                    }
                }
                Sleep(150)
                startWatchdog()
                return
            }
        }

        if (UsePlayAgainBtn = "1" || UsePlayAgainBtn = 1) {

            resReplay := AdvancedImageSearch("Resources\PlayAgain.png", 0, h * 0.5, w, h*0.5, 0.5, 1.5, 0.025)
            
            if (resReplay.status == "success" && resReplay.score > 0.64) {
                if (MultiplayerEnabled && PlayerRole = "Host") {
                    Sleep 5000
                }
                if (!MultiplayerEnabled || PlayerRole = "Host") {
                    playAgainFinder := () => AdvancedImageSearch("Resources\PlayAgain.png", 0, h * 0.5, w, h*0.5, 0.5, 1.5, 0.025)
                    if !ClickResultButton(resReplay, playAgainFinder, "Play Again")
                        LogToConsole("Play Again could not be clicked after 3 tries.", true)
                }
                Sleep(150)
                WaitForLobbyLoad()
                startWatchdog()
                return
            }
        }
    }

    startWatchdog()
    IsRestarting := false
    CloseRoblox()
    RunRoblox()
    if (shouldEquip && AutoEquip) {
        EquipTowers(requiredTowers)
    }
    JoinGame()
}

RunRoblox(doReload := true) {
    global VipLink, UseVipServer
    AuditLog("INFO", "Roblox", "Launching Roblox")
    PlaceID := "3260590327"

    Loop {
        if ((UseVipServer = "1" || UseVipServer = 1) && VipLink != "") {
            if InStr(VipLink, "privateServerLinkCode=") {
                RegExMatch(VipLink, "privateServerLinkCode=([a-fA-F0-9]+)", &f)
                DeepLink := "roblox://placeID=" PlaceID "&linkcode=" f[1]
            } else if InStr(VipLink, "share?code=") {
                RegExMatch(VipLink, "code=([a-fA-F0-9]+)", &f)
                DeepLink := "roblox://navigation/share_links?code=" f[1] "&type=Server"
            } else {
                DeepLink := "roblox://placeID=" PlaceID
            }
        } else {
            DeepLink := "roblox://placeID=" PlaceID
        }

        Run(DeepLink)
        robloxopened := false
        Loop 60 {
            if WinExist("Roblox ahk_exe RobloxPlayerBeta.exe") {
                robloxopened := true
                break
            }
            if WinExist("Roblox ahk_exe ApplicationFrameHost.exe") {
                robloxopened := true
                break
            }
                
            Sleep(1000)
        }
        if (!robloxopened && doReload) {
            LogToConsole("Roblox not started after 1 minute! Reloading...", true)
            SafeReload()
        } else if (!robloxopened && !doReload) {
            return false
        }
        ActivateRoblox()
        ExitFullScreen()
        WinMinimize "Roblox"
        WinMaximize "Roblox"
        ActivateRoblox()

        SetTimer(CheckPopups, 5000)

        startTime := A_TickCount
        getRobloxPos(,,&w,&h)
        Loop {
            ActivateRoblox()

            if (A_TickCount - startTime > 60000) {
                if (doReload) {
                    SafeReload()
                } else {
                    return false
                }
            }

            play_btn := AdvancedImageSearch("Resources/Play.png", Round(w * 0.25), Round(h * 0.66), Round(w * 0.75), Round(h * 0.34))
            if (play_btn.status = "success" && play_btn.score > 0.65) {
                break
            } 
            Sleep(1500)
        }
        SendEvent("{sc00F}")
        return true 
    }
}

ExitFullScreen() {
    if WinExist("Roblox ahk_exe RobloxPlayerBeta.exe") || WinExist("Roblox ahk_exe ApplicationFrameHost.exe") {
        ActivateRoblox()
        style := WinGetStyle("Roblox")
        if !(style & 0xC00000) {
            SendEvent("{F11}")
            Sleep(500)
        }
        WinRestore "Roblox"
        ActivateRoblox()
    }
}

CloseRoblox() {
	
	if (hwnd := GetRobloxHWND())
	{
        getRobloxPos(,,,&windowHeight)
		GetRobloxClientPos(hwnd)
		if (windowHeight >= 500) 
		{
			ActivateRoblox()
			PrevKeyDelay := A_KeyDelay
			SetKeyDelay 500
			send "{" SC_Esc "}{" SC_L "}{" SC_Enter "}"
			SetKeyDelay PrevKeyDelay
		}
		Sleep 4500 
	}
	
	; The client is no longer closed here. Joining a game by deep link only works when the Roblox client is already
	; open; from a cold start it hangs on a white screen and fails with Error Code 256. So the macro just leaves the
	; game (above) and RunRoblox sends the game link to the client that is still running. Leftover Roblox processes are
	; only killed when there is no Roblox window left to reuse.
	if (!GetRobloxHWND()) {
		for p in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name LIKE '%Roblox%' OR CommandLine LIKE '%ROBLOXCORPORATION%'")
			ProcessClose p.ProcessID
	}
}

resetCharacter() {
	if (hwnd := GetRobloxHWND())
	{
        getRobloxPos(,,,&windowHeight)
		GetRobloxClientPos(hwnd)
		if (windowHeight >= 500) 
		{
            LogToConsole("Resetting character...")
			ActivateRoblox()
			send "{" SC_Esc "}"
            Sleep 550 
            send "{" SC_R "}"
            Sleep 550 
            send "{" SC_Enter "}"
		}
	}
}

WaitForLobbyLoad() {
    global difficulty, MultiplayerEnabled, PlayerRole

    SetTimer(CheckPopups, 0)

    startTime := A_TickCount
    if (difficulty != "Pizza Party" && difficulty != "Badlands II" && difficulty != "Polluted Wasteland II") {
        Sleep(6000)
        Loop {
            if (A_TickCount - startTime > 60000) {
                CloseRoblox()
                SafeReload()
            }
            getRobloxPos(,,&w,&h)
            res := AdvancedImageSearch("Resources/Ready.png", Round(w * 0.25), Round(h * 0.66), Round(w * 0.5), Round(h * 0.34), 0.6, 1.7)
            if (res.status = "success" && res.score >= 0.7) {
                break
            }
            Sleep(100)
        }
        if (!MultiplayerEnabled || PlayerRole = "Host") {
            SelectMap(res.x, res.y)
        } else {
            Click(Round(w*0.5), res.y)
            Sleep 250
            Click(Round(w*0.6), res.y)
            if (modifiers != "")
                ApplyModifiers()
        }
    }
}

JoinGame() {
    global SendCurrenciesEnabled, WebhookEnabled, difficulty, CollectPlaytimeRewards, PlayerRole, MultiplayerEnabled
    getRobloxPos(,, &w, &h)

    startTime := A_TickCount
    Loop {
        if (A_TickCount - startTime > 80000) { 
            SafeReload()
            break
        }

        x1 := Round(w * 0.25)
        y1 := Round(h * 0.66)
        x2 := Round(w * 0.75)
        y2 := Round(h * 0.34)
        
        res := AdvancedImageSearch("Resources\Play.png", x1, y1, x2, y2)
        if (res.status == "success" && res.score > 0.65) {
            ActivateRoblox()
            if (CollectPlaytimeRewards = "1" || CollectPlaytimeRewards = 1) {
                claimPlaytimeRewards()
            }
            
            LowerGraphics()
            Sleep(50)

            if (MultiplayerEnabled) {
                if (PlayerRole = "Member") {
                    AcceptInvite(res.x, res.y)
                    WaitForLobbyLoad()
                    return
                } else {
                    CreateParty(res.x, res.y)
                }
                    
            }

            LogToConsole("Joining " difficulty "...", true, false)
            
            Click(res.x, res.y)
            break
        }
        Sleep(100)
    }
    Sleep(500)

    startTime := A_TickCount
    modeImg := ""

    if (difficulty = "Pizza Party" || difficulty = "Badlands II" || difficulty = "Polluted Wasteland II") {
        modeImg := "SpecialMode.png"
    } else {
        modeImg := "Survival.png"
    }

    if modeImg != "" {
        getRobloxPos(,, &w, &h)
        Loop {
            if (A_TickCount - startTime > 20000) {
                newStartTime := A_TickCount
                res := AdvancedImageSearch("Resources\Play.png", x1, y1, x2, y2)
                if (res.status == "success" && res.score > 0.65) {   
                    Click(res.x, res.y)
                    startTime := A_TickCount
                } else {
                    if (A_TickCount - newStartTime > 40000) {
                        SafeReload()
                        break
                    }
                }
            }

            res := AdvancedImageSearch("Resources/" modeImg, 0, 0, w, h)
            if (res.status = "success" && res.score >= 0.67) {
                Click(res.x, res.y)
                break 
            }
            Sleep(100)
        }
        Sleep(300)
    }

    startTime := A_TickCount
    Loop {
        getRobloxPos(,, &w, &h)
        if (A_TickCount - startTime > 20000) {
            newStartTime := A_TickCount
            res := AdvancedImageSearch("Resources\Play.png", x1, y1, x2, y2)
            if (res.status == "success" && res.score > 0.7) {   
                Click(res.x, res.y)
                startTime := A_TickCount
            } else {
                if (A_TickCount - newStartTime > 40000) {
                    SafeReload()
                    break
                }
            }
        }
        res := AdvancedImageSearch("Resources/" difficulty ".png", 0, 0, w, h)
        if (res.status = "success" && res.score >= 0.7) {
            Click(res.x, res.y)
            break 
        }
        Sleep(100)
    }
    Sleep(300)

    startTime := A_TickCount
    Loop {
        getRobloxPos(,, &w, &h)
        if (A_TickCount - startTime > 40000) { 
            SafeReload()
            break
        }
        if (!MultiplayerEnabled) {
            res := AdvancedImageSearch("Resources/Solo.png", 0, Round(h * 0.2), Round(w * 0.7), Round(h * 0.55))
            if (res.status = "success" && res.score >= 0.7) {
                Click(res.x, res.y)
                break 
            }
        } else {
            totalPartyMembers := 0
            Loop Parse, PartyMembers, "," {
                member := Trim(A_LoopField)
                if (member = "") {
                    continue
                }
                totalPartyMembers++
            }
            if (totalPartyMembers = 1) {
                res := AdvancedImageSearch("Resources/duo.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.6))
            } else if (totalPartyMembers = 2) {
                res := AdvancedImageSearch("Resources/trio.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.6))
            } else if (totalPartyMembers = 3) {
                res := AdvancedImageSearch("Resources/quad.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.6))
            } else {
                res := AdvancedImageSearch("Resources/Solo.png", 0, Round(h * 0.2), Round(w * 0.7), Round(h * 0.55))
            }

            if (res.status = "success" && res.score >= 0.7) {
                Click(res.x, res.y)
                break 
            }

        }
        Sleep(100)
    }
    WaitForLobbyLoad()
}

CreateParty(x, y) {
    global PartyMembers
    StartTime := A_TickCount
    CloseX := 0
    CloseY := 0

    Loop {
        Click(x+200, y)

        InnerStartTime := A_TickCount

        if (A_TickCount - StartTime > 10000) {
            LogToConsole("Failed to Create Party: The macro can't see the menu!", true)
            SafeReload()
        }

        getRobloxPos(,,&w,&h)
        Loop {
            resclose := AdvancedImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

            If (resclose.status = "success" && resclose.score >= 0.7) {
                openedMenu := true
                CloseX := resclose.x
                CloseY := resclose.y
                break 2
            } 
            if (A_TickCount - InnerStartTime > 5000)
                break
            Sleep(500)
        }
    }

    Sleep 150

    create_btn := AdvancedImageSearch("Resources\create_party.png", Round(w*0.25), Round(h*0.5), Round(w*0.5), Round(h*0.5))
    Sleep 500
    if (create_btn.score > 0.58) {
        Click(create_btn.x, create_btn.y)
        LogToConsole("Successfully created the party")
    } else {
        LogToConsole("Failed to Create Party: The macro can't see the create party button!", true)
        SafeReload()
    }

    Sleep 300

    invited := false

    SetTimer(CancelInviteIfAppeared, 7500)

    Loop 3 {
        search_bar := AdvancedImageSearch("Resources\type_to_search.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.3))
        if (search_bar.score > 0.58) {
            Loop Parse, PartyMembers, "," {
                member := Trim(A_LoopField)
                if (member = "") {
                    continue
                }
                Click(search_bar.x, search_bar.y)
                Sleep(100)
                if (A_KeyDelay < 5) {
                SendInput(member)
                } else {
                    SendText(member)
                }
                Sleep(100)
                Click(search_bar.x + ScaleX(75), search_bar.y + ScaleY(92))
                Sleep(50)

                LogToConsole("Successfully invited " member)
            }
            invited := true
            break
        }
        Sleep 1500
    }

    if (!invited) {
        LogToConsole("Failed to Create Party: The macro can't see the search_bar!", true)
        SafeReload()
    }

    Sleep 300

    totalPartyMembers := 0
    Loop Parse, PartyMembers, "," {
        member := Trim(A_LoopField)
        if (member = "") {
            continue
        }
        totalPartyMembers++
    }

    xs := 0
    sy := Round(h*0.1)

    waitStartTime := A_TickCount

    Loop {
        x_btn := AdvancedImageSearch("Resources\x.png", Round(w*0.25), sy, Round(w*0.25), Round(h*0.75) - sy)
        if (x_btn.score > 0.7) {

            xs++
            sy := x_btn.y+x_btn.h/2
        }
        LogToConsole("Waiting for " totalPartyMembers " players... (" xs "/"  totalPartyMembers ")")
        if (xs >= totalPartyMembers) {
            LogToConsole("All players: " PartyMembers " have joined!")
            break
        }
        if (A_TickCount - waitStartTime > 30000) { 
            sy := Round(h*0.1)
            xs := 0
            Loop Parse, PartyMembers, "," {
                member := Trim(A_LoopField)
                if (member = "") {
                    continue
                }
                Click(search_bar.x, search_bar.y)
                Sleep(100)
                kdelay := A_KeyDelay
                changedDelay := false
                if (A_KeyDelay < 5) {
                SendInput(member)
                } else {
                    SendText(member)
                }
                Sleep(100)
                Click(search_bar.x + ScaleX(75), search_bar.y + ScaleY(92))
                Sleep(50)

                LogToConsole("Successfully invited " member)
            }
            waitStartTime := A_TickCount
        }
        Sleep 5000
    }

    SetTimer(CancelInviteIfAppeared, 0)

    resclose := AdvancedImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

    If (resclose.status = "success" && resclose.score >= 0.7) {
        Click(resclose.x, resclose.y)
    } 
    Sleep 200
}

CancelInviteIfAppeared(*) {
    getRobloxPos(,,&w,&h)

    cancel_btn := AdvancedImageSearch("Resources/cancel_invite.png", Round(w * 0.2), Round(h * 0.2), Round(w * 0.6), Round(h * 0.65))
    if (cancel_btn.status = "success" && cancel_btn.score >= 0.65) {
        Click(cancel_btn.x, cancel_btn.y)
    }
}

AcceptInvite(x, y) {

    StartTime := A_TickCount
    CloseX := 0
    CloseY := 0
    Loop {
        Click(x+200, y)

        InnerStartTime := A_TickCount

        if (A_TickCount - StartTime > 15000) {
            LogToConsole("Failed to Create Party: The macro can't see the menu!", true)
            SafeReload()
        }

        getRobloxPos(,,&w,&h)
        Loop {
            resclose := AdvancedImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

            If (resclose.status = "success" && resclose.score >= 0.7) {
                openedMenu := true
                CloseX := resclose.x
                CloseY := resclose.y
                break 2
            } 
            if (A_TickCount - InnerStartTime > 5000)
                break
            Sleep(500)
        }
    }


    Sleep 150

    clickedInviteBtn := false

    search_bar_X := 0
    search_bar_Y := 0

    Loop 5 {
        create_btn := AdvancedImageSearch("Resources\invites_btn.png", Round(w*0.25), 0, Round(w*0.5), Round(h*0.4))
        if (create_btn.score > 0.58) {
            clickedInviteBtn := true
            Click(create_btn.x, create_btn.y)
            search_bar_X := create_btn.x - 250
            search_bar_Y := create_btn.y + 50
            break
        }
        Sleep 200
    }

    if (!clickedInviteBtn) {
        LogToConsole("Failed to Accept Invite: The macro can't see the invites button!", true)
        Sleep 300
        SafeReload()
    }

    invited := false

    Sleep 200

    Click(search_bar_X, search_bar_Y)
    Sleep(100)
    if (A_KeyDelay < 5) {
    SendInput(HostName)
    } else {
        SendText(HostName)
    }
    Sleep 100

    InnerStartTime := A_TickCount
    Loop {
        LogToConsole("Waiting for an invite from host: " HostName "...")
        accept_btn := AdvancedImageSearch("Resources\accept_invite.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.3))
        if (accept_btn.score > 0.66) {
            Click(accept_btn.x, accept_btn.y)
            if !(ReadMessage(["Error", "Party", "not", "found"])) {
                LogToConsole("Successfully accepted an invitation from " HostName)
                break
            }
        }
        if (A_TickCount - InnerStartTime > 180000) { 
            LogToConsole("Didn't receive an invite from the host within 3 minutes! Reloading the script and rejoining...", true)
            SafeReload()
        }
        Sleep 5000
    }

    resclose := AdvancedImageSearch("Resources\close.png", Round(w*0.25), Round(h*0.1), Round(w*0.5), Round(h*0.4))

    If (resclose.status = "success" && resclose.score >= 0.7) {
        Click(resclose.x, resclose.y)
    }
}

checkCondition(*) {
    global LeaveCondition, PartyMembers

    totalPartyMembers := 0
    Loop Parse, PartyMembers, "," {
        member := Trim(A_LoopField)
        if (member = "") {
            continue
        }
        totalPartyMembers++
    }

    ActivateRoblox()
    getRobloxPos(&rX, &rY, &w,&h)

    img := ""
    if (LeaveCondition = "All") {
        img := "Resources/(1"
    } else {
        if (totalPartyMembers = 1) {
            img := "Resources/(2"
        } else if (totalPartyMembers = 2) {
            img := "Resources/(3"
        } else if (totalPartyMembers = 3) {
            img := "Resources/(4"
        }
    }

    if (img = "")
        return

    result := AdvancedImageSearch(img ".png", Round(w*0.5), rY, w, h)
    if (result.score > 0.8) {
        if (LeaveCondition = "All") {
            LogToConsole("All players are gone! Closing roblox and reloading the macro...", true)
            CloseRoblox()
            SafeReload()
        }
    } else {
        LogToConsole("Someone has just left! Closing roblox and reloading the macro...", true)
        CloseRoblox()
        SafeReload()
    }

}

CheckTheMapF() {
    global gamemap, CheckTheMap, modifiers

    modifiers_str := (modifiers is Array) ? Join(modifiers) : String(modifiers)

    if (FileExist("Resources\Maps\" . gamemap . ".png") && CheckTheMap = 1 && !InArray(SpecialMaps, gamemap) && !RegExMatch(modifiers_str, "i)fog"))
    {
        AlignCamera(false, false, false)

        LogToConsole("Checking the map... (Make sure you have the lowest graphics)")


        getRobloxPos(,,&w,&h)
        FoundMap := false
        Loop 2 {
            res := AdvancedImageSearch("Resources\Maps\" gamemap ".png", 0, 0, w, h)

            if (res.score > 0.62) {
                FoundMap := true
                break
            }
            
            Sleep(1250)
        }

        if (!FoundMap) {
            LogToConsole("Can't detect the map! Reloading script...", true)
            Sleep 300
            SafeReload()
        }
    }

    if (InArray(SpecialMaps, gamemap)) {
        functionName := gamemap . "Path"

        %functionName%() 
    }
}

ApplyModifiers() {
    global modifiers
    LogToConsole("Setting up modifiers: " modifiers)
    Click(56, ScaleY(930))

    Sleep(300)

    searchX := ScaleX(951)
    searchY := ScaleY(262)

    foundsearchbar := false
    getRobloxPos(&x, &y, &w, &h)
    Loop 2 {
        res := AdvancedImageSearch("Resources/searchbar_modifiers.png", Round(w*0.1),0,Round(w*0.7),Round(h*0.6), 0.5, 1.5)
        
        if (res.status = "success" && res.score >= 0.7)  { 
            searchX := res.x
            searchY := res.y
            foundsearchbar := true 
            break
          } 
        Sleep(500)
    }

    Loop Parse, modifiers, "," {
        modifier := Trim(A_LoopField)
        if (modifier = "") {
            continue
        }
        Click(searchX, searchY)
        Sleep(100)
        if (A_KeyDelay < 5) {
        SendInput(modifier)
        } else {
            SendText(modifier)
        }
        Sleep(100)
        Click(Round(w/2), searchY+ScaleY(80))
        Sleep(50)
        LogToConsole("Modifier added: " modifier)
    }
    Sleep(100)
    Click(ScaleX(1122), ScaleY(853))
    LogToConsole("All modifiers configured")
}

ClickReady() {
    global readyX, readyY

    readyTries := 0
    Loop {
        readyTries++
        MouseMove(readyX, readyY)
        Sleep 50
        MouseClick()
        Sleep 200

        getRobloxPos(,,&w,&h)
        readyc := AdvancedImageSearch("Resources/ready_gs.png",Round(w * 0.25), Round(h * 0.08), Round(w * 0.5), Round(h * 0.34))
        if !(readyc.score > 0.7) {
            if (readyTries > 1)
                AuditLog("RECOVERED", "Match start", "Ready button clicked after " readyTries " attempts")
            LogToConsole("Successfully started the match by clicking the ready button.")
            break
        } else {
            LogToConsole("Failed to press the ready button, retrying...")
            if PixelSearch(&fx, &fy, Round(w*0.4),Round(h*0.05), Round(w*0.7), Round(h*0.35), 0x2BEB00, 2) {
                if ReadyButtonCenter(fx, fy, &cx, &cy) {
                    readyX := cx
                    readyY := cy
                } else {
                    readyX := fx
                    readyY := fy
                }
                continue
            } else {
                break
            }
        }
    }
}

; PixelSearch returns an EDGE pixel of the green area, which can sit just outside the button's
; clickable shape (this made the Ready click land a few pixels off a corner). Starting from that
; pixel, find the green area's bounding box by repeated "is there any green in this rectangle?"
; tests (works whatever order PixelSearch scans in) and return its center instead.
ReadyGreenIn(x1, y1, x2, y2) {
    try return PixelSearch(&px, &py, x1, y1, x2, y2, 0x2BEB00, 2)
    return false
}

ReadyButtonCenter(fx, fy, &cx, &cy) {
    getRobloxPos(,, &w, &h)
    l := Max(0, fx - Round(w * 0.09)), r := Min(w - 1, fx + Round(w * 0.09))
    t := Max(0, fy - Round(h * 0.07)), b := Min(h - 1, fy + Round(h * 0.07))
    if !ReadyGreenIn(l, t, r, b)
        return false
    lo := t, hi := b                    ; top edge: smallest y with green in [t..y]
    while (lo < hi) {
        mid := (lo + hi) // 2
        if ReadyGreenIn(l, t, r, mid)
            hi := mid
        else
            lo := mid + 1
    }
    top := lo
    lo := top, hi := b                  ; bottom edge: largest y with green in [y..b]
    while (lo < hi) {
        mid := (lo + hi + 1) // 2
        if ReadyGreenIn(l, mid, r, b)
            lo := mid
        else
            hi := mid - 1
    }
    bottom := lo
    lo := l, hi := r                    ; left edge: smallest x with green in [l..x]
    while (lo < hi) {
        mid := (lo + hi) // 2
        if ReadyGreenIn(l, top, mid, bottom)
            hi := mid
        else
            lo := mid + 1
    }
    left := lo
    lo := left, hi := r                 ; right edge: largest x with green in [x..r]
    while (lo < hi) {
        mid := (lo + hi + 1) // 2
        if ReadyGreenIn(mid, top, r, bottom)
            lo := mid
        else
            hi := mid - 1
    }
    right := lo
    bw := right - left, bh := bottom - top
    ; Only trust a plausibly button-sized area; otherwise keep the original pixel.
    if (bw < w * 0.04 || bw > w * 0.16 || bh < h * 0.025 || bh > h * 0.12)
        return false
    cx := (left + right) // 2
    cy := (top + bottom) // 2
    return true
}

waitReady() {
    global readyX, readyY, MultiplayerEnabled, PlayerRole
    start := A_TickCount
    getRobloxPos(&x, &y, &w, &h)
    KillSubmacros()
    Loop {
        wt := 40000
        if (MultiplayerEnabled && PlayerRole = "Member") {
            wt := 90000
        }
        If (A_TickCount - start > wt) {
            LogToConsole("The ready button hasn't appeared for too long! Reloading the script...", true)
            CloseRoblox()
            SafeReload()
        }
        if PixelSearch(&fx, &fy, Round(w*0.4),Round(h*0.05), Round(w*0.7), Round(h*0.35), 0x2BEB00, 2) {
            if ReadyButtonCenter(fx, fy, &cx, &cy) {
                readyX := cx
                readyY := cy
            } else {
                readyX := fx
                readyY := fy
            }
            LogToConsole("Ready button: first green pixel " fx "," fy ", clicking " readyX "," readyY)
            break
        } else {
            Sleep(50)
        }
    }
    startWatchdog()
}

activateTimescale() {
    global UseTimeScale, TimeScaleMode, TimeScaleMultiplier, difficulty, SettingsFile, AutorunStartTime, MultiplayerEnabled, TimescaleActive
    if (MultiplayerEnabled) {
        return
    }

    getRobloxPos(&x, &y, &w, &h)
    if (UseTimeScale && difficulty != "Pizza Party" && difficulty != "Badlands II" && difficulty != "Polluted Wasteland II") { 
        LogToConsole("Applying timescale: " TimeScaleMode ". Please, enable UI Navigation Toggle.")
        Click(Round(w*0.5), Round(h*0.5))

        Send("#")
        Send("{sc02B}")
        Sleep 50
        Loop 10 {
            Send("{Down}")
            Sleep 10
        }
        Loop 20 {
            Send("{Left}")
            Sleep 10
        }
        Send("{Right}")
        Sleep 10
        Send("{Enter}")

        Sleep(250)

        res := AdvancedImageSearch("Resources/GetMore.png", Round(w * 0.25), Round(h * 0.45), Round(w * 0.50), Round(h * 0.55))
        if (res.status = "success" && res.score >= 0.67) {
            Click(res.x, res.y+55)
            LogToConsole("Failed to activate timescale! You are out of tickets.", true, false)
            timescaleMention := (PingOnTimescale = 1) ? GetDiscordMention(WebhookUserID) : ""
            SendToWebhookInstant("⚠️ **Timescale Tickets Depleted!**`nFailed to activate timescale because you are out of tickets.", 16724526, true, timescaleMention)
            UseTimeScale := false
            TimescaleActive := false

        } else {
            res := AdvancedImageSearch("Resources/confirm.png", Round(w * 0.25), Round(h * 0.45), Round(w * 0.50), Round(h * 0.55))
            if (res.status = "success" && res.score >= 0.67) {
                Click(res.x, res.y)
            } else {
                LogToConsole("failed to activate timescale. the macro can't see the confirm/get more button... (" res.score ")", true)
                SafeReload()
            }

            timescales := IniRead(StateFile, "State", "Timescale", 0)
            timescales := timescales+1
            LogToConsole("-1 Timescale ticket. Total Timescale Tickets Used: " timescales)
            SendToWebhookInstant("[" runtime := FormatRuntime(AutorunStartTime) "] -1 Timescale ticket. `n-# Total Timescale Tickets Used: " . timescales, 12370112, false)
            IniWrite(timescales, StateFile, "State", "Timescale")
            TimescaleActive := true

            Sleep(250)
            if (TimeScaleMode = "2x") {
                Loop 2 {
                    Sleep(20)
                    Send("{Enter}")
                }
            } else if (TimeScaleMode = "1.5x") {
                Sleep(20)
                Send("{Enter}")
            }
        }

        Send("{sc02B}")
        Send("#")
    }
}

AlignCamera(move := true, skipZoom := false, log := true) {
    global MoveEnabled, MoveDirection, MoveDuration, IsRestarting, MouseDelay
    if (IsRestarting)
        return
    if (log) {
        LogToConsole("Aligning camera")
    }
    closeChat()

    getRobloxPos(&rx, &ry, &rw, &rh)

    MouseMove(rw/2, rh/2.5)
    Sleep 80
    SendInput "{RButton down}"
    Sleep 90                    ; give Roblox time to register the button before any movement
    MouseMove(0, rh/8,, "R")
    Sleep 90                    ; let the drag be applied before the button is released
    SendInput "{RButton Up}"
    Sleep 60
    SendInput "{RButton Up}"    ; make sure the drag really ended: a drag that never ends keeps
    Sleep 100                   ; rotating the camera on every later mouse move

    If (!skipZoom) {
        Send "{WheelDown 30}"
        Sleep 150               ; let the zoom finish before the next input
    }
    if (MoveEnabled && !IsRestarting && move) {
        Sleep(200)
        SendEvent("{" MoveDirection " down}")
        HyperSleep(MoveDuration)
        SendEvent("{" MoveDirection " up}")
    }
}

isDisconnected() {
    w := A_ScreenWidth
    h := A_ScreenHeight
    
    getRobloxPos(,, &w, &h)
    ActivateRoblox()

    if (!w || !h || w <= 0 || h <= 0) {
        w := A_ScreenWidth
        h := A_ScreenHeight
    }

    oldMode := A_CoordModePixel
    CoordMode("Pixel", "Screen")
    
    try {
        if ImageSearch(&FoundX, &FoundY, 0, 0, w, h, "*26 " "Resources\Disconnected.png") {
            CoordMode("Pixel", oldMode)
            TryReconnect()
        } else if ImageSearch(&FoundX, &FoundY, 0, 0, w, h, "*26 " "Resources\disconnected2.png") {
            CoordMode("Pixel", oldMode)
            TryReconnect()
        }
    } catch Error as err {
        CoordMode("Pixel", oldMode)
    }
    
    CoordMode("Pixel", oldMode)
}

TryReconnect() {
    attempts := 0
    Loop {
        attempts++
        LogToConsole("Reconnecting... Attempt " attempts ".", true, false)
        KillSubmacros()
        CloseRoblox()
        if (RunRoblox(false) == false) {
            continue
        } else {
            LogToConsole("Reconnect successful after " attempts " attempts!", true, false)
            startWatchdog()
            break
        }
    }
}

CheckPopups(*) {
    static clickedNotNow := false

    getRobloxPos(,,&w,&h)

    res := AdvancedImageSearch("Resources/Claim.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.5))
    if (res.status = "success" && res.score >= 0.65) {
        LogToConsole("Claimed daily reward.")
        Click(res.x, res.y)
    }

    res := AdvancedImageSearch("Resources/cancel_rejoin.png", Round(w * 0.15), Round(h * 0.4), Round(w * 0.7), Round(h * 0.4))
    if (res.status = "success" && res.score >= 0.65) {
        Click(res.x, res.y)
    }

    if (!clickedNotNow) {
        res2 := AdvancedImageSearch("Resources/notnow.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.5))
        if (res2.status = "success" && res2.score >= 0.65) {
            clickedNotNow := true
            Click(res2.x, res2.y)
        }
    }
}

claimPlaytimeRewards() { 
    global CollectPlaytimeRewards, NextCheckInterval
    
    if (CollectPlaytimeRewards != "1" && CollectPlaytimeRewards != 1) {
        return
    }
    Sleep(2000) ; load
    
    getRobloxPos(&pX, &pY, &w, &h)
    popupColor := PixelGetColor(w - 268, pY + 5, "RGB")
    r1 := (popupColor >> 16) & 0xFF, g1 := (popupColor >> 8) & 0xFF, b1 := popupColor & 0xFF
    r2 := 0xEE, g2 := 0x18, b2 := 0x18
    diff := Sqrt((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2)

    
    if (diff < 3) {
        LogToConsole("Claiming playtime rewards..")
        Click(w - 290, pY + 32)
        
        Sleep(1000)

        openedMenu := false
        Loop 15 {
            getRobloxPos(&pX, &pY, &w, &h)
            X1 := Round(w * 0.2)
            Y1 := Round(h * 0.15)
            W := Round(w * 1) - X1
            H := Round(h * 0.4) - Y1
            resclose := AdvancedImageSearch("Resources\close_freerewards.png", X1, Y1, W, H)

            If (resclose.status = "success" && resclose.score >= 0.86) {
                openedMenu := true
                break
            } 
            Sleep(300)
        }

        if (!openedMenu) {
            getRobloxPos(&pX, &pY, &w, &h)
            MouseMove(w - 290, pY + 32, A_DefaultMouseSpeed+1)
            Sleep(50)
            MouseClick()

            openedMenu := false
            Loop 25 {
                getRobloxPos(&pX, &pY, &w, &h)
                X1 := Round(w * 0.2)
                Y1 := Round(h * 0.15)
                W := Round(w * 1) - X1
                H := Round(h * 0.4) - Y1
                resclose := AdvancedImageSearch("Resources\close_freerewards.png", X1, Y1, W, H)

                If (resclose.status = "success" && resclose.score >= 0.86) {
                    openedMenu := true
                    break
                } 

                res := AdvancedImageSearch("Resources/Claim.png", Round(w * 0.25), Round(h * 0.4), Round(w * 0.5), Round(h * 0.5), 0.5, 2)
                if (res.status = "success" && res.score >= 0.65) {
                    Click(res.x, res.y)
                }

                Sleep(300)
            }

            if (!openedMenu) {
                LogToConsole("Failed to claim rewards!", true, false)
                return
            }
        }

        rewardsCollected := false
        
        Loop {
            getRobloxPos(&pX, &pY, &w, &h)
            
            Loop 10 {
                if (PixelSearch(&cx, &cy, Round(w*0.25), Round(h*0.2), Round(w*0.55), Round(h*0.76), 0x64F711, 5)) 
                    break
                else 
                    Sleep(100)
            }

            if (!PixelSearch(&cx, &cy, Round(w*0.25), Round(h*0.2), Round(w*0.55), Round(h*0.76), 0x64F711, 5)) {
                break
            }
            
            Click(cx, cy)
            rewardsCollected := true
            Sleep(500)

            Loop {
                resConfirm := AdvancedImageSearch("Resources/claimreward.png", Round(w*0.25), Round(h*0.5), Round(w*0.5), Round(h*0.5),,1.5)
                
                if (resConfirm.status == "success" && resConfirm.score > 0.65) {
                    Click(resConfirm.x, resConfirm.y)
                    MouseMove(ScaleX(unfocusX), ScaleY(unfocusY))
                    Sleep(800)
                } else {
                    Sleep(300)
                    resConfirm := AdvancedImageSearch("Resources/claimreward.png", Round(w*0.25), Round(h*0.5), Round(w*0.5), Round(h*0.5),,1.5)
                    if (resConfirm.status == "success" && resConfirm.score > 0.65) {
                        continue
                    }
                    break
                }
            }
        }

        Sleep(800) 
 
        getRobloxPos(&pX, &pY, &w, &h)
    
        x1 := Round(w*0.39)
        y1 := Round(h*0.36)
        x2 := Round(w*0.22)
        y2 := Round(h*0.4)

        langCode := "en-US"
        for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
            if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
                langCode := availableLang
                break
            }
        }
        
        ocrResult := OCR.FromRect(x1, y1, x2, y2, {lang: langCode, invertcolors: 1, scale: 2})
        textOnScreen := ocrResult.Text

        claimedCount := 0
        StrReplace(textOnScreen, "CLAIMED", , , &claimedCount)
        
        if (claimedCount != 0) {
            LogToConsole("Claimed free rewards (" . claimedCount . "/6)")   
        }

        if (claimedCount >= 6) {
            LogToConsole("All rewards collected! Next check in 24 hours.")
            NextCheckInterval := 86400000 
        } else {
            LogToConsole("Not all rewards collected. Next check in 2 hours.")
            NextCheckInterval := 7200000  
        }

        X1 := Round(w * 0.2)
        Y1 := Round(h * 0.15)
        W := Round(w * 1) - X1
        H := Round(h * 0.4) - Y1
        resclose := AdvancedImageSearch("Resources\close_freerewards.png", X1, Y1, W, H)

        If (resclose.status = "success" && resclose.score >= 0.86) {
            Click(resclose.x, resclose.y)
        } else {
            Click(ScaleX(1126), ScaleY(307))
        }
    }
    UpdateDailyRewardTime()
}

UpdateDailyRewardTime() {
    global StateFile, NextCheckInterval

    if (!HasGlobal("NextCheckInterval") || NextCheckInterval == "") {
        NextCheckInterval := 7200000
    }
      
    IniWrite(A_Now, StateFile, "State", "LastDailyCheck")
    IniWrite(NextCheckInterval, StateFile, "State", "NextCheckInterval")
}

CheckDailyRewardTime() {
    global StateFile
    
    lastCheckTime := IniRead(StateFile, "State", "LastDailyCheck", "")
    
    currentIntervalMs := Integer(IniRead(StateFile, "State", "NextCheckInterval", "7200000"))
    
    if (lastCheckTime == "") {
        return true
    }

    intervalSeconds := currentIntervalMs / 1000
    
    try {
        timeDiffSeconds := DateDiff(A_Now, lastCheckTime, "Seconds")
        
        if (timeDiffSeconds >= intervalSeconds) {
            return true
        }
    } catch {
        return true
    }
    
    return false
}

closeChat() {
    global AutoCloseChat
    if !AutoCloseChat
        return

    getRobloxPos(&pX, &pY, &w, &h)
    chatColor := PixelGetColor(pX + 138, pY + 37, "RGB")
    r1 := (chatColor >> 16) & 0xFF, g1 := (chatColor >> 8) & 0xFF, b1 := chatColor & 0xFF
    r2 := 0xF4, g2 := 0xF5, b2 := 0xF8
    diff := Sqrt((r1-r2)**2 + (g1-g2)**2 + (b1-b2)**2)
    if (diff < 12) {
        MouseGetPos(&cx, &cy)
        MouseMove(pX + 140, pY + 35, 2)
        Sleep(100)
        Click()
        Sleep(100)
        MouseMove(cx, cy)
        LogToConsole("Closed chat")
    }
}
