#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

global CFG := Map(
    "LogFile",       A_MyDocuments "\automation_shutdown_log.txt",

    "ChromeExe",         "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "ChromeProfileDir",  "Profile 1",
    "AfterChromeClose",  1200,

    "ChromeTargetMonX1", -2560,
    "ChromeTargetMonY1", 0,
    "ChromeTargetMonX2", -1,
    "ChromeTargetMonY2", 1440,

    "AnyConnectExe", "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe",
    "AnyConnectWin", "Cisco AnyConnect Secure Mobility Client",
    "VpnDisconnectPs1", A_ScriptDir "\VpnDisconnect.ps1",
    "AfterVPNQuit",  1000,

    "EyeBeamExe",    "C:\Program Files (x86)\CounterPath\eyeBeam 1.5\eyeBeam.exe",
    "EyeBeamWin",    "eyeBeam",
    "AfterEyeBeamQuit", 800,

    "WhatsAppAppID",     "5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App",
    "WhatsAppWinTitle",  "WhatsApp",
    "ChatName",          "Team Shift",
    "MsgPool",           ["YOUR-MESSAGE-HERE"],

    "WA_WindowWaitMs",     30000,
    "WA_LaunchAttempts",   2,
    "WA_PreSearchDelayMs", 7000,
    "WA_PostOpenChatDelayMs", 1000,
    "WA_PreCloseDelayMs",     700,

    "WA_SearchBoxName",    "Search or start a new chat",
    "WA_ComposeBoxName",   "Type a message",
    "WA_LoadTimeoutMs",    25000,
    "WA_ClickSettleMs",    450,
    "WA_SearchFilterMs",   1500,
    "WA_OpenSettleMs",     1600,

    "WA_VerifyChatHeader", true,
    "WA_VerifyStrict",     true,

    "RDPWinTitle", "Remote Desktop Connection",
    "AfterRDPClose", 800,

    "WinWaitMs",        20000,
    "ShortWaitMs",      5000,
    "ResultToastSecs",  6
)

SendMode("Input")
SetKeyDelay(-1, -1)

global gCancel := false
global gRunInProgress := false

Esc::CancelShutdown()
F9::RunShutdown()
F7::TestWhatsApp()

TrayTip("Shutdown automation", "Starting in 3 seconds...`nPress ESC to cancel", 3)

Loop 30 {
    if gCancel {
        TrayTip("Shutdown automation", "Cancelled. Press F9 to run manually.", 3)
        return
    }
    Sleep(100)
}

RunShutdown()
return

RunShutdown() {
    global CFG, gRunInProgress

    if gRunInProgress {
        TrayTip("Shutdown automation", "Shutdown already running...", 2)
        return
    }

    gRunInProgress := true

    try {
        Log("===== SHUTDOWN RUN START =====")

        Step_CloseChromeLeftMonitor()
        Step_ExitEyeBeam()
        Step_CloseRDP()
        Step_QuitAnyConnect()
        Step_WhatsApp_SendAndClose()

        Log("===== SHUTDOWN RUN OK =====")
        TrayTip("Shutdown Automation", "Done ✅", 5)
        SetTimer(() => ExitApp(), -(CFG["ResultToastSecs"] * 1000 + 500))
    } catch as e {
        Log("!!! FAILED: " e.Message)
        TrayTip("Shutdown Automation FAILED", e.Message, 8)
        gRunInProgress := false
    }
}

TestWhatsApp() {
    global gRunInProgress

    if gRunInProgress {
        TrayTip("Shutdown automation", "Shutdown already running...", 2)
        return
    }

    gRunInProgress := true

    try {
        Log("===== WHATSAPP TEST (F7) =====")
        Step_WhatsApp_SendAndClose()
        Log("===== WHATSAPP TEST OK =====")
        TrayTip("Shutdown Automation", "WhatsApp test done ✅", 4)
    } catch as e {
        Log("!!! WHATSAPP TEST FAILED: " e.Message)
        TrayTip("Shutdown Automation FAILED", e.Message, 8)
    } finally {
        gRunInProgress := false
    }
}

Step_CloseChromeLeftMonitor() {
    global CFG
    Log("Step: Chrome - close windows on target monitor only")

    closedAny := false
    hwndList := WinGetList("ahk_exe chrome.exe")

    for hwnd in hwndList {
        try {
            wp := Buffer(44, 0)
            NumPut("UInt", 44, wp, 0)
            DllCall("GetWindowPlacement", "Ptr", hwnd, "Ptr", wp)

            left   := NumGet(wp, 28, "Int")
            top    := NumGet(wp, 32, "Int")
            right  := NumGet(wp, 36, "Int")
            bottom := NumGet(wp, 40, "Int")

            cx := left + ((right - left) // 2)
            cy := top + ((bottom - top) // 2)

            if (cx >= CFG["ChromeTargetMonX1"]
             && cx <= CFG["ChromeTargetMonX2"]
             && cy >= CFG["ChromeTargetMonY1"]
             && cy <= CFG["ChromeTargetMonY2"]) {

                WinClose("ahk_id " hwnd)
                Log("Chrome: WinClose hwnd=" hwnd " centerX=" cx " centerY=" cy)
                closedAny := true
            }
        } catch as e {
            Log("Chrome: target-monitor close failed hwnd=" hwnd " | " e.Message)
        }
    }

    Sleep(CFG["AfterChromeClose"])

    if !closedAny
        Log("Step: Chrome - no target-monitor Chrome windows found")
    else
        Log("Step: Chrome - target-monitor close done")
}

Step_ExitEyeBeam() {
    global CFG
    Log("Step: eyeBeam - exit")

    if WinExist(CFG["EyeBeamWin"]) {
        WinActivate(CFG["EyeBeamWin"])
        WinWaitActive(CFG["EyeBeamWin"], , CFG["ShortWaitMs"]/1000)
        Send("!{F4}")
        Sleep(CFG["AfterEyeBeamQuit"])
    }

    if ProcessExist("eyeBeam.exe") {
        try {
            ProcessClose("eyeBeam.exe")
            Log("eyeBeam: ProcessClose eyeBeam.exe")
        } catch as e {
            Log("eyeBeam: ProcessClose failed | " e.Message)
        }
        Sleep(400)
    }

    Log("Step: eyeBeam - exit done")
}

Step_CloseRDP() {
    global CFG
    Log("Step: RDP - close window only")

    closedAny := false

    hwndList := WinGetList("ahk_exe mstsc.exe")
    for hwnd in hwndList {
        try {
            WinActivate("ahk_id " hwnd)
            WinWaitActive("ahk_id " hwnd, , 2)
            WinClose("ahk_id " hwnd)
            Log("RDP: WinClose hwnd=" hwnd)
            closedAny := true
        } catch as e {
            Log("RDP: WinClose failed hwnd=" hwnd " | " e.Message)
        }
    }

    Sleep(CFG["AfterRDPClose"])

    if !closedAny && WinExist(CFG["RDPWinTitle"]) {
        try {
            WinActivate(CFG["RDPWinTitle"])
            WinWaitActive(CFG["RDPWinTitle"], , 2)
            WinClose(CFG["RDPWinTitle"])
            Log("RDP: WinClose by title")
            closedAny := true
        } catch as e {
            Log("RDP: WinClose by title failed | " e.Message)
        }
        Sleep(400)
    }

    if !closedAny
        Log("RDP: no open mstsc window found")

    Log("Step: RDP - close done")
}

Step_QuitAnyConnect() {
    global CFG
    Log("Step: AnyConnect - disconnect + quit (vpncli)")

    if FileExist(CFG["VpnDisconnectPs1"]) {
        tmp := A_Temp "\vpndisconnect_shutdown_out.txt"
        try FileDelete(tmp)
        psCmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' CFG["VpnDisconnectPs1"] '"'
        fullCmd := A_ComSpec ' /c ' psCmd ' > "' tmp '" 2>&1'
        exitCode := -1
        try {
            exitCode := RunWait(fullCmd, , "Hide")
        } catch as e {
            Log("AnyConnect: VpnDisconnect.ps1 launch failed | " e.Message)
        }
        try {
            if FileExist(tmp)
                for _, line in StrSplit(FileRead(tmp), "`n", "`r")
                    if (Trim(line) != "")
                        Log("  [vpndisc] " line)
        }
        Log("AnyConnect: VpnDisconnect.ps1 exit=" exitCode)
    } else {
        Log("AnyConnect: VpnDisconnect.ps1 not found at " CFG["VpnDisconnectPs1"] ", GUI/process cleanup only")
    }

    if ProcessExist("vpnui.exe") {
        try {
            ProcessClose("vpnui.exe")
            Log("AnyConnect: ProcessClose vpnui.exe")
        } catch as e {
            Log("AnyConnect: ProcessClose failed | " e.Message)
        }
        Sleep(CFG["AfterVPNQuit"])
    }

    Log("Step: AnyConnect - disconnect + quit done")
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

    Sleep(CFG["WA_PostOpenChatDelayMs"])

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
    Sleep(CFG["WA_PreCloseDelayMs"])
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
    CoordMode("Mouse", "Window")

    Log("WhatsApp: readiness wait START")
    start := A_TickCount
    pass := 0

    while (A_TickCount - start < 15000) {
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

    Log("WhatsApp: readiness wait timed out (continuing)")
    return false
}

WhatsApp_WaitResponsive(hwnd, maxWaitMs, coldStart := false) {
    if coldStart {
        Log("WhatsApp: cold start - sleeping full " maxWaitMs " ms (WM_NULL probe unreliable pre-paint)")
        Sleep(maxWaitMs)
        return true
    }

    Log("WhatsApp: wait-responsive START (warm, cap " maxWaitMs " ms)")
    start := A_TickCount

    loop {
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

PickRandom(arr) {
    return arr[Random(1, arr.Length)]
}

Log(msg) {
    global CFG
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(ts " | " msg "`r`n", CFG["LogFile"], "UTF-8")
}

CancelShutdown() {
    global gCancel
    gCancel := true
}
