; ======================================================================================================================
; Settings: Saving and checking settings, including the Discord / webhook settings and their tests.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

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
