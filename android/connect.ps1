# Windows -> USB ADB -> Termux/socat -> Control Hub Wi-Fi.
# Prerequisites: Termux is installed, socat is installed, and USB debugging is authorized.
param([string]$PhoneSerial)

$adb = (Get-Command adb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
if (-not $adb) { $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" }
if (-not (Test-Path $adb)) { throw 'ADB not found. Install Android SDK Platform-Tools.' }

if (-not $PhoneSerial) {
    $phones = @(& $adb devices | Where-Object { $_ -match '\s+device\s*$' } |
        ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ -notmatch ':\d+$' })
    if ($phones.Count -ne 1) { throw 'Connect one authorized USB phone, or use -PhoneSerial SERIAL.' }
    $PhoneSerial = $phones[0]
}

# ADB's USB forward talks to a TCP listener inside the phone's network namespace.
& $adb -s $PhoneSerial forward tcp:15555 tcp:15555 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'USB port forwarding failed.' }

function TryRobot {
    & $adb disconnect 127.0.0.1:15555 2>$null | Out-Null
    & $adb connect 127.0.0.1:15555 2>&1 | Out-Null
    $state = (& $adb -s 127.0.0.1:15555 get-state 2>$null | Out-String).Trim()
    return ($state -eq 'device')
}

# Don't type into Termux if a relay is already serving connections.
if (-not (TryRobot)) {
    & $adb -s $PhoneSerial shell am start -n com.termux/.app.TermuxActivity | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Termux could not be opened.' }
    Start-Sleep -Seconds 2
    & $adb -s $PhoneSerial shell input text 'socat%sTCP-LISTEN:15555,bind=127.0.0.1,reuseaddr,fork%sTCP:192.168.43.1:5555'
    if ($LASTEXITCODE -ne 0) { throw 'Could not type the socat command into Termux.' }
    & $adb -s $PhoneSerial shell input keyevent 66
    if ($LASTEXITCODE -ne 0) { throw 'Could not press Enter in Termux.' }

    $connected = $false
    for ($i = 0; $i -lt 5; $i++) {
        Start-Sleep -Seconds 1
        if (TryRobot) { $connected = $true; break }
    }
    if (-not $connected) {
        throw 'Robot not connected. Check that Termux shows socat running and the phone is on Control Hub Wi-Fi.'
    }
}
Write-Host 'Control Hub connected at 127.0.0.1:15555. Select it in Android Studio.'
