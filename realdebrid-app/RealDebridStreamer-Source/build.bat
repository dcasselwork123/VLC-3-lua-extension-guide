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

echo [1/4] Installing dependencies...
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [2/4] Creating assets folder...
if not exist "assets" mkdir assets

echo.
echo [3/4] Building portable Windows executable...
call npm run build:win
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo [4/4] Creating distribution package...
if not exist "dist-package" mkdir dist-package
xcopy /Y /I dist\*.exe dist-package\
xcopy /Y README.md dist-package\

echo.
echo ========================================
echo BUILD COMPLETE!
echo ========================================
echo.
echo Your portable app is ready in: dist-package\
echo.
echo Files:
dir /B dist-package
echo.
echo You can now:
echo 1. Test the app by running the .exe
echo 2. Zip the dist-package folder for distribution
echo.
pause
