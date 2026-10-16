# Builds the PataStay mobile app for the web and opens it in a phone-sized
# Chrome window - for testing without a phone. Docker Desktop (local Supabase)
# must be running.
#   powershell -ExecutionPolicy Bypass -File tools\run-web.ps1            # build + open
#   powershell -ExecutionPolicy Bypass -File tools\run-web.ps1 -NoBuild   # reopen last build
param([switch]$NoBuild, [int]$Port = 8090)

$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root 'apps\mobile'
$flutter = Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'

if (-not $NoBuild) {
  Push-Location $mobile
  & $flutter build web --release --dart-define-from-file=../../env/dev.json
  if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error 'Web build failed.'; exit 1 }
  Pop-Location
}

$web = Join-Path $mobile 'build\web'
$server = Start-Process python -ArgumentList '-m', 'http.server', $Port, '--bind', '127.0.0.1', '--directory', $web -PassThru -WindowStyle Minimized
Start-Sleep 2
Start-Process 'C:\Program Files\Google\Chrome\Application\chrome.exe' -ArgumentList "--app=http://localhost:$Port", '--window-size=430,932', '--new-window'
Write-Host "PataStay is running at http://localhost:$Port. Press Enter to stop the server."
Read-Host | Out-Null
Stop-Process -Id $server.Id -ErrorAction SilentlyContinue
