@echo off
setlocal
echo ===================================================
echo   PING! - Android APK Export Script
echo ===================================================

cd /d "%~dp0"
python "%~dp0..\..\Users\ASUS\.gemini\antigravity\brain\287da06b-d551-4e51-abda-63eb9590f470\scratch\export_and_copy.py"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo   [SUKSES] APK Berhasil dibuat dan disalin!
    echo   Lokasi: %~dp0..\ping-game.apk
    echo ===================================================
) else (
    echo.
    echo [ERROR] Export gagal dengan kode: %ERRORLEVEL%
)

echo.
pause
