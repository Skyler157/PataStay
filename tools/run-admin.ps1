# Runs the PataStay admin dashboard in Chrome at http://localhost:5050.
#   .\admin            # against the local database (starts Supabase in Docker)
#   .\admin -Live      # against the live database - changes real data
# While it runs: r = reload after a code change, R = restart, q = quit.
param([switch]$Live, [int]$Port = 5050)

$root = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'
$supabase = Join-Path $env:USERPROFILE '.local\bin\supabase-cli\supabase.exe'

if ($Live) {
  $envFile = '../../env/admin.prod.json'
  Write-Host 'Using the LIVE database. Approvals and deletions are real.' -ForegroundColor Yellow
} else {
  $envFile = '../../env/dev.json'
  # The local database runs in Docker; open Docker Desktop if it isn't running.
  docker info *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'Starting Docker Desktop...'
    Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
    $deadline = (Get-Date).AddMinutes(3)
    do {
      Start-Sleep 5
      docker info *> $null
    } until ($LASTEXITCODE -eq 0 -or (Get-Date) -gt $deadline)
    if ($LASTEXITCODE -ne 0) { Write-Error 'Docker Desktop did not start. Open it yourself, then run .\admin again.'; exit 1 }
  }
  Write-Host 'Starting the local database...'
  Push-Location $root
  & $supabase start | Out-Null
  $started = $LASTEXITCODE -eq 0
  Pop-Location
  if (-not $started) { Write-Error 'Local Supabase did not start. Is Docker Desktop running?'; exit 1 }
}

Push-Location (Join-Path $root 'apps\admin')
& $flutter run -d chrome --web-port $Port "--dart-define-from-file=$envFile"
Pop-Location
