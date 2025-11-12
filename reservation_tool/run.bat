@echo off
setlocal
REM ASCII-only wrapper to avoid mojibake in CMD

echo ========================================
echo   Reservation Tool Launcher
echo ========================================
echo.

REM Try PowerShell UI first
echo Trying PowerShell UI...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" 2>nul

if errorlevel 1 (
    echo.
    echo PowerShell UI failed. Starting simple mode...
    echo.
    echo ========================================
    echo   Simple Mode
    echo ========================================
    echo.
    echo Browser will open automatically.
    echo After reservation, close this window.
    echo.
    
    REM Set browser path
    set PLAYWRIGHT_BROWSERS_PATH=%~dp0ms-playwright
    
    REM Start EXE directly
    start "" "%~dp0reservation_tool.exe"
    
    echo.
    echo Tool is running in background.
    echo.
    echo [Important]
    echo - Browser window will open
    echo - Follow popup instructions
    echo - After completing reservation,
    echo   close this console window (X button)
    echo.
    echo Press any key to close this console...
    pause > nul
    
    REM Kill all reservation_tool processes
    taskkill /F /IM reservation_tool.exe > nul 2>&1
    
    exit /b 0
)

endlocal
exit /b %ERRORLEVEL%