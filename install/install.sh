#!/usr/bin/env sh
# JD Plain Dark installer (Linux/macOS)
# Usage: install.sh [/path/to/JDownloader]   (the folder that contains 'cfg')
set -eu

HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HERE/theme/cfg/laf/FlatDarkLaf.json"
[ -f "$SRC" ] || { echo "ERROR: $SRC not found. Run this from the unzipped release folder." >&2; exit 1; }

JD_DIR="${1:-}"
if [ -z "$JD_DIR" ]; then
  for c in \
    "$HOME/.jd2" \
    "$HOME/JDownloader" "$HOME/JDownloader 2.0" \
    "$HOME/Applications/JDownloader 2.0" \
    "/Applications/JDownloader 2.0" \
    "/opt/JDownloader" "/opt/JDownloader 2.0"; do
    if [ -d "$c/cfg" ]; then JD_DIR="$c"; break; fi
  done
fi

# Interactive fallback when a terminal is attached - never fail silently.
if { [ -z "$JD_DIR" ] || [ ! -d "$JD_DIR/cfg" ]; } && [ -t 0 ]; then
  printf "Could not auto-detect JDownloader.\nEnter your JDownloader folder (contains 'cfg'), or leave empty to cancel: "
  read -r JD_DIR
fi

if [ -z "$JD_DIR" ] || [ ! -d "$JD_DIR/cfg" ]; then
  echo "JDownloader cfg dir not found." >&2
  echo "Usage: install.sh /path/to/JDownloader   (the folder that contains 'cfg')" >&2
  exit 1
fi

mkdir -p "$JD_DIR/cfg/laf"
cp "$SRC" "$JD_DIR/cfg/laf/FlatDarkLaf.json"
echo "Copied FlatDarkLaf.json -> $JD_DIR/cfg/laf/"

GUI="$JD_DIR/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$GUI" <<'PY'
import json, os, sys
p = sys.argv[1]
d = {}
if os.path.exists(p):
    try:
        d = json.load(open(p))
    except Exception:
        d = {}
d["lookandfeeltheme"] = "FLATLAF_DARK"
json.dump(d, open(p, "w"), indent=2)
PY
  echo "Set lookandfeeltheme=FLATLAF_DARK"
else
  echo "NOTE: python3 not found - open JDownloader and pick"
  echo "      Settings > GUI > Look & Feel > FLATLAF_DARK once."
fi
echo "Done. Restart JDownloader."
