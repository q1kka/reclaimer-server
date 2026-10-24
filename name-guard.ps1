# Kicks players whose name matches name-filter.txt, through the server's remote console (RCON).
# Run it in a second PowerShell window while the server runs:
#   .\name-guard.ps1
# Check names without kicking anyone:
#   .\name-guard.ps1 -Test "Good Name", "n1gg3r"
# Needs an RCON password in the server's dedicated.toml; setup-windows.ps1 sets one up.
param(
    [string]$ServerDir = "C:\reclaimer",
    [string]$WordList = (Join-Path $PSScriptRoot "name-filter.txt"),
    [int]$IntervalSeconds = 5,
    [string]$Reason = "Offensive name. Change your name and rejoin.",
    # Only needed when several servers in dedicated.toml have RCON.
    [string]$Server = "",
    [string[]]$Test
)
$ErrorActionPreference = "Stop"

# Characters players use in place of a letter.
$Leet = @{
    a = "a4@"; b = "b8"; e = "e3"; g = "g69"; i = "i1!|l"; l = "l1|i"
    o = "o0"; s = "s5`$z"; t = "t7+"; z = "z2"
}
# Cyrillic letters that look like Latin ones.
$Lookalikes = @{
    ([char]0x0430) = "a"; ([char]0x0435) = "e"; ([char]0x043E) = "o"; ([char]0x0440) = "p"; ([char]0x0441) = "c"
    ([char]0x0456) = "i"; ([char]0x0443) = "y"; ([char]0x0445) = "x"; ([char]0x043A) = "k"; ([char]0x0455) = "s"
}

function ConvertTo-Pattern([string]$Word) {
    $parts = foreach ($ch in $Word.ToLowerInvariant().ToCharArray()) {
        $c = [string]$ch
        if ($Leet.ContainsKey($c)) { "[" + [regex]::Escape($Leet[$c]) + "]+" }
        else { [regex]::Escape($c) + "+" }
    }
    -join $parts
}

function Read-WordList([string]$Path) {
    foreach ($line in Get-Content $Path) {
        $entry = $line.Trim()
        if ($entry -eq "" -or $entry.StartsWith("#")) { continue }
        $whole = $entry.StartsWith("=")
        $word = $entry.TrimStart("=")
        $pattern = ConvertTo-Pattern $word
        if ($whole) { $pattern = "(?<![a-z0-9])$pattern(?![a-z0-9])" }
        [pscustomobject]@{ Entry = $entry; Whole = $whole; Regex = [regex]::new($pattern) }
    }
}

# Lowercase, strip accents, map lookalikes. Returns the name squeezed together (for "word"
# entries) and with separators as spaces (for "=word" entries).
function Get-NameForms([string]$Name) {
    $decomposed = $Name.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormD)
    $chars = foreach ($ch in $decomposed.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -eq "NonSpacingMark") { continue }
        if ($Lookalikes.ContainsKey($ch)) { $Lookalikes[$ch] } else { [string]$ch }
    }
    $clean = -join $chars
    [pscustomobject]@{
        Squeezed = $clean -replace '[^a-z0-9@$!|+]', ''
        Spaced   = $clean -replace '[^a-z0-9@$!|+]', ' '
    }
}

function Find-BadWord([string]$Name, $Rules) {
    $forms = Get-NameForms $Name
    foreach ($rule in $Rules) {
        $text = if ($rule.Whole) { $forms.Spaced } else { $forms.Squeezed }
        if ($rule.Regex.IsMatch($text)) { return $rule.Entry }
    }
    $null
}

function Write-Log([string]$Message) {
    $line = "{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $Message
    Write-Host $line
    if (Test-Path $ServerDir) { Add-Content -Path (Join-Path $ServerDir "name-guard.log") -Value $line }
}

$rules = @(Read-WordList $WordList)

if ($Test) {
    foreach ($name in $Test) {
        $hit = Find-BadWord $name $rules
        if ($hit) { Write-Host ("KICK  {0,-20} matches '{1}'" -f $name, $hit) }
        else { Write-Host ("ok    {0}" -f $name) }
    }
    return
}

$exe = Join-Path $ServerDir "project-reclaimer.exe"
if (-not (Test-Path $exe)) { throw "No $exe. Run setup-windows.ps1 first, or pass -ServerDir." }

function Invoke-Rcon([string[]]$RconArgs) {
    $all = @("dedicated", "rcon")
    if ($Server) { $all += @("--server", $Server) }
    $all += $RconArgs
    # Windows PowerShell turns a native command's stderr into errors; collect it as text instead.
    $ErrorActionPreference = "Continue"
    Push-Location $ServerDir
    try {
        $raw = @(& $exe @all 2>&1)
        $stdout = $raw | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] } | ForEach-Object { "$_" }
        [pscustomobject]@{
            Ok   = ($LASTEXITCODE -eq 0)
            Out  = ($stdout -join "`n")
            Text = (($raw | ForEach-Object { "$_" }) -join "`n")
        }
    } finally { Pop-Location }
}

function Get-Players {
    $reply = Invoke-Rcon @("--json", "players")
    if (-not $reply.Ok) { throw $reply.Text }
    $data = $reply.Out | ConvertFrom-Json
    if ($data -is [array]) { return $data }
    if ($data.players) { return $data.players }
    if ($data.data.players) { return $data.data.players }
    @()
}

Write-Log "name-guard watching $ServerDir every $IntervalSeconds s, $($rules.Count) entries in $WordList"
$listTime = (Get-Item $WordList).LastWriteTime
$kicked = @{}
$lastError = ""

while ($true) {
    $time = (Get-Item $WordList).LastWriteTime
    if ($time -ne $listTime) {
        $rules = @(Read-WordList $WordList)
        $listTime = $time
        Write-Log "Reloaded word list: $($rules.Count) entries"
    }

    try {
        $players = Get-Players
        if ($lastError) { Write-Log "Connected to the server again"; $lastError = "" }
        foreach ($p in $players) {
            if ($p.admin -eq $true) { continue }
            $hit = Find-BadWord ([string]$p.name) $rules
            if (-not $hit) { continue }

            $id = if ($p.id) { $p.id } else { $p.player_id }
            $target = if ($null -ne $p.number) { "#$($p.number)" } else { $id }
            $key = "$id|$($p.name)"
            if ($kicked.ContainsKey($key) -and ((Get-Date) - $kicked[$key]).TotalSeconds -lt 60) { continue }
            $kicked[$key] = Get-Date

            $reply = Invoke-Rcon @("kick", $target, $Reason)
            if ($reply.Ok) { Write-Log "Kicked '$($p.name)' ($id), matched '$hit'" }
            else { Write-Log "Kick of '$($p.name)' failed: $($reply.Text)" }
        }
    } catch {
        $msg = "$_"
        if ($msg -ne $lastError) {
            Write-Log "Can't read players (server not running, or no RCON password?): $msg"
            $lastError = $msg
        }
    }
    Start-Sleep -Seconds $IntervalSeconds
}
