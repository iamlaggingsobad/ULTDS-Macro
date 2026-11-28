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

; ---- Application modules (src\): functions only, grouped by what they do; the code that runs at start-up stays in this file ----
#Include src\Util.ahk
#Include src\Vision.ahk
#Include src\Gfx.ahk
#Include src\Logging.ahk
#Include src\Discord.ahk
#Include src\Process.ahk
#Include src\Settings.ahk
#Include src\Window.ahk
#Include src\Library.ahk
#Include src\StratInfo.ahk
#Include src\Recording.ahk
#Include src\Playback.ahk
#Include src\Towers.ahk
#Include src\Lobby.ahk

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
global LogTimes := []        ; A_TickCount of each log line, so the Debug Console can fade old lines
global OverlaySig := ""      ; what the Debug Console last drew (skips redraws when nothing changed)
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
; Seconds a Debug Console line stays on screen before it fades away (0 = never). Set "OverlayLifetime" under [Options] in the settings file.
global OverlayLifetime := IniRead(SettingsFile, "Options", "OverlayLifetime", "10")
OverlayLifetime := IsInteger(OverlayLifetime) ? Integer(OverlayLifetime) : 10

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
    sModifiers := IniRead(localPath, "Settings", "modifiers", "")
    sResult := RewardResult(IniRead(localPath, "Info", "result", ""))      ; "win" (default) or "lose"
    sWave := RewardWave(IniRead(localPath, "Info", "wave", ""))             ; the wave a losing strategy reaches
    
    LoadedStrats.Push({
        fileName: A_LoopFileName,
        map: sMap,
        difficulty: sDifficulty,
        towers: sTowers,
        desc: sDesc,
        author: sAuthor,
        title: sTitle,
        time: sTime,
        modifiers: sModifiers,
        result: sResult,
        wave: sWave,
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

; Frame of the card whose strategy is currently loaded for playback: soft slate-blue border (the same blue-grey family
; as the "on" modifier plates in the Info window) and a slightly blue background. Colours: background, outer line, inner line.
hFrameActive := CreateFrame(CardW, CardH, 10, "0xff161b26", "0xff6F8FC9", "0xaa6F8FC9")

for index, strat in LoadedStrats {
    CurrentY := StartY + ((index - 1) * (CardH + Gap))
    ContentH := CurrentY + CardH + Gap 

    C1X := 10
    C1Y := CurrentY

    hFrameBg := CreateFrame(CardW, CardH, 10, "0xff161616", "0xff1d1d1d", "0x62302d2d")
    frameCtrl := ChildGui.Add("Picture", "x" C1X " y" C1Y " w" CardW " h" CardH " +BackgroundTrans", "HBITMAP:*" hFrameBg)

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
    ;   and modifiers, a loss from the wave it reaches. When map scaling or modifiers change a number, the original is
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
    cardRec.frame := frameCtrl, cardRec.hFrame := hFrameBg, cardRec.hFrameOn := hFrameActive, cardRec.active := false   ; for StratLib_UpdateActive
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
StratLib_UpdateActive()

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

~F1:: StartStrategy(0, 0)
~F2:: StopStrategy(0, 0)


;PATHS =======================================


;=====


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


MainGui.OnEvent("Close", (*) => ExitApp())

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


; ===================== Modifier helpers (used by the Strategy Info window) =====================
; The modifier editor lives in the Strategy Info window (Edit button next to MODIFIERS).
