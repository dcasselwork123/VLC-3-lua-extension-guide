@echo off
echo ========================================
echo Real Debrid Streamer - UPDATE
echo ========================================
echo.
echo This will update the app with new features:
echo  - Torrent selection dialog
echo  - Better error messages
echo  - Debug logging
echo.
pause

echo Downloading updated files from GitHub...

REM Download updated renderer.js
curl -L "https://raw.githubusercontent.com/dcasselwork123/VLC-3-lua-extension-guide/genspark_ai_developer/realdebrid-app/renderer.js" -o renderer.js

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Update complete!
    echo.
    echo New features:
    echo  - Choose from multiple torrent qualities
    echo  - See torrent size, seeds, and peers
    echo  - Better error messages showing what went wrong
    echo  - Debug info in console
    echo.
    echo Close and reopen the app to see changes!
    echo.
) else (
    echo.
    echo ❌ Update failed!
    echo Please check your internet connection.
    echo.
)

pause
