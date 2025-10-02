@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo Step 1: Rebuilding code generators...
echo ========================================
call dart run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo ERROR: build_runner failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 2: Running flutter build windows...
echo ========================================
call flutter build windows --debug --verbose
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Executable location:
echo build\windows\x64\runner\Debug\hiddify.exe
echo.
pause
