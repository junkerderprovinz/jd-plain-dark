# JD Plain Dark installer (Windows)
# Recommended: double-click install.bat. Or right-click this file > Run with PowerShell.
# Manual:      powershell -ExecutionPolicy Bypass -File install.ps1 [-JdDir "C:\path\to\JDownloader"]
param([string]$JdDir = "")
$ErrorActionPreference = "Stop"

function Hold { try { if ($Host.UI.RawUI) { Read-Host "`nPress Enter to close" | Out-Null } } catch {} }

$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src  = Join-Path $here "theme\cfg\laf\FlatDarkLaf.json"
if (-not (Test-Path $src)) {
  Write-Host "ERROR: $src not found. Run this from the unzipped release folder."
  Hold; exit 1
}

# Auto-detect the JDownloader folder (the one that contains 'cfg').
if (-not $JdDir) {
  $cands = @(
    "C:\Program Files\JDownloader",
    "C:\Program Files\JDownloader 2.0",
    "C:\Program Files (x86)\JDownloader",
    "C:\Program Files (x86)\JDownloader 2.0",
    "$env:LOCALAPPDATA\JDownloader",
    "$env:LOCALAPPDATA\JDownloader 2.0",
    "$env:APPDATA\JDownloader",
    "$env:APPDATA\JDownloader 2.0",
    "$env:USERPROFILE\JDownloader",
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

$gui = Join-Path $JdDir "cfg\org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
if ($PSVersionTable.PSVersion.Major -ge 6) {
  $d = @{}
  if (Test-Path $gui) { try { $d = Get-Content $gui -Raw | ConvertFrom-Json -AsHashtable } catch { $d = @{} } }
  if ($null -eq $d) { $d = @{} }
  $d["lookandfeeltheme"] = "FLATLAF_DARK"
  # Also switch off JDownloader's built-in advertisements so the GUI stays clean
  # and the download graph keeps its full height (the "Become premium user" banner
  # otherwise squeezes it). Ads only - Donate and functional settings untouched.
  $d["bannerenabled"] = $false
  $d["statusbaraddpremiumbuttonvisible"] = $false
  $d["premiumalertspeedcolumnenabled"] = $false
  $d["premiumalerttaskcolumnenabled"] = $false
  $d["premiumalertetacolumnenabled"] = $false
  $d["premiumdisabledwarningflashenabled"] = $false
  $d["specialdealsenabled"] = $false
  $d["specialdealoboomdialogvisibleonstartup"] = $false
  ($d | ConvertTo-Json -Depth 10) | Out-File -FilePath $gui -Encoding utf8
  Write-Host "Set lookandfeeltheme=FLATLAF_DARK + disabled built-in ads"
} else {
  Write-Host "NOTE: Windows PowerShell 5.1 - now open JDownloader and pick"
  Write-Host "      Settings > GUI > Look & Feel > FLATLAF_DARK once."
}
Write-Host "Done. Restart JDownloader."
Hold
