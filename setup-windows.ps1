# Sets up a Project Reclaimer dedicated server on the Windows PC you also play on.
# Run in an *administrator* PowerShell from the folder holding this script, dedicated.toml and playlists\:
#   powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 -ExePath "C:\Games\Reclaimer\project-reclaimer.exe"
param(
    # The full client exe (it includes the dedicated server). Keep this copy separate from the one you play with.
    [Parameter(Mandatory = $true)][string]$ExePath,
    [string]$ServerDir = "C:\reclaimer",
    [int]$GamePort = 49176,
    [int]$MasterPort = 49175
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

# 1. Create the server folder and copy Halo 3 MP files from your own Steam MCC install.
if (-not (Test-Path (Join-Path $ServerDir "dedicated.toml"))) {
    & $ExePath dedicated init $ServerDir --from
}

# 2. A separate copy of the exe for the server, so the client you play with stays untouched.
Copy-Item $ExePath (Join-Path $ServerDir "project-reclaimer.exe") -Force

# 3. Put our config in place, keeping the generated one as a backup.
$toml = Join-Path $ServerDir "dedicated.toml"
if (Test-Path $toml) { Copy-Item $toml "$toml.generated.bak" -Force }
Copy-Item (Join-Path $here "dedicated.toml") $toml -Force
New-Item -ItemType Directory -Force (Join-Path $ServerDir "playlists") | Out-Null
Copy-Item (Join-Path $here "playlists\*.json") (Join-Path $ServerDir "playlists") -Force
$modes = Join-Path $ServerDir "content\Game Modes"
New-Item -ItemType Directory -Force $modes | Out-Null
Copy-Item (Join-Path $here "game-modes\*.json") $modes -Force

# 4. Firewall: UDP game port + TCP discovery master.
if (-not (Get-NetFirewallRule -DisplayName "Reclaimer game UDP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Reclaimer game UDP" -Direction Inbound -Protocol UDP -LocalPort $GamePort -Action Allow | Out-Null
}
if (-not (Get-NetFirewallRule -DisplayName "Reclaimer master TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Reclaimer master TCP" -Direction Inbound -Protocol TCP -LocalPort $MasterPort -Action Allow | Out-Null
}

# 5. Validate files, map/game names and ports.
Push-Location $ServerDir
try {
    & .\project-reclaimer.exe dedicated content
    Get-ChildItem $modes -Filter *.json | ForEach-Object { & .\project-reclaimer.exe mode-check $_.FullName }
    & .\project-reclaimer.exe dedicated check
} finally { Pop-Location }

Write-Host ""
Write-Host "Start the server:  cd $ServerDir; .\project-reclaimer.exe dedicated"
Write-Host "Then launch your normal client and join from the Server Browser."
