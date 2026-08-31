#!/usr/bin/env sh
# Tests for the JD Plain Dark installers.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
TMP2="$(mktemp -d)"
trap 'rm -rf "$TMP" "$TMP2"' EXIT

# --- Test 1: explicit path argument ---
mkdir -p "$TMP/cfg"
printf '{"foo":"bar"}' > "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
sh "$ROOT/install/install.sh" "$TMP"
test -f "$TMP/cfg/laf/FlatDarkLaf.json" || { echo "FAIL(1): FlatDarkLaf.json not copied"; exit 1; }
grep -q 'FLATLAF_DARK' "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json" \
  || { echo "FAIL(1): lookandfeeltheme not set"; exit 1; }
grep -q '"foo"' "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json" \
  || { echo "FAIL(1): existing key lost"; exit 1; }
grep -q '"bannerenabled": false' "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json" \
  || { echo "FAIL(1): built-in ads not disabled (bannerenabled)"; exit 1; }
echo "PASS(1) explicit path"

# --- Test 2: auto-detection (no argument), via a $HOME candidate ---
mkdir -p "$TMP2/JDownloader/cfg"
HOME="$TMP2" sh "$ROOT/install/install.sh" </dev/null
test -f "$TMP2/JDownloader/cfg/laf/FlatDarkLaf.json" || { echo "FAIL(2): auto-detect didn't copy"; exit 1; }
echo "PASS(2) auto-detect"

# --- Test 3: Windows installer regression guards (the original bug) ---
PS1="$ROOT/install/install.ps1"
grep -qF '"C:\Program Files\JDownloader"' "$PS1" \
  || { echo "FAIL(3): install.ps1 missing 'C:\\Program Files\\JDownloader' (no 2.0 suffix) candidate"; exit 1; }
grep -q 'Read-Host' "$PS1" \
  || { echo "FAIL(3): install.ps1 missing interactive fallback (Read-Host)"; exit 1; }
echo "PASS(3) windows installer guards"

# --- Test 4: issue #11 - the settings write must not be gated on the PS version ---
if grep -q 'PSVersion' "$PS1"; then
  echo "FAIL(4): install.ps1 still gates the settings write on the PowerShell version"; exit 1
fi
grep -q 'lookandfeeltheme' "$PS1" \
  || { echo "FAIL(4): install.ps1 never writes lookandfeeltheme"; exit 1; }
grep -qF 'UTF8Encoding' "$PS1" \
  || { echo "FAIL(4): install.ps1 must write BOM-free UTF-8 (JD rejects a BOM)"; exit 1; }
grep -qF 'ReadAllText($gui, [Text.Encoding]::UTF8)' "$PS1" \
  || { echo "FAIL(4): install.ps1 must read the settings as UTF-8 (5.1 defaults to ANSI)"; exit 1; }
grep -qF '$env:LOCALAPPDATA\JDownloader 2"' "$PS1" \
  || { echo "FAIL(4): install.ps1 missing the '%LOCALAPPDATA%\\JDownloader 2' candidate"; exit 1; }
echo "PASS(4) windows settings write (issue #11)"

# --- Test 5: issue #11 - nothing may point at the GUI menu JDownloader 2 has not ---
for f in "$ROOT/README.md" "$ROOT/install/install.sh" "$PS1"; do
  if grep -qE 'GUI[[:space:]]*(>|&gt;|→|->)[[:space:]]*Look' "$f"; then
    echo "FAIL(5): $f points at 'Settings > GUI > Look & Feel', which JDownloader 2 has not"
    exit 1
  fi
done
grep -q 'Advanced Settings' "$ROOT/README.md" \
  || { echo "FAIL(5): README does not document the Advanced Settings path"; exit 1; }
echo "PASS(5) theme switch documented at Advanced Settings"

echo "ALL PASS"
