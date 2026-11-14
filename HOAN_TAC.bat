@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

:: Lưu ý: -ExecutionPolicy Bypass chỉ là tham số cho phép thực thi PowerShell script trên Windows chưa cấu hình chính sách, không phải sandbox bảo mật.
:: Tính an toàn dữ liệu được đảm bảo nguyên tử bởi kiểm tra manifest SHA-256 và cơ chế hoán đổi Staging.

echo ==========================================================
echo   XAC NHAN HOAN TAC UNG DUNG (1-CLICK ATOMIC ROLLBACK)
echo ==========================================================
echo Ban co chac chan muon hoan tac ve ban snapshot gan nhat?
choice /C YN /N /M "Nhan 'Y' de tiep tuc hoan tac, hoac 'N' de huy: "
if errorlevel 2 (
    echo [*] Da huy thao tac hoan tac.
    echo.
    pause
    exit /b 0
)

:: Ưu tiên Node CLI (dist/cli.js rollback)
if exist "%~dp0dist\cli.js" (
    where node >nul 2>&1
    if not errorlevel 1 (
        node "%~dp0dist\cli.js" rollback restore --force %*
        set "EXIT_CODE=%ERRORLEVEL%"
        goto :finish
    )
)

:: Fallback về PowerShell rollback.ps1
if exist "%~dp0.agents\scripts\rollback.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.agents\scripts\rollback.ps1" -Force %*
    set "EXIT_CODE=%ERRORLEVEL%"
    goto :finish
)

echo [ERROR] Không tìm thấy runtime hoàn tác hợp lệ (node dist/cli.js hoặc .agents/scripts/rollback.ps1).
set "EXIT_CODE=1"

:finish
echo.
pause
exit /b %EXIT_CODE%
