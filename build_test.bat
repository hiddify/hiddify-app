@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo Running Flutter Analyze...
echo ========================================
call flutter analyze --no-fatal-infos
if %errorlevel% neq 0 (
    echo WARNING: Some analysis issues found, but continuing...
)

echo.
echo ========================================
echo Starting Windows Build (Debug)...
echo ========================================
call flutter build windows --debug --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
pause
