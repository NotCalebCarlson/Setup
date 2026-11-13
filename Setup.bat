@echo off
rem Double-click launcher for Setup-NewPC.ps1 (must be in the same folder as this file).
if not exist "%~dp0Source.ps1" (echo Could not find Source.ps1 next to this file. & pause & exit /b 1)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Source.ps1" %*
if errorlevel 1 pause