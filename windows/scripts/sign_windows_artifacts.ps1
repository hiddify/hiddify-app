# Authenticode-sign Windows release artifacts: loose PE files and packages under a
# folder, single files, and the PE files inside portable .zip archives.
#
# Backends (-Backend, default Auto):
#   ArtifactSigning  Azure Artifact Signing (formerly "Trusted Signing"): publicly
#                    trusted, short-lived certificates issued by Microsoft. Chosen
#                    automatically when AZURE_SIGNING_ENDPOINT, AZURE_SIGNING_ACCOUNT
#                    and AZURE_SIGNING_CERT_PROFILE are set. Authentication uses
#                    DefaultAzureCredential: AZURE_TENANT_ID / AZURE_CLIENT_ID /
#                    AZURE_CLIENT_SECRET, or an `azure/login` (OIDC) session.
#   Pfx              signtool with a PFX file (-PfxPath or WINDOWS_SIGN_PFX, password
#                    from -Password or WINDOWS_SIGNING_PASSWORD). Only a CA-issued
#                    OV/EV certificate earns AV / SmartScreen reputation; a self-signed
#                    PFX is accepted but flagged with a warning.
#
# Files whose existing signature already chains to a trusted root (MSVC runtimes,
# Store-signed packages, files signed earlier in the same job) are left untouched.
# See docs/windows-code-signing.md.
#
# Usage (repo root, Windows, Windows SDK installed):
#   pwsh -File windows/scripts/sign_windows_artifacts.ps1 -Path dist
#   pwsh -File windows/scripts/sign_windows_artifacts.ps1 -Path build\windows\x64\runner\Release
#   pwsh -File windows/scripts/sign_windows_artifacts.ps1 -Path "C:\x\Setup.exe"   (Inno Setup Sign Tool)

[CmdletBinding()]
param(
    [ValidateSet('Auto', 'ArtifactSigning', 'Pfx')]
    [string]$Backend = 'Auto',

    [string]$PfxPath = $env:WINDOWS_SIGN_PFX,

    [string]$Password = $env:WINDOWS_SIGNING_PASSWORD,

    [string[]]$Path = @('dist'),

    [string]$Description = 'Hiddify',

    [string]$DescriptionUrl = 'https://hiddify.com',

    # RFC 3161 timestamp server. Default depends on the backend.
    [string]$TimestampUrl = ''
)

$ErrorActionPreference = 'Stop'

$ArtifactSigningModuleVersion = '0.1.20'   # same pin as azure/artifact-signing-action@v2

$peExts = @('.dll', '.exe', '.sys', '.ps1', '.psm1')
$packageExts = @('.msix', '.msixbundle', '.appx', '.appxbundle', '.msi', '.msp', '.msm', '.cab')
$signExts = $peExts + $packageExts

function Write-CiWarning([string]$Message) {
    if ($env:GITHUB_ACTIONS) { Write-Host "::warning::$Message" } else { Write-Warning $Message }
}

function Get-SignTool {
    $signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
        Sort-Object { [version]$_.Directory.Parent.Name } -Descending |
        Select-Object -First 1
    if (-not $signtool) { throw 'signtool.exe not found under Windows Kits\10\bin' }
    return $signtool.FullName
}

function Resolve-Backend {
    if ($Backend -ne 'Auto') { return $Backend }
    if ($env:AZURE_SIGNING_ENDPOINT -and $env:AZURE_SIGNING_ACCOUNT -and $env:AZURE_SIGNING_CERT_PROFILE) {
        return 'ArtifactSigning'
    }
    if ($PfxPath) { return 'Pfx' }
    throw 'No signing backend configured: set AZURE_SIGNING_ENDPOINT / AZURE_SIGNING_ACCOUNT / AZURE_SIGNING_CERT_PROFILE, or -PfxPath / WINDOWS_SIGN_PFX.'
}

# True when the file carries a signature that chains to a trusted root.
function Test-IsTrustedSigned {
    param([string]$SignTool, [string]$FilePath)
    & $SignTool verify /pa /q $FilePath 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Invoke-WithRetry {
    param([scriptblock]$Action, [string]$What, [int]$Attempts = 4)
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            & $Action
            return
        }
        catch {
            if ($i -eq $Attempts) { throw "$What failed after $Attempts attempts: $_" }
            Write-Host "$What failed (attempt $i/$Attempts): $_ -- retrying"
            Start-Sleep -Seconds (5 * $i)
        }
    }
}

# ---------------------------------------------------------------------------
# Backend: Azure Artifact Signing
# ---------------------------------------------------------------------------
function Initialize-ArtifactSigning {
    if (Get-Command Invoke-ArtifactSigning -ErrorAction SilentlyContinue) { return }
    $installed = Get-Module -ListAvailable -Name ArtifactSigning |
        Where-Object { $_.Version -eq [version]$ArtifactSigningModuleVersion }
    if (-not $installed) {
        Write-Host "Installing PowerShell module ArtifactSigning $ArtifactSigningModuleVersion"
        Invoke-WithRetry -What 'Install-Module ArtifactSigning' -Action {
            Install-Module -Name ArtifactSigning -RequiredVersion $ArtifactSigningModuleVersion `
                -Force -Scope CurrentUser -Repository PSGallery -AllowClobber
        }
    }
    Import-Module ArtifactSigning -RequiredVersion $ArtifactSigningModuleVersion -Force
}

function Invoke-ArtifactSigningBackend {
    param([string[]]$Files, [string]$Timestamp)
    Initialize-ArtifactSigning
    $params = @{
        Endpoint               = $env:AZURE_SIGNING_ENDPOINT
        CodeSigningAccountName = $env:AZURE_SIGNING_ACCOUNT
        CertificateProfileName = $env:AZURE_SIGNING_CERT_PROFILE
        Files                  = ($Files -join ',')
        FileDigest             = 'SHA256'
        TimestampRfc3161       = $Timestamp
        TimestampDigest        = 'SHA256'
        Description            = $Description
        DescriptionUrl         = $DescriptionUrl
    }
    Invoke-WithRetry -What 'Invoke-ArtifactSigning' -Action { Invoke-ArtifactSigning @params }
}

# ---------------------------------------------------------------------------
# Backend: PFX + signtool
# ---------------------------------------------------------------------------
$script:PfxCertificate = $null
function Get-PfxCertificate2 {
    if ($script:PfxCertificate) { return $script:PfxCertificate }
    if (-not (Test-Path -LiteralPath $PfxPath)) { throw "PFX not found: $PfxPath" }
    $pfx = (Resolve-Path -LiteralPath $PfxPath).Path
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfx, $Password)
    if (-not $cert.HasPrivateKey) { throw 'The PFX has no private key' }
    if ($cert.NotAfter -lt (Get-Date)) { throw "The signing certificate expired on $($cert.NotAfter)" }
    $script:PfxCertificate = $cert
    Write-Host "PFX certificate: $($cert.Subject) (issuer: $($cert.Issuer), thumbprint $($cert.Thumbprint), valid until $($cert.NotAfter))"
    if ($cert.Subject -eq $cert.Issuer) {
        Write-CiWarning 'Windows artifacts are signed with a SELF-SIGNED certificate. That earns no antivirus or SmartScreen reputation and VirusTotal false positives will continue. Configure Azure Artifact Signing or a CA-issued certificate (docs/windows-code-signing.md).'
    }
    return $cert
}

function Test-PfxIsSelfSigned {
    $cert = Get-PfxCertificate2
    return ($cert.Subject -eq $cert.Issuer)
}

function Invoke-PfxBackend {
    param([string]$SignTool, [string[]]$Files, [string]$Timestamp)
    $null = Get-PfxCertificate2
    $pfx = (Resolve-Path -LiteralPath $PfxPath).Path
    foreach ($file in $Files) {
        Write-Host "signtool sign: $file"
        Invoke-WithRetry -What "signtool sign $file" -Action {
            & $SignTool sign /fd SHA256 /td SHA256 /tr $Timestamp /d $Description /du $DescriptionUrl /f $pfx /p $Password $file
            if ($LASTEXITCODE -ne 0) { throw "signtool exit code $LASTEXITCODE" }
        }
    }
}

# ---------------------------------------------------------------------------
# Common driver
# ---------------------------------------------------------------------------
function Get-FilesToSign {
    param([string]$SignTool, [string]$Root, [string[]]$Extensions)
    $result = @()
    $files = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
        $Extensions -contains $_.Extension.ToLowerInvariant()
    }
    foreach ($file in $files) {
        if (Test-IsTrustedSigned -SignTool $SignTool -FilePath $file.FullName) {
            Write-Host "Already signed by a trusted publisher, skip: $($file.FullName)"
            continue
        }
        $result += $file.FullName
    }
    return $result
}

function Invoke-SignFiles {
    param([string]$SignTool, [string]$ActiveBackend, [string[]]$Files, [string]$Timestamp)
    if (-not $Files -or $Files.Count -eq 0) {
        Write-Host 'Nothing to sign.'
        return
    }
    Write-Host "Signing $($Files.Count) file(s) with backend $ActiveBackend"
    switch ($ActiveBackend) {
        'ArtifactSigning' { Invoke-ArtifactSigningBackend -Files $Files -Timestamp $Timestamp }
        'Pfx' { Invoke-PfxBackend -SignTool $SignTool -Files $Files -Timestamp $Timestamp }
    }

    # Verify. A self-signed PFX never verifies against a trusted root, so only warn there.
    $strict = ($ActiveBackend -eq 'ArtifactSigning') -or -not (Test-PfxIsSelfSigned)
    foreach ($file in $Files) {
        if (Test-IsTrustedSigned -SignTool $SignTool -FilePath $file) {
            Write-Host "Verified (trusted chain): $file"
        }
        elseif ($strict) {
            & $SignTool verify /pa /v $file
            throw "Signature on $file does not chain to a trusted root"
        }
        else {
            Write-Host "Signed (self-signed, not trusted): $file"
        }
    }
}

function Invoke-SignZip {
    param([string]$SignTool, [string]$ActiveBackend, [string]$ZipPath, [string]$Timestamp)

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $guid = [guid]::NewGuid().ToString('N')
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("hiddify-sign-zip-" + $guid)
    $tmpZip = Join-Path ([System.IO.Path]::GetTempPath()) ("hiddify-sign-zip-" + $guid + ".zip")
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        Write-Host "Extracting zip for signing: $ZipPath"
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $tmp)

        # Only PE files inside the zip (not nested packages).
        $files = Get-FilesToSign -SignTool $SignTool -Root $tmp -Extensions $peExts
        if ($files.Count -eq 0) {
            Write-Host "No unsigned PE files in $ZipPath"
            return
        }
        Invoke-SignFiles -SignTool $SignTool -ActiveBackend $ActiveBackend -Files $files -Timestamp $Timestamp

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
$activeBackend = Resolve-Backend
if (-not $TimestampUrl) {
    $TimestampUrl = if ($activeBackend -eq 'ArtifactSigning') { 'http://timestamp.acs.microsoft.com' } else { 'http://timestamp.digicert.com' }
}
Write-Host "Signing backend: $activeBackend (timestamp: $TimestampUrl)"
if ($activeBackend -eq 'Pfx') { $null = Get-PfxCertificate2 }

foreach ($p in $Path) {
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Warning "Path not found, skip: $p"
        continue
    }

    $item = Get-Item -LiteralPath $p
    if ($item.PSIsContainer) {
        # Loose packages / PE files under the tree first (one batch).
        $files = Get-FilesToSign -SignTool $signtool -Root $item.FullName -Extensions $signExts
        Invoke-SignFiles -SignTool $signtool -ActiveBackend $activeBackend -Files $files -Timestamp $TimestampUrl

        # Then PE files embedded in portable zips (the outer .zip itself cannot carry Authenticode).
        $zips = Get-ChildItem -Path $item.FullName -Recurse -File -Filter *.zip
        foreach ($zip in $zips) {
            Invoke-SignZip -SignTool $signtool -ActiveBackend $activeBackend -ZipPath $zip.FullName -Timestamp $TimestampUrl
        }
    }
    elseif ($item.Extension -eq '.zip') {
        Invoke-SignZip -SignTool $signtool -ActiveBackend $activeBackend -ZipPath $item.FullName -Timestamp $TimestampUrl
    }
    else {
        # A file named explicitly is signed whatever its extension: Inno Setup hands the
        # compiler-generated Setup.exe / uninstaller over under temporary names.
        if (Test-IsTrustedSigned -SignTool $signtool -FilePath $item.FullName) {
            Write-Host "Already signed by a trusted publisher, skip: $($item.FullName)"
        }
        else {
            Invoke-SignFiles -SignTool $signtool -ActiveBackend $activeBackend -Files @($item.FullName) -Timestamp $TimestampUrl
        }
    }
}

Write-Host 'Windows Authenticode signing finished.'
# Explicit success: the last native command may be a `signtool verify` that returned
# non-zero (self-signed PFX), and both Inno Setup (Sign Tool) and the GitHub Actions
# pwsh shell treat a leftover non-zero $LASTEXITCODE as failure.
exit 0
