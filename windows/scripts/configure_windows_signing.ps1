# Prepares Windows code signing for one CI job (run before any Windows build step).
#
#   1. Picks the backend for sign_windows_artifacts.ps1:
#        Azure Artifact Signing  when AZURE_SIGNING_ENDPOINT / AZURE_SIGNING_ACCOUNT /
#                                AZURE_SIGNING_CERT_PROFILE are set (preferred: publicly
#                                trusted Microsoft-issued certificate, no PFX secret).
#        PFX                     when WINDOWS_SIGNING_KEY (base64 PFX) is set.
#   2. Validates the material and warns loudly when the PFX is self-signed.
#   3. Patches windows/packaging/msix/make_config.yaml so the MSIX Publisher equals
#      the certificate Subject (otherwise msix signing / sideloading fails).
#   4. Registers the "hiddifysign" Inno Setup Sign Tool (HKCU, read by ISCC) so
#      Setup.exe and its embedded uninstaller are signed by the Inno compiler.
#   5. Exports WINDOWS_SIGN_BACKEND, WINDOWS_SIGN_PFX, HIDDIFY_INNO_SIGNTOOL,
#      AZURE_OIDC to $GITHUB_ENV.
#
# Inputs (environment): AZURE_SIGNING_ENDPOINT, AZURE_SIGNING_ACCOUNT,
#   AZURE_SIGNING_CERT_PROFILE, AZURE_CLIENT_SECRET, AZURE_SUBSCRIPTION_ID,
#   WINDOWS_SIGNING_PUBLISHER, WINDOWS_SIGNING_KEY, WINDOWS_SIGNING_PASSWORD,
#   WINDOWS_SIGNING_SHA1. See docs/windows-code-signing.md.

[CmdletBinding()]
param(
    [string]$MsixConfig = 'windows\packaging\msix\make_config.yaml',
    [string]$PfxOut = 'windows\sign.pfx',
    [string]$SignScript = 'windows\scripts\sign_windows_artifacts.ps1',
    [switch]$SkipInnoSignTool
)

$ErrorActionPreference = 'Stop'

# .NET file APIs resolve relative paths against the process directory, not $PWD.
if (-not [System.IO.Path]::IsPathRooted($PfxOut)) { $PfxOut = Join-Path (Get-Location).Path $PfxOut }

function Set-CiEnv([string]$Name, [string]$Value) {
    if ($env:GITHUB_ENV) { "$Name=$Value" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8 }
    Set-Item -Path "env:$Name" -Value $Value
}

function Add-Summary([string]$Text) {
    if ($env:GITHUB_STEP_SUMMARY) { $Text | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8 }
    Write-Host $Text
}

function Write-CiWarning([string]$Message) {
    if ($env:GITHUB_ACTIONS) { Write-Host "::warning::$Message" } else { Write-Warning $Message }
}

function Set-YamlScalar {
    param([string]$File, [string]$Key, [string]$Value)
    $text = Get-Content -LiteralPath $File -Raw
    $line = "${Key}: $Value"
    $pattern = "(?m)^${Key}:.*$"
    $regex = [regex]::new($pattern)
    if ($regex.IsMatch($text)) {
        # MatchEvaluator: the value is inserted verbatim (no $1-style substitution of passwords).
        $text = $regex.Replace($text, [System.Text.RegularExpressions.MatchEvaluator] { param($m) $line }, 1)
    }
    else {
        if (-not $text.EndsWith("`n")) { $text += "`n" }
        $text += "$line`n"
    }
    Set-Content -LiteralPath $File -Value $text -NoNewline -Encoding utf8
}

function Remove-YamlKey {
    param([string]$File, [string]$Key)
    $text = Get-Content -LiteralPath $File -Raw
    $text = [regex]::Replace($text, "(?m)^${Key}:.*(\r?\n|$)", '')
    Set-Content -LiteralPath $File -Value $text -NoNewline -Encoding utf8
}

function Format-YamlString([string]$Value) {
    return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

$backend = 'None'
$publisher = ''
$selfSigned = $false
$certDescription = ''

if ($env:AZURE_SIGNING_ENDPOINT -and $env:AZURE_SIGNING_ACCOUNT -and $env:AZURE_SIGNING_CERT_PROFILE) {
    $backend = 'ArtifactSigning'
    $publisher = $env:WINDOWS_SIGNING_PUBLISHER
    if (-not $publisher) {
        throw 'WINDOWS_SIGNING_PUBLISHER is required with Azure Artifact Signing: the exact certificate Subject of the certificate profile (e.g. "CN=Hiddify, O=Hiddify, L=City, S=State, C=US"), used as the MSIX Publisher.'
    }
    $certDescription = "Azure Artifact Signing account '$($env:AZURE_SIGNING_ACCOUNT)', profile '$($env:AZURE_SIGNING_CERT_PROFILE)'"
    if ($env:AZURE_CLIENT_SECRET) {
        Set-CiEnv 'AZURE_OIDC' 'false'
    }
    elseif ($env:AZURE_SUBSCRIPTION_ID) {
        # No client secret: the workflow runs azure/login with OIDC (federated credential).
        Set-CiEnv 'AZURE_OIDC' 'true'
    }
    else {
        throw 'Azure Artifact Signing needs credentials: AZURE_CLIENT_SECRET (service principal secret) or AZURE_SUBSCRIPTION_ID + a federated credential for azure/login (OIDC).'
    }
}
elseif ($env:WINDOWS_SIGNING_KEY) {
    $backend = 'Pfx'
    [IO.File]::WriteAllBytes($PfxOut, [Convert]::FromBase64String($env:WINDOWS_SIGNING_KEY))
    $pfx = (Resolve-Path -LiteralPath $PfxOut).Path
    # Fail early with a readable reason instead of SignTool's "No certificates were found".
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfx, $env:WINDOWS_SIGNING_PASSWORD)
    if (-not $cert.HasPrivateKey) { throw 'WINDOWS_SIGNING_KEY has no private key' }
    if ($cert.NotAfter -lt (Get-Date)) { throw "Windows signing certificate expired on $($cert.NotAfter); update WINDOWS_SIGNING_KEY / WINDOWS_SIGNING_PASSWORD / WINDOWS_SIGNING_SHA1" }
    if ($env:WINDOWS_SIGNING_SHA1 -and $cert.Thumbprint -ne $env:WINDOWS_SIGNING_SHA1.ToUpper()) {
        Write-CiWarning 'WINDOWS_SIGNING_SHA1 does not match the certificate thumbprint'
    }
    $publisher = $cert.Subject
    $selfSigned = ($cert.Subject -eq $cert.Issuer)
    $certDescription = "PFX subject '$($cert.Subject)', issuer '$($cert.Issuer)', thumbprint $($cert.Thumbprint), valid until $($cert.NotAfter.ToString('u'))"
    Set-CiEnv 'WINDOWS_SIGN_PFX' $pfx
}
else {
    throw 'No Windows signing material: configure Azure Artifact Signing (AZURE_SIGNING_ENDPOINT, AZURE_SIGNING_ACCOUNT, AZURE_SIGNING_CERT_PROFILE, WINDOWS_SIGNING_PUBLISHER + credentials) or a CA-issued PFX (WINDOWS_SIGNING_KEY, WINDOWS_SIGNING_PASSWORD). See docs/windows-code-signing.md.'
}

Set-CiEnv 'WINDOWS_SIGN_BACKEND' $backend

# --- MSIX: Publisher must equal the certificate Subject --------------------------
if (Test-Path -LiteralPath $MsixConfig) {
    Set-YamlScalar -File $MsixConfig -Key 'publisher' -Value (Format-YamlString $publisher)
    if ($backend -eq 'ArtifactSigning') {
        # The msix tool only signs with a PFX; with sign_msix=false it keeps our Publisher
        # untouched and the .msix is signed afterwards by sign_windows_artifacts.ps1.
        # certificate_path must be absent (an empty value makes the tool look for the file).
        Set-YamlScalar -File $MsixConfig -Key 'sign_msix' -Value '"false"'
        Remove-YamlKey -File $MsixConfig -Key 'certificate_path'
        Remove-YamlKey -File $MsixConfig -Key 'certificate_password'
    }
    else {
        Set-YamlScalar -File $MsixConfig -Key 'sign_msix' -Value '"true"'
        Set-YamlScalar -File $MsixConfig -Key 'certificate_path' -Value (Format-YamlString $PfxOut)
        Set-YamlScalar -File $MsixConfig -Key 'certificate_password' -Value (Format-YamlString $env:WINDOWS_SIGNING_PASSWORD)
    }
    Write-Host "MSIX config patched: publisher=$publisher sign_msix=$($backend -ne 'ArtifactSigning')"
}
else {
    Write-Warning "MSIX config not found: $MsixConfig"
}

# --- Inno Setup Sign Tool (ISCC reads HKCU\Software\Jordan Russell\Inno Setup\SignTools) ---
if (-not $SkipInnoSignTool) {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { $pwsh = (Get-Command powershell).Source }
    $script = (Resolve-Path -LiteralPath $SignScript).Path
    # $f is replaced by Inno Setup with the quoted path of the file to sign.
    $command = "`"$pwsh`" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`" -Path `$f -Description Hiddify"
    $key = 'HKCU:\Software\Jordan Russell\Inno Setup\SignTools'
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name 'SignTool0' -Value "hiddifysign=$command"
    Set-CiEnv 'HIDDIFY_INNO_SIGNTOOL' 'hiddifysign'
    Write-Host "Inno Setup Sign Tool registered: hiddifysign=$command"
}

# --- Summary ---------------------------------------------------------------------
Add-Summary "### Windows code signing`n"
Add-Summary "- Backend: **$backend**"
Add-Summary "- Certificate: $certDescription"
Add-Summary "- MSIX publisher: ``$publisher``"
if ($selfSigned) {
    $msg = 'The Windows release is signed with a SELF-SIGNED certificate. Antivirus engines and SmartScreen give it no reputation, so VirusTotal false positives (Webroot W32.Trojan.Gen, Bkav, DeepInstinct) will continue. Configure Azure Artifact Signing or a CA-issued certificate: docs/windows-code-signing.md'
    Write-CiWarning $msg
    Add-Summary "- :warning: $msg"
}
exit 0
