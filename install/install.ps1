# JD Plain Dark installer (Windows)
# Recommended: double-click install.bat. Or right-click this file > Run with PowerShell.
# Manual:      powershell -ExecutionPolicy Bypass -File install.ps1 [-JdDir "C:\path\to\JDownloader"]
param([string]$JdDir = "", [switch]$NoPause)
$ErrorActionPreference = "Stop"

function Hold {
  if ($NoPause) { return }
  try { if ($Host.UI.RawUI) { Read-Host "`nPress Enter to close" | Out-Null } } catch {}
}

$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src  = Join-Path $here "theme\cfg\laf\FlatDarkLaf.json"
if (-not (Test-Path $src)) {
  Write-Host "ERROR: $src not found. Run this from the unzipped release folder."
  Hold; exit 1
}

# JDownloader rewrites its cfg\*.json on shutdown, so anything written while it is
# running is thrown away the moment the user closes it.
if (Get-Process -Name "JDownloader*" -ErrorAction SilentlyContinue) {
  Write-Host "WARNING: JDownloader seems to be running. It rewrites its settings when it"
  Write-Host "         closes, which would undo this install. Close JDownloader first."
  if (-not $NoPause) {
    $go = Read-Host "Continue anyway? [y/N]"
    if ($go -notmatch '^(y|yes|j|ja)$') { Write-Host "Cancelled - nothing changed."; Hold; exit 1 }
  }
}

# Auto-detect the JDownloader folder (the one that contains 'cfg').
if (-not $JdDir) {
  $cands = @(
    "C:\Program Files\JDownloader",
    "C:\Program Files\JDownloader 2",
    "C:\Program Files\JDownloader 2.0",
    "C:\Program Files (x86)\JDownloader",
    "C:\Program Files (x86)\JDownloader 2",
    "C:\Program Files (x86)\JDownloader 2.0",
    "$env:LOCALAPPDATA\JDownloader",
    "$env:LOCALAPPDATA\JDownloader 2",
    "$env:LOCALAPPDATA\JDownloader 2.0",
    "$env:APPDATA\JDownloader",
    "$env:APPDATA\JDownloader 2",
    "$env:APPDATA\JDownloader 2.0",
    "$env:USERPROFILE\JDownloader",
    "$env:USERPROFILE\JDownloader 2",
    "$env:USERPROFILE\JDownloader 2.0"
  )
  foreach ($c in $cands) { if ($c -and (Test-Path (Join-Path $c "cfg"))) { $JdDir = $c; break } }
}

# Interactive fallback - never fail silently.
while (-not $JdDir -or -not (Test-Path (Join-Path $JdDir "cfg"))) {
  Write-Host "Could not auto-detect JDownloader."
  $JdDir = Read-Host "Enter your JDownloader folder (the one that contains 'cfg'), or leave empty to cancel"
  if (-not $JdDir) { Write-Host "Cancelled - nothing changed."; Hold; exit 1 }
}

$lafDir = Join-Path $JdDir "cfg\laf"
New-Item -ItemType Directory -Force -Path $lafDir | Out-Null
Copy-Item $src (Join-Path $lafDir "FlatDarkLaf.json") -Force
Write-Host "Copied FlatDarkLaf.json -> $lafDir"

# Apply the settings. This runs on Windows PowerShell 5.1 as well as PowerShell 7+:
# no ConvertFrom-Json -AsHashtable (7+ only), and the file is read AND written as
# BOM-free UTF-8 - 5.1 would otherwise decode JD's config with the ANSI codepage and
# mangle every non-ASCII value, and JD's JSON parser rejects a BOM.
$gui = Join-Path $JdDir "cfg\org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
$d = $null
if (Test-Path $gui) {
  try { $d = [IO.File]::ReadAllText($gui, [Text.Encoding]::UTF8) | ConvertFrom-Json } catch { $d = $null }
}
if ($null -eq $d -or $d -isnot [pscustomobject]) { $d = New-Object PSObject }

$settings = [ordered]@{
  "lookandfeeltheme" = "FLATLAF_DARK"
  # Also switch off JDownloader's built-in advertisements so the GUI stays clean
  # and the download graph keeps its full height (the "Become premium user" banner
  # otherwise squeezes it). Ads only - Donate and functional settings untouched.
  "bannerenabled" = $false
  "statusbaraddpremiumbuttonvisible" = $false
  "premiumalertspeedcolumnenabled" = $false
  "premiumalerttaskcolumnenabled" = $false
  "premiumalertetacolumnenabled" = $false
  "premiumdisabledwarningflashenabled" = $false
  "specialdealsenabled" = $false
  "specialdealoboomdialogvisibleonstartup" = $false
}
foreach ($k in $settings.Keys) {
  $d | Add-Member -NotePropertyName $k -NotePropertyValue $settings[$k] -Force
}

# Write via a temp file so an interrupted write can't leave JD an empty config.
$tmp = "$gui.jdpd-tmp"
[IO.File]::WriteAllText($tmp, ($d | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($false)))
Move-Item -LiteralPath $tmp -Destination $gui -Force
Write-Host "Set lookandfeeltheme=FLATLAF_DARK + disabled built-in ads"

Write-Host "Done. Restart JDownloader."
Write-Host "Still light afterwards? Open Settings > Advanced Settings, search for"
Write-Host "'lookandfeeltheme' and set it to FLATLAF_DARK. That switch lives in Advanced"
Write-Host "Settings only - the normal settings panels have no theme entry."
Hold
