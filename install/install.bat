@echo off
REM JD Plain Dark installer - launches install.ps1 with the right policy.
REM Prefers PowerShell 7+ (pwsh, auto-sets lookandfeeltheme), falls back to
REM Windows PowerShell 5.1. The PowerShell script keeps the window open and
REM prompts if it can't find JDownloader.
where pwsh >nul 2>&1
if %errorlevel%==0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
)
