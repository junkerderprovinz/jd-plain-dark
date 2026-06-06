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

echo "ALL PASS"
