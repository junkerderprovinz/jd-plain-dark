# Behavioral tests for the Windows installer (install/install.ps1).
# Runs on Windows PowerShell 5.1 and on PowerShell 7+ - the point of the suite is that
# BOTH apply the settings. 5.1 used to skip them entirely (issue #11).
# Paths use "/" so the suite also runs under pwsh on Linux.
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ps1  = Join-Path $root "install/install.ps1"
$gui  = "org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
$fail = 0

function Check($name, $cond, $why) {
  if ($cond) { Write-Host "PASS $name" }
  else { Write-Host "FAIL $name - $why"; $script:fail = 1 }
}

function New-FakeJd($existingJson) {
  $dir = Join-Path ([IO.Path]::GetTempPath()) ("jdpd-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
  New-Item -ItemType Directory -Force -Path (Join-Path $dir "cfg") | Out-Null
  if ($existingJson) { [IO.File]::WriteAllText((Join-Path $dir "cfg/$gui"), $existingJson) }
  return $dir
}

function Read-Cfg($jd) {
  [IO.File]::ReadAllText((Join-Path $jd "cfg/$gui"), [Text.Encoding]::UTF8) | ConvertFrom-Json
}

Write-Host "PowerShell $($PSVersionTable.PSVersion) - installer test"

# --- Test 1: existing settings file - settings applied, other keys kept ---
# The pre-existing value carries a non-ASCII char, built from its code point so this
# .ps1 stays pure ASCII (5.1 decodes a BOM-less UTF-8 script as ANSI). JD writes
# BOM-less UTF-8, and a path like "Musik-B<uml>cher" must survive the round-trip.
$uml = [string][char]0x00FC
$jd = New-FakeJd ('{"foo":"b' + $uml + 'r"}')
try {
  & $ps1 -JdDir $jd -NoPause | Out-Null
  Check "1a copies FlatDarkLaf.json" (Test-Path (Join-Path $jd "cfg/laf/FlatDarkLaf.json")) "theme file missing"

  $d = Read-Cfg $jd
  Check "1b sets lookandfeeltheme" ($d.lookandfeeltheme -eq "FLATLAF_DARK") "got '$($d.lookandfeeltheme)' - this is issue #11"
  Check "1c disables the built-in ads" ($d.bannerenabled -eq $false -and $d.specialdealsenabled -eq $false) "ad keys not written"
  Check "1d keeps existing keys, non-ASCII intact" ($d.foo -eq ("b" + $uml + "r")) "expected 'b<uml>r', got '$($d.foo)' - encoding mangled"

  $bytes = [IO.File]::ReadAllBytes((Join-Path $jd "cfg/$gui"))
  $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  Check "1e writes BOM-free UTF-8" (-not $bom) "UTF-8 BOM present - JD's JSON parser chokes on it"
} finally { Remove-Item -Recurse -Force $jd -ErrorAction SilentlyContinue }

# --- Test 2: no settings file yet (fresh JDownloader) ---
$jd = New-FakeJd $null
try {
  & $ps1 -JdDir $jd -NoPause | Out-Null
  Check "2a creates the settings file" (Test-Path (Join-Path $jd "cfg/$gui")) "settings file not created"
  if (Test-Path (Join-Path $jd "cfg/$gui")) {
    Check "2b sets lookandfeeltheme" ((Read-Cfg $jd).lookandfeeltheme -eq "FLATLAF_DARK") "not set on a fresh install"
  }
} finally { Remove-Item -Recurse -Force $jd -ErrorAction SilentlyContinue }

# --- Test 3: a corrupt settings file must not abort the install ---
$jd = New-FakeJd 'not json at all {{'
try {
  & $ps1 -JdDir $jd -NoPause | Out-Null
  $laf = $null
  try { $laf = (Read-Cfg $jd).lookandfeeltheme } catch {}
  Check "3a recovers from a corrupt settings file" ($laf -eq "FLATLAF_DARK") "corrupt file not replaced"
} finally { Remove-Item -Recurse -Force $jd -ErrorAction SilentlyContinue }

# --- Test 4: no leftover temp file from the atomic write ---
$jd = New-FakeJd '{"foo":"bar"}'
try {
  & $ps1 -JdDir $jd -NoPause | Out-Null
  Check "4a cleans up the temp file" (-not (Test-Path (Join-Path $jd "cfg/$gui.jdpd-tmp"))) "left a .jdpd-tmp file behind"
} finally { Remove-Item -Recurse -Force $jd -ErrorAction SilentlyContinue }

# --- Test 5: nothing may point at the GUI menu that JDownloader 2 does not have (#11) ---
foreach ($t in @($ps1, (Join-Path $root "install/install.sh"), (Join-Path $root "README.md"))) {
  $c = [IO.File]::ReadAllText($t)
  Check "5 $(Split-Path -Leaf $t) has no 'GUI > Look & Feel' path" `
    (-not ($c -match "GUI\s*(>|&gt;|→|->)\s*Look")) `
    "points at Settings > GUI > Look & Feel, which JDownloader 2 has not"
}

if ($fail) { Write-Host "`nTESTS FAILED"; exit 1 }
Write-Host "`nALL PASS"
