# NuGet Installation Script for Hiddify
# This script installs NuGet CLI and adds it to the system PATH

param(
    [switch]$Force = $false
)

Write-Host "🔧 Hiddify NuGet Setup Script" -ForegroundColor Green

# Check if NuGet is already in PATH
$nugetInPath = Get-Command nuget -ErrorAction SilentlyContinue
if ($nugetInPath -and -not $Force) {
    Write-Host "✅ NuGet is already available in PATH at: $($nugetInPath.Source)" -ForegroundColor Green
    exit 0
}

# Check if local nuget.exe exists and add to PATH
$localNuget = Join-Path $PSScriptRoot "..\nuget\nuget.exe"
if (Test-Path $localNuget) {
    $nugetDir = Split-Path $localNuget -Parent
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -notlike "*$nugetDir*") {
        Write-Host "📦 Adding local NuGet directory to user PATH..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$nugetDir", "User")
        $env:PATH = "$env:PATH;$nugetDir"
        Write-Host "✅ Local NuGet added to PATH successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "✅ Local NuGet directory is already in PATH" -ForegroundColor Green
        exit 0
    }
}

# Download and install NuGet CLI
try {
    Write-Host "🌐 Downloading latest NuGet CLI..." -ForegroundColor Yellow
    
    # Create nuget directory if it doesn't exist
    $nugetDir = Join-Path $PSScriptRoot "..\nuget"
    if (-not (Test-Path $nugetDir)) {
        New-Item -ItemType Directory -Path $nugetDir -Force | Out-Null
    }
    
    # Download NuGet CLI
    $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $nugetPath = Join-Path $nugetDir "nuget.exe"
    
    # Use TLS 1.2 for secure download
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath -UseBasicParsing
    
    # Verify download
    if (Test-Path $nugetPath) {
        $fileSize = (Get-Item $nugetPath).Length
        if ($fileSize -gt 1MB) {
            Write-Host "✅ NuGet CLI downloaded successfully ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green
            
            # Add to PATH
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$nugetDir*") {
                [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$nugetDir", "User")
                $env:PATH = "$env:PATH;$nugetDir"
                Write-Host "✅ NuGet added to PATH successfully!" -ForegroundColor Green
            }
            
            # Test NuGet
            Write-Host "🧪 Testing NuGet installation..." -ForegroundColor Yellow
            & $nugetPath help | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ NuGet is working correctly!" -ForegroundColor Green
                Write-Host ""
                Write-Host "🎉 Setup complete! You may need to restart your terminal for PATH changes to take effect." -ForegroundColor Cyan
            } else {
                throw "NuGet test failed"
            }
        } else {
            throw "Downloaded file is too small (possible download failure)"
        }
    } else {
        throw "Download failed - file not found"
    }
    
} catch {
    Write-Host "❌ Error installing NuGet: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Manual installation options:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://www.nuget.org/downloads" -ForegroundColor Gray
    Write-Host "2. Download nuget.exe and place it in: $nugetDir" -ForegroundColor Gray
    Write-Host "3. Add $nugetDir to your PATH environment variable" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎯 Or use Package Manager:" -ForegroundColor Yellow
    Write-Host "   winget install Microsoft.NuGet" -ForegroundColor Gray
    Write-Host "   choco install nuget.commandline" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "📋 To verify installation, run: nuget help" -ForegroundColor Cyan
Write-Host "📋 Current version:" -ForegroundColor Cyan
& $nugetPath | Select-Object -First 1 