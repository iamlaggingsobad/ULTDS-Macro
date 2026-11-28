; ======================================================================================================================
; Towers: Tower actions: place, upgrade, sell, clone, targets, abilities, DJ tracks, indicators and special map paths.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

DetectTowerForUpgrading(*) {
    global MacroRecording, MacroSteps, MacroStartTime, Recording, Towers, RecordedSteps, Commander, ActiveRTowerID, CachedMenuUI, isUiPositionSaved, isUpgradeAuthorized, activeUpgradeRegions, CachedResV2, CachedResV1

    if (IsSet(MacroRecording) && MacroRecording) {
        MouseGetPos(&mx, &my)
        elapsed := A_TickCount - MacroStartTime
        MacroStartTime := A_TickCount
        MacroSteps.Push("Sleep(" elapsed ")")
        MacroSteps.Push("Click(" mx ", " my ")")
        return
    }

    if (!Recording)
        return

    MouseGetPos(&mx, &my, &clickWindow)
    robloxHwnd := GetRobloxHWND()
    
    if (clickWindow != robloxHwnd)
        return

    currentTowerID := ""
    for id, t in Towers {
        ix1 := t.x - 16
        iy1 := t.y - 16
        ix2 := ix1 + 32
        iy2 := iy1 + 32
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            currentTowerID := id
            break
        }
    }

    if (currentTowerID != "") {
        ActiveRTowerID := currentTowerID
        isUpgradeAuthorized := false
        
        openedSuccessfully := waitForTowerUI(&resv2, &resv1)
        
        if (!openedSuccessfully) {
            ActiveRTowerID := ""
        } else {
            CachedResV2 := IsSet(resv2) ? resv2 : ""
            CachedResV1 := IsSet(resv1) ? resv1 : ""
        }
        return
    } else {
        if (ActiveRTowerID != "") {
            openedSuccessfully := waitForTowerUI(&resv2, &resv1, 120)
            
            if (!openedSuccessfully) {
                ActiveRTowerID := ""
            }
        }
    }
}

DetectUpgrade(*) {
    global Recording, ActiveRTowerID, Towers, RecordedSteps, Commander, isUpgradeAuthorized, activeUpgradeRegions, CachedResV2, CachedResV1
    
    if (!Recording || !IsSet(ActiveRTowerID) || ActiveRTowerID == "")
        return

    towerID := ActiveRTowerID
    
    if (!Towers.Has(towerID)) {
        ActiveRTowerID := ""
        return
    }

    MouseGetPos(&mx, &my, &clickWindow)
    robloxHwnd := GetRobloxHWND()
    
    if (clickWindow != robloxHwnd)
        return

    if (!IsSet(CachedResV2) || !IsSet(CachedResV1) || (CachedResV2 == "" && CachedResV1 == "")) {
        resv2 := ""
        resv1 := ""
        openedSuccessfully := waitForTowerUI(&resv2, &resv1)
        if (!openedSuccessfully) {
            ActiveRTowerID := ""
            return
        }
        CachedResV2 := IsSet(resv2) ? resv2 : ""
        CachedResV1 := IsSet(resv1) ? resv1 : ""
    } else {
        resv2 := CachedResV2
        resv1 := CachedResV1
    }

    path := Towers[towerID].path
    pathLevel := Towers[towerID].pathLevel
    nextLevel := Towers[towerID].level + 1

    doResV2 := (IsObject(resv2) && resv2.HasProp("score") && resv2.score > 0.55)

    if (doResV2) {
        upgAX := resv2.x - ScaleX(100)
        upgAY := resv2.y - ScaleY(260)
        upgAW := ScaleX(300)
        upgAH := ScaleY(110)
    } else if (IsObject(resv1)) {
        upgAX := resv1.x - ScaleX(344)
        upgAY := resv1.y + ScaleY(343)
        upgAW := ScaleX(300)
        upgAH := ScaleY(110)
    } else {
        return
    }

    region := [upgAX, upgAY, upgAW, upgAH]

    if (path != 0 && nextLevel > pathLevel && pathLevel != 0) {
        if (path = 2 && IsObject(resv1)) { 
            region := [resv1.x - ScaleX(344), resv1.y + ScaleY(488), ScaleX(300), ScaleY(110)]
        }
    }

    x1 := region[1]
    y1 := region[2]
    x2 := region[1] + region[3]
    y2 := region[2] + region[4]

    if (mx >= x1 && mx <= x2 && my >= y1 && my <= y2) {
        if PixelSearch(&gx, &gy, x1, y1, x2, y2, 0x206435, 7) {
            if (AdvancedImageSearch("Resources/fully_upgraded.png", x1, y1, region[3], region[4]).score >= 0.69) {
                return
            }

            Towers[towerID].level += 1
            LogToConsole("Upgraded tower " towerID " to level " Towers[towerID].level ".")
            UpdateTowerIndicator(towerID)
            
            if (Towers[towerID].path != 0 && Towers[towerID].path != "") {
                RecordedSteps.Push("UpgradeTower(" towerID ", false, 1, " Towers[towerID].path ", " Towers[towerID].pathLevel ")")
            } else {
                RecordedSteps.Push("UpgradeTower(" towerID ")")
            }
            
            if (Towers[towerID].level >= 2 && RegExMatch(towerID, "i)^Commander\d*$") && !Commander) {
                Commander := true
                if (!HasStep("Commander := true"))
                    RecordedSteps.Push("Commander := true")
            }
        }
    }
}

CataclysmPath() {
    AlignCamera(true, false)

    SendEvent("{WheelUp}")
}

SimplicityPath() {
    global LegacyMode
    attempts := 0
    Loop {
        AlignCamera(false, false)
        SendEvent("{sc01f Down}") 
        HyperSleep(2500)
        SendEvent("{sc01f Up}")
        HyperSleep(300)
        SendEvent("{sc01f Down}")
        SendEvent("{sc020 Down}")
        HyperSleep(2000)
        SendEvent("{sc01f Up}")
        SendEvent("{sc020 Up}")
        HyperSleep(300)
        SendEvent("{sc01e Down}")
        HyperSleep(125)
        SendEvent("{sc01e Up}")
        HyperSleep(300)
        SendEvent("{sc01f Down}")
        SendEvent("{sc020 Down}")
        HyperSleep(2000)
        SendEvent("{sc01f Up}")
        SendEvent("{sc020 Up}")
        HyperSleep(300)
        Send("{sc011 Down}")
        HyperSleep(1300)
        Send("{sc011 Up}")

        modifiers_str := (modifiers is Array) ? Join(modifiers) : String(modifiers)

        if (FileExist("Resources\Maps\Simplicity.png") && CheckTheMap = 1 && !RegExMatch(modifiers_str, "i)fog") && !LegacyMode)
        {
            getRobloxPos(,,&w,&h)
            FoundMap := false
            Loop 5 {
                res := AdvancedImageSearch("Resources\Maps\Simplicity.png", 0, 0, w, h, 0.5, 2)
                
                if (res.score > 0.65) {
                    FoundMap := true
                    LogToConsole("break " res.score )
                    break
                }
                
                Sleep(300)
            }

            if (!FoundMap) {
                if (attempts > 3)
                    SafeReload()
                LogToConsole("Can't detect the correct position! Resetting..", true)
                resetCharacter()
                Sleep(7500)
                attempts++
                continue
            }
        }
        break
    }
}

ToggleAutoskip() {
    global AutoSkip
    if AutoSkip = "ON" {
        AutoSkip := "OFF"
        LogToConsole("Toggled auto-skip: OFF")
    } else {
        AutoSkip := "ON"
        LogToConsole("Toggled auto-skip: ON")
    }
}

ChangeTargets(towerID, target) {
    global LastOpenedTowerID, needtocheckTowerUI, Towers, PotatoMode, ResV2, ResV1, canBeUpgraded, unfocusX, unfocusY
    canUseAbility := false
    
    if (LastOpenedTowerID != towerID) {
        Click(Towers[towerID].x, Towers[towerID].y)
        Sleep 250
    } else {
        MouseMove(0, ScaleY(50),, "R")
    }

    LastOpenedTowerID := towerID
    needtocheckTowerUI := true
    attempts := 0
    targets := ["First Enemy", "Last Enemy", "Strongest", "Weakest", "Closest", "Farthest", "Random"]

    LogToConsole("Changing " towerID " targets to " target "...")

    upgTime := A_TickCount
    Loop {
        openedSuccessfully := false
        StartTime := A_TickCount

        if (PotatoMode) {
            if (A_TickCount - upgTime > 600) {
                needtocheckTowerUI := true
                upgTime := A_TickCount
            }
        } else {
            needtocheckTowerUI := true
        }

        if (needtocheckTowerUI || (!IsObject(ResV2) && !IsObject(ResV1))) {
            openedSuccessfully := waitForTowerUI(&ResV2, &ResV1)

            if (!openedSuccessfully && canBeUpgraded) {
                attempts++
                if (attempts > 30) {
                    LogToConsole("Tower " towerID " menu not found after 30 attempts, reloading...", true)
                    SafeReload()
                }
                variation := Random(-4, 4)
                Click(Towers[towerID].x, Towers[towerID].y + ScaleY(variation))
                Sleep(100)
                continue
            } else {
                attempts := 0
                needtocheckTowerUI := false
            }
        }

        startedSearching := A_TickCount
        loop {
            if (A_TickCount - startedSearching > 5000)
            {
                LogToConsole("Failed to change tower targets...", true)
                return false
            }

            getRobloxPos(,,&w,&h)
            left := AdvancedImageSearch("Resources/TowerUI/left.png", 0,0,w/2,h/1.3)

            if left.score > 0.66 {
                right := AdvancedImageSearch("Resources/TowerUI/right.png", left.x+20,0,w/2,h/1.3)
                if right.score > 0.66 {
                    break
                } 
            }
            Sleep 150
        }

        currentTarget := Towers[towerID].target
        currentIndex := 0
        targetIndex := 0

        for index, name in targets {
            if (name == currentTarget)
                currentIndex := index
            if (name == target)
                targetIndex := index
        }

        if (currentIndex == 0)
            currentIndex := 1

        if (currentIndex == targetIndex) {
            Towers[towerID].target := target
        } else {
            diffRight := targetIndex - currentIndex
            if (diffRight < 0)
                diffRight += 7

            diffLeft := currentIndex - targetIndex
            if (diffLeft < 0)
                diffLeft += 7

            if (diffRight <= diffLeft) {
                clickCount := diffRight
                buttonToClick := right
            } else {
                clickCount := diffLeft
                buttonToClick := left
            }

            Loop clickCount {
                Click(buttonToClick.x, buttonToClick.y)
                Sleep 500
            }
            Towers[towerID].target := target
        }

        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep 250

        LastOpenedTowerID := ""
        Click(Towers[towerID].x, Towers[towerID].y)
        Sleep 250
        LastOpenedTowerID := towerID
        needtocheckTowerUI := true

        Loop {
            openedSuccessfully := false
            if (needtocheckTowerUI || (!IsObject(ResV2) && !IsObject(ResV1))) {
                openedSuccessfully := waitForTowerUI(&ResV2, &ResV1)
                if (!openedSuccessfully && canBeUpgraded) {
                    variation := Random(-4, 4)
                    Click(Towers[towerID].x, Towers[towerID].y + ScaleY(variation))
                    Sleep(100)
                    continue
                } else {
                    needtocheckTowerUI := false
                    break
                }
            }
            break
        }

        getRobloxPos(,,&w,&h)
        checkTargetImg := AdvancedImageSearch("Resources/TowerUI/" target ".png", 0,0,w/2,h/1.3)
        
        if (checkTargetImg.score > 0.66) {
            LogToConsole("Successfully changed tower's target to " target)
            break
        }

        bestScore := 0
        detectedTarget := "First Enemy"
        
        for index, name in targets {
            imgScan := AdvancedImageSearch("Resources/TowerUI/" name ".png", 0,0,w/2,h/1.3)
            if (imgScan.score > bestScore) {
                bestScore := imgScan.score
                detectedTarget := name
            }
        }

        Towers[towerID].target := detectedTarget
        
        if (detectedTarget == target) {
            LogToConsole("Successfully changed tower's target to " target)
            break
        }
    }

    canUseAbility := true
}

CloneTower(towerId, x, y, wait := 0) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, CancelPlacementKey, HologramKey, Recording,canUseAbility

    if (!Towers.Has(towerID)) {
        LogToConsole("Tower " towerID " not found!")
        return false
    }

    if (wait > 0 && !Recording) {
        Sleep(wait)
    }

    canUseAbility := false

    SendEvent("{" CancelPlacementKey "}")
    Sleep 50

    cloneTries := 0
    loop {
        cloneTries++
        SendEvent("{" CancelPlacementKey "}")
        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep(120)

        SendEvent("{" HologramKey "}")
        Sleep 300

        getRobloxPos(,,&w,&h)
        x1 := Round(w * 0.2)
        y1 := Round(h * 0.18)
        x2 := Round(w * 0.7)
        y2 := Round(h * 0.3)

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/hologram_tower_cooldown.png") || ReadMessage(["hologram", "ability", "is on", "cooldown", "hol%ram%", "ility"])) {
            LogToConsole("Failed to clone " towerId "! (hologram cooldown) Retrying again in 5 seconds...")
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        }

        baseX := Towers[towerId].x
        baseY := Towers[towerId].y

        baseX := Towers[towerId].x
        baseY := Towers[towerId].y

        found := false
        startTime := A_TickCount

        while (!found && (A_TickCount - startTime < 6000)) {
            loop 15 {
                variationY := A_Index - 8 

                MouseMove(baseX, baseY + variationY)
                Sleep 270 

                MouseGetPos(&mx, &my)
                
                cashX := mx + 69 
                cashY := my - 59
                
                x1 := cashX - 20
                y1 := cashY - 5
                x2 := cashX + 10
                y2 := cashY + 5

                if PixelSearch(&Fx, &Fy, x1, y1, x2, y2, 0x99BFD4, 6) {
                    found := true
                    MouseClick
                    break 2
                }
            }
            
            if (!found) {
                Sleep 100
            }
        }

        if !found {
            MouseClick(, baseX, baseY)
        }

        Sleep 350

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/no_cash_cloning.png") || ReadMessage(["don't", "have", "enough", "cash", "clone", "this"])) {
            LogToConsole("Failed to clone " towerId "! (no cash) Retrying again in 5 seconds...")
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        }
        
        openedUI := waitForTowerUI(,,500)
        if (openedUI) {
            LogToConsole("Failed to clone tower: accidentally opened upgrade ui! Retrying again..")
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(500)
            continue
        }

        MouseMove(x,y)
        Sleep 100
        MouseClick()

        Sleep 50
        SendEvent("{" CancelPlacementKey "}")

        Sleep 350

        MouseMove(ScaleX(unfocusX), ScaleY(unfocusY))

        Sleep 100

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/stunned.png") || ReadMessage(["error", "that", "cannot", "cann", "activated", "while", "stunned"],,["need", "more", "to"],"\$|\d")) {
            LogToConsole("Failed to clone " towerId "! (hacker is stunned) Retrying again in 5 seconds...")
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        }

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/cannot_place_here.png") || ReadMessage(["cannot", "here", "hereg", "herd", "her", "here!", "cann", "cannd", "he", "h", "hed"],,["need", "more", "to"],"\$|\d")) {
            LogToConsole("Failed to clone " towerId "! (cannot place here!) Retrying again in 5 seconds...")
            canUseAbility := true
            Sleep 4650
            canUseAbility := false
            continue
        } else {
            if (cloneTries > 1)
                AuditLog("RECOVERED", "Clone", "Tower " towerId " cloned after " cloneTries " attempts")
            LogToConsole("Successfully cloned tower " towerId ".")
            break
        }
    }

    canUseAbility := true
}

BrawlerReposition(towerId, x, y) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, CancelPlacementKey, RepoKey, Recording

    canUseAbility := false

    loop {

        if (!Towers.Has(towerID)) {
            LogToConsole("Tower " towerID " not found!")
            return false
        }

        SendEvent("{" CancelPlacementKey "}")
        Sleep 20

        if (LastOpenedTowerID != towerId && LastOpenedTowerID != "") {
            click(ScaleX(unfocusX), ScaleY(unfocusY))
        }

        Sleep 50

        if (LastOpenedTowerID != towerId) {
            click(Towers[towerId].x, Towers[towerId].y)
        }

        attempts := 0
        
        Loop {
            opened := waitForTowerUI()
            if opened {
                attempts := 0
                break
            } else {
                attempts++
                if (attempts > 30) {
                    LogToConsole("Tower " towerID " menu not found after 30 attempts, reloading...", true)
                    SafeReload()
                }
                variation := Random(-4, 4)
                Click(Towers[towerId].x, Towers[towerId].y + ScaleY(variation))
                Sleep(100)
                continue
            }

        }

        getRobloxPos(,,&w,&h)
        send "{" RepoKey "}"

        x1 := Round(w * 0.2)
        y1 := Round(h * 0.18)
        x2 := Round(w * 0.7)
        y2 := Round(h * 0.3)

        Sleep 300

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/reposition_cooldown.png") || ReadMessage(["reposition", "ability", "is on", "cooldown", "ility"])) {
            LogToConsole("Failed to reposition brawler! Retrying again in 4.5 seconds...")
            Sleep 4500
            continue
        }

        placeattempts := 0
        px := x, py := y
        Loop {
            placeattempts++

            if (placeattempts > 5) {
                Send("{" CancelPlacementKey "}")
                LogToConsole("Failed to reposition brawler :( ")
                return false
            }

            MouseMove(px,py)
            Sleep 20
            MouseClick

            sleep 400

            if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/cannot_place_here.png") || ReadMessage(["cannot", "here", "hereg", "herd", "her", "here!", "cann", "cannd", "he", "h", "hed"],,["need", "more", "to"],"\$|\d")) {
                LogToConsole("Failed to reposition brawler: cannot place here! Retrying..")
                Sleep 4400
                variation := Random(-3, 3)
                py := y + variation
                continue
            } else {
                break
            }
        }

        if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/stunned.png") || ReadMessage(["error", "that", "cannot", "cann", "activated", "while", "tower", "tmeer", "stunned"],,["need", "more", "to"],"\$|\d")) {
            LogToConsole("Failed to reposition brawler! Retrying again in 4.5 seconds...")
            Sleep 4400
            continue
        }

        Towers[towerId].x := x
        Towers[towerId].y := y
        UpdateTowerIndicator(towerId)
        if (placeattempts > 1)
            AuditLog("RECOVERED", "Reposition", "Brawler " towerId " repositioned to " x "," y " after " placeattempts " placement attempts")
        LogToConsole("Successfully reposited " towerId " to " x ", " y ".")
        break
    }

    canUseAbility := true
}

ActivateRaiseTheDead(wait := 0) {
    global CancelPlacementKey, LastOpenedTowerID, unfocusX, unfocusY, RaiseDeadKey, Recording

    if (wait > 0 && !Recording) {
        Sleep(wait)
    }

    SendEvent("{" CancelPlacementKey "}")
    if (LastOpenedTowerID != "") {
        Click(ScaleX(unfocusX), ScaleY(unfocusY))
        Sleep(450)
    }

    SendEvent("{" RaiseDeadKey "}")
    LogToConsole("Successfully activated 'Raise the Dead'")
}

SpawnTower(X, Y, slotNumber, towerID) {
    global Towers, LastOpenedTowerID, CancelPlacementKey, canUseAbility, UseNumbersForHotbar, Slots
    LogToConsole("Placing tower " towerID " (slot " slotNumber ") at x:" X " y:" Y "...")

    X := sX(X, StrategyWidth)
    Y := sY(Y, StrategyHeight)
    
    getRobloxPos(,,,&h)
    TowerY := Y
    if (Y < h * 0.5) {
        TowerY := Y - ScaleY(5)
    }

    placeAttempts := 0
    attemptMultiplier := 1
    startTime := A_TickCount
    canUseAbility := false

    Loop {
        placeAttempts++

        if (A_TickCount - startTime > 300000) {
            LogToConsole("Tower placement timed out (5+ minutes). Reloading the macro...")
            SafeReload()
            return
        }

        ActivateRoblox()
        
        if UseNumbersForHotbar {
            Send("{" slotNumber "}")
        } else {
            Click(Slots[slotNumber])
        }

        Sleep((PotatoMode = 1) ? 100 : 30)
        
        MouseMove(X, Y, A_DefaultMouseSpeed)
        Sleep((PotatoMode = 1) ? 100 : 40)
        MouseClick()
        Sleep(100)
        SendEvent("{" CancelPlacementKey "}")

        placedSuccessfully := waitForTowerUI(&resV2)

        if (placedSuccessfully) {
            Towers[towerID] := {x: X, y: TowerY, slot: Integer(slotNumber), level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
            LogToConsole("Tower " towerID " placed successfully")
            LastOpenedTowerID := towerID
            break
        } else {
            LogToConsole("Tower " towerID " placement failed, retrying...")
            if (placeAttempts = 1)
                AuditLog("WARN", "Placement", "Tower " towerID " (slot " slotNumber ") could not be placed at " X "," Y " - retrying")
            if (placeAttempts = 1) {
                continue
            }

            getRobloxPos(,,&w,&h)
            x1 := Round(w * 0.2)
            y1 := Round(h * 0.18)
            x2 := Round(w * 0.7)
            y2 := Round(h * 0.3)
            if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/cannot_place_here.png") || ReadMessage(["cannot", "here", "hereg", "herd", "her", "here!", "cann", "cannd", "he", "h", "hed"],,["need", "more", "to"],"\$|\d")) {
                MouseClick()

                placedSuccessfully := waitForTowerUI(&resV2)
                if (placedSuccessfully) {
                    Towers[towerID] := {x: X, y: TowerY, slot: Integer(slotNumber), level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
                    AuditLog("RECOVERED", "Placement", "Tower " towerID " placed at original spot " X "," Y " after " placeAttempts " attempts")
                    LogToConsole("Tower " towerID " placed successfully")
                    LastOpenedTowerID := towerID
                    break
                }

                offsets := [[0, -5 * attemptMultiplier], [5 * attemptMultiplier, 0], [0, 5 * attemptMultiplier], [-5 * attemptMultiplier, 0]]
                placedSuccessfully := false

                ActivateRoblox()
        
                Send("{" slotNumber "}")
                Sleep(30)

                LogToConsole("Cannot place here! Trying to place tower in different spots...")
                
                for index, offset in offsets {
                    if (A_TickCount - startTime > 300000) {
                        LogToConsole("Tower placement timed out during offset retry. Executing safereload()...")
                        safeReload()
                        return
                    }

                    newX := X + offset[1]
                    newY := Y + offset[2]
                    
                    MouseMove(newX, newY, A_DefaultMouseSpeed)
                    Sleep((PotatoMode = 1) ? 100 : 40)
                    MouseClick()
                    Sleep(100)

                    placedSuccessfully := waitForTowerUI(&resV2)
                    if (placedSuccessfully) {
                        Towers[towerID] := {x: newX, y: newY, slot: Integer(slotNumber), level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
                        AuditLog("RECOVERED", "Placement", "Tower " towerID " placed at offset (" offset[1] "," offset[2] ") from " X "," Y " after " placeAttempts " attempts")
                        LogToConsole("Tower " towerID " placed successfully")
                        LastOpenedTowerID := towerID
                        break 2
                    }
                }
                
                if (!placedSuccessfully) {
                    SendEvent("{" CancelPlacementKey "}")
                    attemptMultiplier := attemptMultiplier * 2
                }
            } 
        }
    }
    canUseAbility := true
}

SellTower(towerID) {
    global Towers, unfocusX, unfocusY

    if (!Towers.Has(towerID)) {
        LogToConsole("Tower " towerID " not found for selling!")
        return false
    }

    LogToConsole("Selling tower " towerID "...")
    targetX := Towers[towerID].x
    targetY := Towers[towerID].y
    Click(targetX, targetY)
    Sleep(400)

    attempts := 0
    Loop {
        menuFound := waitForTowerUI()
        
        if (!menuFound) {
            attempts++
            if (attempts > 15) {
                LogToConsole("Tower " towerID " menu not found for selling")
                return false
            }
            variation := Random(-10, 10)
            Click(Towers[towerID].x, Towers[towerID].y + variation)
            Sleep(400)
            continue
        }
        getRobloxPos(&rx, &ry, &w, &h)
        X1_v2 := 0
        Y1_v2 := Round(h/2)
        W_v2 := Round(w * 0.3) - X1_v2
        H_v2 := Round(h) - Y1_v2

        resV2 := AdvancedImageSearch("Resources\TowerUI\Variant2.png", X1_v2, Y1_v2, W_v2, H_v2, ,,0.05)

        if (resV2.score > 0.55) {
            Click(resV2.x, resV2.y)
        }

        LogToConsole("Tower " towerID " sold successfully")
        if (Towers[towerID].hwnd) {
            WinClose("ahk_id " Towers[towerID].hwnd)
        }
        Towers.Delete(towerID)
        return true
    }
    return false
}

UpgradeTower(towerID, skipOpen := false, totalUpgrades := 1, path := 0, pathLevel := 0) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, needtocheckTowerUI, UpgradeDelay
    global PotatoMode, Recording, RecordedSteps, Commander, canUseAbility

    static resV2 := 0
    static resV1 := 0

    needtocheckTowerUI := true

    if (!Towers.Has(towerID)) {
        LogToConsole("Tower " towerID " not found!")
        return false
    }

    targetX := Towers[towerID].x
    targetY := Towers[towerID].y

    if (!skipOpen && LastOpenedTowerID != towerID) {
        canUseAbility := false
        Click(targetX, targetY)
        Sleep 250
        canUseAbility := true
    }

    LastOpenedTowerID := towerID
    upgradesDone := 0
    attempts := 0

    upgTime := A_TickCount

    Sleep(20)

    Loop {
        openedSuccessfully := false
        StartTime := A_TickCount

        if (PotatoMode) {
            if (A_TickCount - upgTime > 600) {
                needtocheckTowerUI := true
                upgTime := A_TickCount
            }
        } else {
            needtocheckTowerUI := true
        }

        if (needtocheckTowerUI || (!IsObject(ResV2) && !IsObject(ResV1))) {
            openedSuccessfully := waitForTowerUI(&ResV2, &ResV1)

            if (!openedSuccessfully && canBeUpgraded) {
                attempts++
                if (attempts > 30) {
                    LogToConsole("Tower " towerID " menu not found after 30 attempts, reloading...", true)
                    SafeReload()
                }
                variation := Random(-4, 4)
                Click(targetX, targetY + ScaleY(variation))
                Sleep(100)
                continue
            } else {
                attempts := 0
                needtocheckTowerUI := false
            }
        }
        
        doResV2 := (IsObject(resV2) && resV2.HasProp("score") && resV2.score > 0.55)

        if (doResV2) {
            UpgradeX := resV2.x+ScaleX(50)
            UpgradeY := resV2.y-ScaleY(220)

            upgAX := resV2.x + ScaleX(20)
            upgAY := resV2.y - ScaleY(240)
            upgAW := ScaleX(80)
            upgAH := ScaleY(70)
        } else {
            if (!IsObject(ResV1)) {
                needtocheckTowerUI := true
                Sleep(50)
                continue
            }
    
            UpgradeX := resV1.x-ScaleX(164)
            UpgradeY := resV1.y+ScaleY(383)

            upgAX := resV1.x - ScaleX(194)
            upgAY := resV1.y + ScaleY(363)
            upgAW := ScaleX(80)
            upgAH := ScaleY(70)
        }
        
        nextLevel := Towers[towerID].level + 1

        region := [upgAX, upgAY, upgAW, upgAH]

        if (path != 0 && nextLevel > pathLevel && pathLevel != 0) {
            if (path = 2) { 
                if (doResV2) {
                    region := [resV2.x+ScaleX(20), resV2.y-ScaleY(95), ScaleX(80), ScaleY(70)]
                    UpgradeY := resV2.y-ScaleY(120)
                } else {
                    region := [resV1.x - ScaleX(194), resV1.y + ScaleY(508), ScaleX(80), ScaleY(70)]
                    UpgradeY := resV1.y + ScaleY(483)
                }
            }
        } 

        XA := region[1]
        YA := region[2]
        WA := region[3]
        HA := region[4]

        X2 := XA + WA
        Y2 := YA + HA

        searchArea := XA "|" YA "|" X2 "|" Y2

        try {
            isGreen := PixelSearch(&gx, &gy, XA, YA, X2, Y2, 0x206235, 12)
        } catch Error {
            isGreen := false
        }
        if (isGreen && canBeUpgraded) {
            canUseAbility := false
            if (UseHForUpgrade) {
                if (path != 0 && nextLevel > pathLevel && pathLevel != 0) {
                    if (path = 1) { 
                        SendEvent("{" UpgradeTowerGKey "}")
                    } else if (path = 2) {
                    SendEvent("{" UpgradeTowerGBKey "}")
                    } 
                } else {
                    SendEvent("{" UpgradeTowerGKey "}")
                }
            } else {
                Click(UpgradeX, UpgradeY)
            }

            Sleep(UpgradeDelay)

            Towers[towerID].level += 1
            upgradesDone++
            LogToConsole("Tower " towerID " upgraded to level " Towers[towerID].level " (" upgradesDone "/" totalUpgrades ")")
            UpdateTowerIndicator(towerID)

            if (Towers[towerID].level >= 2 && RegExMatch(towerID, "i)^Commander\d*$") && !Commander) {
                Commander := true
                if (Recording && !HasStep("Commander := true"))
                    RecordedSteps.Push("Commander := true")
            }

            canUseAbility := true

            if (upgradesDone >= totalUpgrades) 
                return true

            continue
        }
    }
}

UseAbilities(*) {
    global ChainKey, BeatKey, CaravanKey, CancelPlacementKey, TimeScaleMultiplier, AutoSkip, AbilitySpam
    global autoChain, autoCaravan, autoDropTheBeat, Commander, unfocusX, unfocusY, canUseAbility
    global LastOpenedTowerID, Towers, TimescaleActive, needtocheckTowerUI
    static LastChainTime := 0, LastDropTime := 0, LastCaravanTime := 0

    if (!canUseAbility) {
        return
    }

    multiplier := 1
    if (TimescaleActive) {
    multiplier := TimescaleMultiplier
    } 

    caravanInterval := 26
    chainInterval := 14

    if (AbilitySpam = "ON") {
        caravanInterval := 20
        chainInterval := 10
    }

    if (AutoSkip = "ON") {
        res := AdvancedImageSearch("Resources/Skip.png", Round(A_ScreenWidth * 0.3), 0, Round(A_ScreenWidth * 0.7), Round(A_ScreenHeight * 0.35), 0.5, 1.5)
        if (res.status = "success" && res.score >= 0.65) {
            Sleep(200)
            res := AdvancedImageSearch("Resources/Skip.png", Round(A_ScreenWidth * 0.3), 0, Round(A_ScreenWidth * 0.7), Round(A_ScreenHeight * 0.35), 0.5, 1.5)
            if (res.status = "success" && res.score >= 0.65) {
                SendEvent("{" CancelPlacementKey "}")
                MouseGetPos(&cx, &cy)
                Click(res.x, res.y)
                Sleep(30)
                MouseMove(cx, cy)
                Sleep(20)
                LogToConsole("skipped wave")
            }
        }
    }

    if (autoChain = "ON" && Commander && (A_TickCount - LastChainTime > chainInterval * 1000 / multiplier)) {
        canUseAbility := false
        canBeUpgraded := false
        if (LastOpenedTowerID != "") {
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(100)
        }
        LastChainTime := A_TickCount
        SendEvent("{" ChainKey "}")
        LogToConsole("Activated Call of Arms")
        canUseAbility := true
        if (LastOpenedTowerID != "" && Towers.Has(LastOpenedTowerID)) {
            Click(Towers[LastOpenedTowerID].x, Towers[LastOpenedTowerID].y)
            Sleep 250
        }
        canBeUpgraded := true
        needtocheckTowerUI := true
    }

    if (autoCaravan = "ON" && (A_TickCount - LastCaravanTime > caravanInterval * 1000 / multiplier)) {

        foundCommander := false
        for name, towerID in Towers {
            if towerID.level >= 4 && RegExMatch(name, "i)^Commander\d*$") {
                foundCommander := true
                break
            }
        }

        if (!foundCommander) {
            return
        }

        canBeUpgraded := false
        
        canUseAbility := false
        SendEvent("{" CancelPlacementKey "}")
        if (LastOpenedTowerID != "") {
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(300)
        }
        LastCaravanTime := A_TickCount
        SendEvent("{" CaravanKey "}")
        LogToConsole("Activated Support Caravan")
        if (LastOpenedTowerID != "" && Towers.Has(LastOpenedTowerID)) {
            Click(Towers[LastOpenedTowerID].x, Towers[LastOpenedTowerID].y)
            Sleep 400
        }
        canUseAbility := true
        canBeUpgraded := true
        needtocheckTowerUI := true
    }

    if (autoDropTheBeat = "ON" && Towers.Has("DJ") && Towers["DJ"].level >= 3 && (A_TickCount - LastDropTime > 28000 / multiplier)) {

        canBeUpgraded := false

        SendEvent("{" CancelPlacementKey "}")
        if (LastOpenedTowerID != "DJ" && LastOpenedTowerID != "") {
            Click(ScaleX(unfocusX), ScaleY(unfocusY))
            Sleep(100)
        }

        Loop {
            LastDropTime := A_TickCount
            SendEvent("{" BeatKey "}")

            Sleep 350
            getRobloxPos(,,&w,&h)
            x1 := Round(w * 0.2)
            y1 := Round(h * 0.18)
            x2 := Round(w * 0.7)
            y2 := Round(h * 0.3)
            if (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/stunned.png") || ReadMessage(["error", "that", "cannot", "cann", "activated", "while", "stunned"],,["need", "more", "to"],"\$|\d")) {
                LogToConsole("Failed to use Drop the Beat! The tower is stunned! Retrying...")
                Sleep 4400
            } else {    
                LogToConsole("Successfully used Drop the Beat")
                break
            }
        }

        if (LastOpenedTowerID != "" && LastOpenedTowerID != "DJ" && Towers.Has(LastOpenedTowerID)) {
            Click(Towers[LastOpenedTowerID].x, Towers[LastOpenedTowerID].y)
            Sleep 250
        }
        canBeUpgraded := true
        canUseAbility := true
        needtocheckTowerUI := true
    }
}

SetDJTrack(track) {
    global Towers, unfocusX, unfocusY, LastOpenedTowerID, UseTimeScale, TimeScaleMode
    if (!Towers.Has("DJ")) {
        LogToConsole("DJ tower not found!")
        return
    }
    LogToConsole("Setting DJ track to " track "...")
    canUseAbility := false
    needtocheckTowerUI := true
    
    cleanTrack := StrReplace(track, '"', '')
    cleanTrack := StrReplace(cleanTrack, "'", "")
    trackName  := Format("{:L}", cleanTrack)

    if (LastOpenedTowerID != "DJ") {
        Click(Towers["DJ"].x, Towers["DJ"].y)
        LastOpenedTowerID := "DJ"
    }

    Sleep(200)

    upgTime := A_TickCount

    Loop {
        getRobloxPos(&rx, &ry, &w, &h)
        startTime := A_TickCount

        openedSuccessfully := false
        StartTime := A_TickCount

        if (PotatoMode) {
            if (A_TickCount - upgTime > 600) {
                needtocheckTowerUI := true
                upgTime := A_TickCount
            }
        } else {
            needtocheckTowerUI := true
        }

        if (needtocheckTowerUI) {
            openedSuccessfully := waitForTowerUI(&resv2, &resv1)

            if (!openedSuccessfully) {
                variation := Random(-10, 10)
                Click(Towers["DJ"].x, Towers["DJ"].y + ScaleY(variation))
                Sleep(400)
                continue
            }
        }

        DJTrack := resV2 := AdvancedImageSearch("Resources\" trackName ".png", 0, 0, w, h, 0.5, 1.5, 0.05)
        if (DJTrack.score > 0.6) {
            MouseGetPos(&cx, &cy)
            MouseClick(,DJTrack.x, DJTrack.y)

            Sleep 400
            getRobloxPos(,,&w,&h)
            x1 := Round(w * 0.2)
            y1 := Round(h * 0.18)
            x2 := Round(w * 0.7)
            y2 := Round(h * 0.3)
            If (ImageSearch(&fx,&fy,x1,y1,x2,y2, "*Trans000000 *50 " A_WorkingDir "/Resources/please_wait.png") || ReadMessage(["please", "wait"])) {
                LogToConsole("Need to wait before swithcing the track. Waiting 5 seconds...")
                Sleep(4500)
                continue
            } else {
                LogToConsole("Successfully changed DJ track to " track)
            }

            Sleep 10
            MouseMove(cx, cy)
        }
        break
    }
    canUseAbility := true
}

UpdateTowerIndicator(towerID) {
    global Towers, Recording, ShowIndicators, MainGui
    if (!Recording || !ShowIndicators || !Towers.Has(towerID))
        return
        
    Critical

    level := Towers[towerID].level
    MultiplePaths := (Towers[towerID].path != 0 && Towers[towerID].path != "")

    DetectHiddenWindows True
    
    oldMatchMode := A_TitleMatchMode
    SetTitleMatchMode 3 

    tTitle := "TowerIndicator_" towerID

    mainHwnd := 0
    try mainHwnd := MainGui.Hwnd

    If (Towers[towerID].HasProp("hwnd") && Towers[towerID].hwnd) {
        currentHwnd := Towers[towerID].hwnd
        if (currentHwnd != mainHwnd && WinExist("ahk_id " currentHwnd)) {
            try GuiFromHwnd(currentHwnd).Destroy()
        }
        Towers[towerID].hwnd := 0
    }

    if (oldHwnd := WinExist(tTitle " ahk_class AutoHotkeyGUI")) {
        if (oldHwnd != mainHwnd) {
            try GuiFromHwnd(oldHwnd).Destroy()
        }
    }

    clientLeft := 0
    clientTop := 0
    
    getRobloxPos(,, &clientLeft, &clientTop)
    
    hwnd := GetRobloxHWND()
    pt := Buffer(8, 0)
    DllCall("ClientToScreen", "UPtr", hwnd, "Ptr", pt)
    
    x := NumGet(pt, 0, "Int") + Towers[towerID].x - 16
    y := NumGet(pt, 4, "Int") + Towers[towerID].y - 16

    styleStr := "+ToolWindow +AlwaysOnTop -Caption +Disabled +Border +E0x20 +E0x08000000"

    tg := Gui(styleStr, tTitle)
    tg.BackColor := MultiplePaths ? "1A1A1A" : "FFFFFF"
    
    if (MultiplePaths)
        tg.SetFont("s12 w600 cFFFFFF", "Bahnschrift")
    else
        tg.SetFont("s10 c000000", "Arial")
    
    idLen := StrLen(towerID)

    if (idLen <= 3) {
        fontSize := "s12"
    } else if (idLen <= 5) {
        fontSize := "s8"
    } else if (idLen <= 8) {
        fontSize := "s6"
    } else if (idLen <= 11) {
        fontSize := "s4"
    } else {
        fontSize := "s3"
    }

    tg.SetFont("Bold " fontSize)

    tg.Add("Text", "x0 y0 w32 h24 Center BackgroundTrans 0x200", towerID)

    tg.SetFont("s8 norm")
    tg.Add("Text", "x0 y22 w32 h8 Center BackgroundTrans 0x200", level)
    
    tg.Show("x" x " y" y " w32 h32 NoActivate")
    
    WinSetTransparent(128, "ahk_id " tg.Hwnd)
    
    Towers[towerID].hwnd := tg.Hwnd

    SetTitleMatchMode oldMatchMode
    Critical("Off")
}

DeleteAllIndicators() {
    global Towers
    Critical("On")
    SetWinDelay(-1) 
    for id, t in Towers {
        if (t.HasProp("hwnd") && t.hwnd) {
            WinClose("ahk_id " t.hwnd)
            t.hwnd := ""
        }
    }
    SetWinDelay(10) 
    Critical("Off")
}

GetNextTowerID(slot) {
    global requiredTowers, Towers

    slotArray := StrSplit(requiredTowers, ",")
    for index, name in slotArray {
        slotArray[index] := Trim(name)
    }

    targetSlot := Integer(slot)
    if (targetSlot > slotArray.Length || targetSlot < 1) {
        baseName := ""
    } else {
        baseName := slotArray[targetSlot]
    }
    
    if (InStr(baseName, "DJ") || InStr(baseName, "DJ Booth")) {
        baseName := "DJ"
    }
    
    count := 0

    if (IsObject(Towers)) {
        for id, t in Towers {
            if (RegExMatch(id, "i)^" baseName "(\d+)$", &match)) {
                num := Integer(match[1])
                if (num > count) {
                    count := num
                }
            }
        }
    }

    if (InStr(baseName, "DJ")) {
        return baseName
    } else {
        return baseName (count + 1)
    }
}

waitForTowerUI(&resV2 := "", &resV1 := "", timeout := 0) {
    global PotatoMode
    StartTime := A_TickCount
    Loop {
        getRobloxPos(&rx, &ry, &w, &h)
        X1_v2 := Round(w * 0.02)
        Y1_v2 := Round(h/2.5)
        W_v2 := Round(w * 0.22) - X1_v2
        H_v2 := Round(w * 0.95) - Y1_v2

        resV2 := AdvancedImageSearch("Resources\TowerUI\Variant2.png", X1_v2, Y1_v2, W_v2, H_v2, ,,0.05)

        if (resV2.status == "success" && resV2.score > 0.55) {
            return true
        }

        Sleep(30)

        X1_v1 := Round(w * 0.16)
        Y1_v1 := Round(h * 0.05)
        W_v1  := Round(w * 0.2) - X1_v1
        H_v1 := Round(h * 0.3) - Y1_v1
        resV1 := AdvancedImageSearch("Resources\TowerUI\Variant1.png", X1_v1, Y1_v1, W_v1, H_v1, ,,0.05)

        if (resV1.status == "success" && resV1.score > 0.68) {
            return true
        }
        Sleep(30)

        if (timeout != 0) {
            if (A_TickCount - StartTime > timeout) {
                return false
            }
        }

        if (A_TickCount - StartTime > (PotatoMode == 1 ? 3500 : 2200)) {
            return false
        }

    }
}
