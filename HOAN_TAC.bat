@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File .agents\scripts\rollback.ps1
echo.
pause
