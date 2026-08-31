#!/usr/bin/env sh
# JD Plain Dark installer (Linux/macOS)
# Usage: install.sh [/path/to/JDownloader]   (the folder that contains 'cfg')
set -eu

HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HERE/theme/cfg/laf/FlatDarkLaf.json"
[ -f "$SRC" ] || { echo "ERROR: $SRC not found. Run this from the unzipped release folder." >&2; exit 1; }

# JDownloader rewrites its cfg/*.json on shutdown, so anything written while it runs
# is thrown away the moment the user closes it.
if command -v pgrep >/dev/null 2>&1 && pgrep -f "JDownloader.jar" >/dev/null 2>&1; then
  echo "WARNING: JDownloader seems to be running. It rewrites its settings when it closes," >&2
  echo "         which would undo this install. Close JDownloader first." >&2
  if [ -t 0 ]; then
    printf "Continue anyway? [y/N]: "
    read -r ANSWER
    case "$ANSWER" in
      y|Y|yes|YES|j|J|ja|JA) ;;
      *) echo "Cancelled - nothing changed."; exit 1 ;;
    esac
  else
    echo "Cancelled - nothing changed." >&2
    exit 1
  fi
fi

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
LAF_SET=0
if command -v python3 >/dev/null 2>&1; then
  # Non-fatal: a broken python3 must not abort the install half-done - fall through
  # to the manual instruction below instead.
  if python3 - "$GUI" <<'PY'
import json, os, sys
p = sys.argv[1]
d = {}
if os.path.exists(p):
    try:
        with open(p, encoding="utf-8") as fh:
            d = json.load(fh)
    except Exception:
        d = {}
if not isinstance(d, dict):
    d = {}
d["lookandfeeltheme"] = "FLATLAF_DARK"
# Also switch off JDownloader's built-in advertisements so the GUI stays clean and
# the download graph keeps its full height (the "Become premium user" banner
# otherwise squeezes it). Ads only - Donate and functional settings untouched.
for k in ("bannerenabled", "statusbaraddpremiumbuttonvisible",
          "premiumalertspeedcolumnenabled", "premiumalerttaskcolumnenabled",
          "premiumalertetacolumnenabled", "premiumdisabledwarningflashenabled",
          "specialdealsenabled", "specialdealoboomdialogvisibleonstartup"):
    d[k] = False
# Write via a temp file: an interrupted write must not leave JD an empty config.
tmp = p + ".jdpd-tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(d, fh, indent=2)
os.replace(tmp, p)
PY
  then
    LAF_SET=1
    echo "Set lookandfeeltheme=FLATLAF_DARK + disabled built-in ads"
  fi
fi
if [ "$LAF_SET" -eq 0 ]; then
  echo "NOTE: could not write the settings here - open JDownloader, go to"
  echo "      Settings > Advanced Settings, search for 'lookandfeeltheme'"
  echo "      and set it to FLATLAF_DARK once."
fi
echo "Done. Restart JDownloader."
echo "Still light afterwards? Settings > Advanced Settings, search 'lookandfeeltheme',"
echo "set FLATLAF_DARK. That switch lives in Advanced Settings only."
