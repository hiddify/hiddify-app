# Windows code signing and VirusTotal false positives

Audience: Hiddify maintainers who run the release pipeline and own the GitHub
secrets. Nothing in this document changes the app logic; it is about how the
Windows binaries are built, signed and attested.

## Why the Windows builds were flagged

The draft release assets (`Hiddify-Windows-Setup-x64.exe`,
`Hiddify-Windows-Portable-x64.zip`, `Hiddify-Windows-Setup-x64.Msix`) picked up
generic verdicts on VirusTotal: Bkav Pro `W32.Malware.*`, Webroot
`W32.Trojan.Gen`, DeepInstinct `MALICIOUS`, plus a sandbox "Sysmon File
Executable Creation" Sigma hit on the installer. These engines are
machine-learning / heuristic scanners. They do not find malicious behaviour;
they score how much an unknown file *looks like* the malware they were trained
on. Our files scored badly for reasons that have nothing to do with what the
app does:

| Signal | Status before | Status now |
|---|---|---|
| Authenticode signature | **Self-signed certificate** (issuer = subject `CN=8CB43675-…`). Zero reputation for AV and SmartScreen; self-signing is itself a malware trait. | Signed with a publicly trusted certificate once the secrets below are set. The pipeline warns on every run that still uses a self-signed PFX. |
| Go PE files (`hiddify-core.dll`, `HiddifyCli.exe`) | Fully stripped (`-s -w`), no VERSIONINFO, no manifest: looks like a packed dropper. | Symbol table kept (`-w` only, DWARF still dropped), VERSIONINFO (CompanyName, ProductName, FileDescription, versions) and manifest embedded with go-winres. |
| Inno Setup uninstaller | `unins000.exe` written unsigned into Program Files (the Sigma hit). | Inno compiler signs `Setup.exe` and the uninstaller itself through the registered `hiddifysign` Sign Tool. Setup VERSIONINFO added. |
| MSIX | Signed with the self-signed PFX; Publisher pinned by hand. | Publisher is patched from the signing certificate automatically; signed with the trusted certificate. The Store-signed MSIX still replaces the asset after a release. |
| Provenance | None. | SLSA build provenance attestation for the Windows assets (`gh attestation verify <file> --repo hiddify/hiddify-app`). |
| Monitoring | Badge in the release notes only. | The VirusTotal workflow writes a per-file detection table to the job summary and annotates flagged assets. |

Everything except the certificate is deterministic and already in the
repositories. The certificate is the decisive factor: ML engines and SmartScreen
whitelist by publisher reputation, and reputation only accrues to a trusted
signature. **Without a trusted certificate false positives will come back no
matter how the binaries are built.**

## Pipeline overview

`windows/scripts/configure_windows_signing.ps1` runs first in the Windows job and
decides the backend:

1. **Azure Artifact Signing** (formerly Trusted Signing) when
   `AZURE_SIGNING_ENDPOINT`, `AZURE_SIGNING_ACCOUNT` and
   `AZURE_SIGNING_CERT_PROFILE` exist. Preferred.
2. **CA-issued PFX** when `WINDOWS_SIGNING_KEY` exists. Works with any OV/EV
   certificate you can export as PFX.
3. Otherwise the job fails: release builds must be signed.

`windows/scripts/sign_windows_artifacts.ps1` is the single signing entry point.
It is called for the Flutter `Release` tree before packaging, by the Inno Setup
compiler for `Setup.exe` and the uninstaller, and for `dist/` (MSIX, Setup,
PE files inside the portable zip). Files that already chain to a trusted root
(MSVC runtimes, Store packages) are skipped.

fastforge runs `flutter build windows` itself before it packs anything, and
that rebuild re-copies fresh, unsigned plugin DLLs over the signed tree (only
`Hiddify.exe` survives because it is linked in place). The Makefile therefore
passes `--hook-pre=windows/scripts/sign_release_tree.sh` to every Windows
fastforge target when `WINDOWS_SIGN_BACKEND` is set; fastforge runs that hook
after its build and right before Inno Setup / msix read the tree. Without it
the Setup payload and the MSIX contents ship unsigned DLLs, which is exactly
what the Sysmon "File Executable Creation" sandbox rule fires on.

Both PowerShell scripts end with `exit 0` on purpose: their last native call
may be a `signtool verify` that returns non-zero for a self-signed PFX, and the
Inno compiler as well as the GitHub Actions `pwsh` shell treat a leftover
non-zero exit code as failure.

The Go side lives in `hiddify-core`: `make windows-winres` (run by
`make windows-amd64`) generates `rsrc_windows_amd64.syso` for the DLL and the
CLI from `release/winres/core.json` and `release/winres/cli.json`;
`WINDOWS_LDFLAGS` keeps the symbol table. The CLI's `.syso` is linked into the
C launcher by `x86_64-w64-mingw32-gcc`.

## Option A: Azure Artifact Signing (recommended)

Cost is about USD 10 per month (Basic, 5,000 signatures). Certificates are
short-lived and issued by Microsoft's public root, so SmartScreen and the
AV vendors trust them immediately and reputation builds on the identity, not on
a key file that can leak. Identity validation is currently available to
organizations in the US, Canada, the EU and the UK, and to individuals in the
US and Canada. If Hiddify cannot pass that validation, use option B.

Steps in the Azure portal:

1. Create an **Artifact Signing account** (region, for example East US → endpoint
   `https://eus.codesigning.azure.net/`).
2. Complete **Identity validation** → *Public Trust* (organization or
   individual; this is the step with the documents).
3. Create a **Certificate profile** of type *Public Trust*. Note the generated
   Subject, for example `CN=Hiddify, O=Hiddify, L=City, S=State, C=US`.
4. Create an **App registration** (service principal). Assign it the role
   **Artifact Signing Certificate Profile Signer** on the account.
   - Preferred: add a **Federated credential** for GitHub Actions
     (issuer `https://token.actions.githubusercontent.com`, subject
     `repo:hiddify/hiddify-app:ref:refs/heads/main` plus one per release tag
     pattern, or use environment-based subjects). No secret to store.
   - Alternative: create a **client secret**.
5. GitHub → repository secrets:

| Secret | Value |
|---|---|
| `AZURE_SIGNING_ENDPOINT` | e.g. `https://eus.codesigning.azure.net/` |
| `AZURE_SIGNING_ACCOUNT` | Artifact Signing account name |
| `AZURE_SIGNING_CERT_PROFILE` | certificate profile name |
| `WINDOWS_SIGNING_PUBLISHER` | exact certificate Subject from step 3 (becomes the MSIX `Publisher`) |
| `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` | from the app registration |
| `AZURE_SUBSCRIPTION_ID` | required for OIDC (`azure/login`) |
| `AZURE_CLIENT_SECRET` | only when not using OIDC |

Then delete `WINDOWS_SIGNING_KEY` / `WINDOWS_SIGNING_PASSWORD` /
`WINDOWS_SIGNING_SHA1` or leave them; Azure wins when both are present.

## Option B: CA-issued certificate as PFX

Any OV or EV code-signing certificate from a public CA works with the existing
`WINDOWS_SIGNING_KEY` (base64 PFX), `WINDOWS_SIGNING_PASSWORD` and optional
`WINDOWS_SIGNING_SHA1` secrets. Since 2023 CAs must keep the private key on
hardware, so an exportable PFX is only available from a few providers (for
example Certum's Open Source code-signing certificate, which is inexpensive for
OSS projects). Cloud HSM products (SSL.com eSigner, DigiCert KeyLocker) need
their own signing client; wire them into `Invoke-PfxBackend` in
`sign_windows_artifacts.ps1` if you go that way.

EV certificates get SmartScreen reputation immediately; OV certificates build it
over a few weeks of downloads.

## Option C: SignPath Foundation

Free code signing for open-source projects (OSI license, public repository,
free downloads). Signing happens on their side: the workflow uploads the
unsigned artifact and `signpath/github-action-submit-signing-request` returns
the signed one. It needs a project application and review first. If accepted,
add a job after `build` that submits `out/*.exe`, `out/*.Msix` and the zip's PE
files, then replace the assets.

## Microsoft Store

`.github/workflows/add_signed_microsft.yml` already replaces the release MSIX
with the Store-signed package after a release is published. Keep it; the Store
signature is the best possible one for the MSIX.

## Sandbox "Sigma" matches (Behavior tab)

The VirusTotal *Behavior* tab is produced by sandboxes, and its Sigma matches are
not detections: they do not count toward the engine score. Two things shaped
what shows up there and both are handled in the build:

**Archives are brute-forced.** The CAPE sandbox has no entry point for a zip,
so it extracts it and launches *every* file itself: `.exe` files directly and
everything that looks like a library with `rundll32 "<file>",#1`, including
Microsoft's own `vcruntime140.dll` (which crashes into WerFault). The rundll32
processes are children of Explorer started from the sandbox user's Desktop;
nothing in Hiddify calls rundll32. Zenbox, which opens the archive the normal
way, rates the zip CLEAN.

- Flutter's ICU table used to ship as `data/icudtl.dat`. The sandbox fed it to
  rundll32 too, and `rundll32 *.dat` is literally the pattern of Joe Security's
  critical rule "Execute DLL with spoofed extension" plus the medium "Rundll32
  Execution With Uncommon DLL Extension". The runner now constructs
  `DartProject` with explicit paths and the CMake install step renames the file
  to `data/icudtl.bin` (`windows/runner/main.cpp`, `windows/CMakeLists.txt`).
  The sandbox leaves `.bin` files alone (it never touched
  `flutter_assets/AssetManifest.bin`), so those two matches are gone. Keep the
  rename if the runner is ever regenerated.
- "Rundll32 Spawned Via Explorer.EXE" (medium) fires for every DLL the sandbox
  loads this way and "Unsigned DLL Loaded by Windows Utility" (medium) for
  every DLL without a trusted signature. These cannot be removed from an
  archive that contains DLLs; the unsigned one goes away with a trusted
  certificate.

**"Sysmon File Executable Creation Detected" (medium) is every installer.** The
rule is `EventID: 29` with no other condition: it matches each PE file that any
process writes to disk. The events VirusTotal lists for `Setup.exe` are Inno
Setup unpacking itself (`%TEMP%\is-*.tmp\Hiddify-Windows-Setup-x64.tmp`,
`_isetup\_setup64.tmp`) and then writing `Hiddify.exe` and the DLLs into
`C:\Program Files\Hiddify`. An installer that does not write executables is
not an installer, so the only way to lose this line is to stop shipping
`Setup.exe`. The rule's own `falsepositives` text says hits from legitimate
software mean the Sysmon configuration is too broad, not that the file is
suspicious. For comparison, Git for Windows 2.56.0 (Inno Setup, Microsoft-owned
project, publicly trusted signature), analysed by the same CAPE sandbox three
days before our build, shows the same rule plus two more mediums ("New Root or
CA Certificate to Store", "Suspicious CMD Shell Output Redirect"). MSI does not help either: the Node.js 26.13 MSI and Microsoft's own
PowerShell 7.6.9 MSI, both analysed by CAPE the same week, show the same rule
(msiexec writes the PE files instead of Inno Setup). Hiddify's installer shows
that one rule and nothing else; the MSIX and the zip show none, because the
sandbox never installs an MSIX and extraction of a zip is done by the sandbox
agent before Sysmon logging starts.
Leave it; do not add hacks to the installer to dodge a rule that cannot be
dodged.

**Crowdsourced YARA "Adobe_XMP_Identifier".** This is an informational match,
not a detection and not a Sigma level. It came from Photoshop/Figma metadata
(`xmp.did:…`) left inside `assets/images/tray_icon.png` and
`tray_icon_dark.png`, which the MSIX stores uncompressed. The text chunks were
stripped from both PNGs (pixel data untouched). Export new PNG assets without
metadata, or run `pngcrush -rem allb` / `exiftool -all=` on them, so the rule
does not come back.

**VPN start-up must not spawn PowerShell.** Both places where Windows VPN mode
used to launch `powershell.exe` were replaced by the equivalent native API
call, same behaviour, same UAC prompt:

| Where | Before | Now |
|---|---|---|
| `lib/hiddifycore/core_interface/core_interface_desktop_tun.dart` (`_isPrivileged`) | `powershell -Command "...WindowsPrincipal...IsInRole(Administrator)"` on Windows, `id -u` on Linux/macOS | gRPC `Core.IsAdmin` answered by the in-process core from its own token (`hutils.IsAdmin`, already used by `NeedAdminBgService`); no child process on any platform |
| `hiddify-core/v2/hcore/admin_bgservice_elevate_windows.go` | `powershell -Command "Start-Process HiddifyCli.exe -ArgumentList admin_bgservice,install -Verb RunAs -Wait"` | `ShellExecuteExW` with verb `runas`, wait on the process handle, exit code checked |
| `hiddify-core/v2/hcore/adminbgservice/secret_windows.go` | `icacls <secret> /inheritance:r /grant:r ...` | `go-acl` `Apply` (SetNamedSecurityInfo), same three ACEs |

The elevated process is now `HiddifyAdmin.exe` (`hiddify-core/cmd/adminlauncher`),
a ~150 KB C program with a `requireAdministrator` manifest, the app icon and a
"Hiddify" VERSIONINFO. It forwards its arguments to the same `parseCli()` in the
DLL that `HiddifyCli.exe` uses, is GUI-subsystem (no console flashes while
elevated) and returns a non-zero exit code when the command fails, which the core
reports. It is the only Hiddify binary that ever asks for administrator rights,
so the UAC dialog shows "Hiddify" with the app icon, and antivirus sandboxes see
a manifest-declared elevation instead of `runas` on a console tool. The core
falls back to `HiddifyCli.exe` when the file is missing. It ships in the core
tarball (`HiddifyAdmin.exe` in the CI zip step) and is installed by
`windows/CMakeLists.txt` next to `Hiddify.exe`.

A GUI application spawning `powershell.exe` matches Sigma "Non Interactive
PowerShell Process Spawned" and is a strong feature for ML engines; a
`Start-Process -Verb RunAs` one-liner is the textbook elevation pattern, and
`icacls /inheritance:r /grant` from a freshly installed binary is a
permission-tampering pattern. The
service itself is installed through the Windows service API from
`C:\Program Files`, which only produces the ordinary service-installed event
(no `sc.exe`, `netsh` or `schtasks` processes). Keep it that way: never add
`exec.Command("powershell"|"cmd"|"netsh"|"sc"|"icacls")` or `Process.run('powershell')`
to a path the app runs on its own.

## Disputing a false positive

Signed, attested files that are still flagged are false positives and the
vendors remove them within a day or two when asked. The VirusTotal workflow
summary lists the flagged assets and the SHA-256 hashes to paste.

| Vendor | Where |
|---|---|
| Microsoft Defender / SmartScreen | https://www.microsoft.com/wdsi/filesubmission (choose "Software developer") |
| Webroot | https://www.webroot.com/us/en/business/support/false-positive-submission |
| Bkav | fp@bkav.com (attach the file or hash) |
| DeepInstinct | https://www.deepinstinct.com/ support form, or `falsepositive@deepinstinct.com` |
| Kaspersky | https://opentip.kaspersky.com/ |
| ESET | samples@eset.com |
| Avast / AVG | https://www.avast.com/false-positive-file-form.php |
| Malwarebytes | https://forums.malwarebytes.com/forum/42-false-positives/ |
| McAfee / Trellix | https://www.trellix.com/enterprise/contact-us/ (sample submission) |
| Sophos | https://support.sophos.com/support/s/filesubmission |
| Trend Micro | https://www.trendmicro.com/en_us/about/legal/detection-reevaluation.html |

Mention in every dispute: public source (https://github.com/hiddify/hiddify-app),
built on GitHub-hosted runners, Authenticode-signed by `<publisher>`, provenance
verifiable with `gh attestation verify`.

## What was verified

The whole Windows job was replayed on a clean Windows Server 2025 machine
(Flutter 3.38.5, VS Build Tools 2022, Inno Setup 6, fastforge 0.6.12) with a
throwaway self-signed PFX standing in for the GitHub secret. Result for all
three assets: every PE file inside `Setup.exe`, the MSIX and the portable zip
is Authenticode-signed and timestamped, `unins000.exe` is signed by the Inno
compiler, `hiddify-core.dll` and `HiddifyCli.exe` carry VERSIONINFO, a silent
install/uninstall succeeds and Windows Defender reports no threats.

VirusTotal results of that build (2026-10-29, still self-signed):

| File | Detections | Engines |
|---|---|---|
| `Hiddify-Windows-Setup-x64.exe` | 0 / 70 | – |
| `Hiddify-Windows-Setup-x64.exe` built *before* the `publisher_name` fix (empty CompanyName / AppPublisher) | 2 / 63 | Webroot `W32.Trojan.Gen`, Elastic |
| same Setup.exe with the signature stripped | 2 / 68 | Microsoft `Trojan:Win32/Wacatac.C!ml`, CrowdStrike |
| `hiddify-core.dll` (signed) | 0 / 67 | – |
| `hiddify-core.dll` (unsigned) | 1 / 58 + Sigma | Trapmine `suspicious.low.ml.score` |
| `Hiddify.exe` (signed) | 0 / 70 | – |
| `HiddifyCli.exe` as a Go stub (signed or unsigned, any link flags) | 1 / 68 | Bkav `W32.Malware.*` |
| `HiddifyCli.exe` as the C launcher (`cmd/clilauncher`, unsigned) | **0 / 70** | – |
| Portable zip / MSIX with the Go stub | 1 | Bkav (it is the `HiddifyCli.exe` inside) |
| `HiddifyAdmin.exe` (C, requireAdministrator, unsigned) | **0 / 71** | – |
| Final build, all three assets (Setup.exe, portable zip, MSIX) | **0 / 70, 0 / 67, 0 / 65** | – |
| Same after the `Core.IsAdmin` change and the XMP strip (Setup `3c5eb770…`, zip `3c70aae7…`, MSIX `3c2ec74d…`) | **0 / 70, 0 / 66, 0 / 67**, no crowdsourced YARA match | – |

Take-aways:

- Keep signing even with a self-signed PFX: the unsigned variants collect
  *more* ML verdicts (Microsoft, CrowdStrike, Trapmine), not fewer.
- `windows/packaging/exe/make_config.yaml` must use `publisher_name` (fastforge
  ignores `publisher`). The empty CompanyName was the Webroot/Elastic trigger
  and also left "Publisher" blank in Add/Remove Programs.
- Bkav flagged the Go CLI stub regardless of `-trimpath`, `-w`, `-buildid` or
  DWARF: a generic classifier hit on a small Go PE. The Windows
  `HiddifyCli.exe` is therefore no longer a Go program. `cmd/clilauncher/main.c`
  is a ~150 KB C launcher that converts the wide command line to UTF-8 and calls
  the DLL's exported `parseCli()`, exactly what the Go stub did (identical
  `--help` output, Unicode arguments verified). The Go stub in `cmd/bydll` stays
  for Linux. Keep the launcher in C; do not "simplify" it back to Go.

## Verifying a build locally

```powershell
signtool verify /pa /v Hiddify-Windows-Setup-x64.exe
Get-AuthenticodeSignature .\Hiddify\hiddify-core.dll | Format-List
(Get-Item .\Hiddify\HiddifyCli.exe).VersionInfo
gh attestation verify Hiddify-Windows-Setup-x64.exe --repo hiddify/hiddify-app
```

`Get-AuthenticodeSignature` must say `Valid`; a self-signed PFX shows
`UnknownError` / `NotTrusted`.

## Troubleshooting

- `msix` fails with *publisher mismatch*: the `publisher` in
  `windows/packaging/msix/make_config.yaml` must equal the certificate Subject.
  The configure script patches it; with Azure set `WINDOWS_SIGNING_PUBLISHER`
  to the exact Subject of the certificate profile.
- ISCC fails with *Sign Tool "hiddifysign" not found*: the configure script
  could not write `HKCU\Software\Jordan Russell\Inno Setup\SignTools`. The
  template only enables signing when `HIDDIFY_INNO_SIGNTOOL=hiddifysign`.
- `Invoke-ArtifactSigning` authentication errors: the app registration needs
  the *Artifact Signing Certificate Profile Signer* role on the account, and
  the federated credential subject must match the workflow ref.
- Still flagged after signing: file the disputes above once; vendors whitelist
  the publisher, not only the hash.
