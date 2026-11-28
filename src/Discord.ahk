; ======================================================================================================================
; Discord: Discord: the webhook message queue, sending, and the bot's chat commands.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

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
