; ======================================================================================================================
; Process: Macro lifecycle: safe reload, exit handling, the watchdog and sub-macros.
;
; Functions only. Nothing runs from this file; it is included by Main.ahk (see the #Include lines there).
; ======================================================================================================================

SafeReload() {
    global RestartLock, StateFile, RunningStrategy, OverlayHWND, MainGui
    if (RestartLock) {
        return
    }
    RestartLock := true
    AuditLog("INFO", "Reload", "Macro reloading (SafeReload)")
    KillSubmacros()
    CloseOverlayWindow()

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
