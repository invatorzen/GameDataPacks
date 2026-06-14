@echo off
REM Launcher for generate.rb. Writes manifest.json into each pack folder
REM and a top-level manifests.json index at the repo root.

cd /d "%~dp0\.."
ruby "Manifest tool\generate_manifests.rb"
echo.
echo --- Done. Press any key to close this window. ---
pause >nul
