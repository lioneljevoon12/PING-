@echo off
setlocal
echo ===================================================
echo   PING! - Android APK Export Script
echo ===================================================

set "GODOT_BIN=C:\Users\ASUS\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\Users\ASUS\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

if not exist "build\android" (
    mkdir "build\android"
)

echo [1/2] Menyiapkan environment & mengekspor APK...
"%GODOT_BIN%" --headless --export-debug "Android" "build/android/ping-game.apk"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo   [SUKSES] APK Berhasil dibuat!
    echo   Lokasi: %CD%\build\android\ping-game.apk
    echo ===================================================
) else (
    echo.
    echo [ERROR] Export gagal dengan kode: %ERRORLEVEL%
)

echo.
pause
