@echo off
echo ========================================
echo Real Debrid Streamer - Quick Fix
echo ========================================
echo.

echo [1/3] Fixing package.json...

REM Create a clean package.json
(
echo {
echo   "name": "realdebrid-streamer",
echo   "version": "1.0.0",
echo   "description": "Netflix-style torrent streaming with Real Debrid",
echo   "main": "main.js",
echo   "scripts": {
echo     "start": "electron .",
echo     "build:win": "electron-builder --win --x64"
echo   },
echo   "keywords": ["realdebrid", "torrent", "streaming"],
echo   "author": "Real Debrid Streamer",
echo   "license": "MIT",
echo   "dependencies": {
echo     "axios": "^1.6.0"
echo   },
echo   "devDependencies": {
echo     "electron": "^28.0.0",
echo     "electron-builder": "^24.9.0"
echo   },
echo   "build": {
echo     "appId": "com.realdebrid.streamer",
echo     "productName": "Real Debrid Streamer",
echo     "win": {
echo       "target": ["nsis", "portable"],
echo       "icon": "assets/icon.png"
echo     },
echo     "nsis": {
echo       "oneClick": false,
echo       "allowToChangeInstallationDirectory": true,
echo       "createDesktopShortcut": true,
echo       "createStartMenuShortcut": true
echo     }
echo   }
echo }
) > package.json

echo Package.json fixed!

echo.
echo [2/3] Installing dependencies...
call npm install --production

echo.
echo [3/3] Building app...
call npm run build:win

echo.
echo ========================================
echo BUILD COMPLETE!
echo ========================================
echo.
echo Check the 'dist' folder for your app!
echo.
pause
