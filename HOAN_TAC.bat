@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: Lưu ý: -ExecutionPolicy Bypass chỉ là tham số cho phép thực thi PowerShell script trên Windows chưa cấu hình chính sách, không phải sandbox bảo mật.
:: Tính an toàn dữ liệu được đảm bảo nguyên tử bởi kiểm tra manifest SHA-256 và cơ chế hoán đổi Staging trong rollback.ps1.

echo ==========================================================
echo   XAC NHAN HOAN TAC UNG DUNG (1-CLICK ATOMIC ROLLBACK)
echo ==========================================================
echo Ban co chac chan muon hoan tac ve ban snapshot gan nhat?
set /p "CONFIRM=Nhan 'Y' de tiep tuc hoan tac, hoac phim bat ky de huy: "
if /i not "%CONFIRM%"=="Y" (
    echo [*] Da huy thao tac hoan tac.
    echo.
    pause
    exit /b 0
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.agents\scripts\rollback.ps1" -Force
set "EXIT_CODE=%ERRORLEVEL%"
echo.
pause
exit /b %EXIT_CODE%
