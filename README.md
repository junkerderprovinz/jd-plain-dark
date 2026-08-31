<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/banner-dark.png">
    <img src=".github/assets/banner.png" alt="JD Plain Dark" width="100%">
  </picture>
</p>

<p align="center">
  <a href="https://github.com/junkerderprovinz/jd-plain-dark/actions/workflows/lint.yml"><img src="https://img.shields.io/github/actions/workflow/status/junkerderprovinz/jd-plain-dark/lint.yml?branch=main&label=Lint&style=for-the-badge&logo=githubactions&logoColor=white" alt="Lint" height="36"></a>&nbsp;
  <a href="https://github.com/junkerderprovinz/jd-plain-dark/releases/latest"><img src="https://img.shields.io/github/v/release/junkerderprovinz/jd-plain-dark?display_name=tag&sort=semver&style=for-the-badge&logo=semver&logoColor=white&color=success&cacheSeconds=300" alt="Release" height="36"></a>&nbsp;
  <a href="https://github.com/junkerderprovinz/jd-plain-dark/releases"><img src="https://img.shields.io/github/downloads/junkerderprovinz/jd-plain-dark/total?style=for-the-badge&logo=github&logoColor=white&label=Downloads" alt="Downloads" height="36"></a>&nbsp;
  <a href="#3-install"><img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-555?style=for-the-badge" alt="Platform" height="36"></a>&nbsp;
  <a href="https://jdownloader.org"><img src="https://img.shields.io/badge/JDownloader-2-2d8a42?style=for-the-badge&logoColor=white" alt="JDownloader 2" height="36"></a>&nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-blue?style=for-the-badge&logo=gnu&logoColor=white" alt="License: AGPL-3.0" height="36"></a>
</p>

<br>

<p align="center">
A fully dark <b>JD Plain</b> theme for <b>JDownloader 2</b> — a monochrome IBM Carbon (#161616)
dark across the <i>whole</i> interface (download list, link grabber <b>and</b> settings, not just
the menu bar). It uses JDownloader's own colour configuration, so there is <b>no patched JAR and
no Java agent</b> — just one config file.
</p>

<br>

<p align="center">
Maintained solo, in whatever spare time there is. Bugs, ideas and feature requests via <a href="https://github.com/junkerderprovinz/jd-plain-dark/issues">GitHub issues</a>. If it's useful to you, a coffee is always welcome.
</p>

<br>

<p align="center">
  <a href="https://buymeacoffee.com/junkerderprovinz">
    <img src=".github/assets/button-buy-me-a-coffee.svg" alt="Buy me a coffee" width="220">
  </a>
</p>

<br>

## Table of Contents

1. [What it does](#1-what-it-does)
2. [Screenshots](#2-screenshots)
3. [Install](#3-install)
4. [How it works](#4-how-it-works)
5. [Event Scripter fix (optional)](#5-event-scripter-fix-optional)
6. [Uninstall](#6-uninstall)
7. [Credits](#7-credits)
8. [License](#8-license)
9. [Support this project](#9-support-this-project)

<br>

## 1. What it does

JDownloader 2 ships no proper dark mode: enable a dark Look & Feel and the *chrome*
(menu bar, toolbar, headers, scrollbars) goes dark, but JD's custom content areas — the
**download list**, the **link grabber** and the **Advanced Settings** table — stay light.

**JD Plain Dark** fixes that. It is the **JD Plain** flat icon set rendered in a neutral
IBM Carbon (`#161616`) dark, applied through the colour keys JDownloader reads itself, so the
**entire** UI is dark and consistent. Functional accents stay (green speed graph, muted
red/amber for failed downloads and accounts).

- Works on **Windows, macOS and Linux** (it is just JD config).
- **No patched `flatlaf.jar`, no Java agent** — survives JDownloader self-updates.
- **Ad-free too:** the installer also switches off JDownloader's built-in advertisements (the *"Become premium user"* banner, the premium-alert column nags, special-deal popups), so the GUI stays clean and the download graph keeps its full height. Ads only — the Donate button and all functional settings are untouched.
- One file to install, one file to remove.

<br>

## 2. Screenshots

<p align="center">
  <img src="docs/screenshots/preview.png" alt="JD Plain Dark — download list, context menu and settings in monochrome Carbon #161616" width="92%">
</p>

<p align="center"><sub>The whole UI in monochrome IBM&nbsp;Carbon <code>#161616</code> — download list, context menu and settings.</sub></p>

<br>

## 3. Install

### Option A — download & run the installer (recommended)

1. Download `jd-plain-dark-vX.Y.Z.zip` from the [latest release](https://github.com/junkerderprovinz/jd-plain-dark/releases/latest) and unzip it.
2. **Close JDownloader.** It rewrites its own config on shutdown, which would undo the
   install.
3. Run the installer for your OS:
   - **Windows:** double-click **`install/install.bat`** (recommended). It keeps the
     window open and, if it can't find JDownloader automatically, **asks you for the
     folder**. (Right-click `install/install.ps1` → *Run with PowerShell* also works.)
   - **Linux / macOS:** `sh install/install.sh "/path/to/JDownloader"`
     (the folder that contains `cfg`). Without an argument it auto-detects, and prompts
     if it can't.
4. **Start JDownloader.**

The installer copies `FlatDarkLaf.json` into JD's `cfg/laf/` and selects the
`FLATLAF_DARK` Look & Feel.

### Option B — manual (one file)

1. Close JDownloader.
2. Copy `theme/cfg/laf/FlatDarkLaf.json` into your JDownloader folder under `cfg/laf/`.
3. Start JDownloader, open **Settings → Advanced Settings**, search for
   **`lookandfeeltheme`** and set it to **`FLATLAF_DARK`**.
4. **Restart JDownloader.**

> **Where is the theme switch?** JDownloader 2 has no *Look & Feel* entry in the normal
> settings panels — it lives in **Settings → Advanced Settings** only, under
> `lookandfeeltheme`. If that key offers no `FLATLAF_*` value, your JDownloader core is
> too old: let it update (**Help → Check for Updates**) and try again.

### Installed on Windows before v1.2.2? Run it again

Up to and including v1.2.1 the Windows installer only applied the settings when it happened
to run on PowerShell 7. `install.bat` starts Windows PowerShell 5.1 on a stock machine, so
for most people it copied the theme file, printed `Done`, and changed nothing else — the UI
stayed light and the note it printed pointed at a menu JDownloader does not have
([#11](https://github.com/junkerderprovinz/jd-plain-dark/issues/11)).

If that was you, nothing is broken and there is nothing to clean up: download
[v1.2.2 or later](https://github.com/junkerderprovinz/jd-plain-dark/releases/latest), close
JDownloader, run the installer again, and start JDownloader. Linux and macOS were never
affected.

<br>

## 4. How it works

JDownloader stores per-Look-&-Feel colours in `cfg/laf/FlatDarkLaf.json` using `colorfor*`
keys (e.g. `colorfortablepackagerowbackground`). JD's own renderer reads these — including the
ExtTable behind the download list, link grabber and settings — so setting them dark colours the
content areas too, not only the Swing chrome. `iconsetid: flat` selects the JD Plain icons.
The same file also passes through a handful of raw FlatLaf UIManager keys where JD has no
`colorfor*` equivalent — e.g. `ProgressBar.selectionForeground`, so the percentage text stays
readable against the light "Finished" fill instead of inheriting FlatLaf's own (too-light)
default.

The installer also writes two things into `cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json`:
`lookandfeeltheme: FLATLAF_DARK` (so the dark L&F is active) and a handful of `false` flags that
switch off JDownloader's built-in advertisements (`bannerenabled`, the `premiumalert*` columns,
`specialdeals*`, the status-bar premium button). Ads only — nothing functional is changed.

That is the whole trick: no bytecode patching, no `-javaagent`. Because it is plain
configuration, JD's automatic updates don't break it.

<br>

## 5. Event Scripter fix (optional)

The theme is config-only and needs nothing else. This section is **only** for people who use
the **Event Scripter** extension and hit a separate JDownloader bug: on any FlatLaf dark Look &
Feel (this theme *or* JD's own `flatlaf-themes` dark), the Event Scripter **script editor won't
open** — clicking **edit** or **Add** does nothing. That is a JDownloader bug, not a theme bug
(the stock dark theme triggers it too), so fixing it needs a small optional add-on rather than a
config key.

`jd-es-fix.jar` is a tiny, fail-safe `-javaagent` that null-guards the two code paths involved.
Download it from the [latest release](https://github.com/junkerderprovinz/jd-plain-dark/releases/latest)
and point JDownloader's JVM at it, e.g.:

```
JAVA_TOOL_OPTIONS=-javaagent:/full/path/to/jd-es-fix.jar
```

Full instructions (per-OS setup, building it yourself, and what it patches) are in
[docs/event-scripter-fix.md](docs/event-scripter-fix.md). If you don't use Event Scripter, ignore
this entirely — the theme stays pure config, no agent required.

<br>

## 6. Uninstall

Close JDownloader, delete `cfg/laf/FlatDarkLaf.json` from your JDownloader folder, then start it
again and set `lookandfeeltheme` back to `DEFAULT` under **Settings → Advanced Settings**.
Restart JDownloader.

<br>

## 7. Credits

The technique — overriding JDownloader's native `colorfor*` colour config to reach the content
areas — was inspired by the community **Material Darker** theme. The colours here are our own
(IBM Carbon monochrome) and no Material Darker code or assets are included. Licensed MIT.

Derived from the dark theme built into the [JDownloader-for-Unraid container](https://github.com/junkerderprovinz/jdownloader).

<br>

## 8. License

**Copyright (C) 2026 Junker der Provinz.**

JD Plain Dark is free software under the **GNU Affero General Public License v3.0** (AGPL-3.0); see [LICENSE](LICENSE). You may run, study, share and modify it. If you distribute it, or run a modified version as a network service, you must release your source under the same AGPL-3.0 terms and keep the existing copyright and attribution notices intact.

**Name and branding are not licensed.** The AGPL covers the source code only. "JD Plain Dark", its logo and its branding remain reserved: a fork or derivative must use its own distinct name and branding, and may not present itself as JD Plain Dark. This keeps it unambiguous which project is the original.

<br>

## 9. Support this project

If this saved you some squinting, you can

Questions, bugs, ideas or feature requests? Please [open a GitHub issue](https://github.com/junkerderprovinz/jd-plain-dark/issues).

This is a one-person project. I put a lot of time and effort into building and maintaining it, in whatever free time I have. If it's helped you, I'd genuinely appreciate the support: you're welcome to buy me a coffee.

<p align="center">
  <a href="https://buymeacoffee.com/junkerderprovinz">
    <img src=".github/assets/button-buy-me-a-coffee.svg" alt="Buy me a coffee" width="220">
  </a>
</p>

Issues and suggestions: [GitHub Issues](https://github.com/junkerderprovinz/jd-plain-dark/issues).
