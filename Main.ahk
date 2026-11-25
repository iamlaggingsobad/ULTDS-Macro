; Heavily Modified Version of Ultimate Macro (macro for TDS) by Darksen v1.3.3a, by IAmLaggingSoBad

#Requires AutoHotkey v2.0
#SingleInstance Force

SetWorkingDir(A_ScriptDir)
CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")

ListLines(False)
KeyHistory(0)
SetTitleMatchMode(1)

if (RegExMatch(A_ScriptDir, "i)\.(zip|rar)")) {
    MsgBox("You are attempting to run the script from a ZIP file.`n`nPlease Extract/Unzip the file first, then run the script in the extracted folder.","Running From ZIP", 0x10)
    ExitApp()
}

; close an already-running copy (the old "Ultimate Macro" window title is checked too, so an older build is closed as well)
for oldTitle in ["Unlimited Macro", "Ultimate Macro"] {
    if WinExist(oldTitle)
        WinClose(oldTitle)
}

if (A_PtrSize == 4) {
    MsgBox("You are running 32-bit AutoHotkey, the macro will not work properly, sadly.")
}

#Include lib\Gdip_All.ahk
#Include lib\OCR.ahk
#Include lib\Gdip_ImageSearch.ahk
#Include lib\Roblox.ahk
#Include lib\HyperSleep.ahk
#Include lib\ImageSearch\ImageSearch.ahk
#Include lib\JSON.ahk
#Include lib\Discord.ahk
#Include lib\MapDatabase.ahk
#Include lib\TowerDatabase.ahk
#Include lib\ModifierDatabase.ahk
#Include lib\RewardDatabase.ahk

command_buffer := []

ver := "1.3.3a"

A_MaxHotkeysPerInterval := 9999

pToken := Gdip_Startup()
OnExit(CleanupGdip)
OnExit(HandleExit)

; The app data folder was renamed from Ultimate_Macro to Unlimited_Macro. On first launch, copy the old settings,
; recordings and logs across so nothing is lost (the old folder is left untouched).
if (DirExist(A_AppData "\Ultimate_Macro") && !DirExist(A_AppData "\Unlimited_Macro")) {
    try DirCopy(A_AppData "\Ultimate_Macro", A_AppData "\Unlimited_Macro")
}

global AppDataOpt := A_AppData "\Unlimited_Macro\Options"
global SettingsFile := AppDataOpt "\Settings.tds"
global BotSettings := AppDataOpt "\Discord-Bot-Settings.ini"
global RecordingsDir := A_AppData "\Unlimited_Macro\Recordings"
global StateFile := A_AppData "\Unlimited_Macro\state.ini"

global MyStratsDir := A_WorkingDir "\Strategies"   ; your own strategies, next to Main.ahk (Add / Remove in the Main tab)

global ShowIndicators := true

global WebhookQueue := []
global WebhookTimerActive := false
global WebhookInstantQueue := []
global WebhookInstantTimerActive := false
global WebhookEnabled := false

if !DirExist(AppDataOpt)
    DirCreate(AppDataOpt)
if !DirExist(RecordingsDir)
    DirCreate(RecordingsDir)
if !DirExist(MyStratsDir)
    DirCreate(MyStratsDir)

;INI READS
global VipLink := IniRead(SettingsFile, "Options", "VipLink", "") 
global UseVipServer := IniRead(SettingsFile, "Options", "UseVipServer", "0")
global AlwaysOnTop := IniRead(SettingsFile, "Options", "AlwaysOnTop", 0)

global LegacyMode := IniRead(SettingsFile, "Options", "LegacyMode", 0)

global WebhookLink := IniRead(SettingsFile, "Webhook", "Link", "")
global WebhookLink2 := IniRead(SettingsFile, "Webhook", "Link2", "")
global WebhookUserID := IniRead(SettingsFile, "Webhook", "WebhookUserID", "")
global PingOnWin := Integer(IniRead(SettingsFile, "Webhook", "PingOnWin", 0))
global PingOnLoss := Integer(IniRead(SettingsFile, "Webhook", "PingOnLoss", 0))
global PingOnTimescale := Integer(IniRead(SettingsFile, "Webhook", "PingOnTimescale", 0))
global WebhookEnabled := IniRead(SettingsFile, "Webhook", "Enabled", 0)
global PotatoMode := IniRead(SettingsFile, "Options", "PotatoMode", 0)
global SendCurrenciesEnabled := IniRead(SettingsFile, "Webhook", "SendCurrencies", "1")
global WebhookDebugLogs := IniRead(SettingsFile, "Webhook", "WebhookDebugLogs", "1")
global WebhookScreenshots := IniRead(SettingsFile, "Webhook", "WebhookScreenshots", "1")
global WebhookTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookTriumphScreenshots", 1)
global WebhookSepatateTriumphScreenshots := IniRead(SettingsFile, "Webhook", "WebhookSepatateTriumphScreenshots", 0)
;
global BotToken := IniRead(BotSettings, "Token", "BotToken", "")
global BotEnabled := IniRead(BotSettings, "Settings", "Enabled", 0)
global ChannelID := IniRead(BotSettings, "Settings", "Channel", "")
global UserID := IniRead(BotSettings, "Settings", "UserID", "")
;
global UseRestartBtn := IniRead(SettingsFile, "Options", "UseRestartBtn", "1")
global UsePlayAgainBtn := IniRead(SettingsFile, "Options", "UsePlayAgainBtn", "1")
global RotateStrategies := IniRead(SettingsFile, "Options", "RotateStrategies", 0)
global AutoEquip := IniRead(SettingsFile, "Options", "AutoEquip", 0)
global CheckTheMap := IniRead(SettingsFile, "Options", "CheckTheMap", 1)
global UseNumbersForHotbar := IniRead(SettingsFile, "Options", "UseNumbers", 1)
global UseHForUpgrade := IniRead(SettingsFile, "Options", "UseHotkeyForUpgrade", 1)
global CollectPlaytimeRewards:= IniRead(SettingsFile, "Options", "CollectPlaytimeRewards", 1)
global AutoCloseChat := IniRead(SettingsFile, "Options", "AutoCloseChat", 1)
global Strategy1Path := IniRead(SettingsFile, "Options", "Strategy1", "")
global Strategy2Path := IniRead(SettingsFile, "Options", "Strategy2", "")
global PartyMembers := IniRead(SettingsFile, "Multiplayer", "PartyMembers", "someone, someone...")
global PlayerRole := IniRead(SettingsFile, "Multiplayer", "PlayerRole", "Host")
global LeaveCondition := IniRead(SettingsFile, "Multiplayer", "LeaveCondition", "Any")
global HostName := IniRead(SettingsFile, "Multiplayer", "HostName", "...")
global MultiplayerEnabled := IniRead(SettingsFile, "Multiplayer", "MultiplayerEnabled", 0)

global DefaultMouseSpeed := IniRead(SettingsFile, "Options", "DefaultMouseSpeed", "2")
global MouseDelay := IniRead(SettingsFile, "Options", "MouseDelay", "-1")
global KeyDelay := IniRead(SettingsFile, "Options", "KeyDelay", "-1")

global PlaceTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "PlaceTowerKey", "f")
global UpgradeTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "UpgradeTowerKey", "^u")
global AlignCameraKey := IniRead(SettingsFile, "RecordingHotkeys", "AlignCameraKey", "^t")
global ChangeDJTrackKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey", "^d")
global SellTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "SellTowerKey", "^x")
global DeleteTowerRecordingKey := IniRead(SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey", "^b")
global RecordInputsKey := IniRead(SettingsFile, "RecordingHotkeys", "RecordInputsKey", "^+e")
global HoloKey := IniRead(SettingsFile, "RecordingHotkeys", "HoloKey", "^!h")
global ChangeTargetsKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeTargetsKey", "^vkC0")

global CurrentStratStartTime := Integer(IniRead(StateFile, "State", "CurrentStratStartTime", "0"))
global CurrentRotationIndex := Integer(IniRead(StateFile, "State", "CurrentRotationIndex", "1"))

global g_IsFirstLaunch := Integer(IniRead(StateFile, "State", "IsFirstLaunch", 1))

global SwapAmount := IniRead(SettingsFile, "Options", "SwapAmount", "4")
global SwapUnit := IniRead(SettingsFile, "Options", "SwapUnit", "Runs")
global CurrentRunCount := Integer(IniRead(StateFile, "State", "CurrentRunCount", "0"))

SendMode("Event")
SetDefaultMouseSpeed(DefaultMouseSpeed)
SetMouseDelay(MouseDelay)
SetKeyDelay(KeyDelay)

global LogLines := []
global OverlayHWND := 0
global OverlayBitmap := 0
global OverlayGraphics := 0
global OverlayPicHWND := 0
global OverlayWidth := 500
global OverlayHeight := 200
global OverlayX := 1400
global OverlayY := 820

global StrategyWidth := 1920
global StrategyHeight := 1090

global Slots := [
    ScaleX(800) ", " ScaleY(960), 
    ScaleX(880) ", " ScaleY(960), 
    ScaleX(960) ", " ScaleY(960), 
    ScaleX(1040) ", " ScaleY(960), 
    ScaleX(1120) ", " ScaleY(960)
]

global readyX := 0
global readyY := 0

global ChainKey, BeatKey, CaravanKey, CancelPlacementKey, TimeScaleMode, UseTimeScale, TimeScaleMultiplier
ChainKey := IniRead(SettingsFile, "Hotkeys", "Chain", "C")
BeatKey := IniRead(SettingsFile, "Hotkeys", "Beat", "B")
CaravanKey := IniRead(SettingsFile, "Hotkeys", "Caravan", "J")
global RaiseDeadKey := IniRead(SettingsFile, "Hotkeys", "RaiseTheDead", "V")
global HologramKey := IniRead(SettingsFile, "Hotkeys", "Hologram", "K")
global RepoKey := IniRead(SettingsFile, "Hotkeys", "Repo", "L")
CancelPlacementKey := IniRead(SettingsFile, "Hotkeys", "CancelPlacement", "Q")
global UpgradeTowerGKey := IniRead(SettingsFile, "Hotkeys", "UpgradeTower", "E")
global UpgradeTowerGBKey := IniRead(SettingsFile, "Hotkeys", "UpgradeBottom", "Z")
TimeScaleMode := IniRead(SettingsFile, "Options", "TimeScaleMode", "OFF")
global DebugConsole := IniRead(SettingsFile, "Options", "DebugConsole", "1")

global TimescaleActive := false

if (TimeScaleMode = "1.5x") {
    UseTimeScale := true,  TimeScaleMultiplier := 1.5
} else if (TimeScaleMode = "2x") {
    UseTimeScale := true,  TimeScaleMultiplier := 2
} else {
    UseTimeScale := false, TimeScaleMultiplier := 1
}

global UpgradeDelay := IniRead(SettingsFile, "Options", "UpgradeDelay", 200)

global gamemap := "", difficulty := "", requiredTowers := "", CurrentStrategyFile := ""

; audit log (see AuditLog)
global AuditLogDir := A_WorkingDir "\Logs"
global AuditLogFile := AuditLogDir "\audit_log.tsv"
global AuditMaxBytes := 1048576
global AuditLastKey := "", AuditLastTick := 0
global AuditGui := 0, AuditLV := 0, AuditFilter := 0, AuditCountTxt := 0
OnError(AuditOnError)
A_TrayMenu.Add("Open Audit Log", ShowAuditLog)
AuditLog("INFO", "Macro", "Macro started (v" ver ")")
global autoChain := "OFF", autoCaravan := "OFF", autoDropTheBeat := "OFF"
global Commander := false, AutoSkip := "ON", AbilitySpam := "ON"

global SpecialMaps := ["Simplicity", "Cataclysm"]

global MoveEnabled := false, MoveDirection := "W", MoveDuration := 750
global unfocusX := 150, unfocusY := 200
global Towers := Map(), RecordedSteps := [], Recording := false, RunningStrategy := false
global modifiers := ""
global LastDisconnectCheck := 0
global LastOpenedTowerID := ""
global IsRestarting := false
global SafeExitFlag := false
global RestartLock := false

global isUiPositionSaved := false
global isUpgradeAuthorized := false
global activeUpgradeRegions := [0, 0, 0, 0]
global CachedMenuUI := {x: 0, y: 0}
global ActiveRTowerID := false

global canUseAbility := true, canBeUpgraded := true, needtocheckTowerUI := true

global KeyDownTimes := Map()

global MacroRecording := false
global MacroSteps := []
global MacroStartTime := 0
global InputHookObj := ""

global LastSkipCheck := 0
global SKIP_CHECK_INTERVAL := 1000
global AutorunStartTime := 0
global watchdogPID := ""

global SC_L:="sc026"
global SC_R:="sc013" 
global SC_Esc:="sc001"
global SC_Enter:="sc01c" 
SC_E:="sc012" ; e

if (DebugConsole = "1")
    ShowDebugConsole()

IconPath := A_WorkingDir "\icon.ico"
if FileExist(IconPath)
    TraySetIcon(IconPath)

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

IsRecordingActive(*) {
    global Recording
    return (Recording != false)
}

if (PlaceTowerKey = "") {
    IniWrite("f", SettingsFile, "RecordingHotkeys", "PlaceTowerKey")
    global PlaceTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "PlaceTowerKey", "f")
}
if (PlaceTowerKey = "") {
    IniWrite("f", SettingsFile, "RecordingHotkeys", "PlaceTowerKey")
    global PlaceTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "PlaceTowerKey", "f")
}
if (UpgradeTowerKey = "") {
    IniWrite("^u", SettingsFile, "RecordingHotkeys", "UpgradeTowerKey")
    global UpgradeTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "UpgradeTowerKey", "^u")
}
if (AlignCameraKey = "") {
    IniWrite("^t", SettingsFile, "RecordingHotkeys", "AlignCameraKey")
    global AlignCameraKey := IniRead(SettingsFile, "RecordingHotkeys", "AlignCameraKey", "^t")
}
if (ChangeDJTrackKey = "") {
    IniWrite("^d", SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey")
    global ChangeDJTrackKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey", "^d")
}
if (SellTowerKey = "") {
    IniWrite("^x", SettingsFile, "RecordingHotkeys", "SellTowerKey")
    global SellTowerKey := IniRead(SettingsFile, "RecordingHotkeys", "SellTowerKey", "^x")
}
if (DeleteTowerRecordingKey = "") {
    IniWrite("^b", SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey")
    global DeleteTowerRecordingKey := IniRead(SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey", "^b")
}
if (RecordInputsKey = "") {
    IniWrite("^+e", SettingsFile, "RecordingHotkeys", "RecordInputsKey")
    global RecordInputsKey := IniRead(SettingsFile, "RecordingHotkeys", "RecordInputsKey", "^+e")
}
if (HoloKey = "") {
    IniWrite("^!h", SettingsFile, "RecordingHotkeys", "HoloKey")
    global HoloKey := IniRead(SettingsFile, "RecordingHotkeys", "HoloKey", "^!h")
}
if (ChangeTargetsKey = "") {
    IniWrite("^vkC0", SettingsFile, "RecordingHotkeys", "ChangeTargetsKey")
    global ChangeTargetsKey := IniRead(SettingsFile, "RecordingHotkeys", "ChangeTargetsKey", "^vkC0")
}

RegisterRecordingHotkeys()

;Got this from someone on a Discord server
RegisterRecordingHotkeys(oldKeys := "") {
    global PlaceTowerKey, UpgradeTowerKey, ChangeDJTrackKey, DeleteTowerRecordingKey, IsRecordingActive
    global SellTowerKey, AlignCameraKey, RecordInputsKey, HoloKey, ChangeTargetsKey, RepoKey, UpgradeTowerGKey

    HotIf(IsRecordingActive)

    if IsObject(oldKeys) {
        for old in oldKeys {
            if (old != "") {
                try Hotkey(old, "Off")
            }
        }
    }

    Hotkey(PlaceTowerKey, PlaceTowerHK, "On")
    Hotkey(UpgradeTowerKey, UpgradeTowerHK, "On")
    Hotkey(ChangeDJTrackKey, ChangeDJTrackHK, "On")
    Hotkey(DeleteTowerRecordingKey, DeleteTowerRecordingHK, "On")
    Hotkey(SellTowerKey, SellTowerHK, "On")
    Hotkey(AlignCameraKey, AlignCameraHK, "On")
    Hotkey(RecordInputsKey, RecordInputsHK, "On")
    Hotkey(HoloKey, CloneTowerHK, "On")
    Hotkey(ChangeTargetsKey, ChangeTargetsHK, "On")
    Hotkey("~^" RepoKey, BrawlerRepositionHK, "On")
    Hotkey("~^" RaiseDeadKey, ActivateRaiseTheDeadHK, "On")
    Hotkey("~LButton", DetectTowerForUpgrading, "On")
    Hotkey("~LButton Up", DetectUpgrade, "On")

    HotIf()
}

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

ScaleX(baseX, Width := 1920) {
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)
    return Round(baseX * (currentWidth / Width))
}

ScaleY(baseY, Height := 1009) {
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)
    return Round(baseY * (currentHeight / Height))
}

sX(baseX, Width := 1920) {
    global StrategyHeight
    hwnd := GetRobloxHWND()
    if !hwnd
        return

    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight, hwnd)
    if (Width == 0) 
        return baseX

    if (Width == 1920 && StrategyHeight == 1090) {
        WinGetClientPos(&cX, , , , "ahk_id " hwnd)
        WinGetPos(&wX, , , , "ahk_id " hwnd)
        currentBorderX := cX - wX
        baseX := baseX - currentBorderX 
        Width := 1920 
    }
    
    return Round(baseX * (currentWidth / Width))
}

sY(baseY, Height := 1090) {
    hwnd := GetRobloxHWND()
    if !hwnd
        return
    getRobloxPos(&pX, &pY, &currentWidth, &currentHeight, hwnd)
    if (Height == 0) 
        return baseY
    
    if (Height == 1090) {
        WinGetClientPos(, &cY, , , "ahk_id " hwnd)
        WinGetPos(, &wY, , , "ahk_id " hwnd)
        currentBorderY := cY - wY
        baseY := baseY - currentBorderY 
        Height := 1009 
    }
    
    return Round(baseY * (currentHeight / Height))
}

Join(arr, delim := ", ") {
    if !IsObject(arr)
        return String(arr)

    str := ""
    for index, value in arr
        str .= (index = 1 ? "" : delim) . value
    return str
}


AdvancedImageSearch(templ, x, y, w, h, minScale := 0.0, maxScale := 0.0, scaleStep := 0.05) {
    if (LegacyMode) {
        nx := 0
        ny := 0

        score := ImageSearch(&nx, &ny, x, y, x+w, y+h, "*80 " templ)

        status := "failed"

        if score == 1
            status := "success"

        return {score: score, x: nx, y: ny, message: " ", status: status}
    } else {
        return AdvImageSearch(templ, x, y, w, h, minScale, maxScale, scaleStep)
    }
}


autoRun := IniRead(StateFile, "State", "Running",   0)
autoStrat := IniRead(StateFile, "State", "Strategy",  "")
savedStartTime := IniRead(StateFile, "State", "StartTime", 0)

if (BotEnabled && ChannelID != "" && UserID != "") {
    SetTimer(ProcessCommands, 7500, 1)
}

if (savedStartTime != 0)
    AutorunStartTime := Integer(savedStartTime)

if (autoRun = 1 && autoStrat != "" && FileExist(autoStrat)) {
    LoadStrategyFile(autoStrat)
    RunningStrategy := true
    ActivateRoblox()
    RunStrategy()
} else {
    ; (automatic update check removed)

    MultiInstanceTools := "RobloxAccountManager.exe,Roblox Account Manager.exe,RAM.exe,RobloxMulti.exe,MultiRoblox.exe,MultipleRoblox.exe,Multiple Roblox.exe"
    Loop Parse, MultiInstanceTools, "," {
        if ProcessExist(A_LoopField) {
            MsgBox("Conflicting program detected:`n" A_LoopField "`n`nFor this script to work properly, please close all Roblox multi-client utilities.`nPlease close them and try again.", "Error", 48)
            ExitApp()
        }
    }
}

global MainGui := Gui("-Caption +Border +LastFound")
MainGui.BackColor := "121212"

global SystemHwnds := Map()

sysBar1 := MainGui.Add("Progress", "x0 y3 w700 h39 Disabled Background0A0A0A", 0)
SystemHwnds[sysBar1.Hwnd] := true

MainGui.SetFont("s11 w300 cFFFFFF", "Segoe UI")
if FileExist(IconPath) {
    sysIcon := MainGui.Add("Picture", "BackgroundTrans x20 y12 w20 h20", IconPath)
    SystemHwnds[sysIcon.Hwnd] := true
}

global GuiTitleCtrl := MainGui.Add("Text", "x50 y12 w200 h25 BackgroundTrans", "Unlimited Macro | TDS")
GuiTitleCtrl.OnEvent("Click", MoveWindow)
SystemHwnds[GuiTitleCtrl.Hwnd] := true

MainGui.SetFont("s11 w400 cFFFFFF", "Marlett")
global BtnMin   := MainGui.Add("Text", "x600 y12 w30 h25 Center BackgroundTrans", "0")
BtnMin.OnEvent("Click", MinimizeWindow)
SystemHwnds[BtnMin.Hwnd] := true

MainGui.SetFont("s11 w400 c888888", "Marlett")
sysDot := MainGui.Add("Text", "x630 y12 w30 h25 Center BackgroundTrans", "1")
SystemHwnds[sysDot.Hwnd] := true

MainGui.SetFont("s11 w400 cFFFFFF", "Marlett")
global BtnClose := MainGui.Add("Text", "x660 y12 w30 h25 Center BackgroundTrans", "r")
BtnClose.OnEvent("Click", CloseWindow)
SystemHwnds[BtnClose.Hwnd] := true

sysLine1 := MainGui.Add("Progress", "x0 y42 w700 h1 Background222222", 0)
SystemHwnds[sysLine1.Hwnd] := true


MainGui.SetFont("s10 w400 c888888", "Segoe UI")
global HoverTab := []
global TabCtrl  := []
global HoverEffect := []
global GradientButtons := []

;tabs
global Tab3 := []

global DiscordWebhookTab := []
global DiscordBotTab := []
;==

tabNames := ["Main", "Record", "(Beta) Party", "Discord", "Settings", "Tools"]

Loop tabNames.Length {
    i   := A_Index
    xTab := 20 + (i-1) * 90
    
    hBg := MainGui.Add("Progress", "x" xTab " y43 w80 h34 Hidden Background222222 Disabled")
    HoverTab.Push(hBg)
    SystemHwnds[hBg.Hwnd] := true 
    
    t := MainGui.Add("Text", "x" xTab " y52 w80 h22 Center BackgroundTrans", tabNames[i])
    t.OnEvent("Click", SelectTab)
    TabCtrl.Push(t)
    SystemHwnds[t.Hwnd] := true 
}

global TabLine := MainGui.Add("Progress", "x20 y75 w80 h2 BackgroundFFFFFF", 0)
SystemHwnds[TabLine.Hwnd] := true 

sysLine2 := MainGui.Add("Progress", "x0 y77 w700 h1 Background222222", 0)
SystemHwnds[sysLine2.Hwnd] := true

; tab 1 - MAIN ===========================

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab1_Section1 := MainGui.Add("Text", "x30 y95  w200 h22",  "Custom Strategies")
global Tab1_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1  Background333333", 0)

MainGui.SetFont("s9 w400 cAAAAAA", "Segoe UI")
global Tab1_Lbl1 := MainGui.Add("Text", "x30 y130 w100 h20", "Strategy:")
MainGui.SetFont("s9 w400 c000000")
global Strategy1Ctrl := MainGui.Add("Edit", "x110 y127 w400 h22 vStrategy1", Strategy1Path)
Strategy1Ctrl.OnEvent("Change", SaveStrat1)
MainGui.SetFont("s9 w400 cFFFFFF")
global Tab1_Btn1 := MainGui.Add("Text", "x515 y126 w70 h22 +Border 0x200 Center", "Browse")
Tab1_Btn1.OnEvent("Click", SelectStrat1)
global Tab1_Btn2 := MainGui.Add("Text", "x590 y126 w70 h22 +Border 0x200 Center", "Clear")
Tab1_Btn2.OnEvent("Click", ClearStrat1)

HoverEffect.Push(Tab1_Btn1) 
HoverEffect.Push(Tab1_Btn2) 

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab1_Lbl2 := MainGui.Add("Text", "x30 y160 w100 h20", "Strategy 2:")
MainGui.SetFont("s9 w400 c000000")
global Strategy2Ctrl := MainGui.Add("Edit", "x110 y157 w400 h22 vStrategy2", Strategy2Path)
Strategy2Ctrl.OnEvent("Change", SaveStrat2)
MainGui.SetFont("s9 w400 cFFFFFF")
global Tab1_Btn3 := MainGui.Add("Text", "x515 y156 w70 h22 +Border 0x200 Center", "Browse")
Tab1_Btn3.OnEvent("Click", SelectStrat2)
global Tab1_Btn4 := MainGui.Add("Text", "x590 y156 w70 h22 +Border 0x200 Center", "Clear")
Tab1_Btn4.OnEvent("Click", ClearStrat2)

HoverEffect.Push(Tab1_Btn3) 
HoverEffect.Push(Tab1_Btn4) 

MainGui.SetFont("s9 w400 cFFFFFF")
global RotateStrategiesCtrl := MainGui.Add("Checkbox", "x30 y190 vRotateStrategies 0x200 Checked" RotateStrategies, "Strategy Rotation")
RotateStrategiesCtrl.OnEvent("Click", EnableStratRotation)

MainGui.SetFont("s9 w400 cAAAAAA")
global SwapAfterLbl := MainGui.Add("Text", "x148 y188 w70 h20 0x200 BackgroundTrans", "Swap after:")

MainGui.SetFont("s9 w400 c000000") 
global SwapAmountCtrl := MainGui.Add("Edit", "x217 y186 w40 h22 +Border Number Center vSwapAmount", SwapAmount)

SwapAmountCtrl.OnEvent("Change", (*) => (
    IniWrite(SwapAmountCtrl.Text, SettingsFile, "Options", "SwapAmount"),
    SwapAmount := SwapAmountCtrl.Text
))

MainGui.SetFont("s9 w400 c000000")
global SwapUnitCtrl := MainGui.Add("DropDownList", "x267 y186 w80 Choose" (SwapUnit = "Minutes" ? 2 : 1) " vSwapUnit", ["Runs", "Minutes"])

SwapUnitCtrl.OnEvent("Change", (*) => (
    IniWrite(SwapUnitCtrl.Text, SettingsFile, "Options", "SwapUnit"),
    SwapUnit := SwapUnitCtrl.Text
    IniWrite(SwapAmountCtrl.Text, SettingsFile, "Options", "SwapAmount")
))

MainGui.SetFont("s9 w400 cFFFFFF")
global AutoEquipCtrl := MainGui.Add("Checkbox", "x357 y190 vAutoEquip 0x200 Checked" AutoEquip, "Auto Equip Towers")
AutoEquipCtrl.OnEvent("Click", EnableAutoEquip)

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab1_Section2 := MainGui.Add("Text", "x30 y223 w200 h22 0x200", "Strategy Library")
global Tab1_Line2 := MainGui.Add("Progress", "x30 y250 w640 h1 Background333333", 0)

MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global Tab1_AddBtn := MainGui.Add("Text", "x440 y223 w70 h22 +Border 0x200 Center", "Add")
Tab1_AddBtn.OnEvent("Click", StratLib_Add)
global Tab1_FolderBtn := MainGui.Add("Text", "x515 y223 w75 h22 +Border 0x200 Center", "Open folder")
Tab1_FolderBtn.OnEvent("Click", StratLib_OpenFolder)
global Tab1_RefreshBtn := MainGui.Add("Text", "x595 y223 w75 h22 +Border 0x200 Center", "Refresh")
Tab1_RefreshBtn.OnEvent("Click", StratLib_Refresh)
HoverEffect.Push(Tab1_AddBtn)
HoverEffect.Push(Tab1_FolderBtn)
HoverEffect.Push(Tab1_RefreshBtn)


LoadedStrats := []
needUpdate := true
lastUpdate := IniRead(StateFile, "Cache", "LastUpdateTime", "0")

if (lastUpdate != "0") {
    timeDiff := DateDiff(A_Now, lastUpdate, "Hours")
    if (timeDiff < 6) {
        needUpdate := false 
    }
}

; if (needUpdate) {
;     try {
;         apiURL := "https://api.github.com/repos/DarksenDev/tds-macro/contents/Strategies"
        
;         whr := ComObject("WinHttp.WinHttpRequest.5.1")
;         whr.Open("GET", apiURL, true)
;         whr.SetRequestHeader("User-Agent", "Strategy-Updater")
;         whr.Send()
        
;         while (!whr.WaitForResponse(1)) {
;             Sleep(50)
;         }
        
;         if (whr.Status != 200) {
;             throw Error("API request failed with status: " whr.Status)
;         }
            
;         responseText := whr.ResponseText
        
;         tempDir := StratsDir "\.download_temp"
;         if DirExist(tempDir)
;             DirDelete(tempDir, true)
;         DirCreate(tempDir)

;         pos := 1
;         fileCount := 0
;         successCount := 0
        
;         while (pos := RegExMatch(responseText, '\{[^}]*"name":"([^"]+\.strat)"[^}]*"download_url":"([^"]+)"[^}]*\}', &match, pos)) {
;             fileName := match[1]
;             downloadURL := match[2]
;             fileCount++
            
;             try {
;                 fileWhr := ComObject("WinHttp.WinHttpRequest.5.1")
;                 fileWhr.SetTimeouts(0, 2000, 2000, 1500)
;                 fileWhr.Open("GET", downloadURL, false)
;                 fileWhr.SetRequestHeader("User-Agent", "Strategy-Updater")
;                 fileWhr.Send()
                
;                 if (fileWhr.Status == 200) {
;                     ado := ComObject("ADODB.Stream")
;                     ado.Type := 1
;                     ado.Open()
;                     ado.Write(fileWhr.ResponseBody)
;                     ado.SaveToFile(tempDir "\" fileName, 2)
;                     ado.Close()
;                     successCount++
;                 } else {
;                     LogToConsole("Failed to download file '" fileName "'. Status: " fileWhr.Status, (AlwaysOnTop = 1) ? 0x1000 : 0)
;                 }
;             } catch Error as fileErr {
;                 LogToConsole("Network error downloading file '" fileName "': " fileErr.Message, (AlwaysOnTop = 1) ? 0x1000 : 0)
;             }
            
;             pos += match.Len
;             Sleep(30)
;         }

;         if (fileCount > 0 && successCount == 0) {
;             DirDelete(tempDir, true)
;             throw Error("All strategy downloads failed. Aborting update to protect existing files.")
;         }

;         if !DirExist(StratsDir)
;             DirCreate(StratsDir)

;         oldManifestStr := IniRead(StateFile, "Cache", "CommunityStratFiles", "")
;         oldManifestFiles := (oldManifestStr = "") ? [] : StrSplit(oldManifestStr, "|")

;         for oldFile in oldManifestFiles {
;             if (oldFile != "" && FileExist(StratsDir "\" oldFile))
;                 try FileDelete(StratsDir "\" oldFile)
;         }

;         newManifestStr := ""
;         newFileCount := 0
;         Loop Files, tempDir "\*.strat" {
;             FileMove(A_LoopFileFullPath, StratsDir "\" A_LoopFileName, 1)
;             newManifestStr .= (newManifestStr = "" ? "" : "|") A_LoopFileName
;             newFileCount++
;         }

;         DirDelete(tempDir, true)
;         IniWrite(A_Now, StateFile, "Cache", "LastUpdateTime")
;         IniWrite(newManifestStr, StateFile, "Cache", "CommunityStratFiles")
        
;     } catch Error as err {
;         LogToConsole("Error while downloading strats: " err.Message, (AlwaysOnTop = 1) ? 0x1000 : 0)
;     }
; }

; With Strategy Rotation off the "Strategy 2" row is hidden, so everything below it moves up 30px and the
; library gets 30px more height (see EnableStratRotation).
; UIExtra = how many pixels taller the window is than the original design (565). It gives the library room
; to show 2 cards at once (2 cards of 134px + 10px gaps = 298px). Everything below the library (Start / Stop,
; the footer, and the buttons of the other tabs) is moved down by this amount before the window is shown.
global UIExtra := 0
global FrameX := 30
global FrameY := (RotateStrategies = 1) ? 262 : 232
global FrameW := 640
global FrameH := ((RotateStrategies = 1) ? 224 : 254) + UIExtra
global ContentH := 400
global CurrentScrollPos := 0
global SliderH := 30
global ChildHwnd := 0

ChildGui := Gui("-Caption +E0x20 +Border +Parent" MainGui.Hwnd)
ChildGui.BackColor := "181818"
ChildGui.SetFont("s10 cWhite", "Segoe UI")
width := FrameW - 6

for stratSrc in [[MyStratsDir, true], [RecordingsDir, true]] {
Loop Files, stratSrc[1] "\*.strat" {
    localPath := A_LoopFileFullPath
    
    ; Every key is optional: a missing [Info] section, a missing key or an empty value just gives "".
    sMap := IniRead(localPath, "Settings", "map", "")
    sDifficulty := IniRead(localPath, "Settings", "difficulty", "")
    sTowers := IniRead(localPath, "Settings", "requiredTowers", "")
    sDesc := IniRead(localPath, "Info", "desc", "")
    sAuthor := IniRead(localPath, "Info", "author", "")
    sTitle := IniRead(localPath, "Info", "title", "")
    sTime := IniRead(localPath, "Info", "time", "")
    coinsR := ParseReward("coins", IniRead(localPath, "Info", "coins", ""))
    gemsR := ParseReward("gems", IniRead(localPath, "Info", "gems", ""))
    expR := ParseReward("exp", IniRead(localPath, "Info", "exp", ""))
    sModifiers := IniRead(localPath, "Settings", "modifiers", "")
    sResult := RewardResult(IniRead(localPath, "Info", "result", ""))      ; "win" (default) or "lose"
    
    LoadedStrats.Push({
        fileName: A_LoopFileName,
        map: sMap,
        difficulty: sDifficulty,
        towers: sTowers,
        desc: sDesc,
        author: sAuthor,
        title: sTitle,
        time: sTime,
        coins: coinsR,
        gems: gemsR,
        exp: expR,
        modifiers: sModifiers,
        result: sResult,
        path: localPath,
        user: stratSrc[2],
        stem: RegExReplace(A_LoopFileName, "i)\.strat$", "")
    })
}
}

; Saved order (arrow buttons on each card): file paths separated by |, top of the list first.
; Strats that are not in the saved order yet (new ones) go to the end, in their normal order.
StratLib_ApplyOrder(LoadedStrats)

; Every card's controls are remembered (StratCards) so the arrows can move cards around live, without a reload.
global StratCards := []
global StratInfoGui := 0     ; the open Info window, if any
global StratInfoTiles := []     ; hover areas of the unit squares in the open Info window
global StratInfoTipShown := ""    ; unit name currently shown as a tooltip
global StratInfoTipSince := 0, StratInfoTipLast := ""
global StratInfoW := 460
global StratInfoPath := "", StratInfoEdit := false     ; strat file shown in the Info window, and whether modifiers are being edited
global StratInfoSpecial := false, StratInfoResult := "win"   ; the strat is a special game mode (no modifiers allowed) / a win or lose strat
global StratInfoMods := Map(), StratInfoModsOrig := Map(), StratInfoExtras := []   ; working / saved modifier codes, unknown tokens kept as written
global StratInfoModTiles := []                          ; the 12 modifier squares: {x, y, w, h, code, plate, icon, bmpOn, bmpOff}
global StratInfoHead := 0, StratInfoEditPic := 0, StratInfoSavePic := 0
global StratInfoEditBmps := [0, 0], StratInfoEditRect := [0, 0, 0, 0], StratInfoSaveRect := [0, 0, 0, 0]
global StratInfoLower := [], StratInfoBaseH := 0       ; (kept for compatibility) window height
global StratInfoTitleTxt := 0, StratInfoAuthorTxt := 0, StratInfoByLbl := 0, StratInfoTitleH := 0   ; title / author as shown normally
global StratInfoTitleEdit := 0, StratInfoAuthorEdit := 0, StratInfoDescEdit := 0                       ; edit boxes shown in edit mode
global StratInfoTitleFrame := 0, StratInfoAuthorFrame := 0, StratInfoDescFrame := 0                    ; 1px frames behind the edit boxes
global StratInfoDescHead := 0, StratInfoDescTxt := 0, StratInfoDescH := 0, StratInfoHasDesc := false
global StratInfoLowerY := 0, StratInfoFooter := 0
global StratInfoBonusTxt := 0          ; "REWARDS +NN%" counter at the right end of the MODIFIERS heading
; long descriptions scroll inside a read-only viewport (same look as the library's scroll bar) instead of growing the window
global StratInfoDescVis := 6                     ; lines shown before the scroll bar appears
global StratInfoDescView := 0, StratInfoDescTrack := 0, StratInfoDescThumb := 0
global StratInfoDescScroll := false, StratInfoDescLineH := 16, StratInfoDescTotal := 0, StratInfoDescThumbH := 30, StratInfoDescViewY := 0
global StratInfoOrig := Map("title", "", "author", "", "desc", "")   ; title / author / description as saved in the file
global StratInfoBitmaps := []   ; tile bitmaps of the open Info window, freed when it closes
global StratTips := []      ; invisible hover areas over the icon plates (each has a .Tip text), see Hoverwatchdog
StratSeenHwnds := Map()

StartY := 10
CardH  := 134
CardW  := 610
Gap    := 10

ContentH := StartY

for index, strat in LoadedStrats {
    CurrentY := StartY + ((index - 1) * (CardH + Gap))
    ContentH := CurrentY + CardH + Gap 

    C1X := 10
    C1Y := CurrentY

    hFrameBg := CreateFrame(CardW, CardH, 10, "0xff161616", "0xff1d1d1d", "0x62302d2d")
    ChildGui.Add("Picture", "x" C1X " y" C1Y " w" CardW " h" CardH " +BackgroundTrans", "HBITMAP:*" hFrameBg)

    ; ---- Card layout (610 x 134) --------------------------------------------------
    ; Every element owns a fixed box, so nothing can overlap. Long text is cut off with "...".
    ;   |  Title                                                        [   Load   ]
    ;   |  Title                                                        [        Load        ]
    ;   |  [^] [mode] [map] [coins] [gems] [exp]                        [          Info          ]
    ;   |  [v]  Molten Normal  1425     0     120                       (clock) ~14m 20s
    ;   |  [edit] [trash]
    ; Each icon plate has its value written underneath, in the colour of that icon:
    ;   mode = the game mode colour, coins = gold, gems = magenta, unit exp = cyan, nothing/zero = grey.
    ;   Coins / gems / exp come from ComputeRewards (lib\RewardDatabase.ahk): a win is calculated from the mode, map
    ;   and modifiers, a loss shows the typed values. When map scaling or modifiers change a number, the original is
    ;   shown small and grey with a red streak and the new number sits under it.
    ;   map = the map's picture (Resources\Images\MapIcons) with its difficulty rating underneath.
    ; The up / down arrows move the card in the list (the order is saved).
    ; Special modes (Badlands II, Pizza Party, Polluted Wasteland II) come with their own map, so the strat's
    ; map= line is not used for them: the mode plate says "Special", the map plate shows that mode's map and
    ; says "Exclusive".
    ; Towers and the description are in the Info popup.
    ;
    ; Horizontal map (card-relative):  arrows 10..34 | accent 40-44 | plates 54..366 | buttons 380..600, time below Info
    noneHex := "7E848E"
    modeName := strat.difficulty != "" ? strat.difficulty : "Easy"
    specialName := SpecialModeName(modeName)              ; "Badlands II" / "Pizza Party" / ... or ""
    if (specialName != "")
        modeName := specialName                           ; also fixes spellings such as "Badlands 2"
    modeHex := ModeColorHex(modeName)

    ; mode plate text, and the icon file for the mode
    modeLabel := (specialName != "") ? "Special" : modeName

    ; map plate + chip. mapName picks the icon file; mapHex colours the chip; mapTextHex colours the plate text.
    mapInfo := ""
    if (specialName != "") {
        mapName := specialName, mapChip := specialName, mapHex := modeHex, mapLabel := "Exclusive", mapTextHex := modeHex
    } else if (strat.map != "") {
        mapInfo := GetMapInfo(strat.map)
        mapName := mapInfo ? mapInfo.name : strat.map
        mapChip := mapName
        mapHex := mapInfo ? mapInfo.color : "8A94A6"
        mapLabel := mapInfo ? mapInfo.rating : "Unrated"
        mapTextHex := mapInfo ? LiftHex(mapHex) : noneHex
    } else {
        mapName := "", mapChip := modeLabel, mapHex := modeHex, mapLabel := "Unknown", mapTextHex := noneHex
    }
    mapImg := MapIconPath(mapName)
    mapAbbr := mapName != "" ? MapInitials(mapName) : "?"

    ; accent bar: a full-height divider between the arrow column and the title / icons
    ChildGui.Add("Text", "x" (C1X + 40) " y" (C1Y + 10) " w4 h114 Background" modeHex, "")

    ; title, left aligned above the icon row (falls back to the file name when the strat has no title)
    ChildGui.SetFont("s11 Bold cWhite", "Segoe UI")
    titleCtrl := ChildGui.Add("Text", "x" (C1X + 54) " y" (C1Y + 12) " w320 h24 +0x200 +0x4000 +BackgroundTrans", strat.title != "" ? strat.title : (strat.stem != "" ? strat.stem : "Unknown Strat"))

    ; Five 56x56 icon plates, 8px apart. The plate bitmap carries a 6px shadow margin, so it is
    ; drawn 12px larger and placed 6px up/left of the visible plate.
    ;   [plate id, plate x, icon file, label text, label colour, label font size, label box width]
    hPlateBg := CreateGradientButton(68, 68, 10, "0xff2f353f", "0xff15171b", "0xff000000", "0x232c3a50", "", "Segoe UI", 10, 1)
    diffImg := "Resources/Images/" modeName ".png"
    modeLblSize := StrLen(modeLabel) <= 8 ? 10 : (StrLen(modeLabel) <= 10 ? 9 : 8)
    mapLblSize := StrLen(mapLabel) <= 8 ? 10 : 9
    cardRw := ComputeRewards(strat)       ; {coins, gems, exp, ...}, see lib\RewardDatabase.ahk
    plates := [
        ["plate_diff",  54,  diffImg,                                       modeLabel,        modeHex,                                       modeLblSize, 76],
        ["plate_map",   118, mapImg,                                        mapLabel,         mapTextHex,                                    mapLblSize,  64],
        ["plate_coins", 182, StratRewardIcon("coins", cardRw.coins.size),      cardRw.coins.text,    cardRw.coins.active ? "F9B519" : noneHex,          10,          64],
        ["plate_gems",  246, StratRewardIcon("gems", cardRw.gems.size),        cardRw.gems.text,     cardRw.gems.active ? "E975F5" : noneHex,           10,          64],
        ["plate_exp",   310, "Resources/Images/exp.png",                   cardRw.exp.text,      cardRw.exp.active ? "4FDDF9" : noneHex,            10,          64]
    ]
    rewardKinds := Map("plate_coins", "coins", "plate_gems", "gems", "plate_exp", "exp")
    rewardCtrls := Map()      ; kind -> the labels StratLib_ApplyRewards switches between
    for plate in plates {
        px := C1X + plate[2], py := C1Y + 42
        iconCtrl := ""
        ChildGui.Add("Picture", "x" (px - 6) " y" (py - 6) " w68 h68 +BackgroundTrans", "HBITMAP:*" hPlateBg)
        if (plate[3] != "" && FileExist(plate[3])) {
            iconCtrl := ChildGui.Add("Picture", "x" (px + 4) " y" (py + 4) " w48 h48 +BackgroundTrans", plate[3])
        } else if (plate[1] = "plate_map") {
            ; no icon file for this map yet: the plate shows the map's initials instead
            ChildGui.SetFont("s13 Bold c" mapTextHex, "Segoe UI")
            ChildGui.Add("Text", "x" (px + 4) " y" (py + 4) " w48 h48 +0x200 Center +BackgroundTrans", mapAbbr)
        } else if (plate[1] = "plate_diff" && !strat.user) {
            LogToConsole("Missing resource file: " plate[3], "Error", 0x1010)
        }

        ; value label under the plate, centred on it
        ChildGui.SetFont("s" plate[6] " Bold c" plate[5], "Segoe UI")
        lblMain := ChildGui.Add("Text", "x" (px + 28 - plate[7] // 2) " y" (py + 60) " w" plate[7] " h18 +0x200 +0x4000 Center +BackgroundTrans", plate[4])

        ; Coins / gems / exp also get three hidden labels for strats whose modifiers raise the rewards:
        ; the original number (small, grey, with a red streak through it) and the boosted number under it
        ; in the icon's colour. StratLib_ApplyRewards decides which set is visible.
        if (rewardKinds.Has(plate[1])) {
            lx := px + 28 - plate[7] // 2
            ChildGui.SetFont("s8 w500 c6A717C", "Segoe UI")
            lblOld := ChildGui.Add("Text", "x" lx " y" (py + 57) " w" plate[7] " h13 +0x200 +0x4000 Center +BackgroundTrans Hidden", "")
            picStrike := ChildGui.Add("Picture", "x" lx " y" (py + 57) " w" plate[7] " h13 +BackgroundTrans Hidden", "")
            ChildGui.SetFont("s" plate[6] " Bold c" plate[5], "Segoe UI")
            lblBoost := ChildGui.Add("Text", "x" lx " y" (py + 70) " w" plate[7] " h18 +0x200 +0x4000 Center +BackgroundTrans Hidden", "")
            rewardCtrls[rewardKinds[plate[1]]] := {main: lblMain, old: lblOld, strike: picStrike, boosted: lblBoost, w: plate[7], hbm: 0, icon: iconCtrl, iconPath: plate[3], tip: ""}
        }

        ; hover area over the plate: Hoverwatchdog shows this text as a tooltip while the mouse rests on it
        switch plate[1] {
            case "plate_diff":  plateTip := specialName != "" ? specialName : modeName
            case "plate_map":   plateTip := mapName != "" ? mapName : "Unknown map"
            case "plate_coins": plateTip := RewardTipText("coins", cardRw.coins, cardRw)
            case "plate_gems":  plateTip := RewardTipText("gems", cardRw.gems, cardRw)
            default:            plateTip := RewardTipText("exp", cardRw.exp, cardRw)
        }
        tipCtrl := ChildGui.Add("Text", "x" px " y" py " w56 h56 +BackgroundTrans", "")
        tipCtrl.Tip := plateTip
        StratTips.Push(tipCtrl)
        if (rewardKinds.Has(plate[1]))
            rewardCtrls[rewardKinds[plate[1]]].tip := tipCtrl
    }

    ; Button column at the left of the card: four 24 x 24 squares, 6px apart, spanning the divider line
    ; (y 10..124): up, down, edit, remove. On the first card the up arrow is dimmed, on the last card the down arrow is dimmed.
    arrowN := ["0xff3a404c", "0xff1d2026"], arrowH := ["0xff4d5564", "0xff292d35"]
    cardRec := {strat: strat, ctrls: [], up: "", down: ""}
    cardRec.title := titleCtrl      ; the title text, so StratLib_UpdateCard can change it live
    cardRec.rewards := rewardCtrls  ; coins / gems / exp labels, so StratLib_ApplyRewards can change them live
    for dirName in ["Up", "Down"] {
        glyph := dirName = "Up" ? Chr(0x25B2) : Chr(0x25BC)
        ay := C1Y + 10 + (dirName = "Up" ? 0 : 30)
        ; Both versions are created: the dimmed one (does nothing) and the active one. StratLib_SetArrows shows
        ; the right one: first card has Up dimmed, last card has Down dimmed. They swap live when cards move.
        arrOff := CreateGradientButton(36, 36, 6, "0xff1f2228", "0xff17191d", "0x20000000", "0x1fffffff", glyph, "Segoe UI Symbol", 9, 1, "0xFF4A505B")
        picOff := ChildGui.Add("Picture", "x" (C1X + 4) " y" (ay - 6) " w36 h36 +BackgroundTrans", "HBITMAP:*" arrOff)
        arrNormal := CreateGradientButton(36, 36, 6, arrowN[1], arrowN[2], "0x40000000", "0x5dffffff", glyph, "Segoe UI Symbol", 9, 1)
        arrHover := CreateGradientButton(36, 36, 6, arrowH[1], arrowH[2], "0x60000000", "0x5dffffff", glyph, "Segoe UI Symbol", 9, 1)
        picArr := ChildGui.Add("Picture", "x" (C1X + 4) " y" (ay - 6) " w36 h36 +BackgroundTrans", "HBITMAP:*" arrNormal)
        arr1 := ChildGui.Add("Text", "x" (C1X + 10) " y" ay " w24 h24 +BackgroundTrans +0x200 Center", "")
        arr1.OnEvent("Click", ((p, d) => (*) => StratLib_Move(p, d))(strat.path, dirName = "Up" ? -1 : 1))
        arr1.PicControl := picArr
        arr1.ImgNormal := arrNormal
        arr1.ImgHover := arrHover
        GradientButtons.Push(arr1)
        cardRec.%StrLower(dirName)% := {off: picOff, pic: picArr, hit: arr1}
    }
    StratLib_SetArrows(cardRec, index, LoadedStrats.Length)

    ; time row, right below the Info button: clock icon (Resources\Images\clock.png) then the time text.
    ; Falls back to a plain "Time" label if the icon file is missing.
    timeX := C1X + 402
    if FileExist("Resources/Images/clock.png") {
        ChildGui.Add("Picture", "x" (C1X + 380) " y" (C1Y + 108) " w14 h14 +BackgroundTrans", "Resources/Images/clock.png")
    } else {
        timeX := C1X + 434
        ChildGui.SetFont("s9 w600 c7E848E", "Segoe UI")
        ChildGui.Add("Text", "x" (C1X + 380) " y" (C1Y + 106) " w52 h18 +0x200 +BackgroundTrans", "Time")
    }
    ChildGui.SetFont("s9 w500 cC5CBD3", "Segoe UI")
    ChildGui.Add("Text", "x" timeX " y" (C1Y + 106) " w" (C1X + 600 - timeX) " h18 +0x200 +0x4000 +BackgroundTrans", strat.time != "" ? strat.time : "Unknown")
    timeTip := ChildGui.Add("Text", "x" (C1X + 380) " y" (C1Y + 104) " w220 h22 +BackgroundTrans", "")
    timeTip.Tip := "Estimated run time"
    StratTips.Push(timeTip)

    ; Load (220 x 36). Button bitmaps carry a 6px shadow margin on every side, so they are drawn 12px larger
    ; than the button and placed 6px up/left; the click area sits exactly on the visible button.
    if ((strat.difficulty = "Hardcore" || strat.difficulty = "Voidcore")) {
        hBtnNormal := CreateGradientButton(232, 48, 8, "0xff961ea1", "0xff5f237a", "0x40000000", "0x5dffffff", "Load", "Segoe UI", 13, 1)
        hBtnHover := CreateGradientButton(232, 48, 8, "0xffea00ff", "0xff8d32b7", "0x60000000", "0x5dffffff", "Load", "Segoe UI", 13, 1)
    } else {
        hBtnNormal := CreateGradientButton(232, 48, 8, "0xFF147A6E", "0xFF214B75", "0x40000000", "0x5dffffff", "Load", "Segoe UI", 13, 1)
        hBtnHover := CreateGradientButton(232, 48, 8, "0xFF1CB5A2", "0xFF3272B7", "0x60000000", "0x5dffffff", "Load", "Segoe UI", 13, 1)
    }
    picLoadBtn := ChildGui.Add("Picture", "x" (C1X + 374) " y" (C1Y + 26) " w232 h48 +BackgroundTrans", "HBITMAP:*" hBtnNormal)
    dl1 := ChildGui.Add("Text", "x" (C1X + 380) " y" (C1Y + 32) " w220 h36 +BackgroundTrans +0x200 Center", "")
    dl1.SetFont("cFFFFFF s10 Bold", "Segoe UI")
    dl1.StratFile := strat.fileName
    dl1.StratPath := strat.path
    dl1.OnEvent("Click", DownloadStrat)
    dl1.PicControl := picLoadBtn
    dl1.ImgNormal := hBtnNormal
    dl1.ImgHover := hBtnHover
    GradientButtons.Push(dl1)
    dl1.Tip := "Load strategy"
    StratTips.Push(dl1)

    ; Info (220 x 28): towers, modifiers, description
    infoVisW := 220
    infoNormal := CreateGradientButton(infoVisW + 12, 40, 8, "0xff3a404c", "0xff1d2026", "0x40000000", "0x5dffffff", "Info", "Segoe UI", 10, 1)
    infoHover := CreateGradientButton(infoVisW + 12, 40, 8, "0xff4d5564", "0xff292d35", "0x60000000", "0x5dffffff", "Info", "Segoe UI", 10, 1)
    picInfo := ChildGui.Add("Picture", "x" (C1X + 374) " y" (C1Y + 68) " w" (infoVisW + 12) " h40 +BackgroundTrans", "HBITMAP:*" infoNormal)
    info1 := ChildGui.Add("Text", "x" (C1X + 380) " y" (C1Y + 74) " w" infoVisW " h28 +BackgroundTrans +0x200 Center", "")
    ; The popup re-reads the strat file when clicked, so edits made in it (the modifier editor) and in the file
    ; show up straight away without refreshing the library.
    info1.OnEvent("Click", ((p, st) => (*) => StratLib_ShowInfo(p, st))(strat.path, strat.stem))
    info1.PicControl := picInfo
    info1.ImgNormal := infoNormal
    info1.ImgHover := infoHover
    GradientButtons.Push(info1)
    info1.Tip := "Strategy info"
    StratTips.Push(info1)

    ; Edit: pencil square (third in the column). Opens the strat file in Notepad, or opens its folder with the
    ; file selected (to open it with any program). First click asks which; right-click it, or Shift+click, to change.
    ; Blue gradient. The icon is the "Edit" glyph of Segoe MDL2 Assets.
    edNormal := CreateGradientButton(36, 36, 6, "0xFF3B7BD1", "0xFF1F4A8A", "0x40000000", "0x5dffffff", Chr(0xE70F), "Segoe MDL2 Assets", 10, 1)
    edHover := CreateGradientButton(36, 36, 6, "0xFF5A9BEF", "0xFF2F63B3", "0x60000000", "0x5dffffff", Chr(0xE70F), "Segoe MDL2 Assets", 10, 1)
    picEd := ChildGui.Add("Picture", "x" (C1X + 4) " y" (C1Y + 70 - 6) " w36 h36 +BackgroundTrans", "HBITMAP:*" edNormal)
    ed1 := ChildGui.Add("Text", "x" (C1X + 10) " y" (C1Y + 70) " w24 h24 +BackgroundTrans +0x200 Center", "")
    ed1.OnEvent("Click", ((p) => (*) => StratLib_Edit(p, GetKeyState("Shift", "P")))(strat.path))
    ed1.OnEvent("ContextMenu", ((p) => (*) => StratLib_Edit(p, true))(strat.path))
    ed1.PicControl := picEd
    ed1.ImgNormal := edNormal
    ed1.ImgHover := edHover
    GradientButtons.Push(ed1)
    ed1.Tip := "Edit strategy`n(right-click to change program)"
    StratTips.Push(ed1)

    ; Remove: 24 x 24 trash can square at the bottom of the column, red gradient.
    ; The icon is the "Delete" glyph of Segoe MDL2 Assets. Clicking asks for confirmation first (StratLib_Remove).
    if (strat.user) {
        rmNormal := CreateGradientButton(36, 36, 6, "0xFFA33A48", "0xFF5C1D26", "0x40000000", "0x5dffffff", Chr(0xE74D), "Segoe MDL2 Assets", 10, 1)
        rmHover := CreateGradientButton(36, 36, 6, "0xFFD24A5C", "0xFF8A2A37", "0x60000000", "0x5dffffff", Chr(0xE74D), "Segoe MDL2 Assets", 10, 1)
        picRm := ChildGui.Add("Picture", "x" (C1X + 4) " y" (C1Y + 100 - 6) " w36 h36 +BackgroundTrans", "HBITMAP:*" rmNormal)
        rm1 := ChildGui.Add("Text", "x" (C1X + 10) " y" (C1Y + 100) " w24 h24 +BackgroundTrans +0x200 Center", "")
        rm1.OnEvent("Click", ((p, s) => (*) => StratLib_Remove(p, s.title != "" ? s.title : s.stem))(strat.path, strat))
        rm1.PicControl := picRm
        rm1.ImgNormal := rmNormal
        rm1.ImgHover := rmHover
        GradientButtons.Push(rm1)
        rm1.Tip := "Remove strategy"
        StratTips.Push(rm1)
    }

    ; everything created for this card (any control not seen before)
    for hwndC, ctrlC in ChildGui {
        if !StratSeenHwnds.Has(hwndC) {
            StratSeenHwnds[hwndC] := 1
            cardRec.ctrls.Push(ctrlC)
        }
    }
    StratCards.Push(cardRec)
    StratLib_ApplyRewards(cardRec)
}

if (LoadedStrats.Length == 0) {
    ChildGui.SetFont("s12 c7E848E", "Segoe UI")
    ChildGui.Add("Text", "x0 y0 w" FrameW " h" FrameH " +BackgroundTrans Center +0x200", "No strategies found.")
    ContentH := 220
}

SliderX := FrameW - 10 
SliderW := 6 

if (ContentH > 0) {
    SliderH := Round(FrameH * (FrameH / ContentH))
    
    if (ContentH <= FrameH) {
        SliderH := FrameH
    } else {
        SliderH := Max(30, SliderH)
    }
    
    if (ContentH > FrameH && CurrentScrollPos > 0) {
        maxScroll := ContentH - FrameH
        scrollPercent := CurrentScrollPos / maxScroll
        sliderPos := Round(scrollPercent * (FrameH - SliderH))
        sliderPos := Max(0, Min(sliderPos, FrameH - SliderH))
    } else {
        sliderPos := 0
    }
    
    hSlider := CreateScrollThumb(SliderW, SliderH, 3, "0xFF6EA7FF", "0xff4076ce", "0xd4d4d4")
    hSliderBG := CreateScrollThumb(SliderW, FrameH, 3, "0xff000000", "0xff000000", "0x000000")
    
    global SliderBG := ChildGui.Add("Picture", "x" SliderX " y0 w" SliderW " h" FrameH+ContentH " +BackgroundTrans", "HBITMAP:*" hSliderBG)
    global Slider := ChildGui.Add("Picture", "x" SliderX " y" sliderPos " w" SliderW " h" SliderH " +BackgroundTrans", "HBITMAP:*" hSlider)
    
    SliderBG.Visible := true
    Slider.Visible := true
}

OnMessage(0x0115, OnScroll)
OnMessage(0x020A, OnMouseWheel)


MainGui.SetFont("s11 w400 cFFFFFF", "Segoe UI")
global Tab1_Start := MainGui.Add("Text", "x30 y500 w300 h40 Center Background0e0e0f +Border 0x200", "Start (F1)")
Tab1_Start.OnEvent("Click", StartStrategy)
global Tab1_Stop := MainGui.Add("Text",  "x340 y500 w330 h40 Center Background0e0e0f +Border 0x200", "Stop (F2)")
Tab1_Stop.OnEvent("Click", StopStrategy)

HoverEffect.Push(Tab1_Start) 
HoverEffect.Push(Tab1_Stop) 

; tab 2 - RECORD ===========================

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab2_Title := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "Configuration")
global Tab2_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1  Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab2_Lbl1 := MainGui.Add("Text", "x30 y145 w80 h20 Hidden", "Map:")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecMapsD := MainGui.Add("DropDownList", "x80 y142 w220 Hidden vRecMaps", [ ; WARNING: These are all the supported maps for this macro. If a map is not listed here, it is unsupported
    "Abandoned City", "Area 52", "Autumn Falling", 
    "Badlands II", "Black Spot Exchange", "Candy Valley", "Cataclysm", "Chess Board", 
    "Construction Crazy", "Coral Deep", "Crossroads", "Crystal Cave", 
    "Cyber City", "Dead Ahead", "Derelict Outpost", "Deserted Village", "Dusty Bridges", 
    "Enchanted Forest", "Farm Lands", "Forest Camp", "Forgetten Docks", "Four Seasons", 
    "Fungi Island", "Grass Isle", "Happy Home of Robloxia", "Harbor", "Honey Valley", 
    "Hot Spot", "Iceville", "Infernal Abyss", "Lay By", "Lighthaos", "Marshlands", "Mason Arch", "Medieval Times", "Meltdown", 
    "Midnight Issue", "Moon Base", "Musaceae Kingdom", "Necropolis", "Nether", "Night Station", 
    "Northern Lights", "Outskirts Commune", "Pier Pressure", "Pizza Party", "Polluted Wasteland II", 
    "Portland", "Retro Crossroads", "Retro Lighthouse", "Retro Rocket Arena", "Retro Stained Temple", 
    "Retro The Heights", "Retro Zone", "Rocket Arena", "Ruby Escort", "Sacred Mountains", 
    "Sky Islands", "Simplicity", "Space City", "Spring Fever", "Stained Temple", "Sugar Rush", 
    "The Heavens", "The Heights", "Toyboard", "Tropical Industries", "Tropical Isles", "U-Turn", 
    "Unknown Garden", "Winter Abyss", "Winter Bridges", "Winter Stronghold", "Wrecked Battlefield", 
    "Wrecked Battlefield II", "Wretched Front"
])

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab2_Lbl2 := MainGui.Add("Text", "x320 y145 w80 h20 Hidden", "Mode:")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecDiffCtrl := MainGui.Add("DropDownList", "x380 y142 w220 Hidden vRecDifficulty", [
    "Easy", "Casual", "Intermediate", "Molten", "Fallen", "Frost", 
    "Hardcore", "Voidcore", "Pizza Party", "Badlands II", "Polluted Wasteland II"
])
RecDiffCtrl.OnEvent("Change", RecDiff_Changed)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab2_Lbl3 := MainGui.Add("Text", "x30 y235 w80 h20 Hidden", "Modifiers:")
MainGui.SetFont("s9 w400 c000000")

global RecModifiersCtrl := MainGui.Add("ListBox", "x110 y232 w220 h200 Multi Hidden vRecModifiers", [
    "Broke", "Exploding", "Flying", "Fog", "Glass", 
    "Healthy", "Hidden", "Inflation", "Jailed", "Limitation", 
    "Committed", "Quarantine", "Speedy"
])

MainGui.SetFont("s9 w400 cAAAAAA", "Segoe UI")
global Tab2_Info2 := MainGui.Add("Text", "x20 w60 y275 BackgroundTrans Hidden", "Hold CTRL to deselect/select multiple modifiers.")

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab2_Lbl4 := MainGui.Add("Text", "x30 y185 w80 h20 Hidden", "Towers:")
MainGui.SetFont("s9 w400 c000000")
global RecTowersCtrl := MainGui.Add("Edit", "x80 y182 w220 h22 Hidden vRecRequiredTowers", requiredTowers)

MainGui.SetFont("s9 w400 cAAAAAA", "Segoe UI")
global Tab2_Info1 := MainGui.Add("Text", "x320 y173 BackgroundTrans Hidden", "Enter towers for your strategy using comma after every tower.`nMinigunner, Ranger, Commander, DJ, Military Base for example.`nType G Whatever if the tower you using NEEDS to be golden.")

MainGui.Add("Progress", "x360 y232 w320 h1 Hidden Background333333 vTab2_Line2", 0)
global Tab2_Line2 := MainGui["Tab2_Line2"]

MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global RecAutoChainCtrl := MainGui.Add("Checkbox", "x360 y255 Hidden vRecAutoChain Checked" (autoChain="ON"?1:0), "Use Call of Arms")
global RecAutoCaravanCtrl := MainGui.Add("Checkbox", "x490 y255 Hidden vRecAutoCaravan Checked" (autoCaravan="ON"?1:0), "Use Support Caravan")
global RecAutoDropCtrl := MainGui.Add("Checkbox", "x360 y275 Hidden vRecAutoDropTheBeat Checked" (autoDropTheBeat="ON"?1:0), "Use Drop the Beat")

MainGui.Add("Progress", "x360 y300 w320 h1 Hidden Background333333 vTab2_Line3", 0)
global Tab2_Line3 := MainGui["Tab2_Line3"]
global RecAutoSkipCtrl := MainGui.Add("Checkbox", "x360 y315 h20 Hidden vRecAutoSkip", "Auto Skip Waves")
global RecAbilitySpamCtrl := MainGui.Add("Checkbox", "x490 y315 h20 Hidden vRecAbilitySpam", "Abilities Spam")
global Tab2_Info := MainGui.Add("Link", "x360 y360 w320 h100 Hidden", "
(
There you can create your own strategy and save it into a file. Watch the tutorial here: <a href="https://www.youtube.com/watch?v=j8Y5qHBaYOs&feature=youtu.be">https://www.youtube.com/watch?v=j8Y5qHBaYOs&feature=youtu.be</a>. I recommend using the timescale ticket when recording complex strategies.
)")
RecAutoSkipCtrl.OnEvent("Click", RecordToggleAutoskip)

global RecMoveCtrl := MainGui.Add("Checkbox", "x30 y452 w60 h20 Hidden vRecMoveEnabled Checked" (MoveEnabled?1:0), "Move")
MainGui.SetFont("s9 w400 cAAAAAA")
global DIRECTIONTEXTCtrl := MainGui.Add("Text", "x100 y452 w45 Hidden", "Direction")
MainGui.SetFont("s9 w400 cFFFFFF")
global RecMoveDirCtrl := MainGui.Add("DropDownList", "x160 y450 w45 Hidden Choose1 vRecMoveDirection", ["W", "A", "S", "D"])
MainGui.SetFont("s9 w400 cAAAAAA")
global Tab2_Txt4 := MainGui.Add("Text", "x220 y452 Hidden", "Duration (ms):")
MainGui.SetFont("s9 w400 c000000")
global RecMoveDurCtrl := MainGui.Add("Edit", "x310 y450 w50 h22 Hidden vRecMoveDuration", 1000)

MainGui.SetFont("s11 w400 cFFFFFF", "Segoe UI")
global Tab2_Btn1 := MainGui.Add("Text", "x30  y500 w300 h40 Center Background0e0e0f +Border 0x200 Hidden", "Start Recording")
Tab2_Btn1.OnEvent("Click", StartRecording)
MainGui.SetFont("s11 w400 c808080", "Segoe UI")
global Tab2_Btn2 := MainGui.Add("Text", "x340 y500 w330 h40 Center Background0e0e0f +Border 0x200 Hidden", "Stop")
Tab2_Btn2.OnEvent("Click", StopRecord)

HoverEffect.Push(Tab2_Btn1) 

; tab 3 - MULTIPLAYER ===========================

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab3_Title := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "Usernames")
global Tab3_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1 Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab3_HostNm := MainGui.Add("Text", "x30 y140 w170 BackgroundTrans h20 Hidden", "Host Username:")
MainGui.SetFont("s9 w400 c000000")
global Tab3_HostNm_EDIT := MainGui.Add("Edit", "x130 y137 w540 Hidden vHostName", HostName)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab3_PartyMemb := MainGui.Add("Text", "x30 y175 w165 BackgroundTrans h20 Hidden", "Party Members:")
MainGui.SetFont("s9 w400 c000000")
global Tab3_PartyMemb_Edit := MainGui.Add("Edit", "x130 y168 w540 Hidden vPartyMembersStr", PartyMembers)

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab3_Title2 := MainGui.Add("Text", "x30 y201  w200 h22 Hidden", "Settings")
global Tab3_Line2 := MainGui.Add("Progress", "x30 y224 w640 h1 Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cffffff")
global Tab3_RoleTxt := MainGui.Add("Text", "x30 y240 w60 BackgroundTrans h20 Hidden", "You are:")

global Tab3_Role_Host := MainGui.Add("Radio", "x30 y260 w54 Hidden vPlayerRole Group " (PlayerRole != "Member" ? "Checked" : ""), "Host")
global Tab3_Role_Member := MainGui.Add("Radio", "x85 y260 w80 Hidden " (PlayerRole == "Member" ? "Checked" : ""), "Member")

global Tab3_LConditionTxt := MainGui.Add("Text", "x30 y290 w170 BackgroundTrans h20 Hidden", "Go back to lobby if:")

global Tab3_LCondition_All := MainGui.Add("Radio", "x30 y310 w144 Hidden vLeaveCondition Group " (LeaveCondition == "All" ? "Checked" : ""), "All members are gone")
global Tab3_LCondition_Any := MainGui.Add("Radio", "x175 y310 Hidden " (LeaveCondition == "Any" ? "Checked" : ""), "Any member is gone")

MainGui.SetFont("s10 w400 cFFFFFF")
global MultiplayerEnabledTGL := MainGui.Add("Checkbox", "x30 y368 Hidden vMultiplayerEnabled Checked" MultiplayerEnabled, "Enabled")
global Tab3_Line3 := MainGui.Add("Progress", "x30 y360 w640 h1 Hidden Background333333", 0)

MainGui.SetFont("s11 w400 cFFFFFF")
global Tab3_Btn1 := MainGui.Add("Text", "x30 y500 w645 h40 Center Background0e0e0f +Border 0x200 Hidden", "Save all settings")
Tab3_Btn1.OnEvent("Click", SaveAllSettingsMULTIPLAYER)

HoverEffect.Push(Tab3_Btn1)

MainGui.SetFont("s9 w400 cFFFFFF")
global Tab3_Info := MainGui.Add("Text", "x30 y400 w640 h100 Hidden", "The macro can now run simultaneously with other users. Just enter the host's username and the party members.`nHow to use:`n1. Enter the party leader's username in 'Host Username'.`n2. Enter other players' display names in 'Party Members' (separated by commas).`n3. Click 'Save all settings'.")

TAB3.Push(Tab3_Title, Tab3_Line1, Tab3_HostNm, Tab3_HostNm_EDIT, Tab3_PartyMemb, Tab3_PartyMemb_Edit, Tab3_Line2, Tab3_Btn1, Tab3_Info, MultiplayerEnabledTGL, Tab3_RoleTxt, Tab3_Role_Host, Tab3_Role_Member, Tab3_Title2, Tab3_Line3, Tab3_LCondition_All, Tab3_LCondition_Any, Tab3_LConditionTxt)

; tab 4 - WEBHOOK ===========================

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab4_Title := MainGui.Add("Text", "x30 y95 vTab4_TITLE BackgroundTrans h22 w110 Hidden", "Discord Webhook")
HoverEffect.Push(Tab4_Title)
Tab4_Title.OnEvent("Click", DiscordSettings)
global Tab4_Line1 := MainGui.Add("Progress", "x30 y118 w640 h1  Hidden Background333333", 0)
MainGui.SetFont("s9 w400 cAAAAAA")
MainGui.Add("Text", "x30 y135 w200 h20 Hidden vTab4_Lbl1", "Webhook URL:")
global Tab4_Lbl1 := MainGui["Tab4_Lbl1"]
MainGui.SetFont("s9 w400 c000000")
global WebhookLinkCtrl := MainGui.Add("Edit", "x30 y155 w640 h24 Hidden vWebhookLink", WebhookLink)
WebhookLinkCtrl.OnEvent("Change", CheckWebhookLink)
MainGui.SetFont("s9 w400 cFFFFFF")
global WebhookEnabledCtrl := MainGui.Add("Checkbox", "x30 y195 Hidden vWebhookEnabled Checked" WebhookEnabled, "Enable Webhook")
global Tab4_Line2 := MainGui.Add("Progress", "x30 y243 w640 h1 Hidden Background333333", 0)
global SendCurrCtrl := MainGui.Add("Checkbox", "x30 y253 Hidden vSendCurrenciesEnabled Checked" SendCurrenciesEnabled, "Send Statistics")
SendCurrCtrl.OnEvent("Click", (CtrlObj, *) => CtrlObj.Value ? CheckOcrLanguage() : "")
global DebugLogsCtrl := MainGui.Add("Checkbox", "x140 y253 Hidden vWebhookDebugLogs Checked" WebhookDebugLogs, "Debug Logs")
global WebhookScreenshotsCtrl := MainGui.Add("Checkbox", "x235 y253 Hidden vWebhookScreenshots Checked" WebhookScreenshots, "Automatic screenshots")
global WebhookTriumphScreenshotsCtrl := MainGui.Add("Checkbox", "x385 y253 Hidden vWebhookTriumphScreenshots Checked" WebhookTriumphScreenshots, "Triumph and Loss screenshots")
global WebhookSepatateTriumphScreenshotsCtrl := MainGui.Add("Checkbox", "x30 y283 Hidden vWebhookSepatateTriumphScreenshots Checked" WebhookSepatateTriumphScreenshots, "Send Triumph/Loss to a separate channel")
; global WebhookPingsCtrl := MainGui.Add("Checkbox", "x30 y316 Hidden vWebhookPings Checked" WebhookPings, "Ping")
; MainGui.SetFont("s8 w400 cb9b9b8")
; global WebhookErrorsPingCtrl := MainGui.Add("Checkbox", "x30 y346 Hidden vWebhookErrorsPing Checked" WebhookErrorsPing, "Errors")
; global WebhookWinsPingCtrl := MainGui.Add("Checkbox", "x85 y346 Hidden vWebhookWinsPing Checked" WebhookWinsPing, "Wins")
; global WebhookLossesPingCtrl := MainGui.Add("Checkbox", "x136 y346 Hidden vWebhookLossesPing Checked" WebhookLossesPing, "Losses")
MainGui.SetFont("s9 w400 c000000")
global WebhookLinkCtrl2 := MainGui.Add("Edit", "x280 y280 w360 h20 Hidden vWebhookLink2", WebhookLink2)
; global WebhookUserIDCtrl := MainGui.Add("Edit", "x85 y313 w200 h20 Hidden vWebhookUserID", WebhookUserID)
MainGui.SetFont("s9 w400 cFFFFFF")
WebhookLinkCtrl2.OnEvent("Change", CheckWebhookLink2)
EnableWebhookLink2()
WebhookSepatateTriumphScreenshotsCtrl.OnEvent("Click", EnableWebhookLink2)

MainGui.SetFont("s9 w400 cAAAAAA")
global WebhookUserIDLbl := MainGui.Add("Text", "x30 y320 w55 h20 Hidden BackgroundTrans", "User ID:")
MainGui.SetFont("s9 w400 c000000")
global WebhookUserIDCtrl := MainGui.Add("Edit", "x90 y317 w140 h22 Hidden vWebhookUserID", WebhookUserID)
MainGui.SetFont("s9 w400 cFFFFFF")
global WebhookPingOnWinCtrl := MainGui.Add("Checkbox", "x245 y319 w95 h20 Hidden vPingOnWin Checked" PingOnWin, "Ping on Win")
global WebhookPingOnLossCtrl := MainGui.Add("Checkbox", "x350 y319 w100 h20 Hidden vPingOnLoss Checked" PingOnLoss, "Ping on Loss")
global WebhookPingOnTimescaleCtrl := MainGui.Add("Checkbox", "x460 y319 w185 h20 Hidden vPingOnTimescale Checked" PingOnTimescale, "Timescale Depleted")
global Tab4_Info := MainGui.Add("Text", "x30 y400 w640 h100 Hidden", "Webhook sends real-time logs, screenshots, and currency stats to your Discord server.`nUseful to check if your macro is working while being outside.`nHow to get a webhook URL: Create your own Discord Server > Open any channel's settings > Integrations > Create Webhook > Copy Webhook URL.`nYou can also set up a Discord bot by clicking on the 'Discord Webhook' text to view the Discord bot settings.")
MainGui.SetFont("s12 w400 cFFFFFF")
global Tab4_Btn1 := MainGui.Add("Text", "x30  y500 w300 h40 Center Background0e0e0f +Border 0x200 Hidden", "Test Webhook")
Tab4_Btn1.OnEvent("Click", TestWebhook)
global Tab4_Btn2 := MainGui.Add("Text", "x340 y500 w330 h40 Center Background0e0e0f +Border 0x200 Hidden", "Save Discord Settings")
Tab4_Btn2.OnEvent("Click", SaveWebhookSettings)

HoverEffect.Push(Tab4_Btn1) 
HoverEffect.Push(Tab4_Btn2) 

DiscordWebhookTab.Push(Tab4_Title,Tab4_Line1,Tab4_Line2,Tab4_Btn1,Tab4_Btn2,Tab4_Info,Tab4_Lbl1,WebhookEnabledCtrl,SendCurrCtrl,WebhookLinkCtrl,WebhookLinkCtrl2,DebugLogsCtrl,WebhookScreenshotsCtrl,WebhookTriumphScreenshotsCtrl,WebhookSepatateTriumphScreenshotsCtrl,WebhookUserIDLbl,WebhookUserIDCtrl,WebhookPingOnWinCtrl,WebhookPingOnLossCtrl,WebhookPingOnTimescaleCtrl)

;bot tab

MainGui.SetFont("s9 w400 c000000")
global BotTokenCtrl := MainGui.Add("Edit", "x30 y155 w640 h24 Hidden vBotToken", BotToken)

global ChannelIDCtrl := MainGui.Add("Edit", "x30 y273 w310 h24 Hidden vChannelID", ChannelID)
global WebhookUserIDCtrl2 := MainGui.Add("Edit", "x360 y273 w310 h24 Hidden vWebhookUserID2", UserID)

global Tab4_Line3 := MainGui.Add("Progress", "x30 y305 w640 h1 Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cFFFFFF")
global BotEnabledCtrl := MainGui.Add("Checkbox", "x30 y195 Hidden vBotEnabled Checked" BotEnabled, "Enable Bot")

global Tab4_Info_Bot := MainGui.Add("Link", "x30 y368 w640 h100 Hidden", "
(
Here you can set up a Discord bot.`nThe Discord bot can be used as a remote control for your macro.`nFor example, you can start or stop your macro from your phone, as well as get screenshots, statistics, and more!`n`nYou can find the tutorial on how to set up a bot for your macro here: <a href="https://youtu.be/eAQ5Hm7fQu4">https://youtu.be/eAQ5Hm7fQu4</a>
)")

MainGui.SetFont("s9 w400 cAAAAAA")
global bot_token_text :=  MainGui.Add("Text", "x30 y135 w200 h20 Hidden", "Bot Token:")

global channel_id_text :=  MainGui.Add("Text", "x30 y253 w200 h20 Hidden BackgroundTrans", "Channel ID:")
global userid_text :=  MainGui.Add("Text", "x360 y253 w200 h20 Hidden BackgroundTrans", "User ID:")

MainGui.SetFont("s12 w400 cFFFFFF")

global Tab4_bot_Btn1 := MainGui.Add("Text", "x30  y500 w300 h40 Center Background0e0e0f +Border 0x200 Hidden", "Test Bot")
Tab4_bot_Btn1.OnEvent("Click", TestBot)

HoverEffect.Push(Tab4_bot_Btn1)

DiscordBotTab.Push(Tab4_Title, Tab4_Line1, Tab4_Line2, BotTokenCtrl, BotEnabledCtrl, Tab4_Btn2, Tab4_bot_Btn1, bot_token_text, WebhookUserIDCtrl2, ChannelIDCtrl, channel_id_text, userid_text, Tab4_Line3, Tab4_Info_Bot)

;TAB 5 - SETTINGS ==========================

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab5_Section1 := MainGui.Add("Text", "x30 y95  w200 h22 Hidden", "TDS Keybinds")
global Tab5_Line1 := MainGui.Add("Progress", "x30 y118 w250 h1  Hidden Background333333", 0)

MainGui.SetFont("s8 w400 cAAAAAA", "Segoe UI")
global Tab5_Lbl1 := MainGui.Add("Text", "x30 y135 w70 h16 Hidden", "Call of Arms:")
MainGui.SetFont("s8 w400 c000000")
global ChainKeyCtrl := MainGui.Add("Edit", "x105 y132 w40 h18 Center Limit1 Hidden", ChainKey)

MainGui.SetFont("s8 w400 cAAAAAA")
global Tab5_Lbl2 := MainGui.Add("Text", "x152 y135 w80 h16 Hidden", "Drop The Beat:")
MainGui.SetFont("s8 w400 c000000")
global BeatKeyCtrl := MainGui.Add("Edit", "x238 y132 w40 h18 Center Limit1 Hidden", BeatKey)

MainGui.SetFont("s8 w400 cAAAAAA")
global Tab5_Lbl3 := MainGui.Add("Text", "x30 y160 h16 Hidden", "S. Caravan:")
MainGui.SetFont("s8 w400 c000000")
global CaravanKeyCtrl := MainGui.Add("Edit", "x105 y157 w40 h18 Center Limit1 Hidden", CaravanKey)

MainGui.SetFont("s8 w400 cAAAAAA")
global Tab5_Lbl44 := MainGui.Add("Text", "x152 y160 w80 h16 Hidden", "Raise the Dead:")
MainGui.SetFont("s8 w400 c000000")
global RaiseDeadKeyCtrl := MainGui.Add("Edit", "x238 y157 w40 h18 Center Limit1 Hidden", RaiseDeadKey)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global Tab5_Help12 := MainGui.Add("Text", "x280 y157 w18 h18 0x200 Center Hidden", "?")
Tab5_Help12.OnEvent("Click", HelpRaise)

MainGui.SetFont("s8 w400 cAAAAAA")
global Tab5_Lbl55 := MainGui.Add("Text", "x30 y185 h16 Hidden", "Hologram:")
MainGui.SetFont("s8 w400 c000000")
global HologramKeyCtrl := MainGui.Add("Edit", "x105 y182 w40 h18 Center Limit1 Hidden", HologramKey)

MainGui.SetFont("s8 w400 cAAAAAA")
global Tab5_Lbl56 := MainGui.Add("Text", "x152 y185 h16 Hidden", "Reposition:")
MainGui.SetFont("s8 w400 c000000")
global RepoKeyCtrl := MainGui.Add("Edit", "x238 y182 w40 h18 Center Limit1 Hidden", RepoKey)
MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global Tab5_Help11 := MainGui.Add("Text", "x280 y182 w18 h18 0x200 Center Hidden", "?")
Tab5_Help11.OnEvent("Click", HelpBrawler)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab5_Lbl99 := MainGui.Add("Text", "x183 y248 BackgroundTrans Hidden", "cancel:")
MainGui.SetFont("s8 w400 c000000")
global CancelPlacementKeyCtrl := MainGui.Add("Edit", "x230 y248 w17 h17 Center Limit1 Hidden", CancelPlacementKey)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab5_LblUPG := MainGui.Add("Text", "x30 y248 BackgroundTrans Hidden", "upgrade:")
MainGui.SetFont("s8 w400 c000000")
global UpgradeTowerGCtrl := MainGui.Add("Edit", "x85 y248 w17 h17 Center Limit1 Hidden", UpgradeTowerGKey)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab5_LblUPGBTM := MainGui.Add("Text", "x108 y248 BackgroundTrans Hidden", "bottom:")
MainGui.SetFont("s8 w400 c000000")
global UpgradeTowerGBCtrl := MainGui.Add("Edit", "x158 y248 W17 h17 Center Limit1 Hidden", UpgradeTowerGBKey)

MainGui.SetFont("s9 w400 cFFFFFF")

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab5_Section2 := MainGui.Add("Text", "x310 y95  w200 h22 Hidden BackgroundTrans", "Macro Settings")
global Tab5_Line2    := MainGui.Add("Progress", "x310 y118 w360 h1  Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cFFFFFF", "Segoe UI")
global UseUpgradeHCtrl := MainGui.Add("Checkbox", "x310 y135 Hidden", "Use Hotkeys for Upgrading")
UseUpgradeHCtrl.Value := (UseHForUpgrade = 1)
global Tab5_Help6 := MainGui.Add("Text", "x475 y135 w18 h18 0x200 Center Hidden", "?")
Tab5_Help6.OnEvent("Click", HelpAutoCameraCorrection)

global UseRestartBtnCtrl := MainGui.Add("Checkbox", "x310 y160 Hidden", "Click Restart button")
UseRestartBtnCtrl.Value := (UseRestartBtn = "1" || UseRestartBtn = 1)
global Tab5_Help4 := MainGui.Add("Text", "x475 y158 w18 h18 0x200 Center Hidden", "?")
Tab5_Help4.OnEvent("Click", HelpRestartBtn)

global UsePlayAgainBtnCtrl := MainGui.Add("Checkbox", "x310 y185 Hidden", "Click Play Again button")
UsePlayAgainBtnCtrl.Value := (UsePlayAgainBtn = "1" || UsePlayAgainBtn = 1)
global Tab5_Help5 := MainGui.Add("Text", "x475 y183 w18 h18 0x200 Center Hidden", "?")
Tab5_Help5.OnEvent("Click", HelpPlayAgainBtn)

global CheckTheMapCtrl := MainGui.Add("Checkbox", "x310 y210 Hidden", "Check the map")
CheckTheMapCtrl.Value := (CheckTheMap = "1" || CheckTheMap = 1)
global Tab5_Help7 := MainGui.Add("Text", "x475 y207 w18 h18 0x200 Center Hidden", "?")
Tab5_Help7.OnEvent("Click", HelpCheckTheMap)

global UseNumbersForHotbarCtrl := MainGui.Add("Checkbox", "x310 y235 Hidden", "Use Numbers for Hotbar")
UseNumbersForHotbarCtrl.Value := (UseNumbersForHotbar = "1" || UseNumbersForHotbar = 1)

global AutoCloseChatCtrl := MainGui.Add("Checkbox", "x554 y130 Hidden", "Auto Close Chat")
global CollectPlaytimeRewardsCtrl := MainGui.Add("Checkbox", "x510 y193 Hidden", "Collect playtime rewards")
CollectPlaytimeRewardsCtrl.Value := (CollectPlaytimeRewards = 1)
AutoCloseChatCtrl.Value := (AutoCloseChat = 1)

global DebugConsoleCtrl := MainGui.Add("Checkbox", "x570 y152 Hidden", "Debug Logs")
DebugConsoleCtrl.Value := (DebugConsole = "1" || DebugConsole = 1)

global PotatoModeCtrl := MainGui.Add("Checkbox", "x570 y172 Hidden", "Potato Mode")
PotatoModeCtrl.Value := (PotatoMode = 1)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab1_Lbl3 := MainGui.Add("Text", "x502 y192 w62 h20 Hidden BackgroundTrans", "Timescale:")
global TimeScaleModeCtrl := MainGui.Add("DropDownList", "x566 y187 w74 Hidden", ["OFF","1.5x","2x"])
TimeScaleModeCtrl.Text := TimeScaleMode

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab1_Lbl4 := MainGui.Add("Text", "x505 y245 w100 h20 Hidden BackgroundTrans", "Upgrade Delay:")
MainGui.SetFont("s8 w400 c000000")
global UpgradeDelayCtrl := MainGui.Add("Edit", "x595 y241 w80 Hidden Number Limit3 vUpgradeDelay", UpgradeDelay)
UpgradeDelayCtrl.Text := UpgradeDelay

MainGui.SetFont("s9 w400 cFFFFFF")
global MouseSpeedLbl := MainGui.Add("Text", "x310 y270 w110 h20 Hidden BackgroundTrans", "Mouse Speed:")
global MouseSpeedTxt := MainGui.Add("Text", "x389 y270 w26 Hidden", DefaultMouseSpeed)
global MouseSpeedUpDown := MainGui.Add("UpDown", "Range1-3 Hidden", DefaultMouseSpeed)
MouseSpeedUpDown.OnEvent("Change", (ctrl, *) => MouseSpeedTxt.Value := ctrl.Value)

global MouseDelayLbl := MainGui.Add("Text", "x435 y270 w90 h20 Hidden BackgroundTrans", "Mouse Delay:")
global MouseDelayTxt := MainGui.Add("Text", "x509 y270 w32 Hidden", MouseDelay)
global MouseDelayUpDown := MainGui.Add("UpDown", "Range-1-75 Hidden", MouseDelay)
MouseDelayUpDown.OnEvent("Change", (ctrl, *) => MouseDelayTxt.Value := ctrl.Value)

global KeyDelayLbl := MainGui.Add("Text", "x565 y270 w90 h20 Hidden BackgroundTrans", "Key Delay:")
global KeyDelayTxt := MainGui.Add("Text", "x625 y270 w32 Hidden", KeyDelay)
global KeyDelayUpDown := MainGui.Add("UpDown", "Range-1-100 Hidden", KeyDelay)
KeyDelayUpDown.OnEvent("Change", (ctrl, *) => KeyDelayTxt.Value := ctrl.Value)

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tab5_Section3 := MainGui.Add("Text", " BackgroundTrans x30 y272 w200 h22 Hidden", "Recording Hotkeys")
global Tab5_Line3    := MainGui.Add("Progress", "x30 y295 w640 h1  Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cAAAAAA")
global PlcTowerTEXT := MainGui.Add("Text", "x30 y304 w95 h20 Hidden", "Place Tower:")
global PlaceTowerKeyCtrl := MainGui.Add("Hotkey", "x130 y304 w110 h20 Center Hidden", PlaceTowerKey)

global UpgTowerTEXT := MainGui.Add("Text", "x30 y334 w95 h20 Hidden", "Upgrade Tower:")
global UpgradeTowerKeyCtrl := MainGui.Add("Hotkey", "x130 y334 w110 h20 Center Hidden", UpgradeTowerKey)

global AlignCamTEXT := MainGui.Add("Text", "x30 y366 w95 h20 Hidden", "Align Camera:")
global AlignCameraKeyCtrl := MainGui.Add("Hotkey", "x130 y366 w110 h20 Center Hidden", AlignCameraKey)

global DjTrackTEXT := MainGui.Add("Text", "x255 y304 w95 h20 Hidden", "Change DJ Track:")
global ChangeDJTrackKeyCtrl := MainGui.Add("Hotkey", "x355 y304 w110 h20 Center Hidden", ChangeDJTrackKey)

global SellTowTEXT := MainGui.Add("Text", "x255 y334 w95 h20 Hidden", "Sell Tower:")
global SellTowerKeyCtrl := MainGui.Add("Hotkey", "x355 y334 w110 h20 Center Hidden", SellTowerKey)

global DelRecTEXT := MainGui.Add("Text", "x255 y366 w95 h20 Hidden", "Delete Record:")
global DeleteTowerRecordingKeyCtrl := MainGui.Add("Hotkey", "x355 y366 w110 h20 Center Hidden", DeleteTowerRecordingKey)

global RecInputsTEXT := MainGui.Add("Text", "x480 y304 w95 h20 Hidden", "Record Inputs:")
global RecordInputsKeyCtrl := MainGui.Add("Hotkey", "x580 y304 w90 h20 Center Hidden", RecordInputsKey)

global HoloTEXT := MainGui.Add("Text", "x480 y334 w95 h20 Hidden", "Hologram Tower:")
global HoloKeyCtrl := MainGui.Add("Hotkey", "x580 y334 w90 h20 Center Hidden", HoloKey)

global RaiseDeadTEXT := MainGui.Add("Text", "x480 y366 w95 h20 Hidden", "Change Targets:")
global ChangeTargetsCTRL := MainGui.Add("Hotkey", "x580 y366 w90 h20 Center Hidden", ChangeTargetsKey)

global Tab5_Line4 := MainGui.Add("Progress", "x30 y393 w640 h1 Hidden Background333333", 0)

MainGui.SetFont("s9 w400 cAAAAAA")
global Tab5_Lbl4 := MainGui.Add("Text", "x30 y405 w100 h20 Hidden", "VIP Server Link:")
MainGui.SetFont("s9 w400 c000000")
global VipLinkCtrl := MainGui.Add("Edit", "x30 y430 w640 h24 Hidden", VipLink)
MainGui.SetFont("s11 w400 cFFFFFF")
VipLinkCtrl.OnEvent("Change", CheckVipLink)

global UseVipServerCtrl := MainGui.Add("Checkbox", "x30 y465 Hidden", "Use VIP Server")
UseVipServerCtrl.Value := (UseVipServer = "1" || UseVipServer = 1)

global AlwaysOnTopCtrl := MainGui.Add("Checkbox", "x160 y465 Hidden", "Always On Top")
AlwaysOnTopCtrl.Value := (AlwaysOnTop = "1" || AlwaysOnTop = 1)

global LegacyModeCtrl := MainGui.Add("Checkbox", "x560 y465 Hidden", "Legacy Mode")
LegacyModeCtrl.Value := (LegacyMode = "1" || LegacyMode = 1)
LegacyModeCtrl.OnEvent("Click", LegacyModeInfo)

MainGui.SetFont("s11 w400 cFFFFFF")
global Tab5_Btn1 := MainGui.Add("Text", "x30 y500 w645 h40 Center Background0e0e0f +Border 0x200 Hidden", "Save all settings")
Tab5_Btn1.OnEvent("Click", SaveAllSettings)

HoverEffect.Push(Tab5_Btn1)

; tab 6 - tools ===========================

MainGui.SetFont("s10 w400 c3A86FF", "Segoe UI")
global Tools_Section := MainGui.Add("Text", "x30 y95 w200 h22 Hidden", "Tools")
global Tools_Section_Line := MainGui.Add("Progress", "x30 y118 w640 h1 Hidden  Background333333", 0)

MainGui.SetFont("s9 w400 cffffff")
global Tools_Info:= MainGui.Add("Text", "x30 y490 w640 h100 Hidden", "Additional utilities for optimizing and simplifying the gameplay and automating repetitive actions. It reduces your suffering.")

global Auto_COA := MainGui.Add("Picture", "x30 y125 w197 h176 Hidden", "Resources/Gui/auto_coa_preview.png")

Auto_COA.OnEvent("Click", RunAutoAbTool)

global Auto_Spin := MainGui.Add("Picture", "x240 y125 w197 h139 Hidden", "Resources/Gui/auto_spin_preview.png")

Auto_Spin.OnEvent("Click", RunAutoSpinTool)

global Auto_Consum := MainGui.Add("Picture", "x450 y125 w200 h140 Hidden", "Resources/Gui/auto_open_consumable_preview.png")

Auto_Consum.OnEvent("Click", RunAutoConsumableTool)

global Tools_AuditBtn := MainGui.Add("Text", "x30 y330 w197 h40 Center Background0e0e0f +Border 0x200 Hidden", "Open Audit Log")
Tools_AuditBtn.OnEvent("Click", ShowAuditLog)
HoverEffect.Push(Tools_AuditBtn)
global Tools_AuditInfo := MainGui.Add("Text", "x240 y324 w410 h56 Hidden", "Errors, retries and recoveries (for example a tower that could not be placed and then worked at a different spot) are saved to Logs\audit_log.tsv, so you can review them after stopping the macro.")


; footer (version + links). Only the Credits tab used to show it; now unused.
global Divider := MainGui.Add("Progress", "x0 y500 w700 h1 Hidden Background222222", 0)
global FooterBg := MainGui.Add("Progress", "x0 y501 w700 h64 Disabled Hidden Background0f0f0f", 0)

MainGui.SetFont("s10 italic cFFFFFF", "Segoe UI")
global version_text := MainGui.Add("Text", "x30 y520 BackgroundTrans Hidden", ver " * made by darksen")

global githubImg := MainGui.Add("Picture", "x580 y520 w24 h-1 Hidden BackgroundTrans", "Resources\github.png")
githubImg.OnEvent("Click", githubLink)
global DiscordImg := MainGui.Add("Picture", "x611 y520 w24 h-1 Hidden BackgroundTrans", "Resources\discord.png")
DiscordImg.OnEvent("Click", DiscordLink)
global YoutubeImg := MainGui.Add("Picture", "x642 y520 w24 h-1 Hidden BackgroundTrans", "Resources\youtube.png")
YoutubeImg.OnEvent("Click", YouTubeLink)

MainGui.Title := "Unlimited Macro"

; Make the window UIExtra pixels taller: everything in the bottom bar (y >= 500) moves down by that much.
for hwndM, ctrlM in MainGui {
    ctrlM.GetPos(&mx, &my)
    if (my >= 500)
        ctrlM.Move(mx, my + UIExtra)
}
MainGui.Show("w700 h" (565 + UIExtra))

if (AlwaysOnTop = 1) {
    MainGui.Opt("+AlwaysOnTop")
} else {
    MainGui.Opt("-AlwaysOnTop")
}

SetTimer(() => RemoveInitialFocus(), -50)

; ---- Auto-save: settings are written silently in the background -------------
; (the "Save" buttons still work exactly as before and still show a confirmation)
for ctrl in [UseUpgradeHCtrl, UseRestartBtnCtrl, UsePlayAgainBtnCtrl, CheckTheMapCtrl, UseNumbersForHotbarCtrl,
             AutoCloseChatCtrl, CollectPlaytimeRewardsCtrl, DebugConsoleCtrl, PotatoModeCtrl, UseVipServerCtrl, AlwaysOnTopCtrl]
    try ctrl.OnEvent("Click", (*) => SaveAllSettingsQuiet())
try TimeScaleModeCtrl.OnEvent("Change", (*) => SaveAllSettingsQuiet())
for ctrl in [ChainKeyCtrl, BeatKeyCtrl, CaravanKeyCtrl, CancelPlacementKeyCtrl, UpgradeTowerGCtrl, UpgradeTowerGBCtrl,
             RaiseDeadKeyCtrl, HologramKeyCtrl, RepoKeyCtrl, VipLinkCtrl, UpgradeDelayCtrl,
             PlaceTowerKeyCtrl, UpgradeTowerKeyCtrl, AlignCameraKeyCtrl, ChangeDJTrackKeyCtrl, SellTowerKeyCtrl,
             DeleteTowerRecordingKeyCtrl, RecordInputsKeyCtrl, HoloKeyCtrl, ChangeTargetsCTRL,
             MouseSpeedUpDown, MouseDelayUpDown, KeyDelayUpDown]
    try ctrl.OnEvent("Change", (*) => SetTimer(SaveAllSettingsQuiet, -750))

for ctrl in [WebhookEnabledCtrl, SendCurrCtrl, DebugLogsCtrl, WebhookScreenshotsCtrl, WebhookTriumphScreenshotsCtrl,
             WebhookSepatateTriumphScreenshotsCtrl, WebhookPingOnWinCtrl, WebhookPingOnLossCtrl, WebhookPingOnTimescaleCtrl, BotEnabledCtrl]
    try ctrl.OnEvent("Click", (*) => SaveWebhookSettingsQuiet())
for ctrl in [WebhookLinkCtrl, WebhookLinkCtrl2, WebhookUserIDCtrl, BotTokenCtrl, ChannelIDCtrl, WebhookUserIDCtrl2]
    try ctrl.OnEvent("Change", (*) => SetTimer(SaveWebhookSettingsQuiet, -750))

global CurrentTab := "Tab1"
TabCtrl[1].SetFont("cFFFFFF")
ShowTabContent("Tab1")
ShowChildGui()
EnableStratRotation()

SetTimer(Hoverwatchdog, 10)

OnMessage(0x0201, WM_LBUTTONDOWN_Drag)

RemoveInitialFocus() {
    if !WinActive("ahk_id " MainGui.Hwnd)
        return
    ControlFocus(GuiTitleCtrl, "ahk_id " MainGui.Hwnd)
}

~F1:: StartStrategy(0, 0)
~F2:: StopStrategy(0, 0)

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

; Accepts "large" or "(large)"; anything that is not small/medium/large/largest is "".
NormalizeRewardSize(value) {
    v := StrLower(RegExReplace(value, "[()\s]", ""))
    return (v != "" && InStr("|small|medium|large|largest|", "|" v "|")) ? v : ""
}

; Reads one reward line (coins= / gems= / exp=) from a strat's [Info] section.
; These typed rewards are only used by LOSE strategies (result=lose) and by modes without a reward table (Night
; events). On a WIN strategy the rewards are calculated from the game mode, the map and the modifiers
; (ComputeRewards in lib\RewardDatabase.ahk) and anything typed here is ignored.
; Accepted forms, in any order and any case:
;   coins=1425, large      coins=large, 1425      coins=1425      coins=large      coins=0      coins=   (or missing)
; "1,425" counts as one number. Unknown words are ignored, so a bad line can never break the library.
; Returns {amount, size, text, active}:
;   amount : integer, or "" when no number was given
;   size   : small / medium / large / largest, or "" (chooses the icon; worked out from the amount if not written)
;   text   : what is printed under the icon: the amount ("1425" / "0"), or "?" when it is unknown (coins/gems with only a
;            tier, or exp left blank). Coins/gems that are empty or missing print "0". A tier name is never printed.
;   active : true = the strat earns this currency (coloured icon and text); false = grey (0, empty or missing)
; exp has no tiers, only a number.
ParseReward(kind, raw) {
    amount := "", size := ""
    s := RegExReplace(Trim(raw), "[()~]", "")
    s := RegExReplace(s, "(?<=\d),(?=\d{3}(?!\d))", "")      ; 1,425 -> 1425
    for tok in StrSplit(s, [",", ";", "|", "/", " ", "`t"], " `t") {
        tok := StrLower(tok)
        if (tok = "")
            continue
        if RegExMatch(tok, "^\d{1,9}$") {
            amount := Integer(tok)
        } else if InStr("|small|medium|large|largest|", "|" tok "|") {
            size := tok
        }
    }
    tiers := RewardTiers(kind)
    if (kind = "exp") {
        size := ""
    } else if (amount != "" && amount = 0) {
        size := ""                                              ; an explicit 0 means "none"
    } else if (size = "" && amount != "" && tiers.Length > 0) {
        size := tiers[1][1]
        for t in tiers {
            if (amount >= t[2])
                size := t[1]
        }
    }
    active := (amount != "" && amount > 0) || size != ""
    ; Text under the icon is only ever a number: a tier name is never printed.
    ;   amount given            -> the amount (an explicit 0 shows "0")
    ;   coins/gems, nothing/missing -> "0"
    ;   coins/gems, only a tier -> "?"   (the amount is unknown; the tier still picks the icon)
    ;   exp, blank/missing      -> "?"
    if (amount != "")
        text := amount
    else if (kind = "exp")
        text := "?"
    else
        text := (size != "") ? "?" : "0"
    return {amount: amount, size: size, text: text, active: active}
}

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

; Tooltip of a reward plate, e.g. "Large coins" or, when map scaling / modifiers changed it, "Large coins - map 125%, modifiers +10%".
RewardTipText(kind, v, rw) {
    text := (kind = "exp") ? "Tower EXP" : ((v.size = "" ? "No" : StrUpper(SubStr(v.size, 1, 1)) SubStr(v.size, 2)) " " kind)
    if (v.changed) {
        parts := ""
        if (rw.scalePct != 100)
            parts := "map " rw.scalePct "%"
        if (rw.bonus > 0)
            parts .= (parts != "" ? ", " : "") "modifiers +" rw.bonus "%"
        if (parts != "")
            text .= " - " parts
    }
    return text
}

; Shows a strat's rewards on its library card (coins / gems / exp numbers, the coin / gem icon size and the tooltips).
;   Wins are calculated by ComputeRewards from the game mode, map and modifiers; the coins / gems / exp typed in the
;   strat file are never changed. When the calculated number differs from the game mode's set reward, the set reward
;   is shown small and grey with a red streak through it and the new number sits under it in the normal colour.
;   Rewards with an unknown amount ("?") or 0 are shown as they are.
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

EnableStratRotation(*) {
    global RotateStrategies, SwapAmount, SwapUnit, FrameY, FrameH, CurrentScrollPos, ContentH, SliderH, Slider

    v := MainGui.Submit(false)
    RotateStrategies := v.RotateStrategies
    IniWrite(RotateStrategies, SettingsFile, "Options", "RotateStrategies")

    show := (RotateStrategies = 1)

    Tab1_Lbl2.Visible := show
    Strategy2Ctrl.Visible := show
    Tab1_Btn3.Visible := show
    Tab1_Btn4.Visible := show

    SwapAfterLbl.Visible := show
    SwapAmountCtrl.Visible := show
    SwapUnitCtrl.Visible := show

    AutoEquipCtrl.Enabled := !show

    if (show) {
        AutoEquipCtrl.Value := 1
        v := MainGui.Submit(false)
        AutoEquip := v.AutoEquip
        IniWrite(AutoEquip, SettingsFile, "Options", "AutoEquip")
        SwapAmount := SwapAmountCtrl.Text
        SwapUnit := SwapUnitCtrl.Text
        IniWrite(SwapAmount, SettingsFile, "Options", "SwapAmount")
        IniWrite(SwapUnit, SettingsFile, "Options", "SwapUnit")
    }

    ; Layout: the "Strategy 2" row is only there with rotation on. Without it, the checkbox row and the whole
    ; library section move up by one row (30px) so there is no empty gap under the Strategy row.
    dy := show ? 0 : -30
    AutoEquipCtrl.Move(show ? 357 : 155, 190 + dy)
    for item in [[RotateStrategiesCtrl, 190], [SwapAfterLbl, 188], [SwapAmountCtrl, 186], [SwapUnitCtrl, 186],
                 [Tab1_Lbl3, 192], [TimeScaleModeCtrl, 187],
                 [Tab1_Section2, 223], [Tab1_Line2, 250],
                 [Tab1_AddBtn, 223], [Tab1_FolderBtn, 223], [Tab1_RefreshBtn, 223]]
        item[1].Move(, item[2] + dy)

    ; The library frame follows: starts 30px higher and is 30px taller, so it still ends above Start/Stop.
    newFrameY := 262 + dy
    newFrameH := 224 + UIExtra - dy
    if (newFrameH != FrameH || newFrameY != FrameY) {
        FrameY := newFrameY
        FrameH := newFrameH
        try {
            ; back to the top, then rebuild the scrollbar thumb for the new frame height
            if (CurrentScrollPos > 0)
                DllCall("ScrollWindow", "Ptr", ChildGui.Hwnd, "Int", 0, "Int", CurrentScrollPos, "Ptr", 0, "Ptr", 0)
            CurrentScrollPos := 0
            SliderH := (ContentH <= FrameH) ? FrameH : Max(30, Round(FrameH * (FrameH / ContentH)))
            hThumb := CreateScrollThumb(6, SliderH, 3, "0xFF6EA7FF", "0xff4076ce", "0xd4d4d4")
            Slider.Value := "HBITMAP:*" hThumb
            Slider.Move(0 + (FrameW - 10), 0, 6, SliderH)
            ShowChildGui()
        }
    }
    try WinRedraw(MainGui.Hwnd)
}

EnableAutoEquip(*) {
    global AutoEquip
    
    v := MainGui.Submit(false)
    AutoEquip := v.AutoEquip
    IniWrite(AutoEquip, SettingsFile, "Options", "AutoEquip")
}

SelectStrat1(ctrl, *) {
    global Strategy1Path
    targDir := RecordingsDir
    if (Strategy1Ctrl.Value) {
        SplitPath(Strategy1Ctrl.Value, , &parentDir) 
        targDir := parentDir
    }
    f := FileSelect("3", targDir, "Select strategy file 1", "Strategy (*.strat)")
    if (f != "") {
        Strategy1Ctrl.Value := f
        Strategy1Path := f
        IniWrite(f, SettingsFile, "Options", "Strategy1")
        LoadStrategyFile(f)
    }
}
SelectStrat2(ctrl, *) {
    global Strategy2Path
    targDir := RecordingsDir
    if (Strategy2Ctrl.Value) {
        SplitPath(Strategy2Ctrl.Value, , &parentDir) 
        targDir := parentDir
    }
    f := FileSelect("3", targDir, "Select strategy file 2", "Strategy (*.strat)")
    if (f != "") {
        Strategy2Ctrl.Value := f
        Strategy2Path := f
        IniWrite(f, SettingsFile, "Options", "Strategy2")
    }
}
ClearStrat1(ctrl, *) {
    global Strategy1Path
    Strategy1Ctrl.Value := ""
    Strategy1Path := ""
    IniWrite(" ", SettingsFile, "Options", "Strategy1")
}
ClearStrat2(ctrl, *) {
    global Strategy2Path
    Strategy2Ctrl.Value := ""
    Strategy2Path := ""
    IniWrite(" ", SettingsFile, "Options", "Strategy2")
}
SaveStrat1(ctrl, *) {
    global Strategy1Path, Strategy1Ctrl
    Strategy1Path := Strategy1Ctrl.Text
    IniWrite(Strategy1Ctrl.Text, SettingsFile, "Options", "Strategy1")
}

SaveStrat2(ctrl, *) {
    global Strategy2Path, Strategy2Ctrl
    Strategy2Path := Strategy2Ctrl.Text
    IniWrite(Strategy2Ctrl.Text, SettingsFile, "Options", "Strategy2")
}


StartStrategy(*) {
    if (RunningStrategy or Recording) {
        return
    }
    g_IsFirstLaunch := Integer(IniRead(StateFile, "State", "IsFirstLaunch", 1))

    global RunningStrategy, CurrentRotationIndex, gamemap, difficulty, requiredTowers, modifiers
    global autoChain, autoCaravan, autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global AutorunStartTime, CurrentStratStartTime

    if !IsSet(MainGui) or !MainGui
        return

    v := MainGui.Submit(false)
    IniWrite(v.Strategy1, SettingsFile, "Options", "Strategy1")
    IniWrite(v.Strategy2, SettingsFile, "Options", "Strategy2")

    if (v.RotateStrategies = 1) {
        s1 := Trim(v.Strategy1)
        s2 := Trim(v.Strategy2)

        for num, s in [s1, s2] {
            if (s == "" || !FileExist(s)) {
                ModernMsgBox("Warning", "Rotation mode is enabled but strategy " num " is empty or file doesn't exist!`nPlease select a valid file for Strategy " num "!", "OK", "WARNING")
                return
            }
        }
    }

    stratFile := ""
    s1 := v.Strategy1, s2 := v.Strategy2

    if (v.RotateStrategies = 1 && s2 != "") {
        if (s1 != "" && FileExist(s1)) {
            stratFile := s1
            CurrentRotationIndex := 1
        }
    } else {
        if (s1 != "" && FileExist(s1))
            stratFile := s1
        else if (s2 != "" && FileExist(s2))
            stratFile := s2
    }

    if (stratFile = "") {
        ModernMsgBox("Warning", "No valid strategy file selected!", "OK", "WARNING")
        return
    }

    if (g_IsFirstLaunch = 1) {
        IniWrite(0, StateFile, "State", "IsFirstLaunch")
        MsgBox("Since you are starting the macro for the first time... Read this so your macro can work properly:`n`n1. Go to the TDS Settings and ENABLE 'Prefer Vertical Upgrades`n2. Go to the TDS Settings and set UI Scale to 'LARGE'`n3. Set your Roblox Camera Mode to Classic`n4. If your Roblox graphics are automatic, set them to manual.`n5. Turn off camera shake in TDS.`n6. Disable Dialog in TDS`n7. Enable UI Navigation toggle in the Roblox settings.`n8. Enable 'Show Tower Options' in TDS.`n9. Make sure you have 60 fps in Roblox settings.`n`nRecommended screen resolution for this macro is 1920x1080 (Resolutions bigger than 1080p may not work. You can use 1366x768 & 1280x720 though, they work pretty well). The scale must be 100%.`nThis macro requires a good CPU. You can use it though if your device is bad, enable potato mode and make the delays bigger.`nPlease, join my Discord server to get help and check the FAQ.","READ THIS!!", 0x1030)
    }

    IniDelete(StateFile, "State", "Coins")
    IniDelete(StateFile, "State", "Gems")
    IniDelete(StateFile, "State", "EXP")
    IniDelete(StateFile, "State", "TotalTriumphs")
    IniDelete(StateFile, "State", "TotalLosses")
    IniDelete(StateFile, "State", "TotalTimeSeconds")
    IniDelete(StateFile, "State", "Timescale")
    IniDelete(StateFile, "State", "CurrentStratStartTime")
    IniDelete(StateFile, "State", "CurrentRotationIndex")
    IniDelete(StateFile, "State", "CurrentRunCount")
    IniDelete(StateFile, "State", "StartTime")
    IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
    IniDelete(StateFile, "State", "Equipped")

    AutorunStartTime := 0

    LoadStrategyFile(stratFile)

    if (requiredTowers != "" && !AutoEquip)
        MsgBox(requiredTowers, "Required Towers", "0x1040 T60")

    IniWrite(1, StateFile, "State", "Running")
    IniWrite(stratFile, StateFile, "State", "Strategy")

    MainGui.Hide()
    RunningStrategy := true

    time := FormatTime(, "HH:mm:ss")
    SplitPath(stratFile, &fileName)
    startInfo := "[" time "] Started strategy: " fileName "`n"
    startInfo .= "Map = " gamemap "`nMode = " difficulty "`nTimescale = " TimeScaleMode "`nRequired Towers: " requiredTowers
    if (modifiers != "")
        startInfo .= "`nModifiers: " modifiers
    SendToWebhookInstant(startInfo,, flush := false)
    AuditLog("INFO", "Strategy", "Started: " fileName " | map " gamemap " | mode " difficulty)

    CheckOcrLanguage()

    MultiInstanceTools := "RobloxAccountManager.exe,Roblox Account Manager.exe,RAM.exe,RobloxMulti.exe,MultiRoblox.exe,MultipleRoblox.exe,Multiple Roblox.exe"
    Loop Parse, MultiInstanceTools, "," {
        if ProcessExist(A_LoopField) {
            MsgBox("Conflicting program detected:`n" A_LoopField "`n`nFor this script to work properly, please close all Roblox multi-client utilities.`nPlease close them and try again.", "Error", 0x1030)
            ExitApp()
        }
    }

    CurrentStratStartTime := A_TickCount
    IniWrite(A_TickCount, StateFile, "State", "CurrentStratStartTime")
    CurrentRunCount := 0
    IniWrite(0, StateFile, "State", "CurrentRunCount")

    RunStrategy("", true)
}

StopStrategy(*) {
    global RunningStrategy, AutorunStartTime, Recording, MacroRecording, InputHookObj

    KillSubmacros()

    if (RunningStrategy) {
        if (AutorunStartTime > 0) {
            runtime := FormatRuntime(AutorunStartTime)
            Coins := IniRead(StateFile, "State", "Coins", "0")
            Gems  := IniRead(StateFile, "State", "Gems",  "0")
            Timescales  := IniRead(StateFile, "State", "Timescale",  "0")
            LogToConsole("Strategy stopped. Runtime: " runtime)
            AuditLog("INFO", "Strategy", "Stopped. Runtime: " runtime)
            time := FormatTime(, "HH:mm:ss")
            SendToWebhookInstant("[" time "] Strategy stopped. Runtime: " runtime)
            IniDelete(StateFile, "State", "StartTime")
            AutorunStartTime := 0
        }
        DeleteAllIndicators()
        IniWrite(0, StateFile, "State", "Running")
        IniWrite(0, StateFile, "State", "Strategy")
        IniDelete(StateFile, "State", "Coins")
        IniDelete(StateFile, "State", "Gems")
        IniDelete(StateFile, "State", "EXP")
        IniDelete(StateFile, "State", "TotalTriumphs")
        IniDelete(StateFile, "State", "TotalLosses")
        IniDelete(StateFile, "State", "TotalTimeSeconds")
        IniDelete(StateFile, "State", "Timescale")
        IniDelete(StateFile, "State", "CurrentStratStartTime")
        IniDelete(StateFile, "State", "CurrentRotationIndex")
        IniDelete(StateFile, "State", "CurrentRunCount")
        IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
        IniDelete(StateFile, "State", "Equipped")
        RunningStrategy := false
        SafeReload()
    }

    if (Recording) {
        StopRecord(0)
    }
}

StartRecording(ctrl, *) {
    global Recording, gamemap, difficulty, requiredTowers, modifiers, autoChain, autoCaravan
    global autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global Commander, RecordedSteps, Towers, MacroRecording, GuiTitleCtrl
    global Tab2_Btn1, Tab2_Btn2, HoverEffect

    if (Recording)
        return

    v := MainGui.Submit(false)

    if (!v.RecMaps or !v.RecDifficulty or !v.RecRequiredTowers) {
        MsgBox("Failed to start recording!`nMake sure you have entered the towers, the map, and the difficulty, then try again.", "Error", 0x1010)
        return
    }

    if (A_ScreenWidth != 1920 || A_ScreenHeight != 1080) {
        if (MsgBox("Your screen resolution is not 1920x1080.`nThe recording system is highly recommended for 1920x1080. Do you want to continue?", "Warning", 0x1034) = "No") {
            return
        }
    }

    if (IsSet(GuiTitleCtrl) && GuiTitleCtrl) {
        GuiTitleCtrl.SetFont("cff6b6b")
    }

    if (IsSet(Tab2_Btn1) && Tab2_Btn1) {
        Tab2_Btn1.SetFont("c808080 norm")
        Tab2_Btn1.Opt("Background0e0e0f")
        if (IsSet(HoverEffect) && IsObject(HoverEffect)) {
            for index, element in HoverEffect {
                if (element = Tab2_Btn1) {
                    HoverEffect.RemoveAt(index)
                    break
                }
            }
        }
    }

    if (IsSet(Tab2_Btn2) && Tab2_Btn2) {
        Tab2_Btn2.SetFont("cWhite norm")
        if (IsSet(HoverEffect) && IsObject(HoverEffect)) {
            hasElement := false
            for element in HoverEffect {
                if (element = Tab2_Btn2) {
                    hasElement := true
                    break
                }
            }
            if (!hasElement) {
                HoverEffect.Push(Tab2_Btn2)
            }
        }
    }

    gamemap := v.RecMaps
    difficulty := v.RecDifficulty
    requiredTowers := v.RecRequiredTowers
    modifiers := (SpecialModeName(v.RecDifficulty) != "") ? "" : v.RecModifiers      ; special modes: no modifiers
    autoChain := v.RecAutoChain ? "ON" : "OFF"
    autoCaravan := v.RecAutoCaravan ? "ON" : "OFF"
    autoDropTheBeat := v.RecAutoDropTheBeat ? "ON" : "OFF"
    AutoSkip := v.RecAutoSkip ? "ON" : "OFF"
    AbilitySpam := v.RecAbilitySpam ? "ON" : "OFF"
    MoveEnabled := v.RecMoveEnabled ? true : false
    MoveDirection := v.RecMoveDirection
    MoveDuration := IsNumber(v.RecMoveDuration) ? Integer(v.RecMoveDuration) : 750

    Commander := false
    Recording := true
    RecordedSteps := []
    Towers := Map()
    DeleteAllIndicators()

    LogToConsole("Recording started.")
    
    ActivateRoblox()
}

; Failsafe: special game modes (Pizza Party, Badlands II, Polluted Wasteland II) have fixed rewards and cannot use
; modifiers, so picking one clears and locks the modifier list.
RecDiff_Changed(*) {
    global RecDiffCtrl, RecModifiersCtrl, Tab2_Info2
    special := SpecialModeName(RecDiffCtrl.Text) != ""
    if (special)
        RecModifiersCtrl.Choose(0)
    RecModifiersCtrl.Enabled := !special
    Tab2_Info2.Value := special ? "Special game modes have fixed rewards: modifiers are not allowed." : "Hold CTRL to deselect/select multiple modifiers."
}

StopRecord(ctrl, *) {
    global Recording, MacroRecording, InputHookObj, MacroSteps, RecordedSteps
    global gamemap, difficulty, requiredTowers, modifiers
    global autoChain, autoCaravan, autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global GuiTitleCtrl, Strategy1Ctrl, RecordingsDir
    global Tab2_Btn1, Tab2_Btn2, HoverEffect

    if (MacroRecording) {
        MacroRecording := false
        if (InputHookObj != "")
            InputHookObj.Stop()
        LogToConsole("Macro recording auto-stopped")
        if (ModernMsgBox("Add to Strategy?", "Add recorded actions to current strategy?", "YES|NO") = "YES") {
            for i, step in MacroSteps
                RecordedSteps.Push(step)
            LogToConsole("Added " MacroSteps.Length " macro steps to strategy")
        }
    }

    if (!Recording)
        return
    Recording := false
    DeleteAllIndicators()

    if (IsSet(GuiTitleCtrl) && GuiTitleCtrl) {
        GuiTitleCtrl.SetFont("cWhite")
    }

    if (IsSet(Tab2_Btn1) && Tab2_Btn1) {
        Tab2_Btn1.SetFont("cWhite norm")
        if (IsSet(HoverEffect) && IsObject(HoverEffect)) {
            hasElement := false
            for element in HoverEffect {
                if (element = Tab2_Btn1) {
                    hasElement := true
                    break
                }
            }
            if (!hasElement) {
                HoverEffect.Push(Tab2_Btn1)
            }
        }
    }

    if (IsSet(Tab2_Btn2) && Tab2_Btn2) {
        Tab2_Btn2.SetFont("c808080 norm")
        Tab2_Btn2.Opt("Background0e0e0f")
        if (IsSet(HoverEffect) && IsObject(HoverEffect)) {
            for index, element in HoverEffect {
                if (element = Tab2_Btn2) {
                    HoverEffect.RemoveAt(index)
                    break
                }
            }
        }
    }

    if (ModernMsgBox("Save", "Save the recorded strategy?", "YES|NO") = "YES") {
        box := InputBox("File name (without .strat):", "Save", "w300 h130", "MyStrategy")
        if (box.Result = "Cancel")
            return
        filePath := RecordingsDir "\" box.Value ".strat"
        if FileExist(filePath)
            FileDelete(filePath)
        getRobloxPos(&pX, &pY, &currentWidth, &currentHeight)

        ; win or lose: a win strategy gets its rewards calculated, a lose strategy keeps the ones you type in
        resultWin := (ModernMsgBox("Win or lose?", "Does this strategy WIN the match?`n`nYES = win (the rewards are calculated for you)`nNO = lose (you type the rewards into the strat file)", "YES|NO") = "YES")

        FileAppend("[Info]`nresult=" (resultWin ? "win" : "lose") "`n`n[Settings]`nmap=" gamemap "`ndifficulty=" difficulty "`nrequiredTowers=" requiredTowers
            . "`nmodifiers=" Join(modifiers)
            . "`nautoChain=" autoChain "`nautoCaravan=" autoCaravan "`nautoDropTheBeat=" autoDropTheBeat
            . "`nautoSkip=" AutoSkip "`nabilitySpam=" AbilitySpam "`nmoveEnabled=" MoveEnabled "`nmoveDirection=" MoveDirection
            . "`nmoveDuration=" MoveDuration "`n`n[DO NOT EDIT]`nwidth=" currentWidth "`nheight=" currentHeight "`n`n[Steps]`n", filePath)
        for i, step in RecordedSteps
            FileAppend(step "`n", filePath)
        LogToConsole("Strategy saved: " filePath)
        Strategy1Ctrl.Value := filePath
    } else {
        LogToConsole("Recording cancelled, strategy not saved")
    }
}

PlaceTowerHK(*) {
    global Recording, Towers, RecordedSteps, ActiveRTowerID, CachedMenuUI, isUiPositionSaved, UseNumbersForHotbar, Slots

    if (!Recording) {
        pureKey := RegExReplace(PlaceTowerKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(PlaceTowerKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }
    
    towersStringBackup := Towers 

    MouseGetPos(&mx, &my)
    loop {
        slotBox := InputBox("Enter the tower slot number (1-5):", "Slot (1-5)", "w300 h130", "1")

        if (slotBox.Result = "Cancel")
            return

        try {
            sllot := Integer(slotBox.Value)
            
            if (sllot >= 1 && sllot <= 5) {
                break
            } else {
                continue
            }
        } 
        catch Error {
            continue
        }
    }
    slot := slotBox.Value
    
    suggestedID := GetNextTowerID(slot)
    
    idBox := InputBox("Enter a specific tower id:", "Tower ID", "w300 h130", suggestedID)
    if (idBox.Result = "Cancel")
        return
    towerID := idBox.Value
    ActivateRoblox()

    LogToConsole("Recording: placing tower " towerID " (slot " slot ") at x:" mx " y:" my "...")

    getRobloxPos(,,&w,&h)

    ActivateRoblox()
    
    if UseNumbersForHotbar {
        Send("{" slot "}")
    } else {
        Click(Slots[slot])
    }

    Sleep(30)
    

    MouseMove(mx, my, A_DefaultMouseSpeed)
    Sleep((PotatoMode = 1) ? 100 : 40)
    Click()
    Sleep(100)
    SendEvent("{" CancelPlacementKey "}")

    Towers[towerID] := {x: mx, y: my, slot: slot, level: 0, path: 0, pathLevel: 0, target: "First Enemy"}
    UpdateTowerIndicator(towerID)
    LogToConsole("Recorded tower " towerID " (slot " slot ")")

    RecordedSteps.Push("SpawnTower(" mx ", " my ", " slot ", " towerID ")")

    if (towerID = "" || RegExMatch(towerID, "i)(Juggernaut|Hacker|Pursuit|Kingpin)")) {
        ShowTowerPathDialog(towerID)
    }

    ActiveRTowerID := towerID
    
    openedSuccessfully := false
    Loop 10 {
        getRobloxPos(,,&w,&h)
        resV2 := AdvancedImageSearch("Resources\TowerUI\Variant2.png", 0, Round(h / 2), Round(w * 0.3), Round(h * 0.9) - Round(h / 2), 0.5, 1.5)
        
        if (resV2.status == "success" && resV2.score > 0.6) {
            
            if (!isUiPositionSaved) {
                Sleep(300) 
                
                getRobloxPos(,,&w,&h)
                resV2Final := AdvancedImageSearch("Resources\TowerUI\Variant2.png", 0, Round(h / 2), Round(w * 0.3), Round(h * 0.9) - Round(h / 2), 0.5, 1.5)
                
                if (resV2Final.status == "success") {
                    CachedMenuUI := {x: resV2Final.x, y: resV2Final.y}
                    isUiPositionSaved := true 
                    openedSuccessfully := true
                } else {
                    CachedMenuUI := {x: resV2.x, y: resV2.y}
                    isUiPositionSaved := true
                    openedSuccessfully := true
                }
            } 
            else {
                openedSuccessfully := true
            }
            break
        }
        Sleep(150)
    }
    
    if (!openedSuccessfully) {
        ActiveRTowerID := ""
    }
}

UpgradeTowerHK(*) {
    global Recording, Towers, RecordedSteps, Commander
    if (!Recording) {
        pureKey := RegExReplace(UpgradeTowerKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(UpgradeTowerKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    MouseGetPos(&mx, &my)

    closestID := ""
    for id, t in Towers {
        ix1 := t.x - 12
        iy1 := t.y - 12
        ix2 := ix1 + 24
        iy2 := iy1 + 24
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            closestID := id
            break
        }
    }

    if (closestID != "") {
        Towers[closestID].level += 1
        UpdateTowerIndicator(closestID)
        if (Towers[closestID].path != 0 && Towers[closestID].path != "") {
            RecordedSteps.Push("UpgradeTower(" closestID ", false, 1, " Towers[closestID].path ", " Towers[closestID].pathLevel ")")
        } else {
            RecordedSteps.Push("UpgradeTower(" closestID ")")
        }
        if (Towers[closestID].level >= 2 && RegExMatch(closestID, "i)^Commander\d*$") && !Commander) {
            Commander := true
            if (!HasStep("Commander := true"))
                RecordedSteps.Push("Commander := true")
        }
    }
}

ChangeDJTrackHK(*) {
    global Recording, RecordedSteps
    if (!Recording) {
        pureKey := RegExReplace(ChangeDJTrackKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(ChangeDJTrackKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }
    box := InputBox("Enter Track Color (Purple/Red/Green):", "DJ Track", "w300 h130", "Green")
    if (box.Result != "Cancel") {
        RecordedSteps.Push('SetDJTrack("' box.Value '")')
        LogToConsole("Recorded DJ-track " box.Value)
    }
}

DeleteTowerRecordingHK(*) {
    global Recording, Towers, RecordedSteps
    if (!Recording) {
        pureKey := RegExReplace(DeleteTowerRecordingKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(DeleteTowerRecordingKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    MouseGetPos(&mx, &my)

    closestID := ""
    for id, t in Towers {
        if (!HasProp(t, "x") || !HasProp(t, "y"))
            continue

        ix1 := t.x - 12
        iy1 := t.y - 12
        ix2 := ix1 + 24
        iy2 := iy1 + 24
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            closestID := id
            break
        }
    }

    if (closestID != "") {
        if (HasProp(Towers[closestID], "hwnd") && Towers[closestID].hwnd) {
            try WinClose("ahk_id " Towers[closestID].hwnd)
        }

        newSteps := []
        
        escapedID := RegExReplace(closestID, "([\.\ \+\*\?\^\$\(\)\[\]\{\}\|])", "\$1")

        for i, step in RecordedSteps {
            if (RegExMatch(step, "i)^SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*" escapedID "\s*\)$"))
                continue
            if (RegExMatch(step, "i)^UpgradeTower\s*\(\s*" escapedID "\s*(?:,.*)?\s*\)$"))
                continue
            if (RegExMatch(step, "i)^SellTower\s*\(\s*" escapedID "\s*\)$"))
                continue
            newSteps.Push(step)
        }
        RecordedSteps := newSteps

        try {
            if Towers.Has(closestID) {
                Towers.Delete(closestID)
            }
        } catch {
        }

        LogToConsole("Recorded sell tower " closestID)
    }
}


SellTowerHK(*) {
    global Recording, Towers, RecordedSteps
    if (!Recording) {
        pureKey := RegExReplace(SellTowerKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(SellTowerKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    MouseGetPos(&mx, &my)

    closestID := ""
    for id, t in Towers {
        ix1 := t.x - 12
        iy1 := t.y - 12
        ix2 := ix1 + 24
        iy2 := iy1 + 24
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            closestID := id
            break
        }
    }
    if (closestID != "") {
        if (Towers[closestID].hwnd) {
            WinClose("ahk_id " Towers[closestID].hwnd)
            Towers[closestID].hwnd := ""
        }
        RecordedSteps.Push("SellTower(" closestID ")")
        SellTower(closestID)
        newSteps := []
        for i, step in RecordedSteps {
            if (RegExMatch(step, "i)^SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*" closestID "\s*\)$"))
                continue
            if (RegExMatch(step, "i)^UpgradeTower\s*\(\s*" closestID "\s*\)$"))
                continue
            newSteps.Push(step)
        }
        RecordedSteps := newSteps
        Towers.Delete(closestID)
        LogToConsole("Recorded sell tower " closestID)
    }
}

AlignCameraHK(*) {
    if (!Recording) {
        pureKey := RegExReplace(AlignCameraKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(AlignCameraKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    if (InArray(SpecialMaps, gamemap)) {
        functionName := gamemap . "Path"

        %functionName%() 
    } else {
        AlignCamera()
    }
}

RecordInputsHK(*) {
    global MacroRecording, InputHookObj, MacroSteps, MacroStartTime, RecordedSteps, Recording, KeyDownTimes
    if (!Recording) {
        pureKey := RegExReplace(RecordInputsKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(RecordInputsKey, "^([\^+!#]+)", &match) ? match[1] : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }
    if (MacroRecording) {
        MacroRecording := false
        if (InputHookObj != "")
            InputHookObj.Stop()
        LogToConsole("Recording ALL clicks and keys STOPPED. Steps: " MacroSteps.Length)
        if (ModernMsgBox("Add to Strategy?", "Add recorded actions to current strategy?", "YES|NO") = "YES") {
            for i, step in MacroSteps
                RecordedSteps.Push(step)
            LogToConsole("Added " MacroSteps.Length " steps to strategy")
        }
    } else {
        LogToConsole("Recording ALL clicks and keys...!")
        MacroRecording := true
        MacroSteps     := []
        KeyDownTimes   := Map() 
        MacroStartTime := A_TickCount
        InputHookObj := InputHook("V")
        InputHookObj.KeyOpt("{All}", "N")
        InputHookObj.OnKeyDown := OnKeyDown
        InputHookObj.OnKeyUp := OnKeyUp 
        InputHookObj.Start()
    }
}

CloneTowerHK(*) {
    global Recording, RecordedSteps
    static LastCallTime := 0

    if (!Recording) {
        pureKey := RegExReplace(HoloKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(HoloKey, "^([\^+!#]+)", &match) ? match : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    CoordMode("Mouse", "Client")
    ActivateRoblox()
    MouseGetPos(&mx, &my)

    idBox := InputBox("Enter the tower ID to clone:", "Clone Tower", "w300 h130", "")
    if (idBox.Result = "Cancel")
        return

    towerID := Trim(idBox.Value)
    if (towerID = "") {
        return
    }

    CloneTower(towerID, mx, my)

    RecordedSteps.Push("CloneTower(" towerID ", " mx ", " my ")")
}

BrawlerRepositionHK(*) {
    global Recording, RecordedSteps, ActiveRTowerID

    if (!Recording) {
        pureKey := RegExReplace(HoloKey, "[\^+!#]") 
        SEND_modifiers := RegExMatch(HoloKey, "^([\^+!#]+)", &match) ? match : ""
        
        SendEvent("{Blind}" SEND_modifiers "{" pureKey "}")
        return
    }

    CoordMode("Mouse", "Client")
    MouseGetPos(&mx, &my)

    if (ActiveRTowerID = "") {
        idBox := InputBox("Enter the tower ID to reposition:", "Repo Brawler", "w300 h130", "")
        if (idBox.Result = "Cancel")
            return

        towerID := Trim(idBox.Value)
        if (towerID = "") {
            return
        }
        BrawlerReposition(towerID, mx, my)
    } else {
        towerID := ActiveRTowerID

        Hotkey("~LButton", "Off")
        g := KeyWait("LButton", "D")
        Hotkey("~LButton", "On")

        MouseGetPos(&mx, &my)

        Towers[towerId].x := mx
        Towers[towerId].y := my
        UpdateTowerIndicator(towerId)
    }

    RecordedSteps.Push("BrawlerReposition(" towerID ", " mx ", " my ")")
    LogToConsole("Recorded BrawlerReposition(" towerID ", " mx ", " my ")")
}

ActivateRaiseTheDeadHK(*) {
    global Recording, RecordedSteps
    static LastCallTime := 0

    waitTime := 0
    currentTime := A_TickCount

    if (RecordedSteps.Length > 0) {
        lastStep := RecordedSteps[RecordedSteps.Length]
        
        if (InStr(lastStep, "ActivateRaiseTheDead") && LastCallTime > 0) {
            waitTime := currentTime - LastCallTime
        }
    }

    LastCallTime := currentTime
    ActivateRaiseTheDead(waitTime)

    RecordedSteps.Push("ActivateRaiseTheDead(" waitTime ")")
}

RecordToggleAutoskip(*) {
    global Recording, AutoSkip
    if !Recording {
        return
    }

    v := MainGui.Submit(false)
    at := v.RecAutoSkip ? "ON" : "OFF"

    RecordedSteps.Push("ToggleAutoskip()")

    if at = "ON" {
        LogToConsole("Toggled auto-skip: ON")
    } else {
        LogToConsole("Toggled auto-skip: OFF")
    }
}

ChangeTargetsHK(*) {
    global Recording, RecordedSteps, ActiveRTowerID, LastOpenedTowerID

    CoordMode("Mouse", "Client")
    MouseGetPos(&mx, &my)

    if (ActiveRTowerID = "") {
        idBox := InputBox("Enter the tower ID:", "Change Targets", "w300 h100", "")
        if (idBox.Result = "Cancel")
            return

        towerID := Trim(idBox.Value)
        if (towerID = "") {
            return
        }
    } else {
        towerID := ActiveRTowerID
        LastOpenedTowerID := towerID
    }

    targetBox := InputBox("Enter the target:", "Change Targets", "w300 h100", "")
    if (targetBox.Result = "Cancel")
        return

    target := Trim(targetBox.Value)
    if (target = "") {
        return
    }

    ChangeTargets(towerID, target)

    RecordedSteps.Push("ChangeTargets(" towerID ", " target ")")
    LogToConsole("Recorded ChangeTargets(" towerID ", " target ")")
}

;PATHS =======================================

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



;=====

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


OnKeyDown(ih, vk, sc) {
    global MacroSteps, MacroStartTime, MacroRecording, KeyDownTimes
    if (!MacroRecording)
        return
        
    if (vk = 0xA0 || vk = 0xA1 || vk = 0xA2 || vk = 0xA3
        || vk = 0xA4 || vk = 0xA5 || vk = 0x5B || vk = 0x5C
        || vk = 0x11 || vk = 0x12 || vk = 0x41)
        return
        
    keyId := vk "-" sc
    
    if (KeyDownTimes.Has(keyId))
        return
        
    currentTime := A_TickCount
    elapsed := currentTime - MacroStartTime
    MacroStartTime := currentTime
    
    KeyDownTimes[keyId] := currentTime
    MacroSteps.Push("Sleep(" elapsed ")")
}

OnKeyUp(ih, vk, sc) {
    global MacroSteps, MacroStartTime, MacroRecording, KeyDownTimes
    if (!MacroRecording)
        return
        
    if (vk = 0xA0 || vk = 0xA1 || vk = 0xA2 || vk = 0xA3
        || vk = 0xA4 || vk = 0xA5 || vk = 0x5B || vk = 0x5C
        || vk = 0x11 || vk = 0x12 || vk = 0x41)
        return
        
    currentTime := A_TickCount
    keyId := vk "-" sc
    
    holdDuration := 50
    if (KeyDownTimes.Has(keyId)) {
        holdDuration := currentTime - KeyDownTimes[keyId]
        KeyDownTimes.Delete(keyId) 
    }

    elapsed := currentTime - MacroStartTime
    MacroStartTime := currentTime
    
    keyName := GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc))
    if (keyName = "")
        keyName := "VK" Format("{:02X}", vk)
        
    MacroSteps.Push('Send("' keyName '", hold:=' holdDuration ')')
    
    if (elapsed > 0) {
        MacroSteps.Push("Sleep(" elapsed ")")
    }
}

^SC02C:: {
    global RecordedSteps, Towers, Recording, Commander
    
    if (!Recording) {
        Send("^{SC02C}")
        return
    }
    if (RecordedSteps.Length == 0) {
        return
    }

    lastStep := RecordedSteps.Pop()
    LogToConsole("Undo: Reverting step -> " lastStep)

    if RegExMatch(lastStep, "i)UpgradeTower\s*\(\s*([^\n,\)]+)", &matchUpgrade) {
        towerID := Trim(matchUpgrade[1]) 
        
        if (Towers.Has(towerID)) {
            Towers[towerID].level := Max(0, Towers[towerID].level - 1)
            UpdateTowerIndicator(towerID)
        }
        return
    }

    if RegExMatch(lastStep, "i)SpawnTower\s*\(\s*[^,]+\s*,\s*[^,]+\s*,\s*[^,]+\s*,\s*(.*?)\s*\)", &matchPlace)
    {
        towerID := matchPlace[1] 
        
        if (Towers.Has(towerID)) {
            if (Towers[towerID].HasProp("hwnd") && Towers[towerID].hwnd && WinExist("ahk_id " Towers[towerID].hwnd)) {
                WinClose("ahk_id " Towers[towerID].hwnd)
            }
            Towers.Delete(towerID)

        }
        return
    }

    if (lastStep = "Commander := true") {
        Commander := false
        return
    }
}

~RButton:: {
    global MacroRecording, MacroSteps, MacroStartTime, Towers
    if (!Recording) {
        return
    }

    if (MacroRecording) {
        MouseGetPos(&mx, &my)
        elapsed := A_TickCount - MacroStartTime
        MacroStartTime := A_TickCount
        MacroSteps.Push("Sleep(" elapsed ")")
        MacroSteps.Push("Click(" mx ", " my ", Right)")
        return
    }

    MouseGetPos(&mx, &my)

    towerID := ""

    for id, t in Towers {
        ix1 := t.x - 16
        iy1 := t.y - 16
        ix2 := ix1 + 32
        iy2 := iy1 + 32
        
        if (mx >= ix1 && mx <= ix2 && my >= iy1 && my <= iy2) {
            towerID := id
            break
        }
    }

    if (towerID != "")
        ShowTowerPathDialog(towerID)
}

global ActivePathSelectTowerID := ""

ShowTowerPathDialog(towerID) {
    global Towers, ActivePathSelectTowerID
    if (!Towers.Has(towerID) || Towers[towerID].path = 0 || Towers[towerID].path = "") {
        ActivePathSelectTowerID := towerID
        PathGui := Gui("+AlwaysOnTop +Border", "Path Selection")
        PathGui.SetFont("s12 Bold c000000", "Segoe UI")
        PathGui.Add("Text", "x25 y20 w350", "Tower " towerID)
        PathGui.SetFont("s11 w400 c000000", "Segoe UI")
        PathGui.Add("Text", "x25 y+10 w350", "Choose an upgrade path")
        PathGui.Add("Text", "x25 y+10 w350", "Rigth click on the tower indicator to make this appear.`nNote: enter 3 for Pursuit, Juggernaut, and Kingpin, 4 for Hacker")
        PathGui.SetFont("s10 w600 c000000")
        b1 := PathGui.Add("Button", "x25 y+25 w165 h40", "Path 1 (Top)")
        b1.OnEvent("Click", (*) => SelectPath(PathGui, 1))
        b2 := PathGui.Add("Button", "x+10 w165 h40", "Path 2 (Bottom)")
        b2.OnEvent("Click", (*) => SelectPath(PathGui, 2))
        bc := PathGui.Add("Button", "x25 y+10 w340 h35", "Cancel")
        bc.OnEvent("Click", (*) => PathGui.Destroy())
        PathGui.Show("w390 h280")
        WinWaitClose("ahk_id " PathGui.Hwnd)
    }
}

SelectPath(pathGui, pathNum) {
    global Towers, ActivePathSelectTowerID
    pathGui.Destroy()
    towerID := ActivePathSelectTowerID
    if (towerID = "")
        return
    box := InputBox("Enter the level where the paths appear:", "Level", "w300 h130", "")
    if (box.Result = "Cancel" || !IsInteger(box.Value))
        return
    Towers[towerID].path      := pathNum
    Towers[towerID].pathLevel := Integer(box.Value)
    UpdateTowerIndicator(towerID)
    LogToConsole("Tower " towerID " set to path " pathNum " from level " box.Value)
}

TestWebhook(ctrl, *) {
    global WebhookLink
    v := MainGui.Submit(false)
    if (v.WebhookLink = "") {
        ModernMsgBox("Error", "Enter a webhook URL first!", "OK", "WARNING")
        return
    }
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", v.WebhookLink, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.SetTimeouts(0, 3000, 3000, 3000)
        whr.Send('{"content": "✅ Webhook test successful! Unlimited Macro TDS is connected."}')
        if (whr.Status = 200 || whr.Status = 204)
            ModernMsgBox("Success", "Webhook test successful!", "OK")
        else
            ModernMsgBox("Error", "Webhook test failed! Status: " whr.Status, "OK", "WARNING")
    } catch {
        ModernMsgBox("Error", "Failed to send test message. Check your connection and webhook URL.", "OK", "WARNING")
    }
}

TestBot(ctrl, *) {
    global BotToken, ChannelID
    v := MainGui.Submit(false)
    
    if (v.BotToken = "") {
        ModernMsgBox("Error", "Enter a bot token first!", "OK", "WARNING")
        return
    }
    
    if (v.ChannelID = "") {
        ModernMsgBox("Error", "Enter a channel ID first!", "OK", "WARNING")
        return
    }
    
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Option[9] := 2720
        whr.Open("POST", "https://discord.com/api/v10/channels/" v.ChannelID "/messages", false)
        whr.SetRequestHeader("User-Agent", "DiscordBot (AHK, " A_AhkVersion ")")
        whr.SetRequestHeader("Authorization", "Bot " v.BotToken)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.SetTimeouts(0, 3000, 3000, 3000)
        whr.Send('{"content": "✅ Bot test successful! Unlimited Macro TDS is connected."}')
        
        if (whr.Status = 200 || whr.Status = 201 || whr.Status = 204) {
            ModernMsgBox("Success", "Bot test successful! Message sent to channel.", "OK")
        } else {
            errorMsg := "Bot test failed! Status: " whr.Status

            try {
                response := JSON.parse(whr.ResponseText)
                if response.Has("message")
                    errorMsg .= "`n`nDiscord Error: " response["message"]
            }
            
            switch whr.Status {
                case 401:
                    errorMsg .= "`n`nInvalid bot token!"
                case 403:
                    errorMsg .= "`n`nBot lacks permission to send messages in this channel!"
                case 404:
                    errorMsg .= "`n`nChannel not found! Check Channel ID."
                case 429:
                    errorMsg .= "`n`nRate limited! Try again later."
            }
            
            ModernMsgBox("Error", errorMsg, "OK", "WARNING")
        }
    } catch as err {
        ModernMsgBox("Error", "Failed to send test message. Check your connection and settings.`n`n" err.Message, "OK", "WARNING")
    }
}

SaveWebhookSettings(ctrl := 0, *) {
    SaveWebhookSettingsInternal(true)
}

SaveWebhookSettingsQuiet(*) {
    SaveWebhookSettingsInternal(false)
}

SaveWebhookSettingsInternal(showMsg := true) {
    global WebhookUserID, PingOnWin, PingOnLoss, PingOnTimescale
    global WebhookLink, WebhookLink2, WebhookEnabled, SendCurrenciesEnabled, WebhookDebugLogs, WebhookScreenshots, WebhookTriumphScreenshots, WebhookSepatateTriumphScreenshots, UserID, ChannelID, BotEnabled, BotToken
    v := MainGui.Submit(0)
    WebhookLink := v.WebhookLink
    WebhookLink2 := v.WebhookLink2
    WebhookEnabled := v.WebhookEnabled
    SendCurrenciesEnabled := v.SendCurrenciesEnabled
    WebhookDebugLogs := v.WebhookDebugLogs
    WebhookScreenshots := v.WebhookScreenshots
    WebhookTriumphScreenshots := v.WebhookTriumphScreenshots
    WebhookSepatateTriumphScreenshots := v.WebhookSepatateTriumphScreenshots
    BotToken := v.BotToken
    BotEnabled := v.BotEnabled
    ChannelID := v.ChannelID
    UserID := v.WebhookUserID2
    WebhookUserID := Trim(v.WebhookUserID)
    PingOnWin := v.PingOnWin
    PingOnLoss := v.PingOnLoss
    PingOnTimescale := v.PingOnTimescale
    IniWrite(PingOnWin, SettingsFile, "Webhook", "PingOnWin")
    IniWrite(PingOnLoss, SettingsFile, "Webhook", "PingOnLoss")
    IniWrite(PingOnTimescale, SettingsFile, "Webhook", "PingOnTimescale")
    IniWrite(BotToken, BotSettings, "Token", "BotToken")
    IniWrite(BotEnabled, BotSettings, "Settings", "Enabled")
    IniWrite(ChannelID, BotSettings, "Settings", "Channel")
    IniWrite(UserID, BotSettings, "Settings", "UserID")
    IniWrite(WebhookLink, SettingsFile, "Webhook", "Link")
    IniWrite(WebhookLink2, SettingsFile, "Webhook", "Link2")
    IniWrite(WebhookUserID, SettingsFile, "Webhook", "WebhookUserID")
    IniWrite(WebhookEnabled, SettingsFile, "Webhook", "Enabled")
    IniWrite(SendCurrenciesEnabled, SettingsFile, "Webhook", "SendCurrencies")
    IniWrite(WebhookDebugLogs, SettingsFile, "Webhook", "WebhookDebugLogs")
    IniWrite(WebhookScreenshots, SettingsFile, "Webhook", "WebhookScreenshots")
    IniWrite(WebhookTriumphScreenshots, SettingsFile, "Webhook", "WebhookTriumphScreenshots")
    IniWrite(WebhookSepatateTriumphScreenshots, SettingsFile, "Webhook", "WebhookSepatateTriumphScreenshots")

    if (BotEnabled && ChannelID != "" && UserID != "") {
        SetTimer(ProcessCommands, 7500, 1)
    } else {
        SetTimer(ProcessCommands, 0)
    }

    if (showMsg)
        MsgBox("All discord settings have been successfully saved!", "Unlimited Macro", 0x1040)
}


NormalizeKey(keyName) {
    if (keyName = "")
        return ""

    if !RegExMatch(keyName, "^([~!#^+<>*]*)(.*)$", &Match)
        return keyName
        
    modifiers := Match[1]
    pureKey   := Match[2]

    if (StrLen(pureKey) > 1)
        return keyName
    
    res := DllCall("User32.dll\VkKeyScanW", "UShort", Ord(pureKey), "Short")
    vk := res & 0xFF
    
    if (vk = 0xFF || vk = 0)
        return keyName
    
    sc := DllCall("User32.dll\MapVirtualKeyW", "UInt", vk, "UInt", 0, "UInt")
    
    if (!sc)
        return keyName
    
    return modifiers . Format("sc{:03X}", sc)
}


SaveAllSettings(ctrl := 0, *) {
    SaveAllSettingsInternal(true)
}

SaveAllSettingsQuiet(*) {
    SaveAllSettingsInternal(false)
}

SaveAllSettingsInternal(showMsg := true) {
    global UpgradeDelay
    global ChainKey, BeatKey, CaravanKey, CancelPlacementKey, TimeScaleMode, UseTimeScale
    global TimeScaleMultiplier, VipLink, UseVipServer, AlwaysOnTop, LegacyMode, DebugConsole
    global PotatoMode, UseRestartBtn, UsePlayAgainBtn, CheckTheMap
    global PlaceTowerKey, UpgradeTowerKey, AlignCameraKey, ChangeDJTrackKey
    global SellTowerKey, DeleteTowerRecordingKey, RecordInputsKey
    global SettingsFile
    global DefaultMouseSpeed, MouseDelay, KeyDelay
    global HoloKey, RaiseDeadKey, ChangeTargetsKey, HologramKey, RepoKey, CollectPlaytimeRewards, AutoCloseChat, UpgradeTowerGKey, UpgradeTowerGBKey, UseHForUpgrade, UseNumbersForHotbar

    tempChainKey := SubStr(RegExReplace(ChainKeyCtrl.Value, "\s", ""), 1, 1)
    tempBeatKey := SubStr(RegExReplace(BeatKeyCtrl.Value, "\s", ""), 1, 1)
    tempCaravanKey := SubStr(RegExReplace(CaravanKeyCtrl.Value, "\s", ""), 1, 1)
    tempCancelPlacementKey := SubStr(RegExReplace(CancelPlacementKeyCtrl.Value, "\s", ""), 1, 1)
    tempUpgradeTowerGKey := SubStr(RegExReplace(UpgradeTowerGCtrl.Value, "\s", ""), 1, 1)
    tempUpgradeTowerGBKey := SubStr(RegExReplace(UpgradeTowerGBCtrl.Value, "\s", ""), 1, 1)
    
    if (tempChainKey = "")           
        tempChainKey := "C"
    if (tempBeatKey = "")            
        tempBeatKey  := "B"
    if (tempCaravanKey = "")         
        tempCaravanKey := "J"
    if (tempCancelPlacementKey = "") 
        tempCancelPlacementKey := "Q"
    if (tempUpgradeTowerGKey = "")
        tempUpgradeTowerGKey := "E"
    if (tempUpgradeTowerGBKey = "")
        tempUpgradeTowerGKey := "Z"

    tempPlaceTowerKey := NormalizeKey(PlaceTowerKeyCtrl.Value)
    tempUpgradeTowerKey := NormalizeKey(UpgradeTowerKeyCtrl.Value)
    tempAlignCameraKey := NormalizeKey(AlignCameraKeyCtrl.Value)
    tempChangeDJTrackKey := NormalizeKey(ChangeDJTrackKeyCtrl.Value)
    tempSellTowerKey := NormalizeKey(SellTowerKeyCtrl.Value)
    tempDeleteTowerRecordingKey := NormalizeKey(DeleteTowerRecordingKeyCtrl.Value)
    tempRecordInputsKey := NormalizeKey(RecordInputsKeyCtrl.Value)
    tempHoloKey := NormalizeKey(HoloKeyCtrl.Value)
    tempChangeTargetsKey := NormalizeKey(ChangeTargetsCTRL.Value)

    UsedKeys := Map()
    
    KeysToCheck := [
        {val: NormalizeKey(tempChainKey), name: "Call of Arms Ability"},
        {val: NormalizeKey(tempBeatKey), name: "Drop the Beat Ability"},
        {val: NormalizeKey(tempCaravanKey), name: "Support Caravan Ability"},
        {val: NormalizeKey(tempCancelPlacementKey), name: "Cancel Placement"},
        {val: NormalizeKey(tempUpgradeTowerGKey), name: "Upgrade Tower (TDS keybind)"},
        {val: NormalizeKey(tempUpgradeTowerGBKey), name: "Upgrade Bottom Path (TDS keybind)"},
        {val: tempPlaceTowerKey, name: "Place Tower"},
        {val: tempUpgradeTowerKey, name: "Upgrade Tower"},
        {val: tempAlignCameraKey, name: "Align Camera"},
        {val: tempChangeDJTrackKey, name: "Change DJ Track"},
        {val: tempSellTowerKey, name: "Sell Tower"},
        {val: tempDeleteTowerRecordingKey, name: "Delete Tower Recording"},
        {val: tempRecordInputsKey, name: "Record Inputs"},
        {val: tempHoloKey, name: "Hologram Tower"},
        {val: tempChangeTargetsKey, name: "Change Targets"}
    ]

    hasKeyError := false
    for item in KeysToCheck {
        if (item.val = "") {
            hasKeyError := true
            if (showMsg) {
                MsgBox("Error: Empty hotkey detected!`n`n" 
                . "The hotkey is assigned to: `"" item.name "`"`n"
                . "Please change it before saving.", "Empty Hotkey", 0x10)
                return
            }
            break
        }
        if UsedKeys.Has(item.val) {
            hasKeyError := true
            if (showMsg) {
                MsgBox("Error: Duplicate hotkey detected!`n`n" 
                     . "The hotkey is assigned to: `"" UsedKeys[item.val] "`"`n"
                     . "And also that hotkey is assigned to: `"" item.name "`"`n`n"
                     . "Please change it before saving.", "Duplicate Hotkey", 0x10)
                return 
            }
            break
        }
        UsedKeys[item.val] := item.name
    }

    if (hasKeyError) {
        ; auto-save only: keep the last valid hotkeys until the conflict is fixed
        tempChainKey := ChainKey
        tempBeatKey := BeatKey
        tempCaravanKey := CaravanKey
        tempCancelPlacementKey := CancelPlacementKey
        tempUpgradeTowerGKey := UpgradeTowerGKey
        tempUpgradeTowerGBKey := UpgradeTowerGBKey
        tempPlaceTowerKey := PlaceTowerKey
        tempUpgradeTowerKey := UpgradeTowerKey
        tempAlignCameraKey := AlignCameraKey
        tempChangeDJTrackKey := ChangeDJTrackKey
        tempSellTowerKey := SellTowerKey
        tempDeleteTowerRecordingKey := DeleteTowerRecordingKey
        tempRecordInputsKey := RecordInputsKey
        tempHoloKey := HoloKey
        tempChangeTargetsKey := ChangeTargetsKey
    }

    ChainKey := tempChainKey
    BeatKey := tempBeatKey
    CaravanKey := tempCaravanKey
    CancelPlacementKey := tempCancelPlacementKey
    UpgradeTowerGKey := tempUpgradeTowerGKey
    UpgradeTowerGBKey := tempUpgradeTowerGBKey

    oldRecordingKeys := [PlaceTowerKey, UpgradeTowerKey, AlignCameraKey, ChangeDJTrackKey,
        SellTowerKey, DeleteTowerRecordingKey, RecordInputsKey, HoloKey, ChangeTargetsKey]

    
    PlaceTowerKey := tempPlaceTowerKey
    UpgradeTowerKey := tempUpgradeTowerKey
    AlignCameraKey := tempAlignCameraKey
    ChangeDJTrackKey := tempChangeDJTrackKey
    SellTowerKey := tempSellTowerKey
    DeleteTowerRecordingKey := tempDeleteTowerRecordingKey
    RecordInputsKey := tempRecordInputsKey
    HoloKey := tempHoloKey
    ChangeTargetsKey := tempChangeTargetsKey
    RaiseDeadKey := RaiseDeadKeyCtrl.Value
    HologramKey := HologramKeyCtrl.Value
    RepoKey := RepoKeyCtrl.Value

    recordingKeysChanged := false
    newRecordingKeys := [PlaceTowerKey, UpgradeTowerKey, AlignCameraKey, ChangeDJTrackKey,
        SellTowerKey, DeleteTowerRecordingKey, RecordInputsKey, HoloKey, ChangeTargetsKey]
    for i, oldKey in oldRecordingKeys {
        if (oldKey != newRecordingKeys[i])
            recordingKeysChanged := true
    }
    if (showMsg || recordingKeysChanged)
        RegisterRecordingHotkeys(oldRecordingKeys)

    TimeScaleMode := (TimeScaleModeCtrl.Text = "") ? "OFF" : TimeScaleModeCtrl.Text
    VipLink := VipLinkCtrl.Value
    UseVipServer := UseVipServerCtrl.Value
    AlwaysOnTop := AlwaysOnTopCtrl.Value
    DebugConsole := DebugConsoleCtrl.Value
    PotatoMode := PotatoModeCtrl.Value
    UseRestartBtn := UseRestartBtnCtrl.Value
    UsePlayAgainBtn := UsePlayAgainBtnCtrl.Value
    CheckTheMap := CheckTheMapCtrl.Value
    UseNumbersForHotbar := UseNumbersForHotbarCtrl.Value
    CollectPlaytimeRewards := CollectPlaytimeRewardsCtrl.Value
    AutoCloseChat := AutoCloseChatCtrl.Value
    UseHForUpgrade := UseUpgradeHCtrl.Value
    
    DefaultMouseSpeed := MouseSpeedUpDown.Value
    MouseDelay := MouseDelayUpDown.Value
    KeyDelay := KeyDelayUpDown.Value
    if (Trim(UpgradeDelayCtrl.Value) != "")
        UpgradeDelay := UpgradeDelayCtrl.Value
    
    IniWrite(ChainKey, SettingsFile, "Hotkeys", "Chain")
    IniWrite(BeatKey, SettingsFile, "Hotkeys", "Beat")
    IniWrite(CaravanKey, SettingsFile, "Hotkeys", "Caravan")
    IniWrite(CancelPlacementKey, SettingsFile, "Hotkeys", "CancelPlacement")
    IniWrite(UpgradeTowerGKey, SettingsFile, "Hotkeys", "UpgradeTower")
    IniWrite(UpgradeTowerGBKey, SettingsFile, "Hotkeys", "UpgradeBottom")
    IniWrite(RaiseDeadKey, SettingsFile, "Hotkeys", "RaiseTheDead")
    IniWrite(HologramKey, SettingsFile, "Hotkeys", "Hologram")
    IniWrite(RepoKey, SettingsFile, "Hotkeys", "Repo")
    IniWrite(TimeScaleMode, SettingsFile, "Options", "TimeScaleMode")
    IniWrite(VipLink, SettingsFile, "Options", "VipLink")
    IniWrite(UseVipServer, SettingsFile, "Options", "UseVipServer")
    IniWrite(DebugConsole, SettingsFile, "Options", "DebugConsole")
    IniWrite(PotatoMode, SettingsFile, "Options", "PotatoMode")
    IniWrite(AlwaysOnTop, SettingsFile, "Options", "AlwaysOnTop")
    if (showMsg)
        IniWrite(LegacyModeCtrl.Value, SettingsFile, "Options", "LegacyMode")
    IniWrite(UseRestartBtn, SettingsFile, "Options", "UseRestartBtn")
    IniWrite(UsePlayAgainBtn, SettingsFile, "Options", "UsePlayAgainBtn")
    IniWrite(CheckTheMap, SettingsFile, "Options", "CheckTheMap")
    IniWrite(UseNumbersForHotbar, SettingsFile, "Options", "UseNumbers")
    IniWrite(CollectPlaytimeRewards, SettingsFile, "Options", "CollectPlaytimeRewards")
    IniWrite(AutoCloseChat, SettingsFile, "Options", "AutoCloseChat")
    IniWrite(UseHForUpgrade, SettingsFile, "Options", "UseHotkeyForUpgrade")
    IniWrite(DefaultMouseSpeed, SettingsFile, "Options", "DefaultMouseSpeed")
    IniWrite(MouseDelay, SettingsFile, "Options", "MouseDelay")
    IniWrite(KeyDelay, SettingsFile, "Options", "KeyDelay")
    IniWrite(UpgradeDelay, SettingsFile, "Options", "UpgradeDelay")

    IniWrite(PlaceTowerKey, SettingsFile, "RecordingHotkeys", "PlaceTowerKey")
    IniWrite(UpgradeTowerKey, SettingsFile, "RecordingHotkeys", "UpgradeTowerKey")
    IniWrite(AlignCameraKey, SettingsFile, "RecordingHotkeys", "AlignCameraKey")
    IniWrite(ChangeDJTrackKey, SettingsFile, "RecordingHotkeys", "ChangeDJTrackKey")
    IniWrite(SellTowerKey, SettingsFile, "RecordingHotkeys", "SellTowerKey")
    IniWrite(DeleteTowerRecordingKey, SettingsFile, "RecordingHotkeys", "DeleteTowerRecordingKey")
    IniWrite(RecordInputsKey, SettingsFile, "RecordingHotkeys", "RecordInputsKey")
    IniWrite(ChangeTargetsKey, SettingsFile, "RecordingHotkeys", "ChangeTargetsKey")
    IniWrite(HoloKey, SettingsFile, "RecordingHotkeys", "HoloKey")

    if (TimeScaleMode = "1.5x") {
        UseTimeScale := true
        TimeScaleMultiplier := 1.5
    } else if (TimeScaleMode = "2x") {
        UseTimeScale := true
        TimeScaleMultiplier := 2
    } else {
        UseTimeScale := false
        TimeScaleMultiplier := 1
    }

    if (DebugConsole = "1" || DebugConsole = 1) {
        ShowDebugConsole()
    } else {
        HideDebugConsole()
    }

    if (AlwaysOnTop = 1) {
        MainGui.Opt("+AlwaysOnTop")
    } else {
        MainGui.Opt("-AlwaysOnTop")
    }

    if (showMsg) {
        if (LegacyModeCtrl.Value = 1 && LegacyMode = 0) {
            if A_ScreenHeight != 1080 && A_ScreenWidth != 1920 {
                MsgBox("WARNING! Legacy mode works only for 1920x1080!", "Warning", 0x1030)
            }
            Reload
        }
         if (LegacyModeCtrl.Value = 0 && LegacyMode = 1) {
            Reload
        }

        LegacyMode := LegacyModeCtrl.Value
    }
    
    SetDefaultMouseSpeed(DefaultMouseSpeed)
    SetMouseDelay(MouseDelay)
    SetKeyDelay(KeyDelay)

    if (showMsg)
        MsgBox("All settings have been successfully saved!", "Unlimited Macro", 0x1040)
}

SaveAllSettingsMULTIPLAYER(ctrl, *) {
    global HostName, PartyMembersStr, MultiplayerEnabled, PlayerRole, LeaveCondition
    global SettingsFile

    s := MainGui.Submit(false)

    HostName := Trim(Tab3_HostNm_EDIT.Value)
    PartyMembersStr := RegExReplace(Tab3_PartyMemb_Edit.Value, "\s*,\s*", ",")
    MultiplayerEnabled := MultiplayerEnabledTGL.Value
    PlayerRole := (s.PlayerRole == 2) ? "Member" : "Host"
    LeaveCondition := (s.LeaveCondition == 1) ? "All" : "Any"

    IniWrite(HostName, SettingsFile, "Multiplayer", "HostName")
    IniWrite(PartyMembersStr, SettingsFile, "Multiplayer", "PartyMembers")
    IniWrite(MultiplayerEnabled, SettingsFile, "Multiplayer", "MultiplayerEnabled")
    IniWrite(PlayerRole, SettingsFile, "Multiplayer", "PlayerRole")
    IniWrite(LeaveCondition, SettingsFile, "Multiplayer", "LeaveCondition")

    global PartyMembers := IniRead(SettingsFile, "Multiplayer", "PartyMembers", "someone, someone...")
    global PlayerRole := IniRead(SettingsFile, "Multiplayer", "PlayerRole", "Host")
    global HostName := IniRead(SettingsFile, "Multiplayer", "HostName", "...")
    global LeaveCondition := IniRead(SettingsFile, "Multiplayer", "LeaveCondition", "Any")
    global MultiplayerEnabled := IniRead(SettingsFile, "Multiplayer", "MultiplayerEnabled", 0)

    MsgBox("Multiplayer settings saved!", "Success", 0x1040)
}

LegacyModeInfo(*) {
    if LegacyModeCtrl.Value = 1 {
        MsgBox("Changes how the image detection works. May not work for some people.`n`nWarning: some features - such as Auto Equip, Changing Tower Targeting will not work with this mode!", "Legacy Mode", "0x1040")
    }
}

CheckVipLink(ctrl, *) {
    
    str := Trim(VipLinkCtrl.Value)
    
    if (RegExMatch(str, "i)roblox\.com\/(?:[a-z]{2}\/)?games\/3260590327\/[^\/]*\?privateServerLinkCode=(?<code>[a-z0-9]{32})", &m)) {
        UseVipServerCtrl.Value := 1
        return
    }
    if (RegExMatch(str, "i)roblox\.com\/share\?code=(?<code>[a-f0-9]{32})", &m)) {
        try {
            wr := ComObject("WinHttp.WinHttpRequest.5.1")
            wr.Open("GET", "https://www.roblox.com/share?code=" m["code"] "&type=Server", true)
            wr.Send()
            if (wr.WaitForResponse(3) && wr.Status = 200 && InStr(wr.ResponseText, "3260590327")) {
                return
            }
        } catch Error {
            
        }
    }
    UseVipServerCtrl.Value := 0
}

CheckWebhookLink(ctrl, *) {
    v := MainGui.Submit(false)
    link := v.WebhookLink
    if (link = "" || (!InStr(link, "discord.com/api/webhooks/") && !InStr(link, "discordapp.com/api/webhooks/"))) {
        WebhookEnabledCtrl.Value   := 0
        return
    }
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", link, false)
        whr.SetTimeouts(3000, 3000, 4000, 4000)
        whr.Send()
        WebhookEnabledCtrl.Enabled := (whr.Status = 200)
        if (whr.Status != 200)
            WebhookEnabledCtrl.Value := 0
    } catch {
        WebhookEnabledCtrl.Value := 0
    }
}

EnableWebhookLink2(*) {
    v := MainGui.Submit(false)
    toggle := v.WebhookSepatateTriumphScreenshots
    if toggle = 1 {
        WebhookLinkCtrl2.Visible := true
    } else {
        WebhookLinkCtrl2.Visible := false
    }
}

DiscordSettings(*) {
    if tab4_Title.Text = "Discord Webhook" {
        tab4_Title.Text := "Discord Bot"
        HideAllTabContent()
        ShowDiscordSettings()
    } else {
        tab4_Title.Text := "Discord Webhook"
        HideAllTabContent()
        ShowDiscordSettings()
    }
}

ShowDiscordSettings(*) {
    if tab4_Title.Text = "Discord Webhook" {
        HideAllTabContent()
        for ctrl in DiscordWebhookTab
            ctrl.Visible := true
    } else {
        HideAllTabContent()
        for ctrl in DiscordBotTab
            ctrl.Visible := true
    }
}

CheckWebhookLink2(ctrl, *) {
    v := MainGui.Submit(false)
    link := v.WebhookLink2
    if (link = "" || (!InStr(link, "discord.com/api/webhooks/") && !InStr(link, "discordapp.com/api/webhooks/"))) {
        WebhookSepatateTriumphScreenshotsCtrl.Value := 0
        return
    }
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", link, false)
        whr.Send()
        WebhookSepatateTriumphScreenshotsCtrl.Enabled := (whr.Status = 200)
        if (whr.Status != 200)
            WebhookSepatateTriumphScreenshotsCtrl.Value := 0
    } catch {
        WebhookSepatateTriumphScreenshotsCtrl.Value := 0
    }
}


ShowFAQ(*) {
    ModernMsgBox("FAQ",
        "[SCREEN AND SYSTEM SETTINGS]`n" .
        "- Screen Resolution: Works strictly in 1920x1080.`n" .
        "- Windows Scale: Must be set to 100%.`n" .
        "- Taskbar: Must be visible.`n`n" .
        "[ROBLOX AND GAME SETTINGS]`n" .
        "- UI Scale: Set to Large.`n" .
        "- Screen Shake: Must be DISABLED.`n" .
        "- Roblox Chat: Close the chat before starting the macro.`n" .
        "- Set 'Prefer Vertical Upgrades' to Disabled.`n" .
        "- Fonts: Do not use custom fonts.`n`n" .
        "[COMMANDER ISSUES]`n" .
        "- Auto Chain: Enter 'Commander1', 'Commander2', etc., when placing them.", "OK")
}
HelpChain(*) {
    ModernMsgBox("Info", "Configure hotkey for Commander's 'Call of Arms'.", "OK")
}
HelpBeat(*) {
    ModernMsgBox("Info", "Configure hotkey for DJ's 'Drop The Beat'.", "OK")
}
HelpCaravan(*) {
    ModernMsgBox("Info", "Configure hotkey for the 'Support Caravan'.", "OK")
}
HelpCancelPlacement(*) {
    ModernMsgBox("Info", "Configure hotkey for the 'Cancel Placement'.", "OK")
}
HelpTimeScale(*) {
    ModernMsgBox("Timescale Info", "1.5x — more stable and recommended for most cases.`n2x — requires special strategies but is much more effective.`n`nThis will automatically turn off if you run out of timescale tickets.", "OK")
}
HelpPotatoMode(*) {
    ModernMsgBox("Info", "Turn this on if your macro acts inconsistently or if you have lags.", "OK")
}
HelpSendCurrencies(*) {
    ModernMsgBox("Info", "If you enable the 'Send currencies' toggle, the macro will send you information about your coins, gems, total matches, triumphs, and losses.`n`nMay be buggy.", "OK")
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


LoadStrategyFile(file) {
    global Towers, RecordedSteps, gamemap, difficulty, requiredTowers, autoChain, autoCaravan
    global autoDropTheBeat, AutoSkip, AbilitySpam, MoveEnabled, MoveDirection, MoveDuration
    global modifiers, Commander, StrategyWidth, StrategyHeight, CurrentStrategyFile

    CurrentStrategyFile := file

    Towers := Map()
    RecordedSteps := []
    DeleteAllIndicators()

    gamemap := IniRead(file, "Settings", "map", "")
    difficulty := IniRead(file, "Settings", "difficulty", "")
    requiredTowers  := IniRead(file, "Settings", "requiredTowers",  "")
    autoChain := IniRead(file, "Settings", "autoChain", "OFF")
    autoCaravan := IniRead(file, "Settings", "autoCaravan", "OFF")
    autoDropTheBeat := IniRead(file, "Settings", "autoDropTheBeat", "OFF")
    AutoSkip := IniRead(file, "Settings", "autoSkip", "ON")
    AbilitySpam := IniRead(file, "Settings", "abilitySpam", "ON")
    modifiers := IniRead(file, "Settings", "modifiers", "")

    moveDown := IniRead(file, "Settings", "moveDown", "false")
    tempEnabled := IniRead(file, "Settings", "moveEnabled",   "")
    tempDir := IniRead(file, "Settings", "moveDirection", "")
    tempDur := IniRead(file, "Settings", "moveDuration",  "")

    if (tempEnabled != "") {
        MoveEnabled := (tempEnabled = "true" || tempEnabled = "1") ? true : false
        MoveDirection := (tempDir != "" && (tempDir = "W" || tempDir = "A" || tempDir = "S" || tempDir = "D")) ? tempDir : "W"
        MoveDuration := IsNumber(tempDur) ? Integer(tempDur) : 750
    } else {
        if (moveDown = "true") {
            MoveEnabled := true, MoveDirection := "S", MoveDuration := 750
        } else {
            MoveEnabled := false, MoveDirection := "W", MoveDuration := 750
        }
    }

    Commander := false

    StrategyWidth  := Integer(IniRead(file, "DO NOT EDIT", "width",  "1920"))
    StrategyHeight := Integer(IniRead(file, "DO NOT EDIT", "height", "1090"))

    inSteps := false
    Loop Read, file {
        line := Trim(A_LoopReadLine)
        if (line ~= "i)^\[Settings\]") { 
            inSteps := false
        }
        if (line ~= "i)^\[Steps\]")    { 
            inSteps := true
        }
        if (inSteps && line != "") {
            RecordedSteps.Push(line)
        }
    }

    
    for i, step in RecordedSteps {
        if RegExMatch(step, "i)SpawnTower\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(.*?)\s*\)", &m) {
            towerID := Trim(m[1])
            Towers[towerID] := {x: 0, y: 0, slot: 0, level: 0, path: 0, pathLevel: 0}
        }
        if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(?:false|true)\s*)?(?:,\s*\d+\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
            tid := Trim(m[1])
            if (Towers.Has(tid) && m[2] != "") {
                Towers[tid].path := m[2]
                Towers[tid].pathLevel := (m[3] != "") ? m[3] : 4
            }
        }
    }
}

RunStrategy(stratFile := "", skipRestart := false) {
    global RunningStrategy, difficulty, MoveEnabled, MoveDirection, MoveDuration
    global unfocusX, unfocusY, UseTimeScale, TimeScaleMultiplier, TimeScaleMode
    global SettingsFile, requiredTowers, modifiers, LastOpenedTowerID
    global LastSkipCheck, SKIP_CHECK_INTERVAL, AutorunStartTime, StateFile
    global WebhookEnabled, CurrentStratStartTime, CurrentRunCount, gamemap, AutoEquip

    if (RunningStrategy != true)
        return

    If (!skiprestart)
    	isDisconnected()

    switched := false
    if (RotateStrategies) {
        SwapAmount := Integer(IniRead(SettingsFile, "Options", "SwapAmount", 4))
        SwapUnit := IniRead(SettingsFile, "Options", "SwapUnit", "Runs")
        
        timeToSwitch := false
        if (SwapUnit = "Minutes") {
            if (A_TickCount - CurrentStratStartTime > SwapAmount * 60000)
                timeToSwitch := true
        } else {
            if (CurrentRunCount >= SwapAmount)
                timeToSwitch := true
        }
        
        if (timeToSwitch) {
            SwitchToNextStrategy(&stratName)
            switched := true

            Sleep(100)
        }
    }

    CurrentRunCount++
    IniWrite(CurrentRunCount, StateFile, "State", "CurrentRunCount")

    KillSubmacros()
    startWatchdog()

    LastOpenedTowerID := ""

    LogToConsole("Starting strategy... Press F2 to STOP!!!")
    LogToConsole("Map = " gamemap)
    LogToConsole("Mode = " difficulty)
    LogToConsole("Timescale = " TimeScaleMode)
    LogToConsole("Required Towers: " requiredTowers)
    if (modifiers != "")
        LogToConsole("Modifiers: " modifiers)

    if (switched) {
        time := FormatTime(, "HH:mm:ss")
        SplitPath(stratName, &fileName)
        startInfo := "[" time "] Switched strategy to: " fileName "`n"
        startInfo .= "Map = " gamemap "`nMode = " difficulty "`nTimescale = " TimeScaleMode "`nRequired Towers: " requiredTowers
        if (modifiers != "")
            startInfo .= "`nModifiers: " modifiers
        SendToWebhookInstant(startInfo,, flush := false)
    }

    checkStart := IniRead(StateFile, "State", "StartTime", 0)
    if (checkStart = 0) {
        IniWrite(A_TickCount, StateFile, "State", "StartTime")
        AutorunStartTime := A_TickCount
    } else {
        AutorunStartTime := checkStart
    }

    if (!switched) {
        if (!skipRestart) {
            CheckRestart()
        } else {
            getRobloxPos(,,&w,&h)
            closeRoblox_ := true
            if (GetRobloxHWND()){
                ActivateRoblox()
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

            if (AutoEquip) {
                EquipTowers(RequiredTowers)
            }
            JoinGame()
        }
    } else {

        closeRoblox_ := true
        if (GetRobloxHWND()){
            ActivateRoblox()
            Loop 2 {
                getRobloxPos(,,&w,&h)
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

        EquipTowers(RequiredTowers)

        JoinGame()
    }

    if (readyX = 0 && readyY = 0) {
        waitReady()
    }

    if (!IsRestarting) {
        CheckTheMapF()
        if (!InArray(SpecialMaps, gamemap)) {
            AlignCamera()
        }
    }

    activateTimescale()

    ClickReady()

    PlayStrategy()
}

PlayStrategy() {
    global canUseAbility, MultiplayerEnabled, StateFile, IsRestarting

    IniWrite(A_TickCount, StateFile, "State", "TimeWhenStartedPlaying")
    SetTimer(UseAbilities, 750)
    if (MultiplayerEnabled) {
        SetTimer(checkCondition, 15000)
    }

    i := 1
    while (i <= RecordedSteps.Length) {
        step := RecordedSteps[i]
        isMacroStep := RegExMatch(step, "i)^(Click|Send|Sleep)\s*\(")

        if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(false|true)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
            currentID    := Trim(m[1])
            countUpgrades := (m[3] != "") ? Integer(m[3]) : 1
            currentPath   := (m[4] != "") ? Integer(m[4]) : 0
            currentpathLevel := (m[5] != "") ? Integer(m[5]) : 4

            lookAhead := i + 1
            while (lookAhead <= RecordedSteps.Length) {
                nextStep := RecordedSteps[lookAhead]
                if RegExMatch(nextStep, "i)UpgradeTower\s*\(\s*" currentID "\s*(?:,\s*(?:false|true)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &mN) {
                    countUpgrades += (mN[1] != "") ? Integer(mN[1]) : 1
                    lookAhead++
                } else {
                    break
                }
            }

            success := UpgradeTower(currentID, false, countUpgrades, currentPath, currentpathLevel)
            i := success ? lookAhead : i + 1
        } else if RegExMatch(step, "i)SetDJTrack\s*\(\s*([^\s,)]+)\s*\)", &t) {
            SetDJTrack(t[1])
            i++
        } else if RegExMatch(step, "i)SpawnTower\s*\(.*\)") {
            ExecuteStep(step)
            i++
        } else {
            try {
                ExecuteStep(step)
            } catch Error as e { 
                LogToConsole("ERROR executing step " . i . ": " . step . " '" . e.Message . "' ")
            }
            i++
        }
    }

    Click(ScaleX(unfocusX), ScaleY(unfocusY))
    LogToConsole("All strategy steps completed...")
    Loop {
        canUseAbility := true
        LastOpenedTowerID := ""
        Sleep 3000
    }
    ;If the macro doesn't replaying again after win/loss it's a watchdog.ahk issue. Please report it if this happened to you. 
    ;Do not add anything here.
}

ExecuteStep(step) {
    global Commander, unfocusX, unfocusY
    step := RegExReplace(step, "\s*;.*$", "")
    step := Trim(step)
    if (step = "")
        return
    if RegExMatch(step, "i)SpawnTower\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d)\s*,\s*(.*?)\s*\)", &m) {
        SpawnTower(m[1], m[2], m[3], Trim(m[4]))
        return
    }
    if RegExMatch(step, "i)UpgradeTower\s*\(\s*([^,]+?)\s*(?:,\s*(false|true)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?(?:,\s*(\d+)\s*)?\s*\)", &m) {
        UpgradeTower(Trim(m[1]), (m[2]="true"), (m[3]!="") ? Integer(m[3]) : 1, (m[4]!="") ? Integer(m[4]) : 0, (m[5]!="") ? Integer(m[5]) : 4)
        return
    }
    
    if RegExMatch(step, "i)CloneTower\s*\(\s*([^,]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", &m) {
        CloneTower(Trim(m[1]), Integer(m[2]), Integer(m[3]), Integer(m[4]))
        return
    }

    if RegExMatch(step, "i)^ToggleAutoskip\s*\(\s*\)$", &m) {
        ToggleAutoskip()
        return
    }
    if RegExMatch(step, "i)ChangeTargets\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)", &m) {
        ChangeTargets(Trim(m[1]), Trim(m[2]))
        return
    }


    if RegExMatch(step, "i)CloneTower\s*\(\s*([^,]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", &m) {
        CloneTower(Trim(m[1]), Integer(m[2]), Integer(m[3]), 0)
        return
    }
    if RegExMatch(step, "i)ActivateRaiseTheDead\s*\(\s*(\d+)\s*\)", &m) {
        ActivateRaiseTheDead(Integer(m[1]))
        return
    }
    if RegExMatch(step, "i)ActivateRaiseTheDead\s*\(\s*\)", &m) {
        ActivateRaiseTheDead(0)
        return
    }

    if RegExMatch(step, "i)BrawlerReposition\s*\(\s*([^,]+?)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", &m) {
        BrawlerReposition(Trim(m[1]), Integer(m[2]), Integer(m[3]))
        return
    }

    if RegExMatch(step, "i)SetDJTrack\s*\(\s*(.+?)\s*\)", &m) {
        track := Trim(m[1], ' "')
        if (track != "")
            SetDJTrack(track)
        return
    }
    if RegExMatch(step, "i)^Click\s*\(\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(.+?))?\s*\)$", &m) {
        button := InStr(m[3], "Right") ? "Right" : "Left"
        Click(ScaleX(m[1]) " " ScaleY(m[2]) " " button)
        return
    }
    if RegExMatch(step, 'i)^Send\s*\(\s*"([^"]+)"\s*,\s*hold:=(\d+)\s*\)$', &m) {
        SendEvent("{" m[1] " down}")
        HyperSleep(Integer(m[2]))
        SendEvent("{" m[1] " up}")
        return
    }
    if RegExMatch(step, "i)^Sleep\s*\(\s*(\d+)\s*\)$", &m) {
        Sleep(Integer(m[1]))
        return
    }
    if RegExMatch(step, "i)Commander\s*:=\s*true") {
        Commander := true
        return
    }
    if RegExMatch(step, "i)SellTower\s*\(\s*([^)]+?)\s*\)", &m) {
        SellTower(Trim(m[1]))
        return
    }
}

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

; EquipTowers(towers) { this is faster , but ill keep the previous one cuz i think it is more stable than this
;     getRobloxPos(,,&rw,&rh)

;     LogToConsole("Equipping towers: " towers)

;     savedCloseX := 0
;     savedCloseY := 0

;     closeChat()
;     Sleep(600)

;     maxAttempts := 3
;     openedMenu := false

;     Loop maxAttempts {
;         itemsClicked := false
;         StartTime := A_TickCount
;         W := Round(rw * 0.3)
;         H := rh - 0

;         Loop {
;             resItems := AdvancedImageSearch("Resources\items.png", 0, 0, W, H)
;             if (resItems.status == "success" && resItems.score > 0.56) {
;                 fx := resItems.x
;                 fy := resItems.y
;                 MouseMove(fx, fy + ScaleY(7), A_DefaultMouseSpeed + 1)
;                 Sleep(100)
;                 MouseClick()
;                 itemsClicked := true
;                 break
;             } 
;             if (A_TickCount - StartTime > 5000) {
;                 break
;             }
;             Sleep(500)
;         }

;         if (!itemsClicked) {
;             continue
;         }

;         StartTime := A_TickCount
;         X1 := Round(rw * 0.2)
;         Y1 := 0
;         W_close := Round(rw * 1) - X1
;         H_close := Round(rh * 0.4) - Y1

;         Loop {
;             resclose := AdvancedImageSearch("Resources\close_items.png", X1, Y1, W_close, H_close)

;             if (resclose.status == "success" && resclose.score >= 0.85) {
;                 openedMenu := true
;                 savedCloseX := resclose.x
;                 savedCloseY := resclose.y
;                 break
;             } 
;             if (A_TickCount - StartTime > 4000) {
;                 break
;             }
;             Sleep(500)
;         }

;         if (openedMenu) {
;             break
;         }
;     }

;     if (!openedMenu) {
;         LogToConsole("Failed to equip towers! The macro can't see the towers menu! Reloading...", true, false)
;         Sleep(400)
;         SafeReload()
;         return
;     }

;     srchX := ScaleX(484)
;     srchY := ScaleY(229)

;     StartTime := A_TickCount
;     Loop {
;         resBar := AdvancedImageSearch("Resources\searchbar_items.png", 0,0,Round(rh*0.5),Round(rh*0.5))
;         if (resBar.status == "success" && resBar.score > 0.67) {
;             srchX := resBar.x+30
;             srchY := resBar.y
;             break
;         }
;         if (A_TickCount - StartTime > 4000)
;             break
;         Sleep(200)
;     }

;     Click(srchX, srchY)
;     Sleep(100)
;     if (A_KeyDelay < 5) {
;     SendInput("Sniper")
;     } else {
;         SendText("Sniper")
;     }
;     Sleep(200)
;     Click(srchX+10, ScaleY(409))
;     Sleep(100)

;     X := Round(rw * 0.61)
;     Y := ScaleY(830)
;     X1 := Round(rw * 0.4)
;     Y1 := Round(rh * 0.4)
;     W := Round(rw * 0.9) - X1
;     H := rh - Y1

;     StartTime := A_TickCount
;     getRobloxPos(,,&w,&h)
;     baseScale := h / 1009
;     Loop {
;         resAlign := AdvancedImageSearch("Resources\equip.png", X1, Y1, W, H, 0.5 * baseScale, 1.4 * baseScale, 0.025)

;         if (resAlign.status == "success" && resAlign.score > 0.4) {
;             Y := resAlign.y+ScaleY(110)
;         }

;         offset := -30
;         baseY := Y
        
;         MouseMove(X, Y+ScaleY(offset))

;         oldMode := A_SendMode
;         oldDelay := A_MouseDelay
;         SendMode("Input")
;         SetKeyDelay(5)

;         MouseMove(X, Y+ScaleY(offset))

;         while (offset <= 30) {
;             cY := baseY + ScaleY(offset)

;             MouseMove(X, cY)
;             MouseClick("Left", X, cY,3)

;             offset += 5
;         }
;         SendMode(oldMode)
;         SetKeyDelay(oldDelay)

;         failCount := 0
        
;         InnerStart := A_TickCount
;         Loop {
;             X1 := Round(rw * 0.4)
;             Y1 := Round(rh * 0.5)
;             W := Round(rw * 0.9) - X1
;             H := rh - Y1

;             getRobloxPos(,,&w,&h)
;             baseScale := Round(h / 1009)

;             resUnequip := AdvancedImageSearch("Resources\unequip.png", X1, Y1, W, H, 0.8 * baseScale, 1.4 * baseScale, 0.025)
;             if (resUnequip.status == "success" && resUnequip.score > 0.63) {
;                 if (PixelSearch(&uX, &uY, resUnequip.x-ScaleX(40), resUnequip.y-ScaleY(25), resUnequip.x+ScaleX(40), resUnequip.y+ScaleY(25), 0x7A797A, 5)) {
;                     Click(resUnequip.x, resUnequip.y)
;                     Sleep 20
;                     MouseMove(resUnequip.x, resUnequip.y-ScaleY(80))
;                     failCount := 0
;                     break
;                 } else {
;                     failCount++
;                     if (failCount >= 2) {
;                         break 2
;                     }
;                     Sleep(200)
;                     continue
;                 }
;             } else {
;                 failCount++
;                 if (failCount >= 2) {
;                     break 2
;                 }
;             }
;             if (A_TickCount - InnerStart > 3000)
;                 break
;             Sleep(200)
;         }
;     }
    
;     totalTowers := StrSplit(towers, ",").Length
;     Loop Parse, towers, ","
;     {
;         i := A_Index 
;         ActivateRoblox()
;         tower := Trim(A_LoopField)

;         goldtower := RegExMatch(tower, "i)\b(Golden|G\.|G)\b") ? true : false
;         regulartower := RegExMatch(tower, "i)\b(Regular|R\.|R)\b") ? true : false

;         towerToEnter := RegExReplace(tower, "i)\b(Golden|G\.|G|Regular|R\.|R)\b\s*|\.")
;         towerToEnter := Trim(towerToEnter) 

;         Researched := false

;         Click(srchX, srchY)
;         Sleep(100)
;         if (A_KeyDelay < 5) {
;         SendInput(towerToEnter)
;         } else {
;             SendText(towerToEnter)
;         }
;         Sleep(300)
;         Click(srchX+10, ScaleY(409))
;         Sleep(100)

;         X1 := Round(rw * 0.4)
;         Y1 := Round(rh * 0.5)
;         W := Round(rw * 0.9) - X1
;         H := rh - Y1

;         TowerStart := A_TickCount
;         Loop {
;             getRobloxPos(,,&w,&h)
;             baseScale := h / 1009

;             resEquip := AdvancedImageSearch("Resources\equip.png", X1, Y1, W, H, 0.5 * baseScale, 1.4, 0.025)

;             if (resEquip.status == "success" && resEquip.score > 0.4) {
;                 If (PixelSearch(&eX, &eY, resEquip.x-40, resEquip.y-25, resEquip.x+40, resEquip.y+25, 0x45DC4A, 7)) {
;                     Click(resEquip.x, resEquip.y)
;                     if (i != totalTowers) {
;                         Sleep 20
;                         MouseMove(resEquip.x, resEquip.y-ScaleY(80))
;                     }
                    
;                     if (goldtower) {
;                         GoldStart := A_TickCount
;                         Loop {
;                             resGolden := AdvancedImageSearch("Resources\notgolden.png", X1, Y1, W, H) 
;                             if (resGolden.status == "success" && resGolden.score > 0.55) {
;                                 If (PixelSearch(&eX, &eY, resGolden.x-40, resGolden.y-25, resGolden.x+40, resGolden.y+25, 0x1E1E1E, 4)) {
;                                     Click(resGolden.x, resGolden.y)
;                                     Sleep(200)
;                                     break
;                                 }
;                             }
;                             if (A_TickCount - GoldStart > 1000)
;                                 break
;                             Sleep(400)
;                         }
;                     }
                    
;                     if (regulartower) {
;                         RegStart := A_TickCount
;                         Loop {
;                             resGolden := AdvancedImageSearch("Resources\golden.png", X1, Y1, W, H, 0.4, 2) 
;                             if (resGolden.status == "success" && resGolden.score > 0.55) {
;                                 If (PixelSearch(&eX, &eY, resGolden.x-40, resGolden.y-25, resGolden.x+40, resGolden.y+25, 0xFFC11F, 8)) {
;                                     Click(resGolden.x, resGolden.y)
;                                     Sleep(200)
;                                     break
;                                 }
;                             }
;                             if (A_TickCount - RegStart > 1000)
;                                 break
;                             Sleep(400)
;                         }
;                     }
;                     break
;                 }
;                 Sleep(100)
;             }
;             if (A_TickCount - TowerStart > 5000)
;                 break
;             if (A_TickCount - TowerStart > 2000 && !Researched) {
;                 Researched := true
;                 Click(srchX, srchY)
;                 Sleep(100)
;                 oldDelay := A_KeyDelay
;                 SetKeyDelay(Round(A_KeyDelay*1.6))
;                 if (A_KeyDelay < 5) {
;                 SendInput(towerToEnter)
;                 } else {
;                     SendText(towerToEnter)
;                 }
;                 SetKeyDelay(oldDelay)
;                 Sleep(300)
;                 Click(srchX+10, ScaleY(409))
;                 Sleep(100)
                
;             }
;             Sleep(150)
;         }
;         Sleep(50)
;     }
;     X1 := Round(rw * 0.2)
;     Y1 := 0
;     W := Round(rw * 1) - X1
;     H := Round(rh * 0.4) - Y1
;     resclose := AdvancedImageSearch("Resources\close_items.png", X1, Y1, W, H)

;     If (resclose.status = "success" && resclose.score >= 0.85) {
;         Click(resclose.x, resclose.y)
;     } else if (savedCloseX != 0 && savedCloseY != 0) {
;         Click(savedCloseX, savedCloseY)
;     }
    
;     LogToConsole("Successfully equipped towers: " towers, true, false)
;     IniWrite(1, StateFile, "State", "Equipped")
; }

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
		try WinClose "Roblox"
		Sleep 500
		try WinClose "Roblox"
		Sleep 4500 
	}
	
	for p in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name LIKE '%Roblox%' OR CommandLine LIKE '%ROBLOXCORPORATION%'")
		ProcessClose p.ProcessID
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

SwitchToNextStrategy(&stratName) {
    global CurrentRotationIndex, Strategy1Path, Strategy2Path, requiredTowers
    global CurrentStratStartTime, CurrentRunCount, StateFile, RunningStrategy, difficulty

    if (CurrentRotationIndex = 1) {
        LoadStrategyFile(Strategy2Path)
        CurrentRotationIndex := 2
        IniWrite(2, StateFile, "State", "CurrentRotationIndex")
        stratName := Strategy2Path 
    } else {
        LoadStrategyFile(Strategy1Path)
        CurrentRotationIndex := 1
        IniWrite(1, StateFile, "State", "CurrentRotationIndex")
        stratName := Strategy1Path
    }

    CurrentStratStartTime := A_TickCount
    CurrentRunCount := 0
    IniWrite(A_TickCount, StateFile, "State", "CurrentStratStartTime")
    IniWrite(0, StateFile, "State", "CurrentRunCount")

    IniWrite(1, StateFile, "State", "Running")
    IniWrite(stratName, StateFile, "State", "Strategy")

    return true
}

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

SelectMap(readyX := ScaleX(963), readyY := ScaleY(838)) {
    global gamemap, difficulty, modifiers, CheckTheMap, LegacyMode

    getRobloxPos(,,&w,&h)
    readyX := Round(w*0.5)

    LogToConsole("Selecting map: " gamemap, true, false)
    Sleep(100)
    closeChat()

    if (difficulty = "Hardcore" || difficulty = "Voidcore") {
        If (!LegacyMode) {
            image := A_WorkingDir "/Resources/map_selection.png"

            foundObject := false

            Loop 3 {
                getRobloxPos(&x, &y, &w, &h)
                res := AdvancedImageSearch(image, 0,0,Round(w/2),h)
                if (res.status == "success" && res.score >= 0.51) { 
                    foundObject := true
                    break 
                }
                Sleep(500)
            }

            if (!foundObject) {
                LogToConsole("Wrong camera position!")
                SendEvent("{Left down}")
                Sleep(1500) 
                SendEvent("{Left up}")
                Sleep(50)
            }
        }
    } else {
        ActivateRoblox()
        resetCharacter()
        Sleep(7500)
        AlignCamera(false, false)
    }
    
    if (difficulty = "Hardcore" || difficulty = "Voidcore") {
        attempts := 0

        Sleep(300)
        Send("{WheelDown}")

        Loop {
            Sleep(200)
            ActivateRoblox()
            Sleep(600)
            SendEvent("{sc011 down}")  
            Sleep(3550)
            SendEvent("{sc011 up}")
            Sleep(300)

            LogToConsole("Trying to find: " gamemap ". Please wait..")

            getRobloxPos(,,&w,&h)
            FoundSlot := 0
            regions := [[0, 0, Floor(w * 0.3307), Floor(h * 0.6)],
            [Floor(w * 0.3307), 0, Floor(w * 0.1729), Floor(h * 0.6)],
            [Floor(w * 0.5036), 0, Floor(w * 0.1729), Floor(h * 0.6)],
            [Floor(w * 0.6765), 0, w - Floor(w * 0.6765), Floor(h * 0.6)]]

            langCode := "en-US"
            for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
                if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
                    langCode := availableLang
                    break
                }
            }

            Loop 4 {
                r := regions[A_Index]
                pBmp := Gdip_BitmapFromScreen(r[1] "|" r[2] "|" r[3] "|" r[4])
                result := OCR.FromBitmap(pBmp, {lang:langCode, scale:1.5, grayscale: 1}).Text
                Gdip_DisposeImage(pBmp)
                if RegExMatch(result, "i)\b" . gamemap . "\b") {
                    FoundSlot := A_Index
                    break
                }
            }
            
            if (attempts >= 5) {
                LogToConsole("Map is not found after 5 attempts! Reloading...", true)
                SafeReload()
            }

            if (FoundSlot = 0) {
                LogToConsole("Map is not found! Resetting...", true, false)
                resetCharacter()
                Sleep(8000)
                attempts++
                SendEvent("{Left down}")
                Sleep(1500) 
                SendEvent("{Left up}")
                Sleep(50)
                continue
            } else {
                LogToConsole(gamemap " found in slot " FoundSlot,true,false)
                break
            }
        }

        Sleep(300)
        ActivateRoblox()
        Sleep(100)

        SendEvent("{sc011 down}")  
        HyperSleep(400)
        SendEvent("{sc011 up}")
        Sleep(200)

        if (FoundSlot = 1) { 
            SendEvent("{sc01e down}")
            Sleep(1400)
            SendEvent("{sc01e up}")
            Sleep(600) 
        } else if (FoundSlot = 2) { 
            SendEvent("{sc01e down}")
            Sleep(500)
            SendEvent("{sc01e up}")
            Sleep(600) 
        } else if (FoundSlot = 3) { 
            SendEvent("{sc020 down}")
            Sleep(500)
            SendEvent("{sc020 up}")
            Sleep(600) 
        } else if (FoundSlot = 4) { 
            SendEvent("{sc020 down}")
            Sleep(1400)
            SendEvent("{sc020 up}")
            Sleep(600) 
        }

        if (modifiers != "")
            ApplyModifiers()

        SendEvent("{sc012 down}")  
        Sleep(1000)
        SendEvent("{sc012 up}")
        Sleep(100)
    } else {
        ActivateRoblox()
        Sleep(150)
        SendEvent("{sc01f down}") 
        Sleep(1900)
        SendEvent("{sc01f up}")
        Sleep(700)
        SendEvent("{sc01e down}") 
        Sleep(1800)
        SendEvent("{sc01e up}")
        Sleep(700)

        Loop 3 {
            e_pr := AdvancedImageSearch("Resources\e_prompt.png", 0, 0, w, h,1,1)

            if (e_pr.score >= 0.75) {
                break
            } else {
                Sleep(150)
            }
        }

        if !(e_pr.score >= 0.75) {
            LogToConsole("The macro can't see the E prompt (" e_pr.score "), retrying again... ", true) 
            SelectMap(readyX, readyY)
            return
        }

        SendEvent("{sc012 down}") 
        Sleep(1000)
        SendEvent("{sc012 up}")
        Sleep(500)

        foundsearchbar := false
        getRobloxPos(&x, &y, &w, &h)
        Loop 2 {
            if (!LegacyMode) {
                res := AdvancedImageSearch("Resources/searchbar.png", Round(w*0.1),0,Round(w*0.6),h,0.5,1.5)

                if (res.status = "success" && res.score >= 0.6)  { 
                    Click(res.x, res.y)
                    foundsearchbar := true 
                    break
                } 
            } else {
                res := {x: ScaleX(810), y: ScaleY(218)}
                click(Res.x, res.y)
                foundsearchbar := true 
                break
            }

            Sleep(500)
        }

        if (!foundsearchbar) {
            LogToConsole("Can not found the search bar in the override map menu! Reloading..", true)
            SafeReload()
            return 
        }        

        Sleep(100)
        if (A_KeyDelay < 5) {
        SendInput(gamemap)
        } else {
            SendText(gamemap)
        }
        Loop {
            Sleep(300)
            if (InArray(SpecialMaps, gamemap)) {
                SelectionICON := AdvancedImageSearch("Resources/Maps/" gamemap "_Selection.png", Round(w*0.1),0,Round(w*0.7),h,0.5,1.5)
            
                if (SelectionICON.score >= 0.65)  { 
                    Click(SelectionICON.x, SelectionICON.y)
                } else {
                    Click(res.x - ScaleX(90), res.y + 80)
                }
            } else {
                Click(res.x - ScaleX(90), res.y + 80)
            }
            Sleep(400)

            changedMap := false
            alrinRotation := false
            Loop 2 {
                if PixelSearch(&gx, &gy, Round(w*0.2), Round(h*0.24), Round(w*0.7), Round(h*0.3), 0x00EC00, 3) {
                    LogToConsole("Successfully changed the map to " gamemap,true,false)
                    changedMap := true
                    break
                }

                Sleep(200)
            }

            if (changedMap) {
                break
            }

            if (ReadMessage(["already", "current", "rotation"])) {
                LogToConsole(gamemap " is already in the current rotation. Clicking veto..", true)
                resVeto := AdvancedImageSearch("Resources\Veto.png", 0, 0, w, h,0.5,1.5)
                if (resVeto.status == "success" && resVeto.score > 0.65) {
                    MouseMove(resVeto.x, resVeto.y)
                    Sleep(30)
                    MouseClick
                } else {
                    MouseMove(ScaleX(1152), ScaleY(834))
                    Sleep(30)
                    MouseClick
                }
                Sleep(300)
                Send("{" SC_E " down}")
                Sleep(760)
                Send("{" SC_E " up}")

                alrinRotation := false
                Sleep(400)
                continue
            }

            if (!changedMap) {
                LogToConsole("Failed to change the map to " gamemap, true)
                SafeReload()
            } else {
                break
            }
        }

        if (modifiers != "")
            ApplyModifiers()

        Sleep(200)
        ActivateRoblox()
        Sleep(100)
        SendEvent("{sc020 down}") 
        Sleep(1800)
        SendEvent("{sc020 up}")
        Sleep(200)
        SendEvent("{sc01f down}") 
        Sleep(1680)
        SendEvent("{sc01f up}")
        Sleep(300)
        SendEvent("{sc020 down}") 
        Sleep(1500)
        SendEvent("{sc020 up}")
        Sleep(600)
        Loop 3 {
            e_pr := AdvancedImageSearch("Resources\e_prompt.png", 0, 0, w, h,0.6,1.5)

            if (e_pr.score >= 0.65) {
                break
            } else {
                Sleep(150)
            }
        }

        if !(e_pr.score >= 0.7) {
            LogToConsole("The macro can't see the E prompt (" e_pr.score "), moving slightly to the left... ", true) 
            SendEvent("{sc01e down}") 
            Sleep 300
            SendEvent("{sc01e up}") 
            Loop 3 {
                e_pr := AdvancedImageSearch("Resources\e_prompt.png", 0, 0, w, h,0.6,1.5)

                if (e_pr.score >= 0.65) {
                    break
                } else {
                    Sleep(150)
                }
            }
            if !(e_pr.score >= 0.7) {
                LogToConsole("The macro can't see the E prompt (" e_pr.score "), reloading... ", true) 
                SafeReload()
            }
        }

        SendEvent("{sc012 down}") 
        Sleep(800)
        SendEvent("{sc012 up}")
    }
    Sleep(100)

    Click(readyX, readyY)
    waitReady()
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

getSlots() {
    static cachedSlotsState := ""
    
    if (cachedSlotsState != "") {
        return cachedSlotsState
    }
    
    numbers := Map(
        1, A_WorkingDir "\Resources\1.png",
        2, A_WorkingDir "\Resources\2.png",
        3, A_WorkingDir "\Resources\3.png",
        4, A_WorkingDir "\Resources\4.png",
        5, A_WorkingDir "\Resources\5.png"
    )
    
    Ys := ScaleY(960)
    x1 := ScaleX(800)
    x2 := ScaleX(880)
    x3 := ScaleX(960)
    x4 := ScaleX(1040)
    x5 := ScaleX(1120)

    currentSlotsState := Map(
        1, [x1, Ys], 
        2, [x2, Ys], 
        3, [x3, Ys], 
        4, [x4, Ys], 
        5, [x5, Ys]
    )

    getRobloxPos(&x, &y, &w, &h)
    offsetY := Integer(h * 0.8)
    endY := Integer(h * 0.17)
    endX := Integer(w* 0.75)

    startX := Integer(w*0.15)
    
    for digit, Image in numbers {
        if (!Image)
            continue
            
        Variation := 10 

        Result := AdvancedImageSearch(Image, startX, offsetY, endX, endY, 0.75, 2)
        
        if (Result.status == "success" && Result.score >= 0.84) {
            startX := Result.x+ScaleX(70)
            endY := Result.y+ScaleY(40)-offsetY
            endX := Integer(w* 0.1)

            currentSlotsState[digit] := [Result.x+ScaleX(15), Result.y+ScaleY(20)]
        }
    }

    cachedSlotsState := currentSlotsState
    return cachedSlotsState
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

FindClosestTower(mx, my) {
    global Towers
    closestID := "", minDist := 20
    for id, t in Towers {
        dist := Sqrt((t.x - mx)**2 + (t.y - my)**2)
        if (dist < minDist) {
            minDist := dist
            closestID := id
        }
    }
    return closestID
}

HasStep(searchStep) {
    global RecordedSteps
    for i, s in RecordedSteps {
        if (s = searchStep) {
            return true
        }
    }
    return false
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

ModernMsgBox(Title, Text, Buttons := "OK", type := "") {
    boxType := (Buttons = "OK") ? 0 : 4
    If (type = "WARNING") {
        boxType += 48
    } Else {
        boxType += 64
    }
    if (AlwaysOnTop = 1) {
        boxType += 4096
    }
    result := MsgBox(Text, Title, boxType)
    return (result = "OK" || result = "Yes") ? "YES" : "NO"
}

MapToString(inputMap) {
    result := ""
    for k, v in inputMap
        result .= k " => " v "`n"
    return RTrim(result, "`n")
}


ShowDebugConsole() {
    global DebugConsole, OverlayHWND, OverlayBitmap, OverlayGraphics, OverlayPicHWND
    global OverlayX, OverlayY, OverlayWidth, OverlayHeight
    
    if (DebugConsole != "1" && DebugConsole != 1) {
        return
    }
    if (OverlayHWND && WinExist("ahk_id " OverlayHWND)) {
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
    
}

HideDebugConsole() {
    global OverlayHWND, OverlayBitmap, OverlayGraphics, OverlayPicHWND
    
    if (OverlayBitmap) { 
        Gdip_DisposeImage(OverlayBitmap)
        OverlayBitmap := 0 
    }
    if (OverlayGraphics) { 
        Gdip_DeleteGraphics(OverlayGraphics)
        OverlayGraphics := 0 
    }
    if (OverlayHWND) {
        WinClose("ahk_id " OverlayHWND)
    }
    OverlayHWND    := 0
    OverlayPicHWND := 0
}

UpdateOverlay() {
    global OverlayBitmap, OverlayGraphics, OverlayPicHWND, LogLines, OverlayWidth, OverlayHeight
    if (!OverlayGraphics) {
        return
    }

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
    pBrushBgOverlay  := Gdip_BrushCreateSolid(0xAA000000)

    if (!pBrushTextOverlay || !pBrushBgOverlay) {
        if (pBrushTextOverlay) => Gdip_DeleteBrush(pBrushTextOverlay)
        if (pBrushBgOverlay) => Gdip_DeleteBrush(pBrushBgOverlay)
        Gdip_DeleteStringFormat(hFormatOverlay)
        Gdip_DeleteFont(hFontOverlay)
        Gdip_DeleteFontFamily(hFamilyOverlay)
        return
    }

    maxLines   := Floor(OverlayHeight / (fontSize * 1.4))
    startIndex := Max(1, LogLines.Length - maxLines + 1)
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
            hBitmap := Gdip_CreateHBITMAPFromBitmap(OverlayBitmap)
            SetImage(OverlayPicHWND, hBitmap)
            DeleteObject(hBitmap)
        }
    }
}

LogToConsole(text, SendWebhookInstantly := false, flush := true) {
    global DebugConsole, LogLines, OverlayHWND, WebhookEnabled, WebhookLink, RunningStrategy, AutorunStartTime

    time := FormatTime(, "HH:mm:ss")
    AuditAuto(text)
    formattedText := "[" time "] " text
    LogLines.Push(formattedText)
    while (LogLines.Length > 500)
        LogLines.RemoveAt(1)

    if (OverlayHWND && WinExist("ahk_id " OverlayHWND))
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

FormatRuntime(StartTicks) {
    if (StartTicks = 0) {
        return "00:00"
    }
    elapsed := Floor((A_TickCount - StartTicks) / 1000)
    h := Floor(elapsed / 3600)
    m := Floor(Mod(elapsed, 3600) / 60)
    s := Mod(elapsed, 60)
    return (h > 0) ? Format("{:d}:{:02d}:{:02d}", h, m, s) : Format("{:d}:{:02d}", m, s)
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

HasGlobal(varName) {
    try {
        return %varName% !== ""
    } catch {
        return false
    }
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


SendToWebhook(message) {
    global WebhookQueue, WebhookTimerActive
    if (message = "" || Trim(message) = "") {
        return
    }
    WebhookQueue.Push(message)
    if (!WebhookTimerActive) {
        WebhookTimerActive := true
        SetTimer(ProcessWebhookQueue, -100)
    }
}

SendToWebhookInstant(message, embedColor := 3447003, flush := true, mention := "") {
    global WebhookInstantQueue, WebhookInstantTimerActive, WebhookEnabled
    if (!WebhookEnabled || message = "" || Trim(message) = "") { 
        return
    }
    if (flush) {
        FlushWebhookQueue()
    }

    WebhookInstantQueue.Push({msg: message, color: embedColor, mention: mention})
    
    if (!WebhookInstantTimerActive) {
        WebhookInstantTimerActive := true
        SetTimer(ProcessWebhookInstantQueue, -100)
    }
}

ProcessWebhookInstantQueue() { 
    global WebhookInstantQueue, WebhookInstantTimerActive, WebhookLink

    static whr := ComObject("WinHttp.WinHttpRequest.5.1")

    if (WebhookInstantQueue.Length = 0) { 
        WebhookInstantTimerActive := false 
        return 
    }
    
    allMessages := ""
    finalColor := 3447003
    hasCustomColor := false
    finalMention := ""
    
    while (WebhookInstantQueue.Length > 0) {
        item := WebhookInstantQueue.RemoveAt(1)
        if (Trim(item.msg) = "") 
            continue
            
        allMessages .= (allMessages != "") ? "`n" item.msg : item.msg
        if (item.HasProp("mention") && item.mention != "" && finalMention = "")
            finalMention := item.mention
        
        if (item.color != 3447003) {
            finalColor := item.color
            hasCustomColor := true
        }
    }
    
    WebhookInstantTimerActive := false
    if (allMessages = "") 
        return
        
    if (!hasCustomColor) {
        lower := Format("{:L}", allMessages)
        if (InStr(lower, "error") || InStr(lower, "failed") || InStr(lower, "reloading")) {
            finalColor := 15158332
        } else if (InStr(lower, "success") || InStr(lower, "completed")) {
            finalColor := 3066993
        } else if (InStr(lower, "warning")) {
            finalColor := 16776960
        }
    }
    
    escaped := StrReplace(StrReplace(StrReplace(allMessages, "\", "\\"), '"', '\"'), "`n", "\n")
    payload := '{"embeds":[{"description":"' escaped '","color":' finalColor '}]}'
    if (finalMention != "")
        payload := '{"content":"' finalMention '","embeds":[{"description":"' escaped '","color":' finalColor '}]}'
    
    try {
        whr.Open("POST", WebhookLink, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.SetTimeouts(5000, 5000, 8000, 8000)
        whr.Send(payload)
    } catch Error as err {
        LogToConsole("Webhook send failed: " err.Message)
    }
}


ProcessWebhookQueue() {
    global WebhookQueue, WebhookTimerActive, WebhookLink
    static whr := ComObject("WinHttp.WinHttpRequest.5.1")
    
    if (WebhookQueue.Length = 0) { 
        WebhookTimerActive := false 
        return 
    }
    if (WebhookQueue.Length < 20) { 
        SetTimer(ProcessWebhookQueue, -2000) 
        return 
    }
    
    allMessages := ""
    Loop 20 {
        if (WebhookQueue.Length = 0) 
            break
        
        msg := WebhookQueue.RemoveAt(1)
        if (Trim(msg) = "") 
            continue
            
        escaped := StrReplace(msg, "\", "\\")
        escaped := StrReplace(escaped, '"', '\"')
        escaped := StrReplace(escaped, "`n", "\n")
        escaped := StrReplace(escaped, "`r", "")
        
        if (Trim(escaped) = "") 
            continue
            
        allMessages .= escaped "\n"
    }
    
    if (allMessages = "") { 
        WebhookTimerActive := false 
        return 
    }
    
    allMessages := RTrim(allMessages, "\n")
    
    embedColor := 9868950
    payload := '{"embeds":[{"description":"``````\n' allMessages '\n``````","color":' embedColor '}]}'
    
    try {
        whr.Open("POST", WebhookLink, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(payload)
    } catch Error {
    }
    
    if (WebhookQueue.Length > 0)
        SetTimer(ProcessWebhookQueue, -1000)
    else
        WebhookTimerActive := false
}


FlushWebhookQueue() {
    global WebhookQueue, WebhookTimerActive, WebhookLink
    
    if (WebhookQueue.Length = 0) 
        return
        
    WebhookTimerActive := false
    SetTimer(ProcessWebhookQueue, 0)
    
    allMessages := ""
    while (WebhookQueue.Length > 0) {
        msg := WebhookQueue.RemoveAt(1)
        if (Trim(msg) = "") 
            continue

        escaped := StrReplace(msg, "\", "\\")
        escaped := StrReplace(escaped, '"', '\"')
        escaped := StrReplace(escaped, "`n", "\n")
        escaped := StrReplace(escaped, "`r", "")
        
        if (Trim(escaped) = "") 
            continue
            
        allMessages .= escaped "\n"
    }
    
    if (allMessages = "") 
        return
        
    allMessages := RTrim(allMessages, "\n")
    
    embedColor := 9868950
    payload := '{"embeds":[{"description":"``````\n' allMessages '\n``````","color":' embedColor '}]}'
    
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", WebhookLink, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.SetTimeouts(5000, 5000, 8000, 8000)
        whr.Send(payload)
    } catch Error as err {
        LogToConsole("Webhook send failed: " err.Message)
    }
}

SafeReload() {
    global RestartLock, StateFile, RunningStrategy, OverlayHWND, MainGui
    if (RestartLock) {
        return
    }
    RestartLock := true
    AuditLog("INFO", "Reload", "Macro reloading (SafeReload)")
    KillSubmacros()
    if (OverlayHWND) {
        WinClose("ahk_id " OverlayHWND)
    }
    
    if (IsSet(MainGui) && MainGui) {
        MainGui.Destroy()
    }
    
    DeleteAllIndicators()
    if (RunningStrategy) {
        currentStrat := IniRead(StateFile, "State", "Strategy", "")
        if (currentStrat != "") {
            IniWrite(1, StateFile, "State", "Running")
        }
    } 

    FlushWebhookQueue()

    Reload()
}

startWatchdog() {
    KillSubmacros()

    currentPID := DllCall("GetCurrentProcessId")
    if (A_PtrSize == 4) {
    Run('"' A_ScriptDir '\submacros\AutoHotkey32.exe" "' A_ScriptDir '\submacros\watchdog.ahk" ' currentPID, , , &watchdogPID)
    } else {
    Run('"' A_ScriptDir '\submacros\AutoHotkey64.exe" "' A_ScriptDir '\submacros\watchdog.ahk" ' currentPID, , , &watchdogPID)
    }
}

KillSubmacros() {
    global watchdogPID
    
    if (watchdogPID != "") {
        try {
            RunWait(A_ComSpec " /c taskkill /PID " watchdogPID " /F /T", , "Hide")
        } catch Error {
        }
        watchdogPID := ""
    }
    
    try {
        for process in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey.exe' OR Name = 'AutoHotkey32.exe'") {
            try {
                cmd := process.CommandLine
                if (InStr(cmd, "watchdog.ahk")) {
                    try {
                        pID := process.ProcessId 
                        try {
                            ProcessClose(pID)
                        }

                        process.Terminate()
                    } catch Error {
                        continue
                    }
                }
            } catch Error {
                continue
            }
        }
    } catch Error {
        return
    }
}


HandleExit(ExitReason, ExitCode) {
    global StateFile, SettingsFile

    if (RunningStrategy) {
        KillSubmacros()
        if (ExitReason = "Close" || ExitReason = "Menu" || ExitReason = "Shutdown" || ExitReason = "Logoff") {
            IniWrite(0, StateFile, "State", "Running")
            IniDelete(StateFile, "State", "Strategy")
            IniDelete(StateFile, "State", "StartTime")
            IniDelete(StateFile, "State", "CurrentStratStartTime")
            IniDelete(StateFile, "State", "CurrentRotationIndex")
            IniDelete(StateFile, "State", "CurrentRunCount")
            IniDelete(StateFile, "State", "Coins")
            IniDelete(StateFile, "State", "Gems")
            IniDelete(StateFile, "State", "EXP")
            IniDelete(StateFile, "State", "TotalTriumphs")
            IniDelete(StateFile, "State", "TotalLosses")
            IniDelete(StateFile, "State", "TotalTimeSeconds")
            IniDelete(StateFile, "State", "Timescale")
            IniDelete(StateFile, "State", "TimeWhenStartedPlaying")
            IniDelete(StateFile, "State", "Equipped")
        }
    }
}

CleanupGdip(exitReason, exitCode) {
    global pToken
    Gdip_Shutdown(pToken)
}

MainGui.OnEvent("Close", (*) => ExitApp())

CheckOcrLanguage() {
    try {
        rawLangs := OCR.GetAvailableLanguages()
        hasEnglish := false
        
        availableLangs := StrSplit(rawLangs, ["`n", "`r", ",", " "])
        
        for lang in availableLangs {
            if (lang = "")
                continue
                
            if InStr(lang, "en") {
                hasEnglish := true
                break
            }
        }
        
        if (!hasEnglish) {
            msgText := "English language pack for OCR (text detection) is not installed on your system!`n`n"
                    . "Without it, the script cannot read text from the screen properly.`n`n"
                    . "Would you like to open Windows Settings to download the Language?"
            
            result := MsgBox(msgText, "Missing OCR Language", 48 + 4)
            
            if (result = "Yes") {
                Run("ms-settings:regionlanguage")
            }
            
            ExitApp()
        }
    }
}

SendScreenshot(pBitmap := PrimaryMonitorBitmap(), description := "", color := 12434877, screenshot := WebhookScreenshots) {
    global WebhookLink

    escapedDescription := StrReplace(description, "\", "\\")
    escapedDescription := StrReplace(escapedDescription, '"', '\"')
    escapedDescription := StrReplace(escapedDescription, "`n", "\n")

    fields := []

    if (screenshot == "0" || screenshot == 0) {
        payload_json := '{"embeds": [{"description": "' escapedDescription '", "color": ' color '}]}'
        fields.Push(Map("name", "payload_json", "content-type", "application/json", "content", payload_json))
    } 
    else {
        payload_json := '{"embeds": [{"description": "' escapedDescription '", "color": ' color ', "image": {"url": "attachment://screenshot.png"}}]}'
        fields.Push(Map("name", "payload_json", "content-type", "application/json", "content", payload_json))
        fields.Push(Map("name", "files[0]", "filename", "screenshot.png", "content-type", "image/png", "pBitmap", pBitmap))
    }
    
    CreateFormData(&postdata, &contentType, fields)

    if (screenshot != "0" && screenshot != 0) {
        try Gdip_DisposeImage(pBitmap)
    }

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", WebhookLink "?wait=true", false)
        whr.SetRequestHeader("Content-Type", contentType)
        whr.SetTimeouts(5000, 5000, 15000, 15000)
        whr.Send(postdata)
    } catch Error as err {
        LogToConsole("Screenshot webhook failed: " err.Message)
    }
}

CreateFormData(&retData, &contentType, fields) {
    chars := "0123456789abcdefghijklmnopqrstuvwxyz"
    boundary := ""
    Loop 12 {
        boundary .= SubStr(chars, Random(1, StrLen(chars)), 1)
    }

    hData := DllCall("GlobalAlloc", "UInt", 0x2, "UPtr", 0, "Ptr")
    DllCall("ole32\CreateStreamOnHGlobal", "Ptr", hData, "Int", 0, "PtrP", &pStream)

    for index, field in fields {
        str := "`r`n------------------------------" boundary "`r`n"
        str .= 'Content-Disposition: form-data; name="' field["name"] '"'
        if (field.Has("filename"))
            str .= '; filename="' field["filename"] '"'
        str .= "`r`nContent-Type: " field["content-type"] "`r`n`r`n"
        if (field.Has("content"))
            str .= field["content"] "`r`n"

        length := StrPut(str, "UTF-8") - 1
        utf8 := Buffer(length)
        StrPut(str, utf8, length, "UTF-8")
        DllCall("shlwapi\IStream_Write", "Ptr", pStream, "Ptr", utf8, "UInt", length, "UInt")

        if (field.Has("pBitmap")) {
            try {
                pFileStream := Gdip_SaveBitmapToStream(field["pBitmap"])
                DllCall("shlwapi\IStream_Size",  "Ptr", pFileStream, "UInt64*", &size := 0, "UInt")
                DllCall("shlwapi\IStream_Reset", "Ptr", pFileStream, "UInt")
                DllCall("shlwapi\IStream_Copy",  "Ptr", pFileStream, "Ptr", pStream, "UInt", size, "UInt")
                ObjRelease(pFileStream)
            } catch Error as err {
                LogToConsole("Failed to attach screenshot to webhook: " err.Message)
            }
        }
    }

    str := "`r`n------------------------------" boundary "--`r`n"
    length := StrPut(str, "UTF-8") - 1
    utf8 := Buffer(length)
    StrPut(str, utf8, length, "UTF-8")
    DllCall("shlwapi\IStream_Write", "Ptr", pStream, "Ptr", utf8, "UInt", length, "UInt")
    ObjRelease(pStream)

    pData := DllCall("GlobalLock", "Ptr", hData, "Ptr")
    size  := DllCall("GlobalSize", "Ptr", pData, "UPtr")
    retData := ComObjArray(0x11, size)
    pvData  := NumGet(ComObjValue(retData), 8 + A_PtrSize, "Ptr")
    DllCall("RtlMoveMemory", "Ptr", pvData, "Ptr", pData, "Ptr", size)
    DllCall("GlobalUnlock", "Ptr", hData)
    DllCall("GlobalFree",   "Ptr", hData, "Ptr")
    contentType := "multipart/form-data; boundary=----------------------------" boundary
}

InArray(arr, value) {
    for item in arr
        if (item = value)
            return true
    return false
}

CreateGradientButton(w, h, r, colorStart, colorEnd, shadowColor, strokeColor, btnText := "...", textFont := "Segoe UI", textSize := 12, gradientDirection := 0, textColor := "0xFFFFFFFF") {
    hdc := GetDC(0)
    hbm := CreateDIBSection(w, h)
    hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm)
    G := Gdip_GraphicsFromHDC(hdcMem)
    
    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", G, "int", 7)
    
    pad := 6
    bx := pad, by := pad, bw := w - (pad * 2), bh := h - (pad * 2)

    Gdip_SetSmoothingMode(G, 4)
    Gdip_SetTextRenderingHint(G, 4) 

    Loop 6 {
        alpha := Format("{:02X}", Integer(25 / A_Index))
        currentShadow := "0x" alpha SubStr(shadowColor, -6)
        pBrushShadow := Gdip_BrushCreateSolid(currentShadow)
        
        offset := A_Index * 0.7
        pPathShadow := Gdip_CreateRoundRectanglePath(bx - (offset*0.5), by + offset, bw + offset, bh, r)
        Gdip_FillPath(G, pBrushShadow, pPathShadow)
        Gdip_DeletePath(pPathShadow)
        Gdip_DeleteBrush(pBrushShadow)
    }

    pBrushGrad := Gdip_CreateLineBrushFromRect(bx, by, bw, bh, colorStart, colorEnd, gradientDirection, 1)
    pPathMain := Gdip_CreateRoundRectanglePath(bx, by, bw, bh, r)
    Gdip_FillPath(G, pBrushGrad, pPathMain)

    pPathStroke := Gdip_CreateRoundRectanglePath(bx + 0.5, by + 0.5, bw - 1, bh - 1, r)
    pPenStroke := Gdip_CreatePen(strokeColor, 1)
    Gdip_DrawPath(G, pPenStroke, pPathStroke)
    Gdip_DeletePath(pPathStroke)
    Gdip_DeletePen(pPenStroke)
    
    hFormat := Gdip_StringFormatCreate(0x4000) 
    Gdip_SetStringFormatAlign(hFormat, 1)     
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", hFormat, "int", 1) 
    
    Gdip_SetSmoothingMode(G, 0)
    Gdip_SetTextRenderingHint(G, 0) 

    hFontfamily := Gdip_FontFamilyCreate(textFont)
    hFont := Gdip_FontCreate(hFontfamily, textSize, 1) 
    RC := Buffer(16, 0)
    
    NumPut("float", bx, "float", by + 1, "float", bw, "float", bh, RC)
    pBrushTxtShadow := Gdip_BrushCreateSolid("0x99000000")
    
    Gdip_DrawString(G, btnText, hFont, hFormat, pBrushTxtShadow, &RC)
    Gdip_DeleteBrush(pBrushTxtShadow)
    
    NumPut("float", bx, "float", by, "float", bw, "float", bh, RC)
    pBrushTxtMain := Gdip_BrushCreateSolid(textColor)
    
    Gdip_DrawString(G, btnText, hFont, hFormat, pBrushTxtMain, &RC)
    Gdip_DeleteBrush(pBrushTxtMain)

    Gdip_DeleteFont(hFont)
    Gdip_DeleteFontFamily(hFontfamily)
    Gdip_DeleteStringFormat(hFormat)
    Gdip_DeletePath(pPathMain)
    Gdip_DeleteBrush(pBrushGrad)
    
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    ReleaseDC(0, hdc)
    Gdip_DeleteGraphics(G)
    
    return hbm
}

; A w x h transparent bitmap with a single red, slightly slanted line about tw pixels wide, centred. It is laid
; over the original reward number to show that it has been replaced by the boosted one.
CreateStreakBitmap(w, h, tw) {
    hdc := GetDC(0)
    hbm := CreateDIBSection(w, h)
    hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm)
    G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)
    x1 := Max(0, (w - tw) / 2)
    x2 := Min(w, x1 + tw)
    pPen := Gdip_CreatePen(0xFFE5484D, 2)
    Gdip_DrawLine(G, pPen, x1, h - 3, x2, 3)
    Gdip_DeletePen(pPen)
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    ReleaseDC(0, hdc)
    Gdip_DeleteGraphics(G)
    return hbm
}

; Draws a rounded badge with centred white text and adds it to `gui` as a Picture.
; (x, y, w, h) is the VISIBLE badge. CreateGradientButton keeps a 6px shadow margin on every side,
; so the bitmap is made 12px larger and placed 6px up/left of the badge.
; textSize is in pixels (GDI+ units); it is the largest size tried, and it shrinks automatically if the
; text would not fit on one line.
AddBadge(gui, x, y, w, h, hex, label, textSize := 14) {
    colors := BadgeColors(hex)
    fit := FitBadgeText(label, w - 16, textSize)
    hbm := CreateGradientButton(w + 12, h + 12, 8, colors[1], colors[2], "0x40000000", "0x40ffffff", fit.text, "Segoe UI", fit.size, 1)
    return gui.Add("Picture", "x" (x - 6) " y" (y - 6) " w" (w + 12) " h" (h + 12) " +BackgroundTrans", "HBITMAP:*" hbm)
}

; Finds the largest bold Segoe UI size (from startSize down to minSize, in pixels) at which `text` fits on one
; line in maxW pixels. If even minSize is too wide, the text is cut and ends with "...". The text is measured
; with GDI+ itself, so it adapts to any map or mode name. Returns {size, text}.
FitBadgeText(text, maxW, startSize, minSize := 9) {
    size := startSize, shown := text
    try {
        hdcMem := CreateCompatibleDC()
        hbm := CreateDIBSection(8, 8)
        obm := SelectObject(hdcMem, hbm)
        G := Gdip_GraphicsFromHDC(hdcMem)
        hFamily := Gdip_FontFamilyCreate("Segoe UI")
        hFormat := Gdip_StringFormatCreate(0x1000 | 0x4000)      ; no wrap, no clip: measure the full single line
        RC := Buffer(16, 0)
        NumPut("float", 0, "float", 0, "float", 4000, "float", 200, RC)
        cut := 0
        Loop {
            shown := cut ? RTrim(SubStr(text, 1, StrLen(text) - cut)) "..." : text
            hFont := Gdip_FontCreate(hFamily, size, 1)
            m := StrSplit(Gdip_MeasureString(G, shown, hFont, hFormat, &RC), "|")
            Gdip_DeleteFont(hFont)
            if (Number(m[3]) <= maxW)
                break
            if (size > minSize) {
                size := Max(minSize, size - 0.5)
            } else if (StrLen(text) - cut > 4) {
                cut += 1
            } else {
                break
            }
        }
        Gdip_DeleteStringFormat(hFormat)
        Gdip_DeleteFontFamily(hFamily)
        Gdip_DeleteGraphics(G)
        SelectObject(hdcMem, obm)
        DeleteObject(hbm)
        DeleteDC(hdcMem)
    } catch {
        ; measuring failed for some reason: fall back to a size based on the text length
        len := StrLen(text)
        size := len <= 16 ? startSize : (len <= 20 ? startSize - 2 : startSize - 4)
        shown := text
    }
    return {size: size, text: shown}
}

CreateFrame(w, h, r, bgColor, strokeOuter, strokeInner) {
    hbm := CreateDIBSection(w, h), hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm), G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)

    pBrushBg := Gdip_BrushCreateSolid(bgColor)
    pPathMain := Gdip_CreateRoundRectanglePath(0, 0, w, h, r)
    Gdip_FillPath(G, pBrushBg, pPathMain)

    pPathOuter := Gdip_CreateRoundRectanglePath(0.5, 0.5, w - 1, h - 1, r)
    pPenOuter := Gdip_CreatePen(strokeOuter, 1)
    Gdip_DrawPath(G, pPenOuter, pPathOuter)

    pPathInner := Gdip_CreateRoundRectanglePath(1.5, 1.5, w - 3, h - 3, r - 1)
    pPenInner := Gdip_CreatePen(strokeInner, 1)
    Gdip_DrawPath(G, pPenInner, pPathInner)

    Gdip_DeletePen(pPenInner), Gdip_DeletePath(pPathInner)
    Gdip_DeletePen(pPenOuter), Gdip_DeletePath(pPathOuter)
    Gdip_DeletePath(pPathMain), Gdip_DeleteBrush(pBrushBg)
    SelectObject(hdcMem, obm), DeleteDC(hdcMem), Gdip_DeleteGraphics(G)
    return hbm
}


CreateScrollThumb(w, h, r, colorStart, colorEnd, glowColor) {
    hbm := CreateDIBSection(w, h), hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm), G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)

    Loop 3 {
        alpha := Format("{:02X}", Integer(30 / A_Index))
        pBrush := Gdip_BrushCreateSolid("0x" alpha SubStr(glowColor, -6))
        pPath := Gdip_CreateRoundRectanglePath(0, A_Index*0.5, w, h, r)
        Gdip_FillPath(G, pBrush, pPath), Gdip_DeletePath(pPath), Gdip_DeleteBrush(pBrush)
    }
    
    pBrushGrad := Gdip_CreateLineBrushFromRect(0, 0, w, h, colorStart, colorEnd, 1, 1)
    pPathMain := Gdip_CreateRoundRectanglePath(0, 0, w, h, r)
    Gdip_FillPath(G, pBrushGrad, pPathMain)
    
    Gdip_DeletePath(pPathMain), Gdip_DeleteBrush(pBrushGrad)
    SelectObject(hdcMem, obm), DeleteDC(hdcMem), Gdip_DeleteGraphics(G)
    return hbm
}


CreateGlowButton(w, h, r, colorStart, colorEnd, glowColor) {
    hdc := GetDC(0)
    hbm := CreateDIBSection(w, h)
    hdcMem := CreateCompatibleDC()
    obm := SelectObject(hdcMem, hbm)
    G := Gdip_GraphicsFromHDC(hdcMem)
    Gdip_SetSmoothingMode(G, 4)

    pad := 5
    bx := pad, by := pad, bw := w - (pad * 2), bh := h - (pad * 2)

    Loop 5 {
        alpha := Format("{:02X}", Integer(15 - (A_Index * 2)))
        currentGlow := SubStr(glowColor, 1, 4) . alpha . SubStr(glowColor, 7)
        
        pBrushGlow := Gdip_BrushCreateSolid(currentGlow)
        pPathGlow := Gdip_CreateRoundRectanglePath(bx - A_Index, by - A_Index, bw + (A_Index * 2), bh + (A_Index * 2), r)
        Gdip_FillPath(G, pBrushGlow, pPathGlow)
        Gdip_DeletePath(pPathGlow)
        Gdip_DeleteBrush(pBrushGlow)
    }

    pBrushGrad := Gdip_CreateLineBrushFromRect(bx, by, bw, bh, colorStart, colorEnd, 1, 1)
    pPathMain := Gdip_CreateRoundRectanglePath(bx, by, bw, bh, r)
    Gdip_FillPath(G, pBrushGrad, pPathMain)

    pPenStroke := Gdip_CreatePen("0x60FFFFFF", 1)
    Gdip_DrawPath(G, pPenStroke, pPathMain)

    Gdip_DeletePen(pPenStroke)
    Gdip_DeletePath(pPathMain)
    Gdip_DeleteBrush(pBrushGrad)
    SelectObject(hdcMem, obm)
    DeleteDC(hdcMem)
    ReleaseDC(0, hdc)
    Gdip_DeleteGraphics(G)
    
    return hbm
}

Gdip_CreateRoundRectanglePath(x, y, w, h, r) {
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &pPath := 0)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x, "float", y, "float", r*2, "float", r*2, "float", 180, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x+w-r*2, "float", y, "float", r*2, "float", r*2, "float", 270, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x+w-r*2, "float", y+h-r*2, "float", r*2, "float", r*2, "float", 0, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", pPath, "float", x, "float", y+h-r*2, "float", r*2, "float", r*2, "float", 90, "float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "ptr", pPath)
    return pPath
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

; "REWARDS +NN%": the sum of the reward bonuses of the active modifiers (they all stack). Green when above 0.
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
    total := 0
    for code, on in StratInfoMods
        total += ModifierBonus(code)
    StratInfoBonusTxt.SetFont(total > 0 ? "c5BD98C" : "c6F7785")
    StratInfoBonusTxt.Value := "REWARDS  +" total "%"
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

; reads tds message (e.g., "You cannot place here")
; returns 1 if the given text is found, 0 if not
; ReadMessage(["already", "current", "rotation"]), for example
; works only with red color
ReadMessage(includeStr := "", includeRx := "", excludeStr := "", excludeRx := "") {
    langCode := "en-US"
    for availableLang in StrSplit(OCR.GetAvailableLanguages(), "`n", "`r") {
        if (availableLang != "" && SubStr(availableLang, 1, 2) = "en") {
            langCode := availableLang
            break
        }
    }

    getRobloxPos(,,&w,&h)
    x := Round(w * 0.2), y := Round(h * 0.18)
    width := Round(w * 0.7) - x, height := Round(h * 0.35) - y

    if (width <= 0 || height <= 0)
        return false

    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)
    pGraphics := Gdip_GraphicsFromImage(pBitmap)
    Matrix := "
    (
    5.0|0.0|0.0|0.0|0.0|
    0.0|-5.0|0.0|0.0|0.0|
    0.0|0.0|-5.0|0.0|0.0|
    0.0|0.0|0.0|1.0|0.0|
    -2.5|1.0|1.0|0.0|1.0
    )"
    pBitmapFiltered := Gdip_CreateBitmap(width, height)
    pGraphicsFiltered := Gdip_GraphicsFromImage(pBitmapFiltered)
    Gdip_DrawImage(pGraphicsFiltered, pBitmap, 0, 0, width, height, 0, 0, width, height, Matrix)
    hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmapFiltered)

    ocrResult := OCR.FromBitmap(hBitmap, {lang: langCode, scale: 3, grayscale: 1})

    DeleteObject(hBitmap)
    Gdip_DisposeImage(pBitmapFiltered), Gdip_DeleteGraphics(pGraphicsFiltered)
    Gdip_DeleteGraphics(pGraphics), Gdip_DisposeImage(pBitmap)

    ocrText := ocrResult.Text

    for s in (HasMethod(excludeStr, "__Enum") ? excludeStr : [excludeStr]) {
        if (s != "" && RegExMatch(ocrText, "i)\b" . s . "\b"))
            return false
    }
    for rx in (HasMethod(excludeRx, "__Enum") ? excludeRx : [excludeRx]) {
        if (rx != "" && RegExMatch(ocrText, "i)" . rx))
            return false
    }

    matchStr := (includeStr == "")
    for s in (HasMethod(includeStr, "__Enum") ? includeStr : [includeStr]) {
        if (s != "" && RegExMatch(ocrText, "i)\b" . s . "\b")) {
            matchStr := true
            break
        }
    }

    matchRx := (includeRx == "")
    for rx in (HasMethod(includeRx, "__Enum") ? includeRx : [includeRx]) {
        if (rx != "" && RegExMatch(ocrText, "i)" . rx)) {
            matchRx := true
            break
        }
    }

    return matchStr && matchRx
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

ProcessCommands(*) {
    global command_buffer, UserID, RunningStrategy, ChannelID

    Discord.GetCommands(ChannelID)

    for command in command_buffer {
        content := command.content

        if (content == "!help") {
            Discord.SendEmbed(
                "**Available commands:**\n" .
                "\n!help - shows the help menu" .
                "\n!screenshot - take and send a screenshot" .
                "\n!status - view macro status and statistics" .
                "\n!stop - stop the macro" .
                "\n!start - start the macro"
            )
        }
        
        else if (content == "!screenshot") {
            pBitmap := PrimaryMonitorBitmap()
            Discord.SendScreenshot(pBitmap, "Requested Screenshot")
            Gdip_DisposeImage(pBitmap)
        }
        
        else if (content == "!status") {
            status := "stopped"
            if (RunningStrategy)
                status := "working"

            savedCoins := IniRead(StateFile, "State", "Coins", 0)
            savedGems := IniRead(StateFile, "State", "Gems", 0)
            savedExp := IniRead(StateFile, "State", "EXP", 0)
            
            totalTriumphs := IniRead(StateFile, "State", "TotalTriumphs", 0)
            totalLosses := IniRead(StateFile, "State", "TotalLosses", 0)
            totalMatches := totalTriumphs + totalLosses
            winrate := (totalMatches > 0) ? Round((totalTriumphs / totalMatches) * 100) : 0
            wlRatio := (totalLosses > 0) ? Round(totalTriumphs / totalLosses, 1) : totalTriumphs

            runtime := FormatRuntime(AutorunStartTime)

            autorunStart := IniRead(StateFile, "State", "StartTime", 0)
            coinsPerHour := 0, gemsPerHour := 0, expPerHour := 0
            if (autorunStart > 0) {
                elapsedMs := A_TickCount - autorunStart
                elapsedHours := elapsedMs / 3600000
                if (elapsedHours > 0.001) {
                    coinsPerHour := Round(savedCoins / elapsedHours)
                    gemsPerHour := Round(savedGems / elapsedHours)
                    expPerHour := Round(savedExp / elapsedHours)
                }
            }
            
            currentStrategy := IniRead(StateFile, "State", "Strategy", "")

            SplitPath(currentStrategy, &stratName)
            
            if (RunningStrategy) {
                statusMsg := "**Macro Status:** Working\n"
                statusMsg .= "**Runtime:** " runtime "\n\n"
                statusMsg .= "**Current Strategy:** " stratName "\n\n"
                statusMsg .= "+" savedCoins " **Coins**\t+" savedGems " **Gems**\t+" savedExp " **EXP**\n"
                statusMsg .= coinsPerHour " Coins/h\t" gemsPerHour " Gems/h\t" expPerHour " EXP/h\n\n"
                statusMsg .= "**Total Matches:** " totalMatches "\t**Wins:** " totalTriumphs "\t**Losses:** " totalLosses "\n"
                statusMsg .= "**Winrate:** " winrate "%\t**W/L Ratio:** " wlRatio
            } else {
                statusMsg := "**Macro Status:** Stopped"
            }

            currentTime := A_Hour ":" A_Min ":" A_Sec
            statusMsg .= "\n-# Unlimited Macro Bot • " currentTime

            Discord.SendEmbed(statusMsg, "3447003")
        }

        else if (content == "!stop") {
            if (RunningStrategy) {
                Discord.SendEmbed("Stopping the macro..", "56320")
                id := Discord.GetMessageAPI()
                StopStrategy()
            } else {
                Discord.SendEmbed("Failed to stop: the macro is not running!", "16515072")
            }
        }

        else if (content == "!start") {
            if (RunningStrategy) {
                Discord.SendEmbed("Failed to start: the macro is already running!", "16515072")
            } else {
                Discord.SendEmbed("Starting the macro..", "56320")
                SetTimer(StartStrategy, -100)
            }
        }
    }
    
    command_buffer := []
}


; ===================== Discord mention helper =====================
GetDiscordMention(rawId) {
    if (rawId = "" || Trim(rawId) = "")
        return ""
    cleanId := RegExReplace(Trim(rawId), "[<@!>]", "")
    cleanId := Trim(cleanId)
    if (cleanId = "" || !RegExMatch(cleanId, "^\d+$"))
        return ""
    return "<@" cleanId ">"
}

; Total reward bonus (in %) of a strat's modifiers= line, e.g. "Hid, Fog" -> 30. Same rule as the Info window's
; "REWARDS +NN%": every known modifier counts once, and anything unknown adds nothing.
ModifierBonusTotal(raw) {
    seen := Map(), total := 0
    for tok in StrSplit(RegExReplace(raw, "[;|]", ","), ",", " `t") {
        if (tok = "" || StrLower(tok) = "none")
            continue
        code := NormalizeModifierToken(tok)
        if (!seen.Has(code)) {
            seen[code] := true
            total += ModifierBonus(code)
        }
    }
    return total
}

; ===================== Modifier helpers (used by the Strategy Info window) =====================
; The modifier editor lives in the Strategy Info window (Edit button next to MODIFIERS).

NormalizeModifierToken(token) {
    tok := Trim(token)
    if (tok = "")
        return ""
    tokLower := StrLower(tok)

    static modMap := [
        { code: "Gla", prefix: "gl", name: "glass" },
        { code: "Hid", prefix: "hi", name: "hidden" },
        { code: "Exp", prefix: "ex", name: "exploding" },
        { code: "Lim", prefix: "li", name: "limitation" },
        { code: "Com", prefix: "co", name: "committed" },
        { code: "Fly", prefix: "fl", name: "flying" },
        { code: "Fog", prefix: "fo", name: "fog",        aliases: ["foggy"] },
        { code: "Qua", prefix: "qu", name: "quarantine", aliases: ["arm", "armored"] },
        { code: "Inf", prefix: "in", name: "inflation",  aliases: ["reg", "regeneration"] },
        { code: "Bro", prefix: "br", name: "broke",      aliases: ["slo", "slow"] },
        { code: "Spe", prefix: "sp", name: "speedy" },
        { code: "Hea", prefix: "he", name: "healthy",    aliases: ["str", "strong"] }
    ]

    for item in modMap {
        if (tokLower = StrLower(item.code)
            || tokLower = item.prefix
            || tokLower = item.name
            || (StrLen(tokLower) >= 2 && SubStr(tokLower, 1, 2) = item.prefix)
            || InStr(item.name, tokLower) = 1) {
            return item.code
        }
        if (item.HasProp("aliases")) {
            for alias in item.aliases {
                if (tokLower = alias || (StrLen(tokLower) >= 3 && InStr(alias, tokLower) = 1))
                    return item.code
            }
        }
    }

    if (StrLen(tok) >= 3)
        return StrUpper(SubStr(tok, 1, 1)) . StrLower(SubStr(tok, 2, 2))
    return tok
}

; Writes the modifiers= line of a strategy file. Returns true when it was saved.
SaveModifiersToStrategyFile(path, modStr) {
    if (path = "" || !FileExist(path))
        return false
    try {
        IniWrite(modStr, path, "Settings", "modifiers")
        LogToConsole("Saved modifiers to " path ": " modStr)
        return true
    } catch {
        return false
    }
}
