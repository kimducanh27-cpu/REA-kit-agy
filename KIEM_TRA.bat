@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File .agents\scripts\health_check.ps1
echo.
pause
