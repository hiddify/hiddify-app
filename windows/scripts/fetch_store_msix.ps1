<#
.SYNOPSIS
  Download the Store-signed package of a published Microsoft Store app.

.DESCRIPTION
  Uses the anonymous endpoints the Microsoft Store client itself uses: the display
  catalog (product -> WuCategoryId) and the FE3 delivery service (SyncUpdates ->
  GetExtendedUpdateInfo2 -> CDN URL). No Partner Center or Entra credentials needed.

  Exit codes: 0 = downloaded (path printed last), 3 = the Store does not serve
  -Version yet (still in certification / publishing), anything else = error.

.EXAMPLE
  ./fetch_store_msix.ps1 -ProductId 9NXXXXXXXXXX -OutDir out -Version 5.2.1.0
  ./fetch_store_msix.ps1 -ProductId 9N0DX20HK701 -List
#>
param(
    [Parameter(Mandatory)] [string]$ProductId,
    [string]$OutDir = '.',
    [string]$Version = '',
    [string]$Arch = 'x64',
    [string]$OutName = '',
    [switch]$List
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Fe3 = 'https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx'

function Invoke-Soap([string]$Action, [string]$Body, [string]$Url = $Fe3) {
    $now = [DateTime]::UtcNow
    $created = $now.ToString('yyyy-MM-ddTHH:mm:ss.000Z')
    $expires = $now.AddMinutes(5).ToString('yyyy-MM-ddTHH:mm:ss.000Z')
    $envelope = @"
<s:Envelope xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:s="http://www.w3.org/2003/05/soap-envelope">
<s:Header>
<a:Action s:mustUnderstand="1">http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService/$Action</a:Action>
<a:MessageID>urn:uuid:$([guid]::NewGuid())</a:MessageID>
<a:To s:mustUnderstand="1">$Url</a:To>
<o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
<Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><Created>$created</Created><Expires>$expires</Expires></Timestamp>
<wuws:WindowsUpdateTicketsToken wsu:id="ClientMSA" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wuws="http://schemas.microsoft.com/msus/2014/10/WindowsUpdateAuthorization">
<TicketType Name="AAD" Version="1.0" Policy="MBI_SSL"></TicketType>
</wuws:WindowsUpdateTicketsToken>
</o:Security>
</s:Header>
<s:Body>$Body</s:Body>
</s:Envelope>
"@
    $resp = Invoke-WebRequest -Uri $Url -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($envelope)) `
        -ContentType 'application/soap+xml; charset=utf-8' -UseBasicParsing -TimeoutSec 120
    return [string]$resp.Content
}

# --- 1. product -> WuCategoryId ------------------------------------------------
$catalog = Invoke-RestMethod -UseBasicParsing -TimeoutSec 60 `
    "https://displaycatalog.mp.microsoft.com/v7.0/products/$ProductId`?market=US&languages=en-US,neutral&fieldsTemplate=Details"
$category = $null
foreach ($sku in $catalog.Product.DisplaySkuAvailabilities) {
    $fd = $sku.Sku.Properties.FulfillmentData
    if ($fd) {
        if ($fd -is [string]) { $fd = $fd | ConvertFrom-Json }
        $category = $fd.WuCategoryId
        break
    }
}
if (-not $category) { throw "$ProductId has no FulfillmentData in the display catalog (not a packaged Store app, or not published yet)" }
Write-Host "WuCategoryId: $category"

# --- 2. cookie + SyncUpdates ------------------------------------------------------
$cookieXml = Invoke-Soap 'GetCookie' @'
<GetCookie xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService"><oldCookie></oldCookie><lastChange>2015-10-21T17:01:07.1472913Z</lastChange><currentTime>2017-12-02T00:16:15.217Z</currentTime><protocolVersion>1.40</protocolVersion></GetCookie>
'@
$cookie = [regex]::Match($cookieXml, '<EncryptedData>(.*?)</EncryptedData>').Groups[1].Value
if (-not $cookie) { throw 'FE3 GetCookie returned no cookie' }

# A stock, up-to-date Windows client; FE3 only offers app packages to clients that look like one.
$installed = 1, 2, 3, 11, 19, 544, 549, 2359974, 2359977, 5169044, 8788830, 23110993, 23110994, 54341900, 54343656,
    59830006, 59830007, 59830008, 60484010, 62450018, 62450019, 62450020, 66027979, 66053150, 97657898, 98822896,
    98959022, 98959023, 98959024, 98959025, 98959026, 104433538, 104900364, 105489019, 117765322, 129905029,
    130040031, 132387090, 132393049, 133399034, 138537048, 140377312, 143747671, 158941041, 158941042, 158941043,
    158941044, 159123858, 159130928, 164836897, 164847386, 164848327, 164852241, 164852246, 164852252, 164852253
$ids = ($installed | ForEach-Object { "<int>$_</int>" }) -join ''
$device = 'E:BranchReadinessLevel=CB&amp;CurrentBranch=ge_release&amp;OEMModel=Virtual&amp;FlightRing=Retail&amp;AttrDataVer=321' +
    '&amp;InstallLanguage=en-US&amp;OSUILocale=en-US&amp;InstallationType=Client&amp;FlightingBranchName=&amp;OSSkuId=48' +
    '&amp;App=WU_STORE&amp;ProcessorManufacturer=GenuineIntel&amp;OEMName_Uncleaned=Microsoft&amp;AppVer=1.0' +
    '&amp;OSArchitecture=AMD64&amp;IsFlightingEnabled=0&amp;TelemetryLevel=1&amp;DefaultUserRegion=244' +
    '&amp;WuClientVer=1310.2410.17012.0&amp;OSVersion=10.0.26100.1&amp;DeviceFamily=Windows.Desktop'

$syncXml = Invoke-Soap 'SyncUpdates' @"
<SyncUpdates xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
<cookie><Expiration>2045-03-11T02:02:48Z</Expiration><EncryptedData>$cookie</EncryptedData></cookie>
<parameters>
<ExpressQuery>false</ExpressQuery>
<InstalledNonLeafUpdateIDs>$ids</InstalledNonLeafUpdateIDs>
<OtherCachedUpdateIDs></OtherCachedUpdateIDs>
<SkipSoftwareSync>false</SkipSoftwareSync>
<NeedTwoGroupOutOfScopeUpdates>true</NeedTwoGroupOutOfScopeUpdates>
<FilterAppCategoryIds><CategoryIdentifier><Id>$category</Id></CategoryIdentifier></FilterAppCategoryIds>
<TreatAppCategoryIdsAsInstalled>true</TreatAppCategoryIdsAsInstalled>
<AlsoPerformRegularSync>false</AlsoPerformRegularSync>
<ComputerSpec/>
<ExtendedUpdateInfoParameters>
<XmlUpdateFragmentTypes><XmlUpdateFragmentType>Extended</XmlUpdateFragmentType></XmlUpdateFragmentTypes>
<Locales><string>en-US</string><string>en</string></Locales>
</ExtendedUpdateInfoParameters>
<ClientPreferredLanguages><string>en-US</string></ClientPreferredLanguages>
<ProductsParameters>
<SyncCurrentVersionOnly>false</SyncCurrentVersionOnly>
<DeviceAttributes>$device</DeviceAttributes>
<CallerAttributes>E:Interactive=1&amp;IsSeeker=1&amp;Acquisition=1&amp;SheddingAware=1&amp;Id=Acquisition%3BMicrosoft.WindowsStore_8wekyb3d8bbwe&amp;</CallerAttributes>
<Products/>
</ProductsParameters>
</parameters>
</SyncUpdates>
"@
$sync = [Net.WebUtility]::HtmlDecode($syncXml)

# --- 3. list the packages --------------------------------------------------------
# NewUpdates/UpdateInfo <ID>n</ID>: UpdateIdentity + PackageMoniker (+ SecuredFragment = downloadable)
# ExtendedUpdateInfo/Update <ID>n</ID>: <File FileName=.. Digest=(SHA1, base64) Size=..>
$files = @{}
foreach ($m in [regex]::Matches($sync, '<Update><ID>(\d+)</ID>(.*?)</Update>', 'Singleline')) {
    $f = [regex]::Match($m.Groups[2].Value, '<File FileName="([^"]+)" Digest="([^"]+)" DigestAlgorithm="SHA1" Size="(\d+)"')
    if ($f.Success) { $files[$m.Groups[1].Value] = $f }
}
$packages = @()
foreach ($m in [regex]::Matches($sync, '<UpdateInfo><ID>(\d+)</ID>(.*?)</UpdateInfo>', 'Singleline')) {
    $b = $m.Groups[2].Value
    $moniker = [regex]::Match($b, 'PackageMoniker="([^"]+)"').Groups[1].Value
    $ident = [regex]::Match($b, '<UpdateIdentity UpdateID="([^"]+)" RevisionNumber="(\d+)"')
    $file = $files[$m.Groups[1].Value]
    if (-not $moniker -or $b -notmatch '<SecuredFragment' -or -not $ident.Success -or -not $file) { continue }
    $parts = $moniker.Split('_')
    $packages += [pscustomobject]@{
        Moniker  = $moniker
        Name     = $parts[0]
        Version  = $parts[1]
        Arch     = $parts[2]
        UpdateId = $ident.Groups[1].Value
        Revision = $ident.Groups[2].Value
        Ext      = [IO.Path]::GetExtension($file.Groups[1].Value)
        Sha1     = $file.Groups[2].Value
        Size     = [long]$file.Groups[3].Value
    }
}
if (-not $packages) { throw 'FE3 returned no packages for this product' }
$packages | Sort-Object Name, Version | Format-Table Moniker, Ext, Size -AutoSize | Out-String | Write-Host
if ($List) { exit 0 }

# --- 4. pick the app package (not framework dependencies) -----------------------
# The Store keeps serving older versions too, so match -Version exactly when given.
$candidates = $packages | Where-Object {
    $_.Name -notmatch '^Microsoft\.(VCLibs|UI\.Xaml|NET\.|WindowsAppRuntime|Services\.Store)' -and
    ($_.Arch -eq $Arch -or $_.Arch -eq 'neutral')
}
if (-not $candidates) { throw "No $Arch app package in the Store response" }
$latest = $candidates | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
if ($Version) {
    $app = $candidates | Where-Object Version -eq $Version | Select-Object -First 1
    if (-not $app) {
        Write-Host "Store serves $($latest.Name) up to $($latest.Version); $Version is not available yet."
        exit 3
    }
}
else { $app = $latest }

# --- 5. resolve the CDN URL and download ------------------------------------------
$secured = "$Fe3/secured"
$infoXml = Invoke-Soap 'GetExtendedUpdateInfo2' @"
<GetExtendedUpdateInfo2 xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
<updateIDs><UpdateIdentity><UpdateID>$($app.UpdateId)</UpdateID><RevisionNumber>$($app.Revision)</RevisionNumber></UpdateIdentity></updateIDs>
<infoTypes><XmlUpdateFragmentType>FileUrl</XmlUpdateFragmentType><XmlUpdateFragmentType>FileDecryption</XmlUpdateFragmentType></infoTypes>
<deviceAttributes>$device</deviceAttributes>
</GetExtendedUpdateInfo2>
"@ $secured
# One <FileLocation> per file of the update (package, blockmap, ...); take the one whose
# digest is the package's.
$url = $null
foreach ($loc in [regex]::Matches($infoXml, '<FileLocation><FileDigest>(.*?)</FileDigest><Url>(.*?)</Url>', 'Singleline')) {
    Write-Host "  file location: $($loc.Groups[1].Value)"
    if ($loc.Groups[1].Value -eq $app.Sha1) { $url = [Net.WebUtility]::HtmlDecode($loc.Groups[2].Value) }
}
if (-not $url) { throw "FE3 returned no download URL with digest $($app.Sha1) for $($app.Moniker)" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
if (-not $OutName) { $OutName = "$($app.Moniker)$($app.Ext)" }
$dest = Join-Path (Resolve-Path $OutDir) $OutName
Write-Host "Downloading $($app.Moniker) -> $dest"
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 1800

$sha1 = [Convert]::ToBase64String([Security.Cryptography.SHA1]::Create().ComputeHash([IO.File]::ReadAllBytes($dest)))
if ($sha1 -ne $app.Sha1) { throw "Downloaded file digest $sha1 does not match the Store digest $($app.Sha1)" }
$sig = Get-AuthenticodeSignature -LiteralPath $dest
Write-Host "Signature: $($sig.Status) by $($sig.SignerCertificate.Subject)"
if ($sig.Status -ne 'Valid') { throw "Downloaded package signature is $($sig.Status), expected Valid (Store-signed)" }
Write-Output $dest

exit 0
