param(
    [switch]$Probe
)

$ErrorActionPreference = "Stop"
$cli = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"

function Invoke-Vpncli([string]$verb, [int]$sec = 20) {
    $o = "$env:TEMP\vd_o.txt"; $e = "$env:TEMP\vd_e.txt"
    $pp = Start-Process -FilePath $cli -ArgumentList $verb -NoNewWindow -PassThru `
          -RedirectStandardOutput $o -RedirectStandardError $e
    if (-not $pp.WaitForExit($sec * 1000)) { try { $pp.Kill() } catch {} }
    return ((Get-Content $o -Raw) + "`n" + (Get-Content $e -Raw))
}

if (Test-Path $cli) {
    $out = Invoke-Vpncli "disconnect" 20
    if ($Probe) { Write-Host "----- vpncli disconnect -----"; Write-Host $out }
} else {
    Write-Host "vpncli not found at $cli, skipping graceful disconnect"
}

Start-Sleep -Milliseconds 1000

foreach ($name in @('vpnui', 'vpncli')) {
    $procs = @(Get-Process -Name $name -ErrorAction SilentlyContinue)
    if ($procs.Count -gt 0) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        if ($Probe) { Write-Host "closed $name.exe ($($procs.Count) instance(s))" }
    }
}

if ($Probe -and (Test-Path $cli)) {
    Start-Sleep -Milliseconds 500
    $state = Invoke-Vpncli "state" 15
    Write-Host "----- vpncli state -----"; Write-Host $state
}

Write-Host "RESULT: DISCONNECTED"
exit 0
