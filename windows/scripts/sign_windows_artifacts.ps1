# Authenticode-sign Windows release artifacts under dist/ (and PE files inside .zip).
# Skips files that already verify as signed (keeps Microsoft VC runtime signatures).
#
# Usage (from repo root, on Windows with a Windows SDK):
#   powershell -File windows/scripts/sign_windows_artifacts.ps1 `
#     -PfxPath windows\sign.pfx -Password $env:SIGN_PASSWORD -Path dist

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PfxPath,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string[]]$Path = @('dist'),

    [string]$Description = 'Hiddify'
)

$ErrorActionPreference = 'Stop'

$peExts = @('.dll', '.exe', '.sys', '.ps1', '.psm1')
$packageExts = @('.msix', '.msixbundle', '.appx', '.appxbundle', '.msi', '.msp', '.msm', '.cab')
$signExts = $peExts + $packageExts

function Get-SignTool {
    $signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
        Sort-Object { [version]$_.Directory.Parent.Name } -Descending |
        Select-Object -First 1
    if (-not $signtool) { throw 'signtool.exe not found under Windows Kits\10\bin' }
    return $signtool.FullName
}

function Test-IsSigned {
    param(
        [string]$SignTool,
        [string]$FilePath
    )
    & $SignTool verify /pa /q $FilePath 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Invoke-SignFile {
    param(
        [string]$SignTool,
        [string]$FilePath,
        [string]$Pfx,
        [string]$Pass,
        [string]$Desc
    )

    if (Test-IsSigned -SignTool $SignTool -FilePath $FilePath) {
        Write-Host "Already signed, skip: $FilePath"
        return
    }

    Write-Host "Signing $FilePath"
    $ok = $false
    foreach ($attempt in 1..5) {
        & $SignTool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com `
            /d $Desc /f $Pfx /p $Pass $FilePath
        if ($LASTEXITCODE -eq 0) {
            $ok = $true
            break
        }
        Start-Sleep -Seconds $attempt
    }
    if (-not $ok) { throw "failed to sign $FilePath" }
}

function Invoke-SignTree {
    param(
        [string]$SignTool,
        [string]$Root,
        [string]$Pfx,
        [string]$Pass,
        [string]$Desc,
        [string[]]$Extensions
    )

    $files = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
        $Extensions -contains $_.Extension.ToLowerInvariant()
    }
    foreach ($file in $files) {
        Invoke-SignFile -SignTool $SignTool -FilePath $file.FullName -Pfx $Pfx -Pass $Pass -Desc $Desc
    }
}

function Invoke-SignZip {
    param(
        [string]$SignTool,
        [string]$ZipPath,
        [string]$Pfx,
        [string]$Pass,
        [string]$Desc
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $guid = [guid]::NewGuid().ToString('N')
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("hiddify-sign-zip-" + $guid)
    $tmpZip = Join-Path ([System.IO.Path]::GetTempPath()) ("hiddify-sign-zip-" + $guid + ".zip")
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        Write-Host "Extracting zip for signing: $ZipPath"
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $tmp)

        # Only PE files inside the zip (not nested packages).
        Invoke-SignTree -SignTool $SignTool -Root $tmp -Pfx $Pfx -Pass $Pass -Desc $Desc -Extensions $peExts

        Write-Host "Repacking signed zip: $ZipPath"
        if (Test-Path -LiteralPath $tmpZip) { Remove-Item -LiteralPath $tmpZip -Force }
        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $tmp,
            $tmpZip,
            [System.IO.Compression.CompressionLevel]::Optimal,
            $false
        )
        Move-Item -LiteralPath $tmpZip -Destination $ZipPath -Force
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue
    }
}

$signtool = Get-SignTool
Write-Host "Using $signtool"
$pfx = (Resolve-Path -LiteralPath $PfxPath).Path

foreach ($p in $Path) {
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Warning "Path not found, skip: $p"
        continue
    }

    $item = Get-Item -LiteralPath $p
    if ($item.PSIsContainer) {
        # Sign loose packages / PE under the tree first.
        Invoke-SignTree -SignTool $signtool -Root $item.FullName -Pfx $pfx -Pass $Password -Desc $Description -Extensions $signExts

        # Then sign PE files embedded in portable zips (outer .zip itself is not Authenticode-signed).
        $zips = Get-ChildItem -Path $item.FullName -Recurse -File -Filter *.zip
        foreach ($zip in $zips) {
            Invoke-SignZip -SignTool $signtool -ZipPath $zip.FullName -Pfx $pfx -Pass $Password -Desc $Description
        }
    }
    elseif ($item.Extension -eq '.zip') {
        Invoke-SignZip -SignTool $signtool -ZipPath $item.FullName -Pfx $pfx -Pass $Password -Desc $Description
    }
    elseif ($signExts -contains $item.Extension.ToLowerInvariant()) {
        Invoke-SignFile -SignTool $signtool -FilePath $item.FullName -Pfx $pfx -Pass $Password -Desc $Description
    }
    else {
        Write-Warning "Unsupported path for signing: $p"
    }
}

Write-Host 'Windows Authenticode signing finished.'
