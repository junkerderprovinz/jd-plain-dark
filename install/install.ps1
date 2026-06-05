# JD Plain Dark installer (Windows)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1 [-JdDir "C:\path\to\JDownloader"]
param([string]$JdDir = "")
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src  = Join-Path $here "theme\cfg\laf\FlatDarkLaf.json"

if (-not $JdDir) {
  $cands = @(
    "$env:APPDATA\JDownloader 2.0",
    "$env:LOCALAPPDATA\JDownloader 2.0",
    "C:\Program Files\JDownloader 2.0",
    "$env:USERPROFILE\JDownloader"
  )
  foreach ($c in $cands) {
    if (Test-Path (Join-Path $c "cfg")) { $JdDir = $c; break }
  }
}
if (-not $JdDir -or -not (Test-Path (Join-Path $JdDir "cfg"))) {
  Write-Error "JDownloader cfg dir not found. Pass -JdDir pointing at the folder that contains 'cfg'."
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
  ($d | ConvertTo-Json -Depth 10) | Out-File -FilePath $gui -Encoding utf8
  Write-Host "Set lookandfeeltheme=FLATLAF_DARK"
} else {
  Write-Host "NOTE: Windows PowerShell 5.1 can't safely merge the settings file."
  Write-Host "      Open JDownloader and pick Settings > GUI > Look & Feel > FLATLAF_DARK once."
}
Write-Host "Done. Restart JDownloader."
