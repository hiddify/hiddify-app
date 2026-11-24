# SignPath signing of the Flutter Release tree, in two halves around the SignPath request.
#
# SignPath signs on its own servers: the workflow uploads a GitHub artifact, SignPath
# signs what windows/signpath/release-tree.xml names and returns the signed copy. That
# cannot run inside fastforge's pre-package hook, so the tree is signed once and the hook
# puts the signed files back after each fastforge rebuild:
#
#   -Mode Collect  copies every PE file of the tree that has no trusted signature yet
#                  (MSVC runtimes are Microsoft-signed and stay out) into -Stage, flat,
#                  and writes -Manifest: relative path, flat name and SHA-256 of each file.
#   -Mode Apply    copies the signed files from -Signed back into the tree. A file is only
#                  replaced when it is byte-identical to the one that was signed, so a
#                  rebuild that changed a binary fails the job instead of shipping it unsigned.
#
# See docs/windows-code-signing.md (SignPath).

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Collect', 'Apply')][string]$Mode,
    [string]$Tree = 'build\windows\x64\runner\Release',
    [string]$Stage = $env:SIGNPATH_STAGE_DIR,
    [string]$Signed = $env:SIGNPATH_SIGNED_DIR,
    [string]$Manifest = $env:SIGNPATH_MANIFEST
)

$ErrorActionPreference = 'Stop'

function Get-Sha256([string]$File) { (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash }

$treeRoot = (Resolve-Path -LiteralPath $Tree).Path.TrimEnd('\')

if ($Mode -eq 'Collect') {
    if (-not $Stage -or -not $Manifest) { throw 'Collect needs -Stage and -Manifest (or SIGNPATH_STAGE_DIR / SIGNPATH_MANIFEST)' }
    New-Item -ItemType Directory -Path $Stage -Force | Out-Null
    $entries = @()
    $names = @{}
    $files = Get-ChildItem -LiteralPath $treeRoot -Recurse -File | Where-Object { $_.Extension -in '.exe', '.dll' }
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($treeRoot.Length + 1)
        if ((Get-AuthenticodeSignature -LiteralPath $file.FullName).Status -eq 'Valid') {
            Write-Host "skip (already trusted-signed): $rel"
            continue
        }
        # Flat names keep the artifact configuration to two patterns (*.exe, *.dll).
        $flat = $file.Name
        if ($names.ContainsKey($flat.ToLowerInvariant())) { throw "Two PE files named $flat in the tree ($rel, $($names[$flat.ToLowerInvariant()]))" }
        $names[$flat.ToLowerInvariant()] = $rel
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $Stage $flat)
        $entries += [pscustomobject]@{ path = $rel; name = $flat; sha256 = Get-Sha256 $file.FullName }
        Write-Host "to sign: $rel"
    }
    if (-not $entries) { throw "No unsigned PE files under $treeRoot" }
    ConvertTo-Json -InputObject @($entries) | Set-Content -LiteralPath $Manifest -Encoding utf8
    Write-Host "$($entries.Count) file(s) staged in $Stage"
    exit 0
}

# Apply
if (-not $Signed -or -not $Manifest) { throw 'Apply needs -Signed and -Manifest (or SIGNPATH_SIGNED_DIR / SIGNPATH_MANIFEST)' }
$entries = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
foreach ($entry in $entries) {
    $source = Join-Path $Signed $entry.name
    $target = Join-Path $treeRoot $entry.path
    if (-not (Test-Path -LiteralPath $source)) { throw "SignPath returned no $($entry.name)" }
    if ((Get-AuthenticodeSignature -LiteralPath $source).Status -eq 'NotSigned') { throw "SignPath returned $($entry.name) unsigned" }
    if (-not (Test-Path -LiteralPath $target)) {
        Write-Warning "not in this tree, skipped: $($entry.path)"
        continue
    }
    $current = Get-Sha256 $target
    if ($current -eq (Get-Sha256 $source)) { continue }
    if ($current -ne $entry.sha256) {
        throw "$($entry.path) changed since it was sent to SignPath (rebuild produced a different binary); it would ship unsigned"
    }
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Host "signed copy applied: $($entry.path)"
}
exit 0
