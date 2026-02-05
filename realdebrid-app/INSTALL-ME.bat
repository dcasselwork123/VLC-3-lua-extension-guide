@echo off
echo ========================================
echo Real Debrid Streamer - Quick Install
echo ========================================
echo.
echo This will install and run the app!
echo.
pause

where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js not found!
    echo Install from: https://nodejs.org/
    pause
    exit /b 1
)

echo Installing...
if exist node_modules rmdir /s /q node_modules
call npm install

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! Starting app...
    echo.
    start cmd /k npm start
) else (
    echo.
    echo Installation failed!
    pause
)
