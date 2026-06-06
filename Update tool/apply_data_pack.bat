@echo off
REM Launcher for apply_data_pack.rb so the console stays open after exit.
REM Works whether you double-click this file in Explorer or run it from a terminal.

cd /d "%~dp0"
ruby apply_data_pack.rb %*
echo.
echo --- Script finished. Press any key to close this window. ---
pause >nul
