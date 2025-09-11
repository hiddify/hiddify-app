@echo off
chcp 65001 >nul

echo Setting up NuGet for Flutter builds...

REM Check if NuGet is already in PATH
where nuget >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ NuGet is already available in PATH
    nuget
    exit /b 0
)

REM Check if NuGet exists in tools directory
if exist "C:\tools\nuget\nuget.exe" (
    echo ✓ Found NuGet in C:\tools\nuget\
    echo Adding to PATH for current session...
    set PATH=%PATH%;C:\tools\nuget
    
    REM Add to user PATH permanently
    powershell -Command "[Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'User') + ';C:\tools\nuget', 'User')" >nul 2>&1
    
    echo ✓ NuGet is now available
    C:\tools\nuget\nuget.exe
    exit /b 0
)

REM Download NuGet if not found
echo Downloading NuGet.exe...
mkdir C:\tools\nuget >nul 2>&1

powershell -Command "try { Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'C:\tools\nuget\nuget.exe' -UseBasicParsing; Write-Host 'Download completed successfully' } catch { Write-Host 'Download failed:' $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo ✗ Failed to download NuGet
    exit /b 1
)

if exist "C:\tools\nuget\nuget.exe" (
    echo ✓ NuGet downloaded successfully
    
    REM Add to PATH
    set PATH=%PATH%;C:\tools\nuget
    
    REM Add to user PATH permanently
    powershell -Command "[Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'User') + ';C:\tools\nuget', 'User')" >nul 2>&1
    
    echo ✓ NuGet setup completed
    C:\tools\nuget\nuget.exe
) else (
    echo ✗ NuGet download failed
    exit /b 1
) 