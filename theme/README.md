# theme/

`cfg/laf/FlatDarkLaf.json` is the JD Plain Dark palette — IBM Carbon monochrome
(`#161616` base) written into the keys JDownloader reads itself (`colorfor*`),
so the download list, link grabber and settings table all go dark, not just the
window chrome.

## Source / drift note

This palette mirrors the container image
[`junkerderprovinz/jdownloader`](https://github.com/junkerderprovinz/jdownloader)
→ `rootfs/usr/local/bin/jdownloader-theme.sh` (the `FlatDarkLaf` branch),
**minus the kiosk-only `windowdecorationenabled: false` key** (desktop users need
a normal title bar). Keep the two in sync when colours change.
