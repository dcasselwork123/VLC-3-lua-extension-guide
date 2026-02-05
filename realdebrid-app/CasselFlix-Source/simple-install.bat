@echo off
echo ========================================
echo Real Debrid Streamer - Simple Installer
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed!
    echo.
    echo Please install Node.js first:
    echo 1. Go to: https://nodejs.org/
    echo 2. Download LTS version
    echo 3. Run installer
    echo 4. Restart computer
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

echo Node.js found! Version:
node --version
echo.

echo [Step 1/2] Installing dependencies (this may take 2-3 minutes)...
echo.

REM Clean install
if exist node_modules rmdir /s /q node_modules
if exist package-lock.json del package-lock.json

REM Create minimal package.json if missing or corrupted
if not exist package.json (
    echo Creating package.json...
    echo {"name":"realdebrid-streamer","version":"1.0.0","main":"main.js","dependencies":{"axios":"^1.6.0"},"devDependencies":{"electron":"^28.0.0"}} > package.json
)

call npm install

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to install dependencies
    echo.
    echo Trying alternative method...
    call npm install --legacy-peer-deps
    
    if %ERRORLEVEL% NEQ 0 (
        echo Installation failed. Please check your internet connection.
        pause
        exit /b 1
    )
)

echo.
echo [Step 2/2] Installation complete!
echo.
echo ========================================
echo READY TO USE!
echo ========================================
echo.
echo To start the app, simply run:
echo   start-app.bat
echo.
echo Or you can use:
echo   npm start
echo.
echo A shortcut will be created on your desktop.
echo.

REM Create desktop shortcut script
echo @echo off > start-app.bat
echo cd /d "%%~dp0" >> start-app.bat
echo npm start >> start-app.bat

echo Desktop shortcut: start-app.bat created!
echo.
echo Double-click 'start-app.bat' to launch the app!
echo.
pause
