#!/usr/bin/env sh
# Integration test for install.sh against a temporary fake JDownloader profile.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/cfg"
printf '{"foo":"bar"}' > "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"

sh "$ROOT/install/install.sh" "$TMP"

test -f "$TMP/cfg/laf/FlatDarkLaf.json" || { echo "FAIL: FlatDarkLaf.json not copied"; exit 1; }
grep -q 'FLATLAF_DARK' "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json" \
  || { echo "FAIL: lookandfeeltheme not set"; exit 1; }
grep -q '"foo"' "$TMP/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json" \
  || { echo "FAIL: existing key lost"; exit 1; }

echo "PASS"
