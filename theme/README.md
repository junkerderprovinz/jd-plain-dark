# theme/

`cfg/laf/FlatDarkLaf.json` is the JD Plain Dark palette: IBM Carbon monochrome
(`#161616` base) written into the keys JDownloader reads itself (`colorfor*`),
so the download list, link grabber and settings table all go dark, not just the
window chrome.

## Source / drift note

This palette mirrors the container image
[`junkerderprovinz/jdownloader`](https://github.com/junkerderprovinz/jdownloader)
→ `rootfs/usr/local/bin/jdownloader-theme.sh` (the `FlatDarkLaf` branch). Two keys
differ on purpose. `windowdecorationenabled` is left out here: the container sets it
to `false` for its kiosk window, and the Windows installer sets it to `true` so the
title bar goes dark. `progresscolumntextposition` is `RIGHT` here, because the
desktop has no agent to make the percentage readable on top of the bar. Keep the
colours in sync with the container.
