@echo off
echo === Hiddify Quick Build ===

REM Setup NuGet first
call scripts\setup_nuget.bat
if %errorlevel% neq 0 (
    echo Warning: NuGet setup failed, but continuing with build...
)

REM Optimize memory usage
set DART_VM_OPTIONS=--max-heap-size=4g

REM Check if this is first run or dependencies changed
if not exist "pubspec.lock" (
    echo Getting dependencies...
    flutter pub get
) else (
    echo Dependencies OK, skipping pub get...
)

REM Clean only if needed (check for errors)
if exist "build\windows\x64\runner\Debug\*.exp" (
    echo Cleaning temp files...
    del /q "build\windows\x64\runner\Debug\*.exp" 2>nul
    del /q "build\windows\x64\runner\Debug\*.lib" 2>nul
    del /q "build\windows\x64\runner\Debug\*.pdb" 2>nul
)

echo Building application...
flutter build windows --debug --no-version-check --suppress-analytics

if %ERRORLEVEL% EQU 0 (
    echo.
    echo === BUILD SUCCESSFUL ===
    echo Executable: build\windows\x64\runner\Debug\Hiddify.exe
    echo.
    echo To run: cd build\windows\x64\runner\Debug ^&^& Hiddify.exe
) else (
    echo.
    echo === BUILD FAILED ===
    echo Check the error messages above
)

pause 