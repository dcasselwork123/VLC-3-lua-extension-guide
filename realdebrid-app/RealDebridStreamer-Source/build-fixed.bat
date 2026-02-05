@echo off
echo ========================================
echo Real Debrid Streamer - Build Script
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

echo [1/5] Cleaning old builds...
if exist "dist" rmdir /s /q dist
if exist "dist-package" rmdir /s /q dist-package
if exist "node_modules" rmdir /s /q node_modules

echo.
echo [2/5] Installing dependencies...
call npm install --production
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [3/5] Creating assets folder...
if not exist "assets" mkdir assets

echo.
echo [4/5] Building Windows installer and portable...
call npm run build:win
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo [5/5] Creating distribution package...
if not exist "dist-final" mkdir dist-final
if exist "dist\*.exe" xcopy /Y dist\*.exe dist-final\
if exist "README.md" copy /Y README.md dist-final\

echo.
echo ========================================
echo BUILD COMPLETE!
echo ========================================
echo.
echo Your apps are ready in: dist-final\
echo.
echo Files created:
dir /B dist-final
echo.
echo Two versions available:
echo 1. RealDebridStreamer-Setup.exe - Windows Installer (recommended)
echo 2. RealDebridStreamer-Portable.exe - Portable version
echo.
echo Installer features:
echo - Start menu shortcut
echo - Desktop shortcut
echo - Easy uninstall
echo - Auto-updates (future)
echo.
pause
