#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All
SetTitleMatchMode 2

SendMode("Input")
SetKeyDelay(30, 20)
SetMouseDelay(20)

global CFG := Map()
global gAbort := false
global gPaused := false
global gRunInProgress := false
global TABS := []

CFG["LogFile"] := A_MyDocuments "\automation_log.txt"
CFG["LogDir"]  := A_ScriptDir "\logs"

CFG["RunEyeBeam"]  := true
CFG["RunWhatsApp"] := true

CFG["AnyConnectExe"] := "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe"
CFG["AnyConnectCli"] := "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"
CFG["AnyConnectWin"] := "Cisco AnyConnect Secure Mobility Client"
CFG["CertPhrase"]    := "Security Warning: Untrusted Server Certificate!"

CFG["PwdWin"]        := "Cisco AnyConnect | vpn.example.com"
CFG["PwdTarget"]     := "vpn.example.com"

CFG["VPN_WaitHost"]      := "192.0.2.11"
CFG["VPN_WaitTimeoutMs"] := 45000

CFG["UseVpnCli"]         := true
CFG["VpnConnectPs1"]     := A_ScriptDir "\VpnConnect.ps1"
CFG["VpnGroup"]          := ""

CFG["EyeBeamExe"]   := "C:\Program Files (x86)\CounterPath\eyeBeam 1.5\eyeBeam.exe"
CFG["EyeBeamTitle"] := "eyeBeam"

CFG["WhatsAppAppID"]    := "5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App"
CFG["WhatsAppWinTitle"] := "WhatsApp"
CFG["ChatName"]         := "Team Shift"
CFG["MsgPool"]          := ["YOUR-MESSAGE-HERE"]

CFG["WA_WindowWaitMs"]         := 30000
CFG["WA_LaunchAttempts"]       := 2
CFG["WA_PreSearchDelayMs"]     := 7000
CFG["WA_PostOpenChatDelayMs"]  := 1000
CFG["WA_PreCloseDelayMs"]      := 700
CFG["WA_ReadyTimeoutMs"]       := 5000

CFG["WA_SearchBoxName"]        := "Search or start a new chat"
CFG["WA_ComposeBoxName"]       := "Type a message"
CFG["WA_LoadTimeoutMs"]        := 25000
CFG["WA_ClickSettleMs"]        := 450
CFG["WA_SearchFilterMs"]       := 1500
CFG["WA_OpenSettleMs"]         := 1600

CFG["WA_VerifyChatHeader"]     := true
CFG["WA_VerifyStrict"]         := true

CFG["ChromeExe"]         := "C:\Program Files\Google\Chrome\Application\chrome.exe"
CFG["UserDataDir"]       := EnvGet("LOCALAPPDATA") "\Google\Chrome\User Data"
CFG["ProfileDirName"]    := "Profile 1"

CFG["StartupWaitMs"]     := 4500

CFG["ChromeUseExtension"] := true
CFG["ChromeTabTouchMs"]   := 600
CFG["ChromeExtSettleMs"]  := 6000
CFG["ChromeVerifyLogins"] := true
CFG["VerifyTabDwellMs"]   := 400
CFG["VerifyRetryMs"]      := 1500
CFG["VerifyBypassSettleMs"] := 4000
CFG["TabStabilizeMs"]    := 900
CFG["AfterSubmitMs"]     := 2800
CFG["BetweenRetriesMs"]  := 900
CFG["MaxLoginAttempts"]  := 3
CFG["PageLoadTimeoutMs"] := 5000

CFG["LeftMonX"] := -2560
CFG["LeftMonY"] := 0
CFG["LeftMonW"] := 2560
CFG["LeftMonH"] := 1440

CFG["WinWaitMs"]   := 20000
CFG["ShortWaitMs"] := 5000
CFG["Retries"]     := 3
CFG["ResultToastSecs"] := 6

CFG["PwdDialogSettleMs"] := 400
CFG["PwdSubmitAttempts"] := 4
CFG["PwdCloseWaitTicks"] := 20

TabCfg(name, index, mode, loginTitle, loggedTitle, loggedRegex := ""
    , user := "", pass := ""
) {
    return Map(
        "Name", name,
        "Index", index,
        "Mode", mode,
        "LoginTitle", loginTitle,
        "LoggedTitle", loggedTitle,
        "LoggedRegex", loggedRegex,
        "User", user,
        "Pass", pass
    )
}

TABS.Push(TabCfg("PRTG-SITE-A", 1, "PRTG", "Welcome | PRTG-SITE-A", "Root | Group | PRTG-SITE-A", "", "prtg-viewer", "REPLACE_ME"))
TABS.Push(TabCfg("PRTG-SITE-B", 2, "PRTG", "Welcome | PRTG-SITE-B", "Root | Group | PRTG-SITE-B", "", "prtg-viewer", "REPLACE_ME"))
TABS.Push(TabCfg("PRTG-SITE-C", 3, "PRTG", "Welcome | PRTG-SITE-C", "Root | Group | PRTG", "", "prtg-noc", "REPLACE_ME"))
TABS.Push(TabCfg("Billing Portal #1", 4, "GEN", "Billing Portal", "Billing Portal Home", "", "portal-user", "REPLACE_ME"))
TABS.Push(TabCfg("Billing Portal #2", 5, "GEN", "Billing Portal", "Billing Portal Home", "", "portal-user", "REPLACE_ME"))
TABS.Push(TabCfg("Kerio", 6, "KERIO", "Kerio Connect Client", "", "", "", ""))

$Esc::AbortRun()
F9::RunAll()
F7::TestWhatsApp()
F10::TogglePause()
F8::Calibrate()
$^Esc::AbortRun()

TrayTip("Home Boot", "Starting in 3 seconds...`nPress ESC to cancel`nPress F10 to pause/resume", 3)

Loop 30 {
    if gAbort {
        TrayTip("Home Boot", "Cancelled. Press F9 to run manually.", 3)
        gAbort := false
        return
    }
    if gPaused {
        TrayTip("Home Boot", "Paused. Press F10 to resume.", 2)
        CheckPause()
    }
    Sleep(100)
}

if (A_WDay = 1 || A_WDay = 7) {
    EnsureLogDir()
    Log("===== RUN START =====")
    Log("Weekend detected; auto-run skipped (resident for manual hotkeys: F7 = WhatsApp test, F9 = full run).")
    TrayTip("Home Boot", "Weekend: auto-run skipped.`nF7 = WhatsApp test`nF9 = full run", 6)
} else {
    RunAll()
}
return

RunAll() {
    global CFG, TABS, gAbort, gPaused, gRunInProgress

    if gRunInProgress {
        TrayTip("Home Boot", "Automation already running...", 2)
        return
    }

    gRunInProgress := true
    gAbort := false
    gPaused := false

    try {
        EnsureLogDir()
        Log("===== RUN START =====")

        CheckAbort()
        Step_AnyConnect()
        CheckAbort()

        if CFG["RunEyeBeam"] {
            Step_EyeBeam()
            CheckAbort()
        } else {
            Log("Step: eyeBeam - SKIPPED (CFG RunEyeBeam = false)")
        }

        ok := Step_Chrome_AutoLogin()
        CheckAbort()

        if CFG["RunWhatsApp"] {
            Step_WhatsApp_SendAndClose()
            CheckAbort()
        } else {
            Log("Step: WhatsApp - SKIPPED (CFG RunWhatsApp = false)")
        }

        Log("===== RUN OK =====")
        TrayTip("Home Boot", "Done. Chrome " ok "/" TABS.Length " ✅", 5)
        SetTimer(() => ExitApp(), -(CFG["ResultToastSecs"] * 1000 + 500))

    } catch as e {
        Log("!!! FAILED: " e.Message)
        TrayTip("Home Boot FAILED", e.Message, 8)
        gRunInProgress := false
    }
}

TestWhatsApp() {
    global gAbort, gPaused, gRunInProgress

    if gRunInProgress {
        TrayTip("Home Boot", "Automation already running...", 2)
        return
    }

    gRunInProgress := true
    gAbort := false
    gPaused := false

    try {
        EnsureLogDir()
        Log("===== WHATSAPP TEST (F7) =====")
        Step_WhatsApp_SendAndClose()
        Log("===== WHATSAPP TEST OK =====")
        TrayTip("Home Boot", "WhatsApp test done ✅", 4)
    } catch as e {
        Log("!!! WHATSAPP TEST FAILED: " e.Message)
        TrayTip("Home Boot FAILED", e.Message, 8)
    } finally {
        gRunInProgress := false
    }
}

AbortRun() {
    global gAbort, gPaused
    gAbort := true
    gPaused := false
    TrayTip("Automation", "ESC pressed → Stopping...", 2)
}

TogglePause() {
    global gPaused
    gPaused := !gPaused
    if gPaused
        TrayTip("Automation", "Paused. Press F10 to resume.", 2)
    else
        TrayTip("Automation", "Resumed.", 2)
}

CheckAbort() {
    global gAbort
    if gAbort
        throw Error("Aborted by user (ESC)")
}

CheckPause() {
    global gPaused, gAbort
    while gPaused {
        if gAbort
            throw Error("Aborted by user (ESC)")
        Sleep(100)
    }
}

WaitWithControl(ms, step := 100) {
    endTime := A_TickCount + ms
    Loop {
        CheckAbort()
        CheckPause()
        remaining := endTime - A_TickCount
        if (remaining <= 0)
            break
        Sleep(Min(step, remaining))
    }
}

Step_AnyConnect() {
    global CFG

    if IsVpnAlreadyUp() {
        Log("Step: AnyConnect - VPN already connected ✅ (vpncli state + reachable), skip")
        return
    }

    if (CFG["UseVpnCli"] && TryConnectViaCLI())
        return

    if (CFG["UseVpnCli"])
        Log("AnyConnect: CLI path did not connect, falling back to GUI automation")
    Step_AnyConnect_GUI()
}

TryConnectViaCLI() {
    global CFG
    Log("Step: AnyConnect - connecting via vpncli (VpnConnect.ps1)")

    if !FileExist(CFG["VpnConnectPs1"]) {
        Log("AnyConnect: VpnConnect.ps1 not found at " CFG["VpnConnectPs1"] ", skipping CLI path")
        return false
    }

    groupArg := (CFG["VpnGroup"] != "") ? (' -Group "' CFG["VpnGroup"] '"') : ""
    tmp := A_Temp "\vpnconnect_out.txt"
    try FileDelete(tmp)
    psCmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' CFG["VpnConnectPs1"] '"' groupArg ' -RelaunchGui'
    fullCmd := A_ComSpec ' /c ' psCmd ' > "' tmp '" 2>&1'

    exitCode := -1
    try {
        exitCode := RunWait(fullCmd, , "Hide")
    } catch as e {
        Log("AnyConnect: failed to launch VpnConnect.ps1: " e.Message)
        return false
    }

    try {
        if FileExist(tmp) {
            for _, line in StrSplit(FileRead(tmp), "`n", "`r") {
                if (Trim(line) != "")
                    Log("  [vpncli] " line)
            }
        }
    }

    Log("AnyConnect: VpnConnect.ps1 exit=" exitCode)

    reachWait := (exitCode = 0) ? CFG["ShortWaitMs"] : 3000
    if WaitForVPNConnected(reachWait, CFG["VPN_WaitHost"]) {
        Log("Step: AnyConnect - VPN reachable ✅ (CLI)")
        return true
    }

    Log("AnyConnect: CLI ran (exit=" exitCode ") but VPN not reachable")
    return false
}

Step_AnyConnect_GUI() {
    global CFG
    Log("Step: AnyConnect(GUI) - launch/focus")
    EnsureExeFocused(CFG["AnyConnectExe"], CFG["AnyConnectWin"], CFG["WinWaitMs"])

    if WinExist("Cisco AnyConnect", "already in progress") {
        Log("AnyConnect: dismissing leftover 'Connect already in progress' modal")
        try {
            ControlClick("OK", "Cisco AnyConnect", "already in progress")
            Sleep(500)
        } catch as e {
            Log("AnyConnect: failed to dismiss leftover modal: " e.Message)
        }
        if !EnsureWindowActive(CFG["AnyConnectWin"], CFG["ShortWaitMs"]/1000)
            throw Error("AnyConnect: main window not active after leftover-modal dismissal")
    }

    Log("Step: AnyConnect - trigger Connect (ControlClick Button1)")

    if !EnsureWindowActive(CFG["AnyConnectWin"], CFG["ShortWaitMs"]/1000)
        throw Error("AnyConnect: failed to activate main window before Connect click")

    Sleep(1000)

    state := WaitAnyConnectButton1Settled(3000)
    Log("AnyConnect: Button1 settled='" state "'")

    if (state = "Disconnect") {
        Log("AnyConnect: already connected, verifying VPN reachability and skipping Connect")
        if !WaitForVPNConnected(CFG["ShortWaitMs"], CFG["VPN_WaitHost"])
            throw Error("AnyConnect: Button1='Disconnect' but VPN not reachable")
        Log("Step: AnyConnect - VPN reachable ✅ (already connected)")
        return
    }

    if (state != "Connect") {
        LogWindowControls(CFG["AnyConnectWin"])
        throw Error("AnyConnect: Button1 not in Connect state (last='" state "')")
    }

    try {
        ControlClick("Button1", CFG["AnyConnectWin"])
        Log("AnyConnect: ControlClick Button1 fired")
    } catch as e {
        LogWindowControls(CFG["AnyConnectWin"])
        throw Error("AnyConnect: ControlClick Button1 failed: " e.Message)
    }

    Log("AnyConnect: waiting up to 12s for cert warning or password prompt")
    triggered := WaitAnyConnectTriggered(12000)

    if !triggered {
        retryState := GetButtonText("Button1", CFG["AnyConnectWin"])
        Log("AnyConnect: 12s timeout, Button1 now='" retryState "'")
        if (retryState = "Connect") {
            Log("AnyConnect: state still 'Connect', single re-click")
            try {
                ControlClick("Button1", CFG["AnyConnectWin"])
                Log("AnyConnect: ControlClick Button1 fired (re-click)")
            } catch as e {
                LogWindowControls(CFG["AnyConnectWin"])
                throw Error("AnyConnect: re-click failed: " e.Message)
            }
            triggered := WaitAnyConnectTriggered(12000)
        } else if (retryState = "Disconnect") {
            Log("AnyConnect: Button1 now 'Disconnect', first click took effect, verifying reachability")
            if WaitForVPNConnected(CFG["ShortWaitMs"], CFG["VPN_WaitHost"]) {
                Log("Step: AnyConnect - VPN reachable ✅ (post-click, no cert/pwd surfaced)")
                return
            }
        }
        if !triggered {
            LogWindowControls(CFG["AnyConnectWin"])
            throw Error("AnyConnect: Connect did not trigger")
        }
    }
    Log("AnyConnect: Connect triggered (password/cert detected)")

    if WaitForWindowText(CFG["AnyConnectWin"], CFG["CertPhrase"], 8000) {
        Log("Step: AnyConnect - cert warning detected; sending Right+Enter")

        dismissed := false
        Loop 3 {
            CheckAbort()
            CheckPause()

            if !EnsureWindowActive(CFG["AnyConnectWin"], CFG["ShortWaitMs"]/1000) {
                Log("AnyConnect: failed to refocus cert dialog attempt " A_Index)
                WaitWithControl(300)
                continue
            }

            Sleep(200)
            Send("{Right}{Enter}")
            Log("AnyConnect: sent Right+Enter on cert dialog (attempt " A_Index ")")

            WaitWithControl(500)

            if !WaitForWindowText(CFG["AnyConnectWin"], CFG["CertPhrase"], 300) {
                dismissed := true
                break
            }
        }

        if !dismissed
            throw Error("AnyConnect: couldn't dismiss certificate warning")
    } else {
        Log("Step: AnyConnect - no certificate warning detected (within 8s)")
    }

    Log("Step: AnyConnect - wait for password prompt")
    if !WinWait(CFG["PwdWin"], , CFG["WinWaitMs"]/1000)
        throw Error("AnyConnect: password prompt did not appear in time")

    if !EnsureWindowActive(CFG["PwdWin"], CFG["ShortWaitMs"]/1000)
        throw Error("AnyConnect: password window did not become active")

    Log("Step: Credential - read password from Windows Credential Manager (WinAPI, no prompts)")
    pw := CredReadGenericPassword(CFG["PwdTarget"])
    if (pw = "")
        throw Error("Credential read failed for target: " CFG["PwdTarget"])

    Log("Credential OK (length=" StrLen(pw) ").")
    Log("Step: AnyConnect - enter password + submit")

    Sleep(CFG["PwdDialogSettleMs"])

    LogWindowControls(CFG["PwdWin"])

    submitted := false
    Loop CFG["PwdSubmitAttempts"] {
        attempt := A_Index
        CheckAbort()
        CheckPause()

        if !WinExist(CFG["PwdWin"]) {
            submitted := true
            break
        }

        if !EnsureWindowActive(CFG["PwdWin"], CFG["ShortWaitMs"]/1000)
            Log("AnyConnect: pwd dialog not active before entry (attempt " attempt ")")

        try ControlFocus("Edit2", CFG["PwdWin"])
        try ControlSetText("", "Edit2", CFG["PwdWin"])
        Retry(() => ControlSetText(pw, "Edit2", CFG["PwdWin"]), 2, 200
            , "AnyConnect: couldn't set password field (Edit2)")
        Sleep(150)

        clickedLabel := TryClickButtonByText(CFG["PwdWin"], ["OK", "Connect"])
        if clickedLabel {
            Log("AnyConnect: ControlClick pwd '" clickedLabel "' (attempt " attempt ")")
        } else {
            Log("AnyConnect: no OK/Connect by text; ClassNN fallback (attempt " attempt ")")
            for _, btn in ["Button1", "Button2"] {
                try {
                    ControlClick(btn, CFG["PwdWin"])
                    Log("AnyConnect: ControlClick " btn " on pwd dialog")
                    break
                } catch as e {
                    Log("AnyConnect: ControlClick " btn " threw: " e.Message)
                }
            }
        }

        Loop CFG["PwdCloseWaitTicks"] {
            CheckAbort()
            CheckPause()
            WaitWithControl(300)
            if !WinExist(CFG["PwdWin"]) {
                submitted := true
                break
            }
        }
        if submitted
            break

        Log("AnyConnect: pwd dialog still open after attempt " attempt ", retrying")
    }

    pw := ""

    if !submitted
        throw Error("AnyConnect: password dialog did not close after " CFG["PwdSubmitAttempts"] " submit attempts")

    Log("Step: AnyConnect - submitted credentials")

    Log("Step: AnyConnect - waiting for VPN network reachability")
    if !WaitForVPNConnected(CFG["VPN_WaitTimeoutMs"], CFG["VPN_WaitHost"])
        throw Error("VPN did not become reachable (" CFG["VPN_WaitHost"] ")")

    Log("Step: AnyConnect - VPN reachable ✅")
    WaitWithControl(800)
}

GetButtonText(controlClassNN, winTitle) {
    try {
        return ControlGetText(controlClassNN, winTitle)
    } catch {
        return ""
    }
}

WaitAnyConnectButton1Settled(timeoutMs := 3000) {
    global CFG
    endWait := A_TickCount + timeoutMs
    last := ""
    while (A_TickCount < endWait) {
        CheckAbort()
        CheckPause()
        last := GetButtonText("Button1", CFG["AnyConnectWin"])
        if (last = "Connect" || last = "Disconnect")
            return last
        Sleep(200)
    }
    return last
}

WaitAnyConnectTriggered(timeoutMs := 12000) {
    global CFG
    endWait := A_TickCount + timeoutMs
    while (A_TickCount < endWait) {
        CheckAbort()
        CheckPause()
        if WinExist(CFG["PwdWin"])
            return true
        if WinExist(CFG["AnyConnectWin"]) {
            txt := WinGetText(CFG["AnyConnectWin"])
            if (txt != "" && InStr(txt, CFG["CertPhrase"]))
                return true
        }
        Sleep(200)
    }
    return false
}

Step_EyeBeam() {
    global CFG
    Log("Step: eyeBeam - launch/focus")
    EnsureExeFocused(CFG["EyeBeamExe"], CFG["EyeBeamTitle"], CFG["WinWaitMs"])
    Log("Step: eyeBeam - OK")
}

Step_WhatsApp_SendAndClose() {
    global CFG

    Log("Step: WhatsApp - ensure window")
    isCold := false
    waHwnd := WhatsApp_EnsureWindowHwnd(&isCold)
    waWin  := "ahk_id " waHwnd
    Log("Step: WhatsApp - window ready (hwnd=" waHwnd ", cold=" (isCold ? "yes" : "no") ")")

    WhatsApp_WaitResponsive(waHwnd, CFG["WA_PreSearchDelayMs"], isCold)

    Log("Step: WhatsApp - open chat via UIA+click: " CFG["ChatName"])
    if !WhatsApp_OpenChat_UIA(waHwnd, CFG["ChatName"], 4)
        throw Error("WhatsApp: failed to open chat '" CFG["ChatName"] "'")

    WaitWithControl(CFG["WA_PostOpenChatDelayMs"])

    if CFG["WA_VerifyChatHeader"] {
        verdict := WhatsApp_VerifyHeader_UIA(waHwnd, CFG["ChatName"])
        Log("Step: WhatsApp - header verify = " verdict)
        if (verdict = "mismatch" && CFG["WA_VerifyStrict"])
            throw Error("WhatsApp: header verify says the wrong chat is open; aborting send (strict)")
    }

    msg := PickRandom(CFG["MsgPool"])
    Log("Step: WhatsApp - send message (picked): [" msg "]")

    if !WhatsApp_SendMessage_UIA(waHwnd, msg)
        throw Error("WhatsApp: message send failed")

    Log("Step: WhatsApp - close")
    WaitWithControl(CFG["WA_PreCloseDelayMs"])
    WinClose(waWin)

    Loop 30 {
        if !WinExist(waWin)
            break
        Sleep(100)
    }

    Log("Step: WhatsApp - fully closed")
}

WhatsApp_EnsureWindowHwnd(&isCold) {
    global CFG
    isCold := false
    title := CFG["WhatsAppWinTitle"]

    hwnd := WinExist(title)
    if hwnd {
        WinActivate("ahk_id " hwnd)
        WinWaitActive("ahk_id " hwnd, , 8)
        WhatsApp_WaitReady("ahk_id " hwnd)
        return hwnd
    }

    isCold := true
    Loop CFG["WA_LaunchAttempts"] {
        Log("WhatsApp: launch attempt " A_Index "/" CFG["WA_LaunchAttempts"])
        Run('explorer.exe shell:AppsFolder\' CFG["WhatsAppAppID"])
        Log("WhatsApp: launch command fired")

        if WinWait(title, , CFG["WA_WindowWaitMs"]/1000) {
            hwnd := WinExist(title)
            if hwnd {
                Log("WhatsApp: window detected hwnd=" hwnd)
                WinActivate("ahk_id " hwnd)
                WinWaitActive("ahk_id " hwnd, , 10)
                Log("WhatsApp: launch activation=OK")
                WhatsApp_WaitReady("ahk_id " hwnd)
                return hwnd
            }
        }
        Sleep(1000)
    }

    throw Error("WhatsApp: main window did not appear (title='" title "')")
}

WhatsApp_WaitReady(waWin) {
    global CFG

    Log("WhatsApp: readiness wait START")
    start := A_TickCount
    pass := 0

    while (A_TickCount - start < CFG["WA_ReadyTimeoutMs"]) {
        pass += 1
        try {
            WinActivate(waWin)
            WinWaitActive(waWin, , 2)
            Log("WhatsApp: readiness pass " pass " activation=OK")
            Log("WhatsApp: ready")
            return true
        } catch as e {
            Log("WhatsApp: readiness pass " pass " activation failed | " e.Message)
        }
        Sleep(400)
    }

    Log("WhatsApp: readiness wait timed out after " CFG["WA_ReadyTimeoutMs"] "ms")
    return false
}

WhatsApp_WaitResponsive(hwnd, maxWaitMs, coldStart := false) {
    if coldStart {
        Log("WhatsApp: cold start - waiting full " maxWaitMs " ms (WM_NULL probe unreliable pre-paint)")
        WaitWithControl(maxWaitMs)
        return true
    }

    Log("WhatsApp: wait-responsive START (warm, cap " maxWaitMs " ms)")
    start := A_TickCount

    loop {
        CheckAbort()
        CheckPause()

        elapsed := A_TickCount - start

        if WhatsApp_IsResponsive(hwnd, 200) {
            Log("WhatsApp: UI responsive after " elapsed " ms")
            return true
        }

        if (elapsed >= maxWaitMs) {
            Log("WhatsApp: wait-responsive cap hit at " elapsed " ms (continuing)")
            return false
        }

        Sleep(100)
    }
}

WhatsApp_IsResponsive(hwnd, timeoutMs := 200) {
    out := 0
    result := DllCall("SendMessageTimeoutW"
        , "Ptr",   hwnd
        , "UInt",  0
        , "Ptr",   0
        , "Ptr",   0
        , "UInt",  0x0002
        , "UInt",  timeoutMs
        , "Ptr*",  &out
        , "Ptr")
    return result != 0
}

WhatsApp_OpenChat_UIA(hwnd, chatName, tries) {
    global CFG
    uia := WA_UIA()
    if !uia {
        Log("WhatsApp: cannot create UIAutomation")
        return false
    }

    root := 0, search := 0
    start := A_TickCount
    loop {
        CheckAbort()
        WinActivate("ahk_id " hwnd)
        if root
            ObjRelease(root)
        root := WA_Root(uia, hwnd)
        search := root ? WA_FindSearchBox(uia, root, hwnd) : 0
        if search
            break
        if (A_TickCount - start > CFG["WA_LoadTimeoutMs"]) {
            Log("WhatsApp: search box never appeared within " CFG["WA_LoadTimeoutMs"] " ms")
            if root
                ObjRelease(root)
            return false
        }
        Sleep(400)
    }
    Log("WhatsApp: search box ready after " (A_TickCount - start) " ms")

    Loop tries {
        CheckAbort()
        Log("WhatsApp: UIA open-chat attempt " A_Index "/" tries)

        if !search
            search := WA_FindSearchBox(uia, root, hwnd)
        if !search {
            Log("WhatsApp: search box lost; refreshing")
            ObjRelease(root)
            root := WA_Root(uia, hwnd)
            Sleep(400)
            continue
        }

        WA_ClickElem(search)
        ObjRelease(search)
        search := 0
        Sleep(CFG["WA_ClickSettleMs"])
        Send("^a")
        Sleep(80)
        Send("{Delete}")
        Sleep(150)
        SendText(chatName)
        Log("WhatsApp: typed '" chatName "' into search")
        Sleep(CFG["WA_SearchFilterMs"])

        ObjRelease(root)
        root := WA_Root(uia, hwnd)
        row := root ? WA_FindDataItemStartingWith(uia, root, chatName) : 0
        if (row && WA_RectVisible(row, hwnd)) {
            Log("WhatsApp: matched row = '" SubStr(WA_Name(row), 1, 50) "'")
            WA_ClickElem(row)
            ObjRelease(row)
            ObjRelease(root)
            Log("WhatsApp: clicked row to open chat")
            Sleep(CFG["WA_OpenSettleMs"])
            return true
        }
        if row {
            Log("WhatsApp: matched row off-screen; retry")
            ObjRelease(row)
        } else {
            Log("WhatsApp: no visible row starting with '" chatName "'; retry")
        }
        Sleep(300)
    }

    if root
        ObjRelease(root)
    return false
}

WhatsApp_VerifyHeader_UIA(hwnd, chatName) {
    uia := WA_UIA()
    if !uia
        return "unknown"
    root := WA_Root(uia, hwnd)
    if !root
        return "unknown"

    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    bstr := DllCall("oleaut32\SysAllocString", "wstr", chatName, "ptr")
    vnt := Buffer(24, 0)
    NumPut("ushort", 8, vnt, 0)
    NumPut("ptr", bstr, vnt, 8)
    cond := 0, arr := 0, headerFound := false
    try {
        ComCall(23, uia, "int", 30005, "ptr", vnt, "ptr*", &cond)
        ComCall(6, root, "int", 4, "ptr", cond, "ptr*", &arr)
        if arr {
            len := 0
            ComCall(3, arr, "int*", &len)
            Loop len {
                el := 0
                try {
                    ComCall(4, arr, "int", A_Index - 1, "ptr*", &el)
                    if !el
                        continue
                    rc := Buffer(16, 0)
                    ComCall(43, el, "ptr", rc)
                    l := NumGet(rc, 0, "int"), t := NumGet(rc, 4, "int")
                    relL := ww ? (l - wx) / ww : 0.0
                    relT := wh ? (t - wy) / wh : 1.0
                    if (relL > 0.28 && relT < 0.16) {
                        headerFound := true
                        Log(Format("WhatsApp: header confirmed relL={1} relT={2}", Round(relL, 3), Round(relT, 3)))
                    }
                } finally {
                    if el
                        ObjRelease(el)
                }
                if headerFound
                    break
            }
        }
    } catch as e {
        Log("WhatsApp: header verify error | " e.Message)
    }
    if arr
        ObjRelease(arr)
    if cond
        ObjRelease(cond)
    DllCall("oleaut32\SysFreeString", "ptr", bstr)
    ObjRelease(root)
    return headerFound ? "match" : "mismatch"
}

WhatsApp_SendMessage_UIA(hwnd, msg) {
    global CFG
    WinActivate("ahk_id " hwnd)
    if !WinWaitActive("ahk_id " hwnd, , 5)
        return false

    uia := WA_UIA()
    if !uia
        return false
    root := WA_Root(uia, hwnd)
    if !root
        return false

    compose := WA_FindByName(uia, root, CFG["WA_ComposeBoxName"])
    if !compose
        compose := WA_FindRightPaneEdit(uia, root, hwnd)
    if !compose {
        Log("WhatsApp: compose box not found ('" CFG["WA_ComposeBoxName"] "')")
        ObjRelease(root)
        return false
    }
    ok := WA_ClickElem(compose)
    ObjRelease(compose)
    ObjRelease(root)
    if !ok {
        Log("WhatsApp: compose box has a bad rect; not clickable")
        return false
    }

    Sleep(CFG["WA_ClickSettleMs"])
    SendText(msg)
    Log("WhatsApp: typed message text")
    Sleep(300)
    Send("{Enter}")
    Log("WhatsApp: pressed Enter to send")
    Sleep(500)
    return true
}

WA_UIA() {
    try
        return ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
    catch
        return 0
}

WA_Root(uia, hwnd) {
    root := 0
    try ComCall(6, uia, "ptr", hwnd, "ptr*", &root)
    return root
}

WA_FindByName(uia, root, nameVal) {
    bstr := DllCall("oleaut32\SysAllocString", "wstr", nameVal, "ptr")
    vnt := Buffer(24, 0)
    NumPut("ushort", 8, vnt, 0)
    NumPut("ptr", bstr, vnt, 8)
    cond := 0, found := 0
    try {
        ComCall(23, uia, "int", 30005, "ptr", vnt, "ptr*", &cond)
        ComCall(5, root, "int", 4, "ptr", cond, "ptr*", &found)
    }
    if cond
        ObjRelease(cond)
    DllCall("oleaut32\SysFreeString", "ptr", bstr)
    return found
}

WA_FindSearchBox(uia, root, hwnd) {
    global CFG
    s := WA_FindByName(uia, root, CFG["WA_SearchBoxName"])
    if s
        return s
    return WA_FindEditByRegion(uia, root, hwnd, "left")
}

WA_FindRightPaneEdit(uia, root, hwnd) {
    return WA_FindEditByRegion(uia, root, hwnd, "right")
}

WA_FindEditByRegion(uia, root, hwnd, side) {
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    vnt := Buffer(24, 0)
    NumPut("ushort", 3, vnt, 0)
    NumPut("int", 50004, vnt, 8)
    cond := 0, arr := 0, hit := 0
    try {
        ComCall(23, uia, "int", 30003, "ptr", vnt, "ptr*", &cond)
        ComCall(6, root, "int", 4, "ptr", cond, "ptr*", &arr)
        if arr {
            len := 0
            ComCall(3, arr, "int*", &len)
            Loop len {
                el := 0
                ComCall(4, arr, "int", A_Index - 1, "ptr*", &el)
                if !el
                    continue
                rc := Buffer(16, 0)
                ComCall(43, el, "ptr", rc)
                l := NumGet(rc, 0, "int"), t := NumGet(rc, 4, "int")
                r := NumGet(rc, 8, "int"), b := NumGet(rc, 12, "int")
                relL := ww ? (l - wx) / ww : 0.0
                good := (r > l && b > t) && (side = "left" ? relL < 0.28 : relL > 0.30)
                if good {
                    hit := el
                    break
                }
                ObjRelease(el)
            }
        }
    }
    if arr
        ObjRelease(arr)
    if cond
        ObjRelease(cond)
    return hit
}

WA_FindDataItemStartingWith(uia, root, prefix) {
    vnt := Buffer(24, 0)
    NumPut("ushort", 3, vnt, 0)
    NumPut("int", 50029, vnt, 8)
    plen := StrLen(prefix)
    cond := 0, arr := 0, preferred := 0, loose := 0
    try {
        ComCall(23, uia, "int", 30003, "ptr", vnt, "ptr*", &cond)
        ComCall(6, root, "int", 4, "ptr", cond, "ptr*", &arr)
        if arr {
            len := 0
            ComCall(3, arr, "int*", &len)
            Loop len {
                el := 0
                ComCall(4, arr, "int", A_Index - 1, "ptr*", &el)
                if !el
                    continue
                nm := WA_Name(el)
                if (SubStr(nm, 1, plen) = prefix) {
                    nextCh := SubStr(nm, plen + 1, 1)
                    if (nextCh = " " || nextCh = "") {
                        if loose
                            ObjRelease(loose)
                        preferred := el
                        break
                    } else if !loose {
                        loose := el
                        continue
                    }
                }
                ObjRelease(el)
            }
        }
    }
    if arr
        ObjRelease(arr)
    if cond
        ObjRelease(cond)
    return preferred ? preferred : loose
}

WA_Name(el) {
    p := 0
    try ComCall(23, el, "ptr*", &p)
    if !p
        return ""
    s := StrGet(p, "UTF-16")
    DllCall("oleaut32\SysFreeString", "ptr", p)
    return s
}

WA_RectVisible(el, hwnd) {
    rc := Buffer(16, 0)
    try ComCall(43, el, "ptr", rc)
    l := NumGet(rc, 0, "int"), t := NumGet(rc, 4, "int")
    r := NumGet(rc, 8, "int"), b := NumGet(rc, 12, "int")
    if (r <= l || b <= t)
        return false
    cx := (l + r) // 2, cy := (t + b) // 2
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    return (cx >= wx && cx <= wx + ww && cy >= wy && cy <= wy + wh)
}

WA_ClickElem(el) {
    rc := Buffer(16, 0)
    try ComCall(43, el, "ptr", rc)
    l := NumGet(rc, 0, "int"), t := NumGet(rc, 4, "int")
    r := NumGet(rc, 8, "int"), b := NumGet(rc, 12, "int")
    if (r <= l || b <= t)
        return false
    cx := (l + r) // 2, cy := (t + b) // 2
    prev := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    Click(cx, cy)
    CoordMode("Mouse", prev)
    return true
}

Step_Chrome_AutoLogin() {
    global CFG, TABS, gAbort

    Log("Step: Chrome - START")
    CloseAllChrome()

    hwnd := LaunchChrome()
    if !hwnd
        throw Error("Chrome window not found")

    MoveToLeftMonitor(hwnd)

    WinActivate("ahk_id " hwnd)
    WinWaitActive("ahk_id " hwnd,, 3)

    Sleep(CFG["StartupWaitMs"])

    freshHwnd := FindChromeHwnd()
    if freshHwnd {
        if (freshHwnd != hwnd) {
            Log("Chrome hwnd re-acquired (was " hwnd ", now " freshHwnd ")")
        }
        hwnd := freshHwnd
    }

    if CFG["ChromeUseExtension"] {
        Loop TABS.Length {
            if gAbort
                throw Error("Aborted")
            SwitchToTab(A_Index, hwnd)
            Sleep(CFG["ChromeTabTouchMs"])
            BypassPrivacyErrorIfPresent(hwnd)
        }
        SwitchToTab(1, hwnd)
        Log("Chrome - " TABS.Length " tabs touched; extension handling logins, settling " CFG["ChromeExtSettleMs"] "ms")
        Sleep(CFG["ChromeExtSettleMs"])

        verified := TABS.Length
        if CFG["ChromeVerifyLogins"]
            verified := VerifyExtensionLogins(hwnd)

        Log("Step: Chrome - DONE (extension login) | verified=" verified "/" TABS.Length)
        return verified
    }

    success := 0
    total := TABS.Length

    for _, tab in TABS {
        if gAbort
            throw Error("Aborted")

        Log("---- " tab["Name"] " ----")

        if !SwitchToTab(tab["Index"], hwnd) {
            freshHwnd := FindChromeHwnd()
            if freshHwnd && (freshHwnd != hwnd) {
                hwnd := freshHwnd
                Log("Chrome hwnd recovered=" hwnd)
                if !SwitchToTab(tab["Index"], hwnd) {
                    Log("SKIP: failed to switch to tab " tab["Index"] " after hwnd recovery")
                    continue
                }
            } else {
                Log("SKIP: failed to switch to tab " tab["Index"])
                continue
            }
        }

        if (tab["Index"] = 1)
            Sleep(250)
        else
            Sleep(CFG["TabStabilizeMs"])

        KillAutoFillPopups()
        Sleep(60)

        st := WaitTabLoadState(hwnd, tab, CFG["PageLoadTimeoutMs"])
        Log("Title: " st["Title"])
        Log("State: " st["State"])

        if (st["State"] = "TIMEOUT") {
            Log("SKIP: page did not load into usable state within " CFG["PageLoadTimeoutMs"] "ms")
            continue
        }
        if (st["State"] = "DOWN") {
            Log("SKIP: network/error page detected")
            continue
        }

        if (st["State"] = "LOGGED_IN" && tab["Mode"] != "KERIO") {
            Log("OK: already logged in.")
            success++
            continue
        }

        if (st["State"] != "LOGIN") {
            if IsPaesslerRedirect(st["Title"]) {
                Log("On Paessler before login -> Back. Title=" st["Title"])
                Send("!{Left}")
                Sleep(900)

                st2 := WaitTabLoadState(hwnd, tab, 2500)
                Log("Title(after back): " st2["Title"])
                Log("State(after back): " st2["State"])

                if (st2["State"] = "LOGGED_IN" && tab["Mode"] != "KERIO") {
                    Log("OK: already logged in after Back.")
                    success++
                    continue
                }

                if (st2["State"] != "LOGIN") {
                    Log("SKIP: still not in LOGIN after Back.")
                    continue
                }
            } else {
                if (tab["Mode"] != "KERIO") {
                    Log("SKIP: unknown pre-login state (not LOGIN/LOGGED_IN).")
                    continue
                }
            }
        }

        if !Login(tab, hwnd) {
            Log("SKIP: Login failed (" tab["Name"] ")")
            continue
        }

        if (tab["Mode"] = "KERIO") {
            Log("OK: Kerio clicked login (skip title verification).")
            success++
            continue
        }

        Sleep(700)

        verifyTitle := GetTitle(hwnd)
        verifyState := GetState(verifyTitle, tab)
        Log("Verify title: " verifyTitle)
        Log("Verify state: " verifyState)

        if (verifyState = "LOGGED_IN")
            success++
        else
            Log("SKIP: Post-login verification failed (" tab["Name"] ")")
    }

    Log("Step: Chrome - DONE | success=" success "/" total)
    return success
}

GetState(title, tab) {
    if (tab["LoggedRegex"] != "" && RegExMatch(title, tab["LoggedRegex"]))
        return "LOGGED_IN"

    if (tab["LoggedTitle"] != "" && InStr(title, tab["LoggedTitle"]))
        return "LOGGED_IN"

    if (tab["LoginTitle"] != "" && InStr(title, tab["LoginTitle"]))
        return "LOGIN"

    return "UNKNOWN"
}

VerifyExtensionLogins(hwnd) {
    global CFG, TABS
    ok := 0
    for _, tab in TABS {
        idx := tab["Index"]
        if !SwitchToTab(idx, hwnd) {
            hwnd := FindChromeHwnd()
            SwitchToTab(idx, hwnd)
        }
        Sleep(CFG["VerifyTabDwellMs"])
        title := GetTitle(hwnd)
        reason := VerifyFailReason(title, tab)

        if (reason != "") {
            if IsPrivacyError(title) {
                BypassPrivacyErrorIfPresent(hwnd)
                Sleep(CFG["VerifyBypassSettleMs"])
            } else {
                Sleep(CFG["VerifyRetryMs"])
            }
            title := GetTitle(hwnd)
            reason := VerifyFailReason(title, tab)
        }

        if (reason != "") {
            Log("  verify " tab["Name"] ": NOT CONFIRMED - " reason " (" title ")")
        } else {
            ok++
            Log("  verify " tab["Name"] ": ok")
        }
    }
    SwitchToTab(1, hwnd)
    return ok
}

VerifyFailReason(title, tab) {
    if IsPrivacyError(title)
        return "cert interstitial"
    if IsChromeNetErrorTitle(title)
        return "error page"
    if IsLoginPage(title, tab)
        return "still on login page"
    return ""
}

IsLoginPage(title, tab) {
    if (tab["Mode"] = "KERIO") {
        if RegExMatch(title, "^\(\d+\)")
            return false
        return InStr(title, tab["LoginTitle"]) ? true : false
    }
    if (tab["LoggedRegex"] != "" && RegExMatch(title, tab["LoggedRegex"]))
        return false
    if (tab["LoggedTitle"] != "" && InStr(title, tab["LoggedTitle"]))
        return false
    if (tab["LoginTitle"] != "" && InStr(title, tab["LoginTitle"]))
        return true
    return false
}

IsPaesslerRedirect(title) {
    t := StrLower(title)
    return InStr(t, "paessler")
        || InStr(t, "free trial")
        || InStr(t, "monitoring experts")
        || InStr(t, "start your free trial")
}

IsPrivacyError(title) {
    t := StrLower(title)
    return InStr(t, "your connection is not private")
        || InStr(t, "privacy error")
        || InStr(t, "net::err_cert")
        || InStr(t, "not private")
}

BypassPrivacyErrorIfPresent(hwnd) {
    title := GetTitle(hwnd)
    if !IsPrivacyError(title)
        return false

    Log("Chrome: privacy error on this tab -> bypassing with thisisunsafe (title=" title ")")
    Loop 3 {
        try WinActivate("ahk_id " hwnd)
        Sleep(200)
        CoordMode("Mouse", "Window")
        Click(400, 400, 1)
        Sleep(300)
        Send("thisisunsafe")
        Sleep(3000)

        title := GetTitle(hwnd)
        if !IsPrivacyError(title) {
            Log("Chrome: privacy error bypassed on attempt " A_Index)
            return true
        }
        Log("Chrome: bypass attempt " A_Index " still showing, retrying")
        Sleep(500)
    }
    Log("Chrome: privacy error could not be bypassed after 3 attempts")
    return false
}

IsChromeNetErrorTitle(title) {
    t := StrLower(title)
    if InStr(t, "this site can’t be reached") || InStr(t, "this site can" Chr(8217) "t be reached")
        return true
    if InStr(t, "server ip address could not be found")
        return true
    if InStr(t, "refused to connect")
        return true
    if InStr(t, "dns_probe")
        return true
    if InStr(t, "err_")
        return true
    if InStr(t, "timed out")
        return true
    if InStr(t, "problem loading")
        return true
    if (t = "error" || t = "tab crashed")
        return true
    return false
}

WaitTabLoadState(hwnd, tab, timeoutMs) {
    start := A_TickCount
    Loop {
        title := GetTitle(hwnd)

        if IsPrivacyError(title) {
            BypassPrivacyErrorIfPresent(hwnd)
            title := GetTitle(hwnd)
        }

        if IsChromeNetErrorTitle(title)
            return Map("State", "DOWN", "Title", title)

        s := GetState(title, tab)
        if (s = "LOGIN" || s = "LOGGED_IN")
            return Map("State", s, "Title", title)

        if (A_TickCount - start >= timeoutMs)
            return Map("State", "TIMEOUT", "Title", title)

        Sleep(200)
    }
}

CloseAllChrome() {
    Log("Closing Chrome")
    for hwnd in WinGetList("ahk_exe chrome.exe") {
        try WinClose("ahk_id " hwnd)
    }
    Sleep(900)

    Loop 25 {
        if !ProcessExist("chrome.exe")
            break
        try ProcessClose("chrome.exe")
        Sleep(200)
    }
}

LaunchChrome() {
    global CFG
    Log("Launching Chrome with profile")

    if !FileExist(CFG["ChromeExe"])
        throw Error("Chrome exe not found: " CFG["ChromeExe"])

    args := Format('--user-data-dir="{1}" --profile-directory="{2}" --new-window'
        , CFG["UserDataDir"], CFG["ProfileDirName"])

    Run(Format('"{1}" {2}', CFG["ChromeExe"], args))

    if !WinWait("ahk_exe chrome.exe",, 10)
        return 0

    hwnd := WinExist("ahk_exe chrome.exe")
    Log("Chrome hwnd=" hwnd)
    return hwnd
}

MoveToLeftMonitor(hwnd) {
    global CFG
    Log("Move Chrome to left monitor + maximize")
    WinMove(CFG["LeftMonX"], CFG["LeftMonY"], CFG["LeftMonW"], CFG["LeftMonH"], "ahk_id " hwnd)
    Sleep(250)
    WinMaximize("ahk_id " hwnd)
}

SwitchToTab(n, hwnd) {
    if (n < 1 || n > 9)
        return false
    try {
        WinActivate("ahk_id " hwnd)
        if !WinWaitActive("ahk_id " hwnd,, 2)
            return false
    } catch {
        return false
    }
    Send("^" n)
    return true
}

GetTitle(hwnd) {
    try {
        return WinGetTitle("ahk_id " hwnd)
    } catch {
        return ""
    }
}

FindChromeHwnd() {
    try {
        hwnd := WinExist("ahk_exe chrome.exe")
        if hwnd
            return hwnd
    }
    return 0
}

KillAutoFillPopups() {
    Send("{Esc}")
    Sleep(70)
    Send("{Esc}")
    Sleep(70)
}

ClearAndType(text) {
    Send("^a")
    Sleep(50)
    Send("{Backspace}")
    Sleep(50)
    SendText(text)
    Sleep(140)
}

Login(tab, hwnd) {
    global CFG, gAbort
    winSpec := "ahk_id " hwnd

    Loop CFG["MaxLoginAttempts"] {
        attempt := A_Index
        if gAbort
            return false

        try {
            WinActivate(winSpec)
            if !WinWaitActive(winSpec,, 2)
                return false
        } catch {
            return false
        }

        Sleep(150)

        Send("{Esc}")
        Sleep(80)
        Send("^{0}")
        Sleep(120)
        KillAutoFillPopups()

        if (tab["Mode"] = "KERIO") {
            Log("Kerio attempt " attempt "/" CFG["MaxLoginAttempts"] " (Enter on prefilled form)")
            ReactivateIfLost(winSpec)
            Send("{Enter}")
            Sleep(CFG["AfterSubmitMs"])
            Log("Kerio post-submit title=" GetTitle(hwnd))
            return true
        }

        Log("Login attempt " attempt "/" CFG["MaxLoginAttempts"] " (" tab["Name"] ")")

        if (tab["Mode"] = "GEN" || tab["Mode"] = "PRTG") {
            ReactivateIfLost(winSpec)
            ClearAndType(tab["User"])

            KillAutoFillPopups()
            Sleep(80)

            ReactivateIfLost(winSpec)
            Send("{Tab}")
            Sleep(180)
            KillAutoFillPopups()
            Sleep(80)

            ReactivateIfLost(winSpec)
            ClearAndType(tab["Pass"])
            KillAutoFillPopups()
            Sleep(80)

            ReactivateIfLost(winSpec)
            Send("{Enter}")
        } else {
            throw Error("Login(): unsupported mode: " tab["Mode"])
        }

        sleepAfter := CFG["AfterSubmitMs"]
        if (tab["Mode"] = "PRTG")
            sleepAfter += 900
        Sleep(sleepAfter)

        title := GetTitle(hwnd)

        if IsPaesslerRedirect(title) {
            Log("Redirected to Paessler -> Back + retry. Title=" title)
            ReactivateIfLost(winSpec)
            Send("!{Left}")
            Sleep(1100)
            continue
        }

        state := GetState(title, tab)
        Log("Post-submit state: " state " | title=" title)

        if (state = "LOGGED_IN")
            return true

        Sleep(CFG["BetweenRetriesMs"])
    }

    return false
}

LogWindowControls(winTitle) {
    hwnds := ""
    try {
        hwnds := WinGetControlsHwnd(winTitle)
    } catch as e {
        Log("LogWindowControls '" winTitle "' failed: " e.Message)
        return
    }
    Log("LogWindowControls '" winTitle "' (" hwnds.Length " controls)")
    for idx, cHwnd in hwnds {
        cCls := "?"
        cTxt := "?"
        try {
            cCls := ControlGetClassNN(cHwnd)
        } catch {
        }
        try {
            cTxt := SubStr(ControlGetText(cHwnd), 1, 60)
        } catch {
        }
        Log("  [" idx "] class=" cCls " text='" cTxt "'")
    }
}

TryClickButtonByText(winTitle, textPatterns) {
    hwnds := ""
    try {
        hwnds := WinGetControlsHwnd(winTitle)
    } catch {
        return ""
    }
    for _, cHwnd in hwnds {
        cCls := ""
        try {
            cCls := ControlGetClassNN(cHwnd)
        } catch {
            continue
        }
        if !InStr(cCls, "Button")
            continue
        cTxt := ""
        try {
            cTxt := ControlGetText(cHwnd)
        } catch {
            continue
        }
        for _, pat in textPatterns {
            if InStr(cTxt, pat) {
                try {
                    ControlClick(cHwnd, winTitle)
                    return cTxt
                } catch {
                    return ""
                }
            }
        }
    }
    return ""
}

EnsureExeFocused(exePath, winTitle, timeoutMs) {
    CheckAbort()
    CheckPause()

    hwnd := WinExist(winTitle)
    if !hwnd {
        SplitPath(exePath, &exeName)
        if (exeName != "") {
            hwnd := WinExist("ahk_exe " exeName)
            if hwnd
                Log("EnsureExeFocused: '" winTitle "' found by ahk_exe " exeName " (hwnd=" hwnd ")")
        }
    }

    if hwnd {
        try WinShow("ahk_id " hwnd)
        try WinRestore("ahk_id " hwnd)
        WinActivate("ahk_id " hwnd)
        WinWaitActive("ahk_id " hwnd, , timeoutMs/1000)
        return
    }

    Run('"' exePath '"')
    if !WinWait(winTitle, , timeoutMs/1000)
        throw Error("Window not found: " winTitle)
    WinActivate(winTitle)
    WinWaitActive(winTitle, , timeoutMs/1000)
}

EnsureWindowActive(winTitleOrAhk, timeoutSec := 5) {
    CheckAbort()
    CheckPause()
    if !WinExist(winTitleOrAhk)
        return false
    WinActivate(winTitleOrAhk)
    return !!WinWaitActive(winTitleOrAhk, , timeoutSec)
}

ReactivateIfLost(winTitleOrAhk, timeoutSec := 2) {
    if WinActive(winTitleOrAhk)
        return true
    if !WinExist(winTitleOrAhk)
        return false
    WinActivate(winTitleOrAhk)
    return !!WinWaitActive(winTitleOrAhk, , timeoutSec)
}

WaitForWindowText(winTitleOrAhk, phrase, timeoutMs) {
    start := A_TickCount
    while (A_TickCount - start < timeoutMs) {
        CheckAbort()
        CheckPause()
        if WinExist(winTitleOrAhk) {
            txt := WinGetText(winTitleOrAhk)
            if (txt != "" && InStr(txt, phrase))
                return true
        }
        Sleep(150)
    }
    return false
}

VpnCliState() {
    global CFG
    cli := CFG["AnyConnectCli"]
    if !FileExist(cli)
        return "Unknown"

    tmp := A_Temp "\vpn_state_" A_TickCount ".txt"
    try FileDelete(tmp)
    cmd := A_ComSpec ' /c ""' cli '" state" > "' tmp '" 2>&1'
    try {
        RunWait(cmd, , "Hide")
    } catch as e {
        return "Unknown"
    }

    txt := ""
    try txt := FileRead(tmp)
    try FileDelete(tmp)
    if (txt = "")
        return "Unknown"

    if RegExMatch(txt, "i)state:\s*Connected")
        return "Connected"
    if RegExMatch(txt, "i)state:\s*(Disconnect|Connecting|Reconnecting)")
        return "Disconnected"
    return "Unknown"
}

IsVpnAlreadyUp() {
    global CFG
    if (VpnCliState() != "Connected")
        return false
    return WaitForVPNConnected(2500, CFG["VPN_WaitHost"])
}

WaitForVPNConnected(timeoutMs := 45000, host := "") {
    global CFG
    if (host = "")
        host := CFG["VPN_WaitHost"]

    start := A_TickCount
    Loop {
        CheckAbort()
        CheckPause()

        rc := RunWait('cmd.exe /c ping -n 1 -w 800 ' host ' >nul', , "Hide")
        if (rc = 0)
            return true

        if (A_TickCount - start > timeoutMs)
            return false

        WaitWithControl(700)
    }
}

Retry(fn, maxTries, delayMs, failMsg) {
    lastErr := ""
    Loop maxTries {
        CheckAbort()
        CheckPause()
        try {
            fn.Call()
            return true
        } catch as e {
            lastErr := e.Message
            WaitWithControl(delayMs)
        }
    }
    throw Error(failMsg " | last error: " lastErr)
}

PickRandom(arr) {
    return arr[Random(1, arr.Length)]
}

EnsureLogDir() {
    global CFG
    if !DirExist(CFG["LogDir"])
        DirCreate(CFG["LogDir"])
}

Log(msg) {
    global CFG
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(ts " | " msg "`r`n", CFG["LogFile"], "UTF-8")
}

Calibrate() {
    EnsureLogDir()
    CoordMode("Mouse", "Window")
    MouseGetPos(&mx, &my, &hwnd)
    title := GetTitle(hwnd)
    Log("CALIBRATE X=" mx " Y=" my " | " title)
    A_Clipboard := mx ", " my
    TrayTip("Calibration", "Copied: " mx ", " my, 2)
}

CredReadGenericPassword(targetName) {
    pCred := 0
    ok := DllCall("Advapi32\CredReadW"
        , "WStr", targetName
        , "UInt", 1
        , "UInt", 0
        , "PtrP", &pCred
        , "Int")

    if !ok || !pCred
        return ""

    try {
        if (A_PtrSize = 8) {
            offBlobSize := 32
            offBlobPtr  := 40
        } else {
            offBlobSize := 24
            offBlobPtr  := 28
        }

        blobSize := NumGet(pCred, offBlobSize, "UInt")
        blobPtr  := NumGet(pCred, offBlobPtr, "Ptr")
        if (blobSize = 0 || !blobPtr)
            return ""

        chars := blobSize // 2
        pw := StrGet(blobPtr, chars, "UTF-16")
        pw := RTrim(pw, Chr(0))

        if (pw = "") {
            pw := StrGet(blobPtr, blobSize, "UTF-8")
            pw := RTrim(pw, Chr(0))
        }
        return pw
    } finally {
        DllCall("Advapi32\CredFree", "Ptr", pCred)
    }
}
