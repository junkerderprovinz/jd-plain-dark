@echo off
REM JD Plain Dark installer - launches install.ps1 with the right policy.
REM The PowerShell script keeps the window open and prompts if it can't find JDownloader.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
