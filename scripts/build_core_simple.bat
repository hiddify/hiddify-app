@echo off
chcp 65001 >nul

echo === Building Hiddify Core (Simple) ===

REM Set Go path
set GO_EXE=%cd%\go-tools\go\bin\go.exe

REM Check if Go exists
if not exist "%GO_EXE%" (
    echo ❌ Go not found at %GO_EXE%
    exit /b 1
)

echo ✓ Go found: %GO_EXE%

REM Go to core directory
cd hiddify-core-main

REM Set environment variables
set GOOS=windows
set GOARCH=amd64
set CGO_ENABLED=0

echo 🔨 Building core without CGO...

REM Try building without CGO first
%GO_EXE% build -ldflags="-w -s" -o bin\hiddify-core.exe ./cli

if %errorlevel% equ 0 (
    echo ✅ Core built successfully without CGO
    echo ℹ️  Note: Some features may be limited without CGO
) else (
    echo ❌ Build failed
    exit /b 1
)

echo 📁 Copying to libcore directory...
copy bin\hiddify-core.exe ..\libcore\bin\

echo ✅ Build completed!
cd .. 