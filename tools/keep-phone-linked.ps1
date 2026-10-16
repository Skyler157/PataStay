# Keeps a USB-connected Android phone linked to the local Supabase backend.
# `adb reverse` is dropped whenever the USB connection blips; this re-applies it.
# Usage (leave the window open while testing):
#   powershell -ExecutionPolicy Bypass -File tools\keep-phone-linked.ps1
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$port = 54321
Write-Host "Keeping phone linked to local backend on port $port. Press Ctrl+C to stop."
while ($true) {
  $devices = & $adb devices | Select-String "\tdevice$" | ForEach-Object { ($_ -split "\t")[0] }
  foreach ($id in $devices) {
    $current = & $adb -s $id reverse --list 2>$null
    if (-not ($current -match "tcp:$port")) {
      & $adb -s $id reverse "tcp:$port" "tcp:$port" | Out-Null
      Write-Host "$(Get-Date -Format HH:mm:ss) linked $id"
    }
  }
  Start-Sleep -Seconds 3
}
