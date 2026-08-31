@echo off
REM JD Plain Dark installer - launches install.ps1 with the right policy.
REM Works on stock Windows PowerShell 5.1; the script keeps the window open and
REM prompts if it can't find JDownloader.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
