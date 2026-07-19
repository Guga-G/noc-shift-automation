param(
    [string]$VpnHost    = "vpn.example.com",
    [string]$CredTarget = "vpn.example.com",
    [string]$Group      = "",
    [int]   $TimeoutSec = 60,
    [switch]$Probe,
    [switch]$RelaunchGui
)

$ErrorActionPreference = "Stop"
$cli    = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"
$vpnui  = Join-Path (Split-Path $cli) 'vpnui.exe'
$driver = Join-Path $PSScriptRoot 'VpnDriver.ps1'
$dlog   = Join-Path $PSScriptRoot 'vpndriver.log'

function Invoke-Vpncli([string]$verb, [int]$sec = 20) {
    $o = "$env:TEMP\vc1_o.txt"; $e = "$env:TEMP\vc1_e.txt"
    $pp = Start-Process -FilePath $cli -ArgumentList $verb -NoNewWindow -PassThru `
          -RedirectStandardOutput $o -RedirectStandardError $e
    if (-not $pp.WaitForExit($sec * 1000)) { try { $pp.Kill() } catch {} }
    return ((Get-Content $o -Raw) + "`n" + (Get-Content $e -Raw))
}

function Ensure-VpnAgent {
    $svc = Get-Service -Name vpnagent -ErrorAction SilentlyContinue
    if (-not $svc) { return }
    if ($svc.Status -ne 'Running') {
        if ($Probe) { Write-Host "vpnagent is $($svc.Status), starting it" }
        try { Start-Service vpnagent -ErrorAction Stop; Start-Sleep -Milliseconds 1000 }
        catch { if ($Probe) { Write-Host "Start vpnagent failed: $_" } }
    }
}
function Reset-VpnAgent {
    if (-not (Get-Service -Name vpnagent -ErrorAction SilentlyContinue)) { return }
    if ($Probe) { Write-Host "restarting vpnagent to clear a possibly-wedged state" }
    try { Restart-Service -Name vpnagent -Force -ErrorAction Stop; Start-Sleep -Milliseconds 1500 }
    catch { if ($Probe) { Write-Host "Reset vpnagent failed (needs elevation?): $_" } }
}

if (-not (Test-Path $driver)) { Write-Host "VpnDriver.ps1 not found at $driver"; exit 4 }

Ensure-VpnAgent

$gui = @(Get-Process vpnui -ErrorAction SilentlyContinue)
if ($gui.Count -gt 0) {
    $gui | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 900
    if ($Probe) { Write-Host "closed vpnui.exe ($($gui.Count) instance(s))" }
}

[void](Invoke-Vpncli "disconnect" 20)
Start-Sleep -Milliseconds 1200
if (Test-Path $dlog) { Remove-Item $dlog -Force -ErrorAction SilentlyContinue }

$vpn = Start-Process -FilePath $cli -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 800
if ($Probe) { Write-Host "launched interactive vpncli (pid $($vpn.Id))" }

$dArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $driver,
           '-TargetPid', [string]$vpn.Id, '-VpnHost', $VpnHost, '-CredTarget', $CredTarget,
           '-TimeoutSec', [string]$TimeoutSec, '-LogFile', $dlog)
if ($Group -ne "") { $dArgs += @('-Group', $Group) }
$drv = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList $dArgs
if (-not $drv.WaitForExit(($TimeoutSec + 8) * 1000)) { try { $drv.Kill() } catch {} }
$drvExit = 1; try { $drvExit = $drv.ExitCode } catch {}

try {
    if (-not $vpn.HasExited) {
        if (-not $vpn.WaitForExit(3000)) { $vpn.Kill() }
    }
} catch {}

$connected = ($drvExit -eq 0)

if (-not $connected) { Reset-VpnAgent }

if ($connected -and $RelaunchGui) { try { Start-Process $vpnui -WindowStyle Minimized } catch {} }

if ($Probe) {
    Write-Host "===== VpnDriver log ====="
    if (Test-Path $dlog) { Get-Content $dlog | ForEach-Object { Write-Host $_ } }
    Write-Host "===== end ====="
    Write-Host "driverExit=$drvExit  connected=$connected"
}

if ($connected) { Write-Host "RESULT: CONNECTED"; exit 0 }
Write-Host "RESULT: NOT CONNECTED (driver exit $drvExit)"
exit 3
