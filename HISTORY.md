# Changelog


## 5.2.0 (2026-10-30)

#### New

* Vaydns with scanner and multi resolver. 

#### Fix

* #2392 [iOS] After reopening the app, it shows Disconnected while the VPN tunnel is still connected. 

* Reopen the proxies stream instead of showing an error. 
  _The proxies page turned any failure of its gRPC stream into an error and
showed "Unexpected error" until the page was rebuilt, though the tunnel
kept working. The stream fails whenever its connection drops, e.g. when
iOS suspends the app, and nothing opened it again.

Like the active proxy, the page now keeps its last list, reopens the
stream when it ends (with the same backoff) and when the core is set up
again on resume. Reopening no longer drops the pinned proxy._

* Back off when reopening the active proxy stream keeps failing. 
  _When the core stays unreachable while the tunnel is reported as running,
the stream was reopened every 2 seconds, and each failure is logged as an
error with a stack trace, which floods the in-memory log. The wait now
doubles up to 30 seconds and goes back to 2 seconds once the stream
delivers again or the connection state changes._

* Close the old gRPC channels when the core is set up again on resume. 
  _HiddifyCoreService.init() runs on every resume, and each run opened new
channels to the core without closing the ones they replaced, plus a hello
channel that was never closed. Each stayed connected until its idle
timeout, so switching back to the app often left extra connections open,
on iOS to the VPN extension, which has a tight memory cap. The replaced
channels and the hello channel now shut down gracefully._

* Reopen the active proxy stream after the app returns from the background. 
  _After the phone was locked for a few minutes, or after a while on macOS,
the connection button stayed yellow on "connecting" while the tunnel kept
working. The gRPC stream that carries the active outbound's delay drops
when the app is suspended; its error was turned into an empty outbound
with no delay, and the stream was never opened again because
serviceRunning stays true.

The notifier now drops the failed event, keeps the last outbound, opens
the stream again when it ends, and also rebuilds when the core is set up
again on resume. Stats get the same rebuild._

* Update ConfigOptions to use unblocker mode and license keys; add tests for CoreStatus behavior. 

* Enable Android APK and Linux/Windows builds in CI workflow. 

* Update code signing process and add local signing materials. 

* Issues. 

* Update Android SDK setup to install platform-tools. 

* Leak issue. 

* Check for existence before dropping profile_override column. 

* Update Turkish i18n strings for LAN sharing. 

* Update non-English translations for LAN sharing settings. 

* Correct arrow icon direction in chain quick settings. 

* Resolve ChainTimelineHeader background visibility in light theme. 

* Correct Turkish translation for WARP license required. 

* Add missing required text to fa WARP missingLicense translation. 

* Add confirmation for deep link profile addition to prevent SSRF. 

* Temporarily patch Riverpod lazy build-phase collision on connection status changes. 
  _Temporary hotfix to resolve fatal 'setState() called during build' errors caused by lazy
evaluation of dirty provider dependency chains during high-frequency status transitions.

- Establishes eager evaluation by listening to `activeProxyNotifierProvider` at the root
  container level during bootstrap to resolve dirty state flushes in microtasks.
- Refactors `serviceRunningProvider` and all downstream dependent stream/future
  notifiers to execute synchronously to prevent build-phase timing hops.
- Defers secondary state updates using `Future.microtask()`.

Note: This is a temporary architectural patch to bypass Riverpod's lazy widget evaluation
mechanics under high-frequency stream updates. A full core communication redesign is
recommended for future maintenance to address this natively._

* Liquid Glass icon-launcher setup for iOS and macOS. 

* Get error when the string len of title is less than 3. 

* Set getApplicationDocumentsDirectory as a fallback for getExternalStorageDirectory in Android. 

#### Other

* Fix(dependencies): upgrade core version to 5.2.0. 

* Feat(settings): use the system's TLS when available. 
  _A switch on macOS, iOS and Windows, on by default, sent to the core as
use-system-tls-engine: connections without a TLS fingerprint use the
system's TLS once it passed the core's check on the device, and look like
Chrome otherwise. English and Persian strings._

* Fix(connection): reconnect when the service mode changes on Windows and Linux. 
  _Switching from proxy or system proxy to VPN while connected cut the
connection on Windows. The mode change was applied as a hot reload to
the core running in the app: VPN mode gives the TUN to the admin service,
so that core got TUN off and system proxy off, removed the system proxy,
and nothing started the VPN service. VPN to proxy reloaded the admin
service with its old settings. A new service mode now disconnects and
connects again, which also asks for admin consent when needed._

* Build(linux): make the AppDir world-readable before appimagetool rebuilds the AppImage. 

* Ci(windows): pass signing credentials to the zip step that runs the fastforge sign hook. 

* Feat(notification): enhance service notification with dynamic updates and improved rendering. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Merge pull request #2418 from veto9292/fix/next-release. 
  _Home proxy card redesign, plain proxy lists from the core_

* Feat(proxy): the proxies page shows a proxy's own chain. 
  _The core no longer joins a proxy's name with its detour, so the proxies
page builds it: "A → B" when a proxy dials through another of the
user's proxies. The app's own hidden ones, such as the unblocker hop,
are left out, so with the unblocker the servers no longer all read
"→ Unblocker"._

* Feat(proxy): Material 3 home proxy card with the chain band. 
  _The card shows how the traffic goes: a band tinted in the chain's color
with the chain type (its menu) and the hop (exit flag with the hop's
badge, name, IP and its own state: a thin loader, then a green check),
above the proxy row (who picked it, the name, IP and protocol).

- the final IP is green; "Final IP" shows once in its place, then the IP
- IPs and flags load with a skeleton and pop in when they arrive
- on narrow screens the hop's name goes first, then the type's label
  shortens; nothing overflows from 320 dp up
- IPCountryFlag takes a corner radius_

* Feat(chain): animated extra security and unblocker icons. 
  _ChainTypeIcon: a shield with an orbiting light for extra security and a
turning key for the unblocker, in each chain's colors (blue with a
Profile hop). The chain page's headers use them; they move only while
their chain is on, and are a still grey icon otherwise._

* Refactor(proxy): one main list for the active proxy and the home card. 
  _The core's main list is now read as one message (OutboundGroupList), so
the chain hop comes from its own field, chain_hop. MainOutboundsNotifier
owns the stream; the active proxy and the new home card data
(ActiveProxyCardData: the server, the group that picked it, the hop)
are derived from it.

The active proxy, whose ping drives the delay indicator, the tray and
the connect haptics, is the hop with extra security (the traffic leaves
through it) and the user's pick otherwise._

* Fix(proxy): a new connection no longer shows the last one's proxies. 
  _The core service keeps the last main proxy list and sends it first to
every new listener. It was never cleared, so after a reconnect the home
card first showed the previous connection's proxies and flags for a
moment. It is now cleared when the core starts._

* Chore(core): update hiddify-core to the plain proxy lists (8e373b4) 
  _hiddify-core#161: each proxy is sent as it is, the active chain hop
comes in OutboundGroupList.chain_hop, and with extra security the core
says connected only once the hop has a ping. Also brings the saved IP of
the previous run no longer being shown (hiddify-sing-box#43).

hcore.proto regenerated alone, as before: OutboundInfo.status,
OutboundGroupList.chain_hop and IsAdminResponse._

* Chore(core): update hiddify-core to the latest main (e89fabc) 

* Feat(preferences): add support for clearing nullable preferences. 

* Docs(windows): record VirusTotal results of the final rebuild. 

* Build(windows): antivirus-clean release assets, native privilege checks, signed packaging. 
  _Fixes the VirusTotal false positives on the Windows Setup, portable zip and MSIX
without changing app logic. Measured result: 0 detections on all three assets.

Packaging and signing
- fastforge targets get --hook-pre=windows/scripts/sign_release_tree.sh when a
  signing backend is configured: fastforge re-runs `flutter build`, which copied
  unsigned plugin DLLs over the signed tree before Inno/MSIX read it.
- configure_windows_signing.ps1 selects Azure Artifact Signing or a PFX,
  patches the MSIX publisher from the certificate, registers the Inno Setup
  sign tool (Setup.exe and the uninstaller are signed by the compiler) and
  warns when the certificate is self-signed. Both scripts end with `exit 0`.
- Setup VERSIONINFO: `publisher_name` (fastforge ignored `publisher`, leaving
  CompanyName empty, which Webroot/Elastic score as a dropper).
- CI: attest build provenance for the Windows assets; the VirusTotal workflow
  writes a per-file detection table to the job summary.

Sandbox / Sigma
- Flutter's ICU table ships as data/icudtl.bin (explicit DartProject paths in
  the runner, CMake install RENAME): sandboxes rundll32 every *.dat in an
  archive, which matched the critical "DLL with spoofed extension" rule.
- Tray icon PNGs stripped of Photoshop XMP metadata (crowdsourced YARA match).

VPN start-up
- The privilege check asks the in-process core (new Core.IsAdmin RPC) instead
  of spawning PowerShell or `id -u`. Regenerated hcore Dart protobuf files.
- HiddifyAdmin.exe (from hiddify-core) is installed next to Hiddify.exe and is
  the only binary that requests UAC.

docs/windows-code-signing.md documents the secrets, the measured VirusTotal
results and why the remaining "Sysmon File Executable Creation" medium is
inherent to every installer._

* Refactor(platform): update SFTP server and SSH host key methods to use NSErrorPointer for error handling. 

* Delete(test): remove fallback tests for DioHttpClient. 

* Test(profile): update warp mode expectation to "warp_auto" for compatibility. 

* Fix(profile): update ChainMode to handle "warp" as "warp_auto" for compatibility. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Merge pull request #2413 from veto9292/fix/next-release. 
  _LAN sharing QR: open the dialog at once, fall back to 127.0.0.1_

* Chore(core): update hiddify-core to the latest main (5fae35d) 

* Chore(core): update hiddify-core to the latest main (84b47e9) 

* Refactor(qr): drop the LAN-only parameters from showQrCode. 
  _Only the profile share uses it now._

* Feat(qr): open the LAN sharing dialog at once and fall back to 127.0.0.1. 
  _The dialog used to wait for the local IP, and when the lookup failed it
showed an error toast instead of opening. Now it opens right away and
looks the IP up while open.

Without a local IP it uses 127.0.0.1, the answer the core already gives
when this device has no local network. A failed lookup, or one that
takes over 10 seconds, gets the same. That address works only on this
device, so the QR spot says so instead of showing a code (the device
that scans it would reach itself), the proxy is named "Localhost only"
instead of "LAN only", and the copy buttons keep working for other apps
here. The copied link now carries the proxy's name, as the QR code does._

* Chore(l10n): carry the LAN sharing 127.0.0.1 texts into the ten locales. 

* Feat(i18n): texts for LAN sharing on 127.0.0.1. 
  _Adds the "This device only" title and its line for the QR spot, and
shortens the dialog subtitle to "SOCKS5 proxy". Drops the old LAN IP
error text, which nothing shows any more._

* Refactor(platform): update SFTP server and SSH host key methods to throw exceptions and add useProcFS method. 

* Refactor(platform): update SFTP server and SSH host key methods to return error pointers instead of throwing exceptions. 

* Feat(windows): implement service management in installer and add script for signing artifacts. 

* Feat(build): enhance Windows build process with artifact signing and packaging. 

* Merge pull request #2405 from veto9292/fix/next-release. 
  _Android first connect, connect button and DMG fixes, analyzer cleanup_

* Chore(core): clear the analyzer infos in the gRPC identity and core service. 
  _The identity generator is a factory constructor, the stop wait drops a default
argument, and the core info subscription is cancelled through its field._

* Chore(http): drop two unneeded this. qualifiers. 

* Fix(windows): make the taskbar status dot smaller and lighter. 
  _The dot filled the whole 16 px overlay with a 2 px white ring and hid
much of the app icon. It is now a smaller dot with a 1 px ring, pinned
to the top-right corner where Windows 11 draws the overlay._

* Fix(home): keep the H in one piece while the bars light up. 
  _The H's crossbar took the short bar's shade, so it ended in a hard edge at the
tall bar. It now fades from the short bar's shade into the tall bar's. The wave
also wraps round smoothly: the dot's light no longer cuts off at the end of
each round._

* Fix(home): keep the radar out of the connect button's logo. 
  _While connecting, the faded bars let the radar show through them. The logo
now keeps the button's white under it._

* Fix(core): cancel the mobile status listener on dispose. 

* Chore(core): clear the analyzer infos in the desktop, macOS and mTLS code. 
  _The control secret is late instead of nullable, the snapshot method drops an
unneeded async, and SecurityContext drops a default argument._

* Refactor(proxy): make the IP info parsers factory constructors. 

* Chore: remove two unused imports. 

* Chore(claude): remove CLAUDE.md and the writing rules. 
  _The project instructions and the Material writing rules now live in
personal Claude Code skills outside the repository._

* Fix(android): wait once for the start status instead of polling it. 
  _The start wait polled the status 20 times and its `break` left only the
switch, so every connect waited ~4 s even after the service was up. It now
waits once for the first status that settles the start: started, or stopped
with an alert, within 20 s.

The status stream is now created once. setup runs again on every resume,
including the one right after the VPN dialog closes, and replaced it; a wait
on the old stream never saw "started" and ran into the timeout._

* Fix(macos): show the DMG background steps in English and Persian. 

* Fix(android): answer the start call only after the permission dialogs. 
  _On a fresh install the start call returned at once, while Android was still
showing the notification and VPN permission dialogs. The app's 20 s wait for
the service ran out behind them, so the first connect failed with "starting
background core...", and the service started later with nobody waiting.

startService now waits until every dialog is answered and returns whether the
service was asked to start; a refusal returns false and sends its alert._

* Fix(macos): show the quarantine steps in order on the DMG background. 
  _Users opened Hiddify before removing the quarantine flag and got the
"App is damaged" error (#2193). The background now lists the steps in
the order to follow them._

* Feat(http_client): fix user agent handling in DioHttpClient and corresponding tests. 

* Feat(proxy):refactor the whole connection diagarm in ios and android enhance connection state handling and UI updates. 
  _- Updated ActiveProxyFooter to clear held proxies on new Connecting state.
- Modified ActiveProxyDelayIndicator to consider NoAvailableProxies as connected.
- Adjusted ProxiesOverviewNotifier to return null on service not running instead of an error.
- Improved ProxiesOverviewPage to display appropriate messages based on service status.
- Refactored SystemTrayNotifier to handle new connection states and update tray icon accordingly.
- Introduced GrpcClientIdentity for managing client certificates in mTLS.
- Enhanced CoreInterfaceMobile to utilize GrpcClientIdentity for secure connections.
- Updated core status handling in HiddifyCoreService to reflect new states like WAITING and NO_AVAILABLE_PROXIES.
- Added new CoreStatus variants for better state representation in the application._

* Chore: update CI workflow for asset naming and target handling. 

* Refactor: enhance active proxy components and desktop status handling. 
  _- Updated ActiveProxyFooter to utilize hooks for managing proxy state during connection transitions.
- Improved ActiveProxyDelayIndicator to handle connection status more effectively and reserve space during loading.
- Modified ActiveProxyNotifier to emit an empty outbound on disconnect to prevent stale UI states.
- Refactored DesktopStatusBadge to support multiple connection states (none, error, ok) for better visual feedback on macOS and Windows.
- Adjusted SystemTrayNotifier to update the tray icon based on the new badge statuses, ensuring accurate representation of connection state._

* Chore: update release message and CI scripts for asset handling. 
  _- Replaced the fill_vt_sha256.py script with prepare_release_notes.py to streamline the generation of release notes.
- Enhanced the release message format to include a structured downloads table with VirusTotal badges.
- Updated CI workflows to ensure proper asset management and cache busting for VirusTotal badge images._

* Feat: implement desktop status badge for connection state. 
  _- Added DesktopStatusBadge class to manage dock/taskbar status indicators for connected states on macOS and Windows.
- Integrated badge updates into SystemTrayNotifier to reflect connection status visually.
- Enhanced tooltip handling to avoid displaying text badges when disconnected, ensuring a cleaner UI experience._

* Chore: add ole32.lib to Windows runner dependencies. 

* Feat: add desktop status overlay for connected state. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Remove stale bot; issue triage is now handled manually. 

* Chore: implement admin background service support for Windows/Linux. 
  _- Added new RPC methods to the core service for managing elevated admin background services.
- Introduced dialogs for user consent regarding admin permissions for VPN and proxy features.
- Updated connection logic to handle admin service requirements and preferences.
- Enhanced profile management to include user preferences for admin service usage.
- Refactored related components to improve clarity and maintainability._

* Chore: refactor macOS App Store upload process. 

* Chore: update release message and CI scripts for macOS and iOS. 
  _- Enhanced the release message to include additional macOS App Store assets.
- Improved the fill_vt_sha256.py script to generate a SHA-256 checksum table for assets.
- Updated CI workflows to handle errors more gracefully and ensure proper asset collection for VirusTotal scans._

* Chore: enhance macOS App Store build process. 

* Chore: enhance macOS App Store build workflow. 
  _- Added TARGET_NAME_macos_appstore_pkg to build configuration for macOS App Store package.
- Improved artifact handling by copying the macOS App Store package to the output directory.
- Updated comments for clarity regarding artifact uploads and error handling in the CI workflow._

* Chore: update build scripts and configurations for iOS and macOS. 
  _- Added PrivacyInfo.xcprivacy to the Resources build phase in the Xcode project to ensure proper inclusion in the app bundle.
- Enhanced validation scripts to check for the presence of PrivacyInfo.xcprivacy in both the main app and the packet tunnel extension.
- Updated Makefile comments for clarity regarding CI build processes for the Mac App Store._

* Chore: update iOS build configurations for manual signing and improve macOS App Store workflow. 
  _- Changed code signing style to Manual and updated provisioning profile specifier in Xcode project files.
- Enhanced macOS build workflow to ensure proper artifact uploads and error handling for Apple Distribution identity.
- Updated exportOptions.plist to correct provisioning profile references._

* Refactor: streamline macOS build workflow and improve provisioning profile handling. 

* Feat: add macOS App Store installation dependencies to Makefile. 

* Feat: update macOS build process and enhance core integration. 

* Feat: update .gitignore and enhance desktop mTLS smoke test. 

* Feat: improve animation rendering. 

* Feat: update connection notifier to reflect disconnecting state. 
  _- Modified the _disconnect method in ConnectionNotifier to set the state to Disconnecting when a disconnect action is initiated.
- Added comments to clarify the behavior of the connection state during the disconnect process._

* Feat: enhance IP information handling with custom `ipinfo-url` support. 
  _- Updated `ProfileParser` to include `ipinfo-url` in allowed override configurations and populated headers.
- Modified `IpInfoNotifier` to utilize a custom IP information URL from headers when available.
- Enhanced `ProxyRepository` to accept a custom `ipinfo-url` for fetching IP information.
- Added flexible parsing for various IP information JSON structures to accommodate custom endpoints.
- Introduced tests for new IP information parsing logic and validation of `ipinfo-url` handling._

* Feat: implement mTLS support for gRPC connections. 
  _- Updated hiddify-core submodule to the latest commit for mTLS functionality.
- Added new test cases for mTLS handshake in both Android and iOS environments.
- Enhanced MethodHandler to register client certificates for secure connections.
- Integrated mTLS setup in CoreInterface for mobile and desktop platforms.
- Introduced new assets (client certificate and key) for testing mTLS functionality.
- Updated build.gradle and other configurations to support new dependencies for testing._

* Feat: enhance release notes with VirusTotal integration and SHA-256 digest automation. 
  _- Added VirusTotal status badges and download counts to the release message template.
- Introduced a new script to replace placeholders with actual SHA-256 digests of release assets.
- Updated GitHub Actions workflows to automate the generation of release notes with VirusTotal links and asset information._

* Feat: integrate VirusTotal scanning into release workflow. 
  _- Added a new workflow for VirusTotal scanning of release assets.
- Implemented two jobs: virustotal-draft for draft releases and virustotal-release for non-draft releases.
- Enhanced build.yml to include VirusTotal scanning steps and permissions.
- Created virustotal_scan.yml to handle the scanning process and update release notes with scan results._

* Feat: add CoreInterfaceDesktopTun for VPN management on Windows and Linux. 
  _- Introduced CoreInterfaceDesktopTun to manage VPN connections using gRPC.
- Implemented snapshotVpnConfiguration for handling local file references in VPN profiles.
- Updated CoreInterfaceMacOS to utilize snapshotVpnConfiguration for configuration management.
- Enhanced TunnelServiceController to ensure service readiness and manage build IDs.
- Updated core interface wrapper to support the new desktop tunnel interface._

* Chore: hiddify-tunnel-service in macos. 
  _- Updated hiddify-core submodule to the latest commit.
- Changed cache dependency path in GitHub Actions build workflow to point to hiddify-core/go.sum.
- Enhanced TunnelStartRequest in tunnel.proto to include additional fields for configuration.
- Removed unused NetworkExtensionCore files and adjusted macOS build scripts accordingly.
- Updated TunnelServiceController to manage VPN service state and configuration more effectively._

* Feat: Implement VPN service management for Mac App Store and Developer ID builds. 
  _- Added support for running the VPN through a bundled hiddify-core library with administrator rights.
- Introduced AppStore.entitlements for sandboxing and network extension capabilities.
- Created AppStore.xcconfig for Mac App Store build configurations.
- Updated NetworkExtension configurations to differentiate between app extension and system extension.
- Added Unsigned.xcconfig for builds without Developer ID, utilizing hiddify-core's tunnel service.
- Enhanced Info.plist to include new keys for tunnel kind and application category.
- Developed TunnelServiceController to manage VPN service installation and state.
- Implemented install and uninstall scripts for the VPN service.
- Updated build scripts to handle different distribution modes (unsigned, developer-id, app-store).
- Removed obsolete prepare-tunnel-source.sh script and adjusted source handling in build scripts._

* Feat: update GitHub Actions permissions for release workflow. 

* Feat(macos): adopt latest changes for macos no root vpn. 

* Merge pull request #2354: run the macOS VPN in a packet tunnel system extension. 
  _Conflicts in startup_connection.dart and hiddify_core_service.dart: both sides
kept. When the extension manages the core, its own start, stop and status path
runs first; otherwise the start/stop cancellation and status listener numbering
from main apply._

* Chore: merge upstream main into macOS network extension branch. 
  _Preserve the macOS managed VPN lifecycle while adopting upstream logging and dependency changes. Avoid restarting a tunnel already restored by macOS on app startup._

* Fix(macos): Change user-visible bundle display name to more user friendly. 

* Fix(macos): support universal Flutter builds with Apple lipo. 

* Fix(macos): make signing errors self-contained. 

* Refactor(macos): adopt shared extension provider. 

* Fix(macos): resolve VPN resources from the core working directory. 

* Fix(macos): restore process lookup in VPN mode. 

* Chore: remove unnecessary MD file. 

* Chore: clean lint and whitespace in touched code. 

* Fix(macos): prepare signed releases for notarization. 

* Fix(macos): disable saved VPN before changing engines. 

* Chore(macos): isolate local VPN testing and configure release signing. 

* Fix(macos): present VPN extension approval as a permission prompt. 

* Feat(macos): run VPN in a packet tunnel system extension. 

* Feat(connection): update EclipseLook states to include stopping and adjust animation logic. 

* Fix(dialogs): streamline focus node initialization and improve markdown link handling. 

* Feat(home): show the traffic as an eclipse round the connect button. 
  _The button is a white disc that curves at its edge; while connected, download
glows sun yellow and upload plasma blue behind it, reaching further as more
flows. A failed connection shows a badge that opens the error. The home page
background lightens a little round the button._

* Feat(connection): improve connection handling and add cancellation logic. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Merge pull request #2382 from saeed-jalilian/fix/proxies-list-recovers. 
  _Fix "Unexpected error" on the Proxies page after the app returns from the background_

* Merge pull request #2386 from veto9292/fix/pre-release. 
  _feat: QR code from image, http2 cancel fix, bump hiddify-core_

* Chore(l10n): carry the QR code texts into the ten locales. 

* Feat(profile): read a QR code from an image in the scanner dialog. 

* Feat(i18n): rename the scan button to QR code and add the no-QR-in-image text. 

* Fix(deps): use http2 3.1.0 so a cancelled call no longer drops the core connection. 
  _With http2 2.3.1, when the app cancels a gRPC call just as the core answers
it, the late answer makes the client close the whole connection
(dart-lang/http#1799). Every call on it fails, including the status
listener the connect button relies on. The app's own listener re-opening
already triggers it: the logs show 90 such drops on Windows and 2 on
Android.

http2 3.1.0 fixes this, but grpc still allows only 2.x, so the version is
overridden until grpc allows 3.x._

* Chore(dev): allow flutter_driver in profile builds. 
  _The iPhone build running on a Mac only starts as a profile build, so the
driver was never available there. It stays behind the driver flag, which
still costs the real keyboard, and stays out of release builds._

* Merge remote-tracking branch 'upstream/main' into fix/pre-release. 

* Feat(vpn): add always-on VPN functionality and UI toggle. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Merge pull request #2367 from veto9292/fix/pre-release. 
  _Pre-release fixes_

* Fix(home): stop the connect spinner from throwing duplicate keys. 
  _The spinner sat in an AnimatedSwitcher, which keeps an outgoing child on
screen for its 300 ms fade. When the state flipped twice within that time,
as a hot restart while connected did, two unkeyed empty boxes faded out
together with the same key and Flutter threw "Duplicate keys found". The
spinner is now one child that fades with AnimatedOpacity, and its
animation stops while hidden._

* Chore(l10n): carry the balancer strategy texts into the ten locales. 

* Feat(routing): describe the balancer strategy for a few seconds after a pick. 

* Feat(i18n): add the text describing each balancer strategy. 

* Test(proxy): cover the pinned proxy row. 

* Fix(proxy): keep the picked proxy in the row the user tapped. 
  _A new ping re-sorted the proxies page right after a tap, so the proxy the
user had just picked could jump, often to the end of the list. It now
stays in the row it was tapped in while the rest sorts around it, as long
as it is the main group's choice. Picking a group such as lowest pins
that row, not the proxy the group picks. A new connection or sort clears
the pin._

* Test(proxy): cover a failed proxy switch. 

* Chore(l10n): carry the failed proxy switch text into the ten locales. 

* Fix(proxy): tell the user when switching to a proxy fails. 
  _A failed switch threw from the tap handler, where nothing caught it: the
app logged an uncaught error and the tap looked ignored. It now shows an
error SnackBar, "Couldn't switch to this proxy. Try again."_

* Feat(i18n): add the text for a failed proxy switch. 

* Test(rules): cover the built-in rules. 
  _Test file only, no app code changes, so it needs no close review.
It checks the built-in rules' order, switches, region changes, reset
and import, and how the routing page shows them._

* Fix(profile): keep the config editor's type dropdown from crashing on unknown values. 
  _Add awg to the endpoint types, and show any value the list doesn't know as
an extra item instead of tripping DropdownButton's assertion._

* Feat(logs): keep the category filter across runs. 
  _Same as the level filter: the category filter is saved as the
log-filter-category preference, the page opens on it, and picking a
category saves it. "All" is saved as an empty string and stays the
default._

* Feat(logs): keep the level filter across runs. 
  _The logs page's level filter went back to warn on every run, and on a
phone also every time the page was closed, since the page's state is
dropped with it. It is now saved as the log-filter-level preference:
the page opens on the saved level, and picking a level saves it. warn
stays the default._

* Fix(android): keep the VPN service's platform interface when the front core restarts. 
  _The core keeps one platform interface per process, and the front
core's setup passed null. After the front core was closed on pause and
set up again, the running VPN service lost its link to Android's
VpnService, and the next in-place restart (profile update or switch)
failed with "open /dev/tun: permission denied", leaving a dead tunnel
that Android still showed as connected.

BoxService now records its platform interface while it runs, and the
front core's setup passes that one instead of null._

* Fix(app): stop the front core on pause only, not on inactive. 
  _The lifecycle state came from useAppLifecycleState, which reports a
change only when the widget rebuilds, and no frame is drawn once the
app is in the background. On Android "paused" often never arrived, so
the front core was closed on "inactive" instead, which also fires for
a dialog or the notification shade.

The state now comes from AppLifecycleListener, which the engine calls
directly: "paused" closes the front core, "resumed" sets it up again,
and "inactive" does nothing. The state at startup is still handled
once, as before._

* Fix(profile): stop the add when an inner link download is canceled. 
  _Cancelling used to write "null" lines and carry on. It now returns
ProfileFailure.cancelByUser and leaves the file unwritten._

* Fix(profile): keep HTTP proxy lines and log failed inner links. 
  _A line counts as a subscription link only when its URL has a path.
HTTP proxy links have none, so they stay as they are instead of being
downloaded and lost. A subscription link that fails to download is
dropped and logged with its host only, since the URL carries a token._

* Fix(profile): drop the Windows line ending from inner links. 
  _The trailing \r went into the request URL, so the download failed._

* Fix(profile): find inner links in base64 subscriptions. 
  _Decode the file before looking for links. A base64 file without links
is still left as it is._

* Fix(profile): keep lines that are not links untouched. 
  _The expander trimmed every line, which removed YAML indentation._

* Refactor(profile): rebuild the inner link expander as text in, text out. 
  _Replace expandRemoteLinesInParallel with expandLinks and
_expandLinksInFile. They now run after the headers are read, in
addLocal, addRemote and updateRemote. A file with no links is no longer
rewritten, so indented Clash YAML stays intact, and links are fetched
into memory instead of side files that were never deleted._

* Feat(http): let DioHttpClient.get return the body as text. 
  _Add an optional responseType to get(). Callers that leave it out keep
Dio's default JSON decoding._

* Test(profile): cover the temp file cleanup. 
  _Check that adding, a failed add, updating and an offline update each
leave no <id>.tmp.json behind, and that the file still exists while
the config is validated._

* Fix(profile): delete the temp file after adding or updating a profile. 
  _upsertRemote and offlineUpdate returned a lazy TaskEither from inside
try/finally, so finally ran before the task wrote <id>.tmp.json, and
the file was never deleted. Run the task inside the try instead, so
the file is deleted after the task, whether it succeeds or fails._

* Test(profile): cover the shared subscription link. 
  _Check that a non-default port, userinfo, path and query survive, that
the old fragment is kept when no name is given, and that the name is
percent-encoded into the fragment._

* Fix(profile): keep the port in the shared subscription link. 
  _The link was rebuilt from scheme, host, path, query and fragment only,
so an explicit port (https://panel.example.com:2053/sub) fell back to
the default one and the shared URL or QR pointed at the wrong server.
Userinfo was dropped the same way.

Replace only the fragment on the parsed Uri instead. This also stops
adding an empty "#" when the link has no fragment and no name is given._

* Feat(notification): pause the SnackBar timer on hover. 
  _The pointer on a SnackBar stops its close timer, as on the toast;
leaving starts it again with the full time. SnackBar's own timer can't
stop, so it is turned off and a timer in the content closes it. That
timer starts when the SnackBar is first drawn, so one raised in the
background still shows, then closes._

* Chore(l10n): carry the applying-changes text into the ten locales. 
  _Persian is re-translated from the new English; the other nine get the key for
the first time. Each follows its locale's wording of "Reconnecting to apply
changes…"._

* Fix(i18n): call the hot reload state "Applying changes…" 
  _"Hot reloading" is developer jargon on a user-facing label. "Applying
changes…" says what happens and matches "Reconnecting to apply changes…"._

* Fix(proxy): stop the active proxy type from overflowing its card. 

* Build(deps): remove toastification. 
  _Its two helper packages, equatable and pausable_timer, leave the lock
file with it._

* Chore(notification): delete the toast hover workaround and its test. 
  _ToastHoverPause only stood in for toastification's pauseOnHover, which
broke the mouse tracker when a toast closed under the pointer. Nothing
uses it now._

* Refactor(app): remove ToastificationWrapper. 
  _Nothing shows a toast anymore._

* Refactor: replace CustomToast with InAppNotificationController. 
  _CustomToast showed the same message as the controller, only from a
widget's context and without an action. Its two uses, the About page's
update check and choosing a profile, now call the controller. Its unused
toast widget goes with it._

* Feat(notification): show a close button on hover in SnackBars. 
  _A SnackBar without an action shows a close button while the pointer is
over it, as the toast did. Hidden, the button keeps its room so the text
doesn't move, but it can't be pressed or reached by a screen reader._

* Feat(notification): round SnackBars and space them like the toast. 
  _Corners of 12 instead of 4, and the toast's spacing: 16 before the icon,
10 between the icon and the text, and a minimum height of 40. Text of
several lines keeps room above and below it._

* Feat(notification): give SnackBars a type icon and medium text. 
  _Each message shows the icon and color of its type, as the toast did: a
green check for success, a red cross for an error, a blue info icon. The
text is medium weight, like the toast's title, instead of regular._

* Feat(notification): show in-app messages as SnackBars. 
  _toastification starts a toast's close timer before the toast is drawn.
A toast raised while the app was in the background drew no frames, so
its timer ran out first and the toast stayed on screen for good. A
SnackBar starts its timer only once it is fully on screen.

InAppNotificationController now shows a floating SnackBar through the
app's ScaffoldMessenger. A new one replaces the one on screen. It closes
after 4 s, or 8 s with an action, is at most 480 wide, and sits 92 above
the bottom on a phone, clear of the bottom bar, and 16 elsewhere._

* Feat(notification): add a SnackBar layer above every screen. 
  _A Scaffold around the Navigator, so a SnackBar can show above every
route: a dialog or a bottom sheet can't cover it. A ScaffoldMessenger
shows a SnackBar only on the outermost of its Scaffolds, and the pages'
Scaffolds sit inside this one.

The pages get the app's MediaQuery unchanged. The layer's own MediaQuery
has no top padding, since on iOS a Scaffold puts a status bar tap target
there, over the pages' own. It counts the keyboard as bottom padding, so
a floating SnackBar stays above it. Nothing shows a SnackBar here yet._

* Feat(profile): import a zip as one profile named after it. 
  _A zip used to become one profile per file. The files are now merged
into one text, with a line of #=== between them, and added as a single
profile named after the zip file. The core reads the #=== line as a
comment, so it ends one config and starts the next, and it skips a
file it cannot read.

readZipText replaces readZipTexts: it returns the merged text, or an
empty string when the bytes are not a zip or no file could be read.
addArchive makes one addLocal call and takes the profile name._

* Refactor(utils): remove the unused BottomSheetPage. 
  _Left over from when bottom sheets were go_router pages. The sheets open
through BottomSheetsNotifier now._

* Fix(router): label the dim layer behind bottom sheets for screen readers. 
  _BottomSheetsNotifier built its ModalBottomSheetRoute by hand. That skips the
barrier label and tap hint showModalBottomSheet adds, so screen readers found
the dim layer behind every sheet without a name. Open the sheets with
showModalBottomSheet on the root navigator instead; they look and close the same._

* Fix(settings): apply a setting changed back after a hot reload. 
  _The listener read the running options snapshot once, in build(). A restart
rebuilt the notifier through the status change; a hot reload keeps the status
connected, so the snapshot went stale and changing a setting back was skipped.
It is now read on every change._

* Feat(home): show the hot reloading look on the connect button. 
  _A new _Look, hotReloading: "Hot reloading…" label, the yellow of noPing, the
connected image, and the tap off while the core applies the config. It comes
before the ping checks. Same behaviour as upstream's version, rebuilt on _Look._

* Feat(profile): accept zip files in the file import. 
  _The picker now lists .zip as well. A picked zip goes to addArchive, and
every other file takes the same path as before._

* Feat(profile): add one profile per file of a zip. 
  _addArchive reads a zip with readZipTexts and adds each file through
addLocal, named after the file, so the core decides which files are
valid configs. Files the core rejects are skipped. The add fails, with
the first failure, only when no file could be added._

* Feat(utils): read the files of a zip as text. 
  _readZipTexts turns the bytes of a zip into a list of (name, text), one
per file, and never looks at what a file contains. It skips folders,
the __MACOSX folder and ._ files that macOS adds when it zips a folder,
and files over 256 KB. The name is the file name without its
extension. Bytes that are not a zip give an empty list._

* Build(deps): declare archive as a direct dependency. 
  _The package was already in the lockfile, pulled in by another package.
The profile import is about to read zip files with it, so the app now
declares it. The resolved version stays 4.0.4._

* Merge upstream/main into fix/pre-release. 
  _Upstream's hot reload (1839ecf6) and the v5.0.0 beta bump (98387fe9).

connection_button.dart keeps this branch's version. Upstream edited the old
per-parameter switches that the _Look refactor removed, so the hot reloading
look is added to _Look in the next commit._

* Fix(profile): show the bulk update toast only for manual runs. 
  _The periodic background update no longer pops a toast every time it
refreshes profiles; only the user-triggered update reports its result._

* Refactor(connection): tidy the checks on a failed core start. 
  _The message is read once before the first check, an empty message
gets its own check instead of a ternary at the end, each check has
one comment, and the commented-out leftovers are gone. The failure
returned for every input is unchanged._

* Chore(l10n): carry the VPN dialog texts into the ten locales. 

* Feat(connection): explain a failed start when another VPN holds the TUN. 
  _The core gives its TUN adapter the fixed address 172.19.0.1. When
another adapter already has it, Windows answers "The object already
exists" and the dialog showed that raw text. The failure now maps to
its own dialog, "Another VPN is active"._

* Fix(i18n): shorten the administrator warning for VPN mode. 
  _The title already names the cause, so the message now gives the
effect and the fix in one line, like the other-VPN dialog._

* Feat(i18n): texts for the dialog when another VPN holds the TUN. 

* Fix(connection): show the core's text when a start fails. 
  _Until February 2026 the dialog for a failed core start showed the
core's message. A type change replaced it with a fixed line, so the
reason stayed in the log. The core's message is back in the dialog,
and the fixed line stays for a core that sends none._

* Fix(connection): warn when VPN mode needs administrator rights. 
  _The warning, its text and the MissingPrivilege failure exist, but
nothing has built the failure since the app-side check went away in
2024. The core's own start error now decides: when it says Windows
denied access to the TUN adapter, the start fails with
MissingPrivilege._

* Fix(connection): open the failed-connect dialog in debug builds. 
  _A failed start sends the core restart signal, which marks the notifier
out of date until the next frame. The failure handler then asked
Riverpod for the dialog, and debug builds refuse that, so no dialog
opened. The dialog, the translations and startedByUser are now read
before the connect starts._

* Feat(home): ring, ripple and error text for the connect button. 
  _The colors stay. The colored glow gives way to the standard level 3
elevation, and the shrink and blur while busy give way to a ring that
spins around the button while it connects or disconnects. One ripple
marks a connect the user waited for, loading dims the logo, and a
failure reads "Couldn't connect" with "Tap to try again" below._

* Fix(home): show a failed start as a failure on the connect button. 
  _The core reports a failed start as disconnected with the failure
attached, and the button showed it as a plain "Tap to connect". It now
shows the error look until the next tap or status._

* Fix(home): keep the connect button's look while the status reloads. 
  _After every core start the connection status rebuilds, and Riverpod
marks it as reloading: AsyncLoading, still carrying the last value. The
button matched settled data only, so it flashed its loading look in the
middle of a connect. It now reads the last value; an error is checked
first because it carries an old value too._

* Fix(connection): set a failed connect's error before showing its dialog. 
  _The error was set only after the dialog closed. A status the core sent
while it was open, such as a late Started, was then overwritten, and
the button showed an error over a working tunnel. Set first, a later
status wins, and nothing after it can leave the connect hanging._

* Fix(connection): report Connecting from the first step of a connect. 
  _The core reports Starting only once the config is built, about a
second after the tap, so the app still showed Disconnected in between.
The notifier now marks itself connecting as soon as a connect starts._

* Chore(l10n): carry the failed-connect texts into the ten locales. 

* Feat(i18n): texts for a failed connect on the connect button. 

* Fix(home): stop at Add profile when there is no profile to connect. 
  _With no active profile, a tap showed the dialog, opened Add profile and
then went on to connect: it could show the experimental notice over the
sheet, vibrated, and saved startedByUser as true before the connect
step gave up. On desktop that flag made the next launch connect by
itself once a profile was added._

* Refactor(home): derive the connect button's look in one place. 
  _One function now turns the core's status and the active server's ping
into the button's look; label, color and image all read from it. A
tunnel with no ping yet still looks like connecting, so one wait has
one look, and a ping timeout says Connected. Loading no longer looks
like an error.

The ping is read without Riverpod's previous value. After a
disconnect that value is the last session's ping, which made the next
connection look up before its own ping answered.

The reconnect branch, the secure label and the unused values are gone:
the reconnect flag only ever held false, and the provider behind it
stays alive through ConnectionWrapper._

* Fix(qr): center the password eye and even out tile padding. 
  _The eye now sits at the tile's end, centered top to bottom, instead of
in the value's row. Tiles get the same 12 dp on both sides; the eye's
own padding lines it up with that._

* Feat(qr): confirm a copy in place instead of with a toast. 
  _Tapping a tile, or the copy-full-link button, swaps its label for a
green "Copied" for a moment. The hidden text keeps its size, so
nothing around it shifts._

* Chore(l10n): carry the QR dialog "Copied" text into the ten locales. 

* Feat(i18n): a "Copied" text for the QR dialog. 

* Feat(qr): Material 3 QR dialog with copyable LAN proxy details. 
  _The QR dialog is now a standard Material 3 dialog: the code on a white
card with the app logo, a title and subtitle, and a copy-full-link
button. For LAN sharing it also lists IP, port, username and password
as tiles that copy themselves on tap; revealing the password gives
each credential its own full-width row.

The sharing row in settings and quick settings keeps its switch and
gets a QR button beside it, replacing the two buttons that sat under
the row._

* Chore(l10n): carry the QR dialog texts into the ten locales. 

* Feat(i18n): English texts for the new QR dialog. 
  _Adds the dialog's copy-full-link button, its IP, port, username and
password labels, the show/hide password tooltips, and the LAN sharing
subtitle. Drops the old "Copy link" key, which the sharing row no
longer uses._

* Chore(l10n): carry the shorter built-in rule titles into the ten locales. 

* Feat(i18n): shorter titles for two built-in rules. 
  _"Bypass LAN" and "Block ads and malware" fit beside the Built-in tag._

* Feat(rules): a lock marks built-in rules after their name. 
  _The Built-in word moves from the outbound line to the end of the
name, after a lock, both in the accent color, and always shows whole._

* Feat(rules): keep a rule's name on one line. 
  _A long name ends in an ellipsis instead of making its tile taller._

* Feat(routing): a mode change turns auto selection off. 
  _As with a region change, the old mode's auto picks go and the user's
own picks stay; the new mode's list isn't applied by itself. Auto
selection still comes on when App-based routing is turned on, until
the user turns it off by hand._

* Style(connection): end two files with a newline. 
  _flutter analyze reported eol_at_end_of_file for both._

* Merge pull request #2369 from xNOTHlNGx/fix/fix-profile-name-after-edit. 
  _fix(profile): preserve profile names after config edits_

* Test(profile): verify renamed profiles persist across edits. 

* Test(profile): cover name preservation across protocols. 

* Fix(profile): preserve imported name after config edits. 

* Merge pull request #2377 from saeed-jalilian/fix/stuck-connecting-after-resume. 
  _Fix status stuck on "connecting" after the app returns from the background_

* Feat: add Profile.xcconfig and update project settings for new configuration. 

* V5.0.0 beta. 

* Feat(hot-reload): implement hot reload functionality for core configuration. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Merge pull request #2365 from veto9292/feat/preset-rules. 

* Merge upstream/main into feat/preset-rules. 
  _Conflicts:
- .gitignore: this branch drops the aider entries; upstream adds the
  local signing material. Both kept.
- analysis_options.yaml: both sides' analyzer excludes kept.
- Makefile: upstream's portable zip (7z, or Compress-Archive) from
  #2359, which fixes the same thing as this branch's tar.exe line.
- hiddify-core: upstream's e5b8ef2, which already contains db74dfc.
- profile_parser_test.dart: both new test groups kept._

* Fix(routing): the region chip leaves the direct DNS server alone. 
  _The old region picker never reset it: its handler never ran. So the
chip doesn't either._

* Fix(rules): rule chips keep their tint with dynamic colors. 
  _dynamic_color 1.7 leaves surfaceContainerHighest unset, so it falls
back to the page color and the chips disappear. Until the Flutter
upgrade, they use surfaceVariant, the same tone._

* Fix(toast): alert toasts start on the reading side. 
  _They were pinned to the bottom left, which in Persian and Arabic is
the end of the line._

* Refactor(routing): build the rules menu when it opens. 
  _The menu no longer has a short form for an empty list, so its items
are built in its itemBuilder instead of on every rules change, and the
two export items use plain tear-offs like the others._

* Fix(routing): sharp app logos at any screen density. 
  _The logos on the routing page and in the share sheet were decoded for
a 2x screen, so most phones scaled them up and blurred them._

* Fix(routing): count the days since an update across clock changes. 
  _The days between two midnights were counted in whole days, so a
23-hour day at a clock change turned yesterday into today._

* Fix(routing): the region chip resets DNS even if the page closes. 
  _The chip read the DNS setting after waiting for the region to save,
when the page may already be gone. It now takes it before the wait._

* Fix(rules): a new install gets the default rule order. 
  _The intro sets the region after the rules load with region Other, so
the region rule was added on top, above Block ads, while Reset puts it
last. A list that was never saved is the default list, so it is now
rebuilt in the default order._

* Refactor(rules): one set tracks the built-in rules still missing. 
  _The allowed built-ins, the ones found and the checks between them
become one ordered set: a built-in seen for the first time is crossed
off, and what's left goes first. Same behavior._

* Refactor(rules): save the rules without sorting them again. 
  _Every change renumbers the list or keeps each rule in its place, so
the list is always in order. The sort also changed the state in place._

* Fix(rules): Proxy only with no apps keeps every app in the VPN. 
  _With an empty Proxy only list, Android lets every app into the VPN,
but the package picker marked every app as outside it, and every
picked one as a rule that won't apply._

* Fix(routing): importing app lists replaces them. 
  _The flags were cleared through a cascade, which kept the column as it
was, so an import merged into the current lists although its dialog
says it replaces them. Auto picks stay, as before._

* Fix(routing): auto selection's loading bar waits for every run. 
  _A mode change can start a run while another still loads. The first
one to end hid the bar and brought back the switch while the other
was still loading._

* Refactor(routing): fewer hops in App-based routing. 
  _The region listener needs no checks: it only fires on a change. The
list page restores the removed auto picks through the data source it
already uses for Undo, so AppBasedRouting no longer passes it along._

* Refactor(routing): auto selection fetches only what it's asked for. 
  _Its one caller always passes the mode and the region, so they are
required, and the unused include/exclude getters, result helpers and
preference fallbacks are gone._

* Fix(routing): the app list survives being rebuilt. 
  _AppList copied its family argument into a late final field in build,
so a second build threw, and its exports watched the translations,
which rebuilds it on a language change. It now uses the generated
mode, and the exports read the translations._

* Refactor(routing): drop the last-update clear that never ran. 
  _Writing null to that preference fails and only logs a warning, so the
date was never cleared. Nothing reads it while auto selection is off,
and turning it on writes a new one._

* Fix(routing): a mode whose list fails leaves auto selection off. 
  _A mode change cleared only the old mode's auto picks, so when the new
mode's list failed to load, auto selection still showed on with no
picks, and Share counted the user's own apps as added. It now turns
auto selection off first, and a list that loads turns it back on._

* Fix(routing): skip an auto selection list that loaded too late. 
  _The region or the mode can change while a list loads, and that change
already settled auto selection. A list that arrives after it is
dropped instead of bringing back the old region's or mode's picks._

* Feat(routing): auto selection row under App-based routing. 
  _Outside region Other, a row turns auto selection on and off, updates
it now, and shows when it was updated or why its list is missing.
While it loads, a bar takes the switch's place._

* Feat(routing): show App-based routing's apps as logos. 
  _While it's on, a row shows up to ten app logos, the user's own picks
first, and opens the app list. It keeps its height while loading._

* Feat(routing): App-based routing section above the rules. 
  _On Android, App-based routing heads the rules list, since it applies
before every rule. Its switch turns it on and off, and its two modes
sit under its name, the current one in a tinted pill._

* Feat(routing): the general options head the rules list. 
  _Balancer, Resolve destination and IPv6 sit above the rules and can't
be moved. Each value sits at the end of its row and opens its menu
there._

* Feat(routing): the rules list fills the page. 
  _The built-in rules keep the list from being empty, so its empty text
goes and the menu always offers every item._

* Feat(routing): remove the general options panel under the rules. 
  _The panel, its Routing tab and the setting that kept it open are gone.
Its options move to the top of the rules list._

* Feat(routing): the region as a chip in the app bar. 
  _The region leaves the bottom panel for a chip beside the menu, with
its flag and the word Region. Changing it still resets the direct DNS
server, whose default follows the region._

* Feat(routing): a plain button adds a rule. 
  _The expandable button offered a new rule and the predefined rules,
which the built-in rules have replaced._

* Feat(routing): share the list's changes from a bar, after a preview. 
  _While auto selection is on and the list differs from the region's
list, a bar counts the changes. Share opens a sheet, shown like the
app's other sheets, with exactly what gets sent and where before it
opens GitHub. The share item leaves the menu._

* Feat(routing): chips to hide system apps and restore auto picks. 
  _The chip row under the app bar also shows while searching. Restoring
the removed auto picks shows a toast that can undo it._

* Refactor(routing): auto selection leaves the app list page. 
  _Its button and the spinner that took the menu's place while it loaded
are gone. Auto selection lives on the routing page now._

* Feat(routing): the app list follows the mode chosen on the routing page. 
  _The page reads the mode in use and takes its title from it. Its own
mode menu, which still offered "off", is gone._

* Feat(routing): tag auto picks in the app list. 
  _An Auto tag after the name of each auto pick replaces the red dot that
marked the removed ones._

* Feat(routing): search the app list by package name too. 

* Chore(routing): name the exported file after App-based routing. 

* Feat(routing): share the lists the share sheet shows. 
  _Sharing no longer loads the region's list again or asks again: it
opens the issue with the added and removed apps the share sheet
already showed, and the link now encodes its title and body._

* Perf(routing): fetch each app logo once per run. 
  _The plugin lists every installed app for each logo it looks up, so ten
logos took seconds. Each logo now stays until the app closes, which
suits the few logos on the routing page, not whole app lists._

* Feat(routing): auto selection comes on until turned off by hand. 
  _Turning App-based routing on, or changing its mode, runs auto
selection unless the user turned it off with its switch. A region
change or Clear all doesn't count as turning it off by hand._

* Feat(routing): a region change turns auto selection off. 
  _The new region's list isn't applied by itself. As with the auto
selection switch, the auto picks go and the user's own picks stay._

* Feat(routing): turn App-based routing on and off, and change its mode. 
  _Turning it on again brings back its mode and list. Each mode keeps its
own list, and when the mode changes, auto selection moves to it with
that mode's region list._

* Refactor(routing): move auto selection into AppBasedRouting. 
  _Applying, clearing and restoring auto selection move from the app list
into AppBasedRouting, next to the new handlers for its switch and its
Update now button. Results show on a status line instead of toasts,
and a region with no list turns auto selection off. The daily refresh
runs every day instead of after a set interval, and its toast is gone._

* Feat(routing): save App-based routing's switch apart from its mode. 
  _The switch gets its own key, and the mode keeps just Proxy only and
Bypass, with Bypass by default. Turning it off no longer forgets the
mode. A saved "off" from older versions counts as never turned on.
Android reads the new switch, and falls back to the old "off" until
the app has moved it._

* Feat(routing): keep auto selection's loading and result in state. 
  _The loading flag now always clears, even when the download fails, and
stays alive while no page watches it. A new state keeps why the last
auto selection gave no list, for a status line under its switch
instead of a passing toast._

* Feat(region): give the region's name without its code. 
  _presentName turns "Iran (ir)" into "Iran", for texts that put the name
in a sentence, such as "Auto selection based on Iran"._

* Fix(routing): an empty auto selection list means no list. 
  _Some regions have an empty list file, such as direct_cn and proxy_ru.
It was taken as a list with no apps, so auto selection showed as on
while doing nothing. It now counts as no list for the region._

* Fix(routing): tapping an auto-picked app goes auto, removed, yours. 
  _A tap on an auto pick now removes it first, as the user most likely
means, then makes it theirs, then gives it back to auto selection. A
removed app that auto selection no longer picks becomes the user's own
instead of vanishing._

* Feat(rules): pick a rule's package names from the installed apps. 
  _The Package names field of a route rule is back. On Android it opens a
list of installed apps with checkboxes, search and a filter for system
apps; elsewhere it opens the plain text list. Apps the rule already has
come first, and the order stays put while ticking. An app that
App-based routing keeps out of the VPN carries a mark, and once ticked
it says the rule won't apply to it. Apps the rule names but that aren't
installed show as such. The old picker and its notifier, both
commented out, are replaced._

* Feat(rules): built-in rules instead of predefined ones. 
  _Bypass local network, Block ads and harmful sites, and the region rule
are now always in the rule list, tagged Built-in. They can be switched
and moved but not edited or deleted. Their content comes from the app,
so an update can improve it; the saved list keeps only their key,
switch and place. The region rule takes the region's name; it leaves
the list when the region is set to Other and comes back at the top,
turned on, with any other region. A list that lacks a built-in rule,
such as a new or imported one, gets it at the top in its default state.
A new rule now goes first, ahead of every other rule.

The predefined rules sheet goes, and so does the auto selection sheet
that the app list page no longer opens._

* Chore(l10n): carry app-based routing and built-in rule texts into the ten locales. 
  _The same text changes as the English commit. Arabic and Russian carry
more plural forms. The region rule reads "region $region" in Russian,
French and Portuguese, so the country name keeps its plain form._

* Feat(i18n): English texts for app-based routing and built-in rules. 
  _New texts for the App-based routing section and its app list, auto
selection's status, the share sheet, the built-in rules and Undo.
Per-app proxy is now called App-based routing, and Proxy is now Proxy
only. The texts of the old per-app page, the predefined rules sheet and
the General routing options heading are removed._

* Refactor(routing): rename the per-app proxy code after the UI. 
  _Names only, no logic: the per_app_proxy folder becomes app_based_routing;
PerAppProxyService, PerAppProxy, PerAppProxyPage and AppProxyLoading
become AppBasedRouting, AppList, AppListPage and AutoSelectionLoading,
with their files; the perAppProxy route becomes appList; and the code
reads the moved text keys. Imports are re-sorted where a path changed
their order._

* Chore(l10n): move the routing text keys in the ten locales. 
  _The same key moves as the English commit; no text changes._

* Refactor(i18n): move the routing text keys to match the UI. 
  _Only key paths change, no text: generalOptions.region, regions,
balancerStrategy, resolveDestination, ipv6Route and ipv6Modes move up to
routing.*, generalOptions.perAppProxy becomes routing.appBasedRouting,
and dialogs.confirmation.perAppProxy becomes dialogs.confirmation.appList._

* Docs(claude): note hot reload and build_runner watch. 

* Feat(toast): flat toasts with an optional action button. 
  _Update toastification to 3.2. Toasts use the flat style instead of the
filled one, and a toast can carry one action button, such as Undo, at
its end; pressing it closes the toast.

Every toast now stays a fixed time: 4 s, a Material 3 snackbar's time,
or 8 s when it has a button, to read it and reach the button. The
duration arguments are gone, so errors, the clipboard size warning and
the bulk profile update no longer set their own times. A toast with a
button hides the close button, so the button reaches the toast's end._

* Feat(rules): give each new rule a numbered name. 
  _A new rule was always called "Rule", so several new rules looked alike in
the list. Add a random four-digit number, such as "Rule 4821"._

* Fix(rules): accept IPv6 addresses in IP CIDR fields. 
  _The IP CIDR check took only IPv4, and an unescaped dot in its pattern let
any character stand between the last two numbers, so 1.2.3x4 passed.
Parse the address with Dart's own IPv4 and IPv6 parsers instead, and
allow a prefix of up to 32 or 128 bits._

* Fix(makefile): ship the Windows portable package as a real zip. 
  _The portable package is repacked with tar -a, which picks the archive
format from the file extension. The recipe runs in Git's sh, where tar
is GNU tar. GNU tar does not know .zip, so it quietly wrote an
uncompressed tar under a .zip name; v4.0.4 and v4.1.1 both shipped that
way. Windows' own zip support shows the file as empty and Expand-Archive
rejects it, so only tools that read the content, such as 7-Zip, could
open it.

Call Windows' own tar.exe, which is bsdtar and writes a real, compressed
zip for -a. Checked by running the recipe with a stand-in fastforge: the
result opens in Explorer and in Expand-Archive, with the Hiddify folder
intact.

Reported in hiddify/hiddify-app#2348._

* Fix(profile): drop .mobileconfig from the accepted import formats. 
  _A .mobileconfig holds an Apple IKEv2 profile. Hiddify is a sing-box
client and cannot read one, so offering it in the picker only ever led
to a failed import, with a message that reads like a broken file rather
than an unsupported format._

* Fix(router): keep the back button working after a settings sub-page. 
  _The PopScope that sent back to home lived inside the settings branch. Branches
stay mounted after the user leaves them, so it kept answering presses meant for
other branches and the app could no longer be closed with back at all. Reported
upstream as flutter/flutter#193098.

Move the handling to the shell, where exactly one instance exists and it always
belongs to the branch on screen. The NotificationListener beside it keeps the
platform told that Flutter handles back; without it Android stops believing that
once a branch pops a page, and closes the app without calling Flutter.

Verified on an Android 16 emulator with both the back button and the edge swipe._

* Feat(profile): accept more config formats when importing from a file. 
  _The picker allowed .txt and .json only, so a Clash .yaml, a WireGuard
.conf or an .ovpn had to be opened and pasted by hand. It now takes
.yaml, .yml, .conf, .ovpn and .mobileconfig as well.

Widening it exposed two ways the read could fail. utf8.decode is strict,
so one byte that is not valid UTF-8 threw and took the whole import with
it; it now runs with allowMalformed, and a UTF-8 byte order mark is
skipped rather than left in front of the first character, where it
breaks JSON parsing. The path was also dereferenced with a bang, which
the web build never has._

* Fix(profile): name the real host in the deep-link import warning. 
  _The confirmation parsed the deep link itself, whose host is always the
literal "import", so every link claimed to come from the same place. It
now unwraps the link to the subscription URL first and reports that host._

* Fix(connection): log a failed connection at error, not info. 
  _Every status went through one info call, success and failure alike. A
failure carries the core's own panic text, which is the last thing that
should need hunting for among the ordinary comings and goings — and the
app log file now keeps errors only, so at info it was not kept at all._

* Feat(logs): rebuild the logs page. 
  _The page used to show only what the engine said, from a buffer that
started empty every time it opened. It now reads the shared ring, so it
holds every category and already has history the moment it opens.

The list reads like a terminal: oldest at the top, newest at the bottom,
and the view follows the newest line until you scroll away from it. A
long press or a right click copies one line.

Three chips and a search field sit under the list, next to the newest
line rather than the oldest. Two of them hide rows; the third is the
core's log level, which changes what gets recorded, so a toast says it
lands on the next connection. Below 700px the search takes its own row.

Sharing became a choice rather than two buttons: the visible history,
which can be filtered again before it leaves, or one of the files, each
listed only when it exists and has something in it. A history too long
for the clipboard falls back to a file.

Both sheets go through BottomSheetsNotifier, so they get the app's own
width, corners and route rather than a bare showModalBottomSheet._

* Refactor(logs): read the shared ring instead of the engine's stream. 
  _Four pieces did one job. The engine kept its own buffer of the last 300
messages and re-emitted the whole list on every line, a parser turned
those messages into an entity, a repository wrapped the parser, and the
page watched the repository.

The engine already writes each message straight into the shared ring:

    coreLogFor(event.type).log(getLogLevel(event.level), event.message)

so the buffer, the parser, the entity and its failure type are gone. The
repository's last job — making sure the file exists — moved into the
sink that opens it, which leaves nothing for the repository to hold.

The path resolver now points at the engine's real crash file rather than
the goroutine dump it writes at every start. That dump is not a crash
report: it exists on a healthy machine and says nothing about a failure._

* Feat(logs): translate the renamed app log entry. 

* Feat(logs): name the app log file for what it now holds. 
  _The file used to hold everything the app recorded. It now holds errors
from the app and the core alike, so "App log file" named the wrong two
things: the wrong source, and the wrong amount._

* Feat(logging): keep only errors in the app log file. 
  _The file exists so a crash leaves something behind. Everything quieter
than an error is already somewhere better: the page reads the in-memory
ring, and the core keeps its own complete log in data/box.log.

Narrowing it to errors removed three mechanisms that only existed to
make a busy file affordable — the write batching, its timer, and the
size cap with the trim that enforced it. Errors are rare, so each one is
written straight through and is on disk before the crash that follows
it. The file grows by the handful, so it no longer needs bounding.

Four tests cover what the sink now promises._

* Feat(logging): three log categories instead of five. 
  _The page filtered by five prefixes: core, app, ui, infra, boot. Two of
them told the reader nothing — a logger named HomePage already says it
is a widget — so ui is gone and PresLogger writes app like AppLogger.

The remaining three become a type rather than a prefix string, and app
is defined as whatever boot and core do not claim, so loggers from
packages that never heard of our naming still land somewhere.

The ring also returns oldest first now, which is how a log reads on the
page, in the clipboard and in a file, and drops the per-category counts
nothing was reading._

* Feat(logging): drop debug mode, keep only the log level. 
  _Two controls produced one outcome. The app had a debug mode switch it
passed to the core at startup, and the core turns the same flag on by
itself whenever the level is trace or debug:

    static.debug = static.debug || static.logLevel <= LogLevel_DEBUG

So the two could disagree — switch off, level debug, core in debug, app
believing otherwise. The switch is gone and the app reads the level with
the same rule the core uses, which is what isVerbose says.

The buffer size preference lands here too. It answers the same question
as the level does: how much gets recorded._

* Feat(logging): give every level one name. 
  _package:logging spells its levels FINEST, FINE, INFO, WARNING, SEVERE.
The engine says trace, debug, info, warn, error. Both names appeared on
the same page, next to each other, for the same idea.

The engine's win, since those are the ones the user picks from, and the
log file now writes them too. uiLevels is the subset a filter can offer:
FINER and CONFIG are never produced, and SHOUT never needs its own entry
because the filter is a floor and error already covers it._

* Feat(logs): translate the new logs page. 
  _The same 17 strings in the other ten locales, written from the English
rather than from each other, and anchored on the words each language
already uses for core, app and log so the page reads like the rest of
the app.

Drops the two old share buttons and the Settings strings for debug mode
and log level, which no longer exist in the base locale._

* Feat(logs): word the new logs page. 
  _Adds the strings the redesigned page needs: the three filter chips, the
share sheet's sources, the export action and its match count, and the
buffer chip in the app bar.

Drops shareCoreLogs and shareAppLogs, since sharing is no longer two
buttons, and the Settings strings for debug mode and log level, since
neither setting lives there any more._

* Fix(driver): stop the driver extension from blocking the keyboard. 
  _enableFlutterDriverExtension registers a TestTextInput, which takes over
the text input channel. Every debug build called it, so no text field in
the app could accept a real keyboard — the search box on the logs page
would focus and show a caret, and then swallow every keystroke.

It now runs only when asked for, so a normal debug build types again and
the driver is still one flag away._

* Feat(logging): keep the log file across runs, and point at the engine's real one. 
  _Three changes to what lands on disk.

The file is no longer emptied at launch. A crash leaves its evidence in the
previous run's lines, and wiping on startup threw exactly that away. Growth is
bounded instead: past 5 MB the older half is dropped and the newer half kept,
checked every 500 lines rather than on every write. Each run writes a marker
line, since one file now spans several.

Engine lines are filtered to warnings and above. The engine keeps its own
complete log, so repeating its routine chatter here only flooded the file and
ate the cap — while an engine failure still sits next to the app line that led
to it.

coreFile() pointed at <workingDir>/box.log, which nothing writes. The engine
logs into <workingDir>/data/box.log — so "share core logs" has been handing
over an empty file. Adds coreHangFile() for the goroutine dump the engine
writes beside it, which is what a hang needs._

* Fix(logging): point the origin at the caller, and say where logs appear. 
  _Two defects the first real run exposed, neither visible to the analyzer.

The origin pointed at the logger itself. error() captures StackTrace.current
inside the extension, so frame zero was log_level_compat.dart rather than
whoever called it. Frames from core/logger are skipped when picking the origin
now, and the '.<anonymous closure>' suffix is dropped — it said nothing the
file and line did not already say, and splitting it on whitespace produced
'closure>'.

  before  status  <-  LogLevelCompat.error (log_level_compat.dart:29)
  after   status  <-  HiddifyCoreService.startListeningStatus (hiddify_core_service.dart:442)

A terminal showed no logs at all. dev.log writes to the VM service, never to
stdout — verified with a probe: print and debugPrint appear there, dev.log does
not. Printing every record as well would fix the terminal but show everything
twice in an IDE console, so stdout gets one notice at startup naming the three
places records do appear.

CI is unaffected: build failures come from the compiler and the flutter tool,
never through the app's logger._

* Fix(logging): let a phone share its app logs. 
  _A phone in release keeps no app.log — writing one continuously costs storage
nobody reads — so the share menu was hidden there entirely and the user had no
way to send app logs at all.

The history is in memory anyway. Sharing now writes the ring out to
app-logs.txt at the moment the user asks, so the file exists exactly when it is
needed and never otherwise. Continuous cost stays zero, and the menu is useful
on every platform except web.

The export uses its own file name rather than app.log, which the file sink is
still writing to on desktop.

Engine logs were never affected: box.log is written by the engine itself on
every platform._

* Refactor(logging): remove loggy. 
  _The last step of the switch. Sentry becomes a listener like every other sink,
the file sink is attached, and loggy's plumbing is deleted.

  sinks/sentry_sink.dart  replaces analytics_logger.dart. Same rule as before —
                          info and up becomes a breadcrumb, severe and up
                          becomes a reported event — but as a subscription the
                          analytics toggle attaches and cancels, rather than an
                          entry in a printer map. Levels map onto Sentry's five
                          properly now: SHOUT is fatal instead of collapsing
                          into error.

  bootstrap.dart          the three LoggerController calls become logStart,
                          logAddFile and logFinish. This reattaches app.log,
                          which had no writer since the mixins switched.

Deleted: logger_controller.dart, custom_logger.dart, analytics_logger.dart, and
the dependency itself. Nothing imports loggy any more.

Whether to keep the log file is unchanged in effect but clearer to read: worth
its cost on desktop or while debugging, pure waste on a phone in release._

* Feat(logging): split engine logs by their type. 
  _Every LogMessage from the engine already carries a type — CORE, SERVICE or
CONFIG — and hiddify dropped it, so a failed profile import and a thousand
connection lines landed in the same pile.

  core.core     the proxy engine: connections, routing, dns
  core.service  the background tunnel: start, stop, permissions
  core.config   reading and validating a profile

Nothing new is transmitted; the field was already on the wire. When a profile
fails to import you can now ask for core.config alone.

Also renames the boot logger to boot.bootstrap, after the file it reports on._

* Refactor(logging): make the category impossible to get wrong. 
  _Nothing outside custom_loggers.dart builds a Logger any more. A name without a
category would quietly break the logs page filter, so the only way to get one
is through a mixin or a factory, and both stamp the prefix.

Classes use a mixin. Static and top level code cannot — a mixin needs an
instance — so it uses the matching factory. UriUtils, the FFI interface and the
preferences provider were all constructing loggers by hand; they now go through
infraLogger() and appLogger().

Adds CoreLogger, so the engine bridge is a category like the rest rather than a
bare name, and boot., which separates startup from the app layer. Startup logs
are what you read first when the app fails to start, and they were mixed in
with everything else.

Drops LoggerMixin. It declared "this class has a loggy" for ExceptionHandler,
which never used it._

* Refactor(logging): switch the three mixins to package:logging. 
  _The step that moves every app log at once. PresLogger, AppLogger and
InfraLogger now hand out a package:logging Logger.

The getter keeps the name `loggy`, and log_level_compat is re-exported from
this file, so the ~200 classes that write logs are untouched. Only five call
sites needed editing — the ones that passed loggy's own LogLevel as an
argument, which is a type the extension cannot alias away.

Logger names gain a layer prefix: ui., app. and infra. That is what will let
the logs page filter a whole layer, and taking the rest from $runtimeType means
a renamed class cannot leave a stale name behind.

Note app.log receives nothing until the next step. loggy's file printer still
owns the file but no longer has any writers, and the replacement file sink is
not attached yet — two IOSinks on one path would truncate each other._

* Feat(logging): say where an error came from. 
  _Every log line that carries a stack now ends with the method, file and line it
came from, taken from the first frame belonging to this package:

  could not save the profile  <-  ProfileRepository.save (profile_repository.dart:88)

It is appended to the message rather than kept in a separate field, because the
message is the one thing DevTools, the logs page and app.log all display.

error() and fatal() capture StackTrace.current when the caller does not pass
one, so a bare loggy.error('...') still knows its origin. Errors are rare
enough to afford the stack walk.

The stack handed to dev.log is trimmed to this package's frames as well. A raw
trace is about twenty frames, nearly all of them inside Flutter, and the
console printed every one — three lines instead of twenty-two, and the ones
that survive are still clickable in the terminal._

* Fix(logging): stop swallowing the Flutter error report. 
  _FlutterError.onError defaults to presentError, which prints the full formatted
report. Assigning a handler replaced it, so an error that used to arrive as a
complete report with the widget context became a single terse line — which is
why crashes have been hard to read.

  - presentError is called again in debug builds
  - details.library and details.context are now logged; exceptionAsString()
    leaves both out, and they are the parts that say which subsystem failed and
    what it was doing

Also completes log_level_compat with trace() and fatal(), so all six levels the
engine can produce have a short name, not just the four loggy happened to have._

* Refactor(logging): move the crash hooks off loggy. 
  _Both uncaught-error handlers now write through package:logging. The class keeps
the name Logger so the existing Logger.bootstrap.info(...) call sites are
untouched; package:logging's own Logger is aliased to avoid the clash.

Adds log_level_compat.dart, which aliases loggy's debug() and error() onto
fine() and severe(). This is the single reason the migration does not have to
edit the ~200 classes that write logs.

A Dart extension is only visible where it is imported, so it is re-exported
from logger.dart rather than added to every call site._

* Refactor(logging): move engine logs onto the new pipeline. 
  _First real traffic through package:logging. App logs still go through loggy.

The level mapping was rewritten and fixes two defects:

  TRACE had no case at all and fell into the default, so engine trace lines
  arrived as INFO — they looked as important as normal traffic and could not be
  filtered out. FATAL collapsed into error because loggy had nothing above it.
  Six engine levels now map onto six distinct levels, FINEST through SHOUT.

The per-line split is gone. It existed defensively, but the engine already
sends one line per message, so it only allocated a list and multiplied the
per-record work during a connect burst.

Engine records now carry the name `core`, so the logs page can filter the whole
engine in or out with a single prefix check.

Until the file sink is attached, engine lines are absent from app.log. Nothing
is lost: the logs page still reads the gRPC stream directly, and box.log is
written by the engine itself._

* Refactor(logging): run the new pipeline alongside loggy. 
  _Adds the replacement for LoggerController and starts it in bootstrap. Still no
behaviour change: every class logs through loggy, so Logger.root has no writers
and the console and ring sinks receive nothing.

Where loggy took a single printer and needed a class to fan out to the rest,
the root stream accepts any number of listeners, so each destination is just a
subscription that can be attached or cancelled.

Two sinks are deliberately absent until loggy is gone:
  - the file sink, because loggy's FileLogPrinter still owns app.log and two
    IOSinks on one file would corrupt it
  - Sentry, which needs the real SDK integration rather than the bench's
    counting stand-in_

* Refactor(logging): add the ring buffer and file sink, wired to nothing. 
  _First step of moving off loggy. These files are inert: nothing imports them
yet, so behaviour is unchanged.

  ring/log_ring.dart   bounded history the logs page will read. Stores
                       LogRecord objects, not formatted strings, and bumps a
                       revision counter instead of publishing a stream, so one
                       log line does not become one stream event.
  sinks/file_sink*     three files behind one conditional export. The compiler
                       picks the dart:io version natively and a no-op stub on
                       web, which replaces the kIsWeb checks.

package:logging is added next to loggy rather than replacing it, so both
systems can coexist until the last step._

* Fix(debug): import foundation.dart for kDebugMode. 
  _material.dart re-exports foundation.dart with a show list that does not
include kDebugMode, so both entrypoints failed to compile. app.dart
already imports foundation.dart explicitly for the same reason._

* Feat(debug): enable flutter_driver in debug builds. 
  _Both entrypoints register the flutter_driver extension behind kDebugMode,
so a running debug app can be driven from outside — taps, text input,
scrolling, reading widgets, screenshots. kDebugMode is a compile-time
const, so release builds drop the branch entirely.

flutter_driver is declared as a normal dependency, matching how
accessibility_tools is already handled._

* Refactor(i18n): fix the notAvailabeInThisPlatform key spelling. 
  _The key was missing an "l" in "Available". Renamed with `dart run slang edit
move`, which rewrites the key across all eleven locale files in one pass, per
the tooling note in CLAUDE.md.

Key name only — no translated string changes, so this needs no separate en
and locale commits._

* Chore(l10n): carry the routing empty state into the ten locales. 
  _Follow-up to the two previous commits. Every locale had translated the "+
button" and the tap gesture literally, so all ten needed the same rewrite,
translated from the new English text rather than from another locale.

Also adds routeRule.add, the FAB's accessibility label, per locale.

Terminology follows each locale's own routing.title and
predefinedRules.title, so "routing rules" and "predefined rules" read the same
here as on the rest of the screen._

* Fix(a11y): name the routing rules FAB and its menu for screen readers. 
  _The FAB carried only an add icon, so a screen reader announced it as an
unnamed button. It now takes a tooltip, which serves as both the hover label
and the accessibility name: "Add rule" when closed, "Close" when open.

The two menu buttons had their names in a sibling Text widget, so each button
was also announced bare. MergeSemantics joins each pair into one node.

Both menu buttons were built even while the menu was closed and hidden with
Opacity(0), which hides pixels but keeps the widget hit-testable and in the
semantics tree — they were clickable and reachable while invisible. Naming
them would have made that worse, so they are now wrapped in IgnorePointer and
ExcludeSemantics while closed._

* Fix(i18n): drop the tap gesture from the empty routing rules state. 
  _"Tap the + button to create a new rule or choose from predefined rules" was
wrong on the desktop builds, where the button is clicked with a mouse, and it
named the control by its icon shape, which a screen reader user never sees.
It also promised one action while the button opens a menu of two.

Naming the two choices instead removes the gesture entirely, so one string is
correct on every platform, and the wording now matches the two menu labels —
the consistent-verbs rule in .claude/writing/m1-writing.md. Per
.claude/writing/m1-empty-states.md the tagline names the topic and no longer
reads like a button.

Adds routeRule.add for the button's accessibility label, used in the next
commit._

* Chore(l10n): carry the English wording fixes into the ten locales. 
  _Follow-up to the previous commit. Each string was translated from the new
English text, not from another locale, and kept in the v2ray/VPN context.

18 strings per locale, 19 for fa. Four of the English fixes were rules about
English only and changed nothing here: the "don't" to "do not" contraction,
"which" to "that", and the two "config" spellings, which every locale except
fa had already spelled out. fa gets the extra edit for the same reason —
"کانفیگ" to "پیکربندی".

Typography kept per language: fr keeps U+202F inside its guillemets, and the
two Chinese locales keep their fullwidth punctuation._

* Fix(i18n): apply the writing rules to the English strings. 
  _First pass over en.i18n.json against the rules captured in .claude/writing/ —
the three Material Design 3 files, plus the older Material pages for the
subjects M3 does not cover. 22 strings changed:

- "Remember my choice" mixed first person into UI text (m3-word-choice)
- the two version labels dropped their trailing colon (m1-writing)
- seven confirmations lost the polite run-up: "Are you sure you want to
  permanently delete this profile?" is now "Delete this profile? You can't
  undo this." (m1-writing, and m3-ux-writing-best-practices on consequences)
- an em dash and a hyphen-as-dash became periods (m3-grammar-and-punctuation)
- the unverified-link warning takes "do not" over "don't" for weight (ditto)
- "Warning" became "Check this link first", so the title names its topic
  (m3-ux-writing-best-practices)
- "config" spelled out, and "enable" became "turn on" (m3 abbreviations,
  m1 jargon)
- the chain filtering text lost its side-note parentheses and split into two
  sentences (m3-grammar-and-punctuation)
- two strings moved into second person, two ungrammatical ones fixed_

* Fix(ui): move the version label separator out of the translation. 
  _The M1 writing rules in .claude/writing/m1-writing.md say a label takes no
colon. The two version labels in the update dialog carried a trailing ": ",
and the dialog glued them straight onto the version number, so dropping the
colon would also drop the space and render "Current version1.2.3".

Put the space in the widget instead. The labels lose the colon in the next
commit, and a translator can no longer break the spacing in ten locales by
trimming a trailing space._

* Fix(readme): render the Google Play badge in local previews. 
  _The badge pointed at a github.com /blob/ URL. GitHub redirects those to the
raw bytes for images, so it rendered there, but every other renderer gets an
HTML page back and draws a broken image.

A relative path works in both places, and drops the stale hiddify-next repo
name at the same time._

* Docs(i18n): move the writing rules out of docs/ into .claude/ 
  _docs/ is not a documentation tree here - it holds one image, the Play Store
badge, which six README files link to through a GitHub URL. The nine writing
files are read by Claude, not published, so they belong beside the other
Claude project files._

* Docs(i18n): replace copied writing rules with captured sources and links. 
  _CLAUDE.md carried a 48-line summary of the Material writing rules with no
clear provenance, plus slang command documentation copied from pub.dev.
Both are now sourced.

The nine writing docs under docs/writing/ each carry their source URL and
capture date, so they can be refreshed later:
- three from the M3 style guide (all it has)
- six from the older Material site, for subjects M3 does not cover

slang is not captured at all. Its README is one page, so CLAUDE.md keeps a
link map into it instead, one line each on which section answers what.

Dropped along the way: the standard button labels, which the confirmation
page turns out never to define; the per-language exception list; and the
rule about preserving placeholders and keys.

The remaining prose is only project decisions - context, English first,
long strings wait for approval, en commits alone._

* Chore(l10n): apply the Material Design 3 rules to the ten locales. 
  _Carries 3662764c into every locale, following the rules now recorded in
CLAUDE.md rather than copying English shape.

Colons dropped from all 19 proxyInfo labels in each locale, 190 in
total, including the full-width colons the Chinese files used.

Quotation marks follow each language instead of the ASCII quotes most
files carried: guillemets for Arabic, Persian and Russian; French adds
its narrow no-break spaces; curly quotes for Spanish, Indonesian,
Portuguese, Turkish and Simplified Chinese; corner brackets for
Traditional Chinese. Simplified Chinese also loses the spaces it had
around them, which do not belong with full-width marks.

The ellipsis character replaces three dots in the five in-progress
strings per locale.

Turn on / turn off replaces enable / disable where the language draws
that distinction: Spanish moves from habilitar to activar, Turkish to
aç / kapat, both Chinese to 开启 / 关闭. Arabic, Persian, French,
Indonesian, Portuguese and Russian already used their turn-on verb.
The IPv6 dropdown becomes a state rather than an action in every
locale: Off / On, Desactivado / Activado, Kapalı / Açık, 关闭 / 开启.

The link warning loses its "we" in all ten, matching the English fix.

please / por favor / veuillez / harap / пожалуйста / lütfen / 请 removed
from the Psiphon licence text.

Final periods added where a string has two or more sentences:
contentTooLarge, unblocker.msg, and useXrayCoreWhenPossibleMsg, which
was missing one in six locales — using 。 for the two Chinese files.

Verified: zero violations across all eleven locales for colons after
labels, three-dot ellipsis, straight quotes, missing final periods and
exclamation points. dart run slang analyze --full stays clean._

* Chore(i18n): drop "we" from the unverified-link warning. 
  _Material says to avoid "we" unless a real person is acting for the
user. "We can't verify this link" made the app speak as a company in
the one dialog where the user needs a fact, not a voice._

* Chore(i18n): bring English fully in line with Material Design 3. 
  _Applies the rule set just written into CLAUDE.md, including the two
rules the old summary had wrong.

Colons dropped from all 19 proxyInfo labels. Material says to skip
colons after labels, and the layout makes it worse than style: the row
is spaceBetween, so the label sits far left and the value far right,
leaving the colon stranded in empty space. This reverses the isGroup
change from e6192f5c, which added a colon to match its siblings when
all 19 were wrong. newVersion.currentVersion keeps its colon because
that TextSpan is followed immediately by the version number.

Periods added to the two multi-sentence strings that lacked them,
contentTooLarge and chain.levels.unblocker.msg. Both already used a
period between their sentences, so they contradicted themselves.

Curly quotes and apostrophes replace the straight ones, 16 quote pairs
and 9 apostrophes. As a side effect the escaped \" sequences are gone
from the JSON.

The ellipsis character replaces three dots in the five in-progress
strings. The truncated-path example keeps literal dots.

Enable/Disable become Turn on/Turn off across labels and prose. The
IPv6 route dropdown reads Off/On instead, since those are option values
rather than actions.

"Please read them carefully before proceeding" loses the "please" and
the stiffer verb. The WARP consent switches to active voice.

The auto-selection dialog dropped the passive "was disabled due to the
region change" for "was turned off because the region changed"._

* Docs(i18n): write the full Material Design 3 rules into CLAUDE.md. 
  _The principles list compressed MD3 to "sentence case, concise, no
trailing period on short UI strings, action-oriented". That was enough
to miss real rules, and I did miss two of them: colons are meant to be
skipped after labels, and periods ARE required once a string holds more
than one sentence. The old wording implied the opposite of both.

Replaces it with the actual rule set from Material's writing style
guide, the M3 grammar and punctuation page, and Material's error
patterns page, grouped by capitalization, punctuation, voice and tone,
word choice, errors, and buttons.

Also records how far the rules travel into the other ten locales, since
several are English-only or script-specific: letter case does not apply
to Arabic, Persian or CJK; contractions and singular "they" are English
only; each language keeps its own quotation marks and spacing; and
plurals follow that language's real CLDR forms._

* Chore(l10n): sync the ten locales with the reworked English. 
  _Follows f73458d7 and 5f2b8e61, which changed 40 English strings. Around
half of those changed meaning rather than wording, so the existing
translations were wrong, not merely stale:

- the clipboard entries said "add" in every locale, but the action is a
  copy: نسخ, Copiar, کپی, Salin, Копировать, kopyala, 复制, 複製
- isGroup was a sentence ("Is group") and is now a label, so its ten
  translations gain the colon their siblings already had
- both license messages became two short sentences naming the fix
- badResponse names the server, invalidConfig went singular
- experimentalNotice points at Settings by the name each UI uses
- eight toasts dropped "successfully" in all ten languages

Fills every gap the analyze report has been carrying:

- remainingDuration and bulkSuccess return as real plurals, in each
  language's own CLDR forms. Arabic gets six (zero/one/two/few/many/
  other), Russian four with the noun case changing per form, Indonesian
  Turkish and both Chinese a single "other" because those languages do
  not inflect a noun after a number. This is the bug that started the
  thread: the old hardcoded string could not have been right anywhere.
- remainingUnlimited, openWebPage, support, openLinkTitle,
  openLinkAction and the five unknownDomainsWarning strings
- French was missing addProfileByDeepLinkWarning and
  importRouteRuleByDeepLinkWarning outright, so French users saw
  English on both, one of them a security prompt

Removes youAreAboutToVisit and thisWebsiteIsNotInOurTrustedList, the
two keys that no longer exist in English. They were the only entries in
the unused report, which is now empty for all ten locales.

Sentence case in the routing hints reaches id, pt-BR and tr, the three
locales that had copied English's old Title Case; es, fr and ru never
had it.

avoidIfUnsure keeps the wording that was already there, per review.

dart run slang analyze --full now reports nothing missing and nothing
unused across all eleven locales._

* Chore(i18n): keep "connection profile" in the empty-profile message. 
  _The previous shortening dropped "connection" from "connection profile".
That is the term the rest of the UI uses, and someone seeing this
message has no profiles yet, so "profile" alone gives them nothing to
attach the idea to.

Restores the full term, brings back a friendly opening, and links the
two paragraphs: the first now asks for VPN *server* details, which is
what the second offers to help create._

* Chore(i18n): tighten English against UI-writing and warning guidance. 
  _Second pass over the base locale, after reading Material Design 3, the
Microsoft UI text style guide, and Mozilla's research on security
warnings. 39 strings.

Warnings now name the concrete risk instead of the abstract one, which
is the change Mozilla measured a 22-50% drop in warning-dismissal from:

- importRouteRuleByDeepLinkWarning said importing from untrusted
  sources "can be a security risk"; it now says route rules decide
  where your traffic goes. Its title also loses a stray hyphen.
- ownResponsibility read as a liability disclaimer that blamed the
  user ("Any loss from misuse is your own responsibility") and is now
  "You continue at your own risk".
- avoidIfUnsure is deliberately left alone.

Errors state the fix rather than the mechanism. The WARP and Psiphon
license messages were one passive sentence naming the feature twice;
both are now "This profile uses X. Accept the X license to continue."
"Bad response" and "Bad certificate" say which thing is invalid.

Filler removed: eight toasts dropped "successfully", which adds no
information and inflates every translation of them.

Verbs match the action: clipboard entries said "Add"/"URL to
clipboard" where the action is a copy, and the QR entries omitted
"code". Note this makes the existing ten translations of these keys
wrong rather than merely stale.

Sentence case finishes the job started in dfea6ace: the routing hints
still capitalised "Process Name", "Process Path", "Port Range" and
"Domain Suffix", and several locales had copied that.

proxyInfo labels read like field dumps ("Is selected:", "Is group");
they are now plain labels, and isGroup gains the colon its siblings
all had.

One screen, one name: "config options page" now points at Settings,
and "Quick setting options" and "Route general options" are named the
way the UI names them.

noActiveProfile drops from 44 words to 25, loses the marketing aside
and the curly apostrophe, and stops using "connection" three times in
one sentence._

* Fix(l10n): apply the translation principles to all ten locales. 
  _Reviewed every non-English locale line by line against the project
translation principles. Also drops remainingDuration and bulkSuccess,
which became slang plural maps in the base locale, so the flat strings
the ten locales still carried no longer matched that structure; both
fall back to English until the next translation pass.

Wrong syntax in a user-facing hint (ar, pt-BR, ru, zh-CN, zh-TW):
validPortRangeEx taught "1-65000", but the app parses a colon. Five
locales share the defect, so it came from an older English string
rather than five independent mistakes.

Text that was never translated (tr, zh-TW):
- tr memoryLimit was the English "Memory limit", sitting directly above
  its own Turkish description
- tr tap_license read "Licence"
- zh-TW enableAnalyticsMsg had an English "and" mid-sentence

Wrong script in the Traditional Chinese file:
- simplified 护/过/规则 replaced with 護/過/規則
- addProfileByDeepLinkWarning had been copied from zh-CN wholesale:
  simplified vocabulary (添加/配置 instead of 新增/設定檔) and ASCII
  quotes instead of 「」
- directPort said 本地 (zh-CN) where Taiwan uses 本機, as the next line
  already did

Terms the files spelled two different ways:
- id: proxy/proksi and Fragment/fragmen/Fragmentasi, now one form each
- fa: Psiphon, Fragment, TUN and IP each had a transliterated variant
- ar: WARP was spelled وارب, fragment as التجزئة, Telegram as التيليجرام
- ru: one stray "Warp" among six correct "WARP"
- padding is kept in English in the six Latin-script locales, matching
  how they already treat Fragment and Balancer; the CJK locales keep
  填充 because they localize systematically

Sentence case per Material Design 3, respecting each language:
- Title Case removed from id, pt-BR, tr, es and the license dialogs
- es and pt-BR continue lowercase after a colon; tr keeps its capital,
  because TDK capitalizes a full sentence after one
- fr regions.cz is now "République tchèque"; pt-BR keeps "República
  Tcheca", which is the correct official form there

Mistranslations:
- id mixedSniCase used "kasus" (a legal case) for letter case
- fa delay.timeout said the test failed rather than timed out

Trailing periods dropped from activeProfileName in the seven locales
that had them, clearListMsg switched from past to future tense in all
ten, and lanSharing regained the "secure" that English gained in
39539c63. es fixes two strings that slipped into formal usted where the
file otherwise uses tú, one of them a security warning._

* Refactor(profile): use the plural remaining-days string. 
  _remainingDuration is now a slang plural taking a num, so the ">365 days"
branch can no longer pass the infinity glyph through it. Read the
dedicated remainingUnlimited string instead._

* Chore(i18n): align English strings with Material Design 3. 
  _Apply the project translation principles to the base locale:

- sentence case: "QR code", "Fragmentation packets", "Psiphon license
  agreement", "Extra security & unblocker", and the Psiphon license
  links, which now match the WARP dialog wording
- drop trailing periods from the two short strings that had them
- restore standard casing for technical terms: WARP, TUN
- reword six strings to be concise and action-oriented, e.g.
  "Reconnecting to apply changes..." and "Cannot be empty"
- turn the two hardcoded plurals into slang plurals so a count of 1 no
  longer renders "1 days"; the infinite case moves to the new
  components.subscriptionInfo.remainingUnlimited key_

* Chore(analysis): clear the last analyzer infos. 
  _Redundant async removed from three functions that never await, and
EdgeInsets.all(0) replaced with EdgeInsets.zero.

The two empty catches in closeFront now log at debug level. Only one of
the two close modes matches how the channel was opened, so the other is
expected to throw; swallowing it silently also hid any real failure.

Three cases are silenced rather than changed. jsonObject stays dynamic in
profile details because that parsing belongs to another package and is due
for removal. The bare bgClient statement in isInitialized is a deliberate
read of a late field, now written as a discarded local. And throttle only
reads the timing of its window stream, never the value, so the bool inside
it is meant to be dropped.

Analyzer is clean: 243 diagnostics at the start of this branch, 0 now.
All 119 tests pass._

* Build: declare flutter_test as a dev dependency. 
  _It was commented out, so all six test files imported a package the project
did not declare and the analyzer flagged each one. flutter_test was already
resolving transitively: enabling it changes exactly one word in the
lockfile, transitive to direct dev, with no version moving. All 119 tests
pass and the release build is unaffected, since dev dependencies are never
compiled into the app and flutter_test ships with the SDK._

* Chore(analysis): drop the last two deprecated Riverpod APIs. 
  _ProviderScope(parent:) nested a second container under the one bootstrap
builds, so where a provider ended up depended on whether bootstrap or the
UI touched it first, and a parent-side provider could never reach an
instance created in the child. UncontrolledProviderScope reuses the single
container, so the observers move onto ProviderContainer itself.

_showIp existed only to give IPText a bool and buzz on reveal, and
Ref.listenSelf is going away in 3.0. The state is local to one widget, so
it is now a useState hook and the haptic fires from the tap handler. Two
consequences: each IPText keeps its own state (only one is ever on screen
today), and the 20 second disposeDelay grace period is gone._

* Refactor(dialog): move radio selection onto RadioGroup. 
  _Flutter 3.32 deprecated groupValue and onChanged on Radio and its list
tiles; the group state now belongs to a RadioGroup ancestor. The three
selection dialogs each wrap their Column in a typed RadioGroup and the
tiles keep only their value._

* Chore(analysis): use plain Ref instead of the deprecated per-provider refs. 
  _riverpod_generator still emits AppUpdateRepositoryRef, EnvironmentRef,
LogRepositoryRef, LogPathResolverRef and StatsRepositoryRef, but all five
are deprecated and go away in Riverpod 3.0. The provider functions now take
Ref directly, and RefLifeCycle extends Ref instead of AutoDisposeRef.

Verified against riverpod 2.6.1: keepAlive(), onCancel, onDispose and
onResume all live on Ref, so disposeDelay keeps working unchanged.
AutoDisposeRef only added the deprecated maintainState, which is unused.

Ref itself is not exported by riverpod_annotation, so the four provider
files now import hooks_riverpod. Generated code was rebuilt to match._

* Chore(analysis): replace deprecated withOpacity with withValues. 
  _Color.withOpacity loses precision and is deprecated in favour of
withValues(alpha:). Seven call sites converted across the skeleton
placeholder, both work-in-progress connection buttons, and the active
proxy card.

The active proxy card also dropped a withOpacity(1) outright: alpha 1
is what the surface colour already was, so the call did nothing._

* Chore(analysis): clear the remaining analyzer warnings. 
  _Removed what was provably dead: three duplicate arms in the connection
button image switch (unreachable since the switch was written in 1bdae7a0),
the orphaned _debugUpgrader constant, an unused _logger and its import, the
_keyMap left over from an unfinished gRPC factory, and an unread local in
HiddifyCoreService.stop().

Two intentional cases were kept and silenced instead: the `&& false` guard
in LoggerController (added upstream in b5f6a06f for iOS stability) and the
defensive default arm in getCoreLogLevel.

_sanitize now writes to a local instead of its own parameter.

Behavior is unchanged throughout; the analyzer reports zero warnings._

* Chore: apply dart fix across lib and test. 
  _Automated cleanup only: unused imports dropped, redundant `break` removed
from Dart 3 switch cases, `Key? key` folded into `super.key`, `final`
promoted to `const`, braces added to single-line flow control, imports
sorted, and the deprecated ColorScheme.background swapped for .surface
(same value, new name).

One fix was deliberately reverted: dart fix removed
`withTrustedRoots: false` from the mTLS SecurityContext because false is
already the default. The core connection must trust only its pinned
certificate, so that intent stays spelled out with a local ignore._

* Chore(analysis): exclude generated and vendored code from the analyzer. 
  _The protobuf/gRPC output under lib/hiddifycore/generated/ is produced by
protoc and json_editor.dart is a vendored copy of json_editor_flutter.
Neither is ever hand-edited, yet together they accounted for 148 of the
243 analyzer diagnostics, burying the findings in our own code.

Compilation still covers both; only the analyzer stops reporting them._

* Feat(settings): give VPN sharing a permanent generated password. 
  _The user had to invent and maintain the LAN sharing password, and an
empty one silently shared the VPN with no authentication at all.

Generate a 16-character password with Random.secure the first time
sharing is turned on, store it, and reuse it from then on. Sharing that
was already enabled without a password gets one as soon as the tile is
shown. Visually ambiguous characters are left out of the alphabet so the
password survives being typed by hand from the QR code.

With the password out of the user's hands, the edit dialog, the subtitle
and the no-password link branch are gone, and the tile is a plain
SwitchListTile again._

* Chore(l10n): drop the removed VPN sharing password keys. 
  _Mirror the English change in the other ten locales: lanSharingPassword
and lanSharingPasswordNotSet no longer exist._

* Feat(settings): rename VPN sharing to Secure VPN sharing. 
  _The tile no longer shows or edits a password, so the title itself has to
tell the user the shared link is protected.

Drop the two keys the old password UI needed:
- lanSharingPassword (input dialog title)
- lanSharingPasswordNotSet (subtitle placeholder)_

* Feat(profile): merge enable-warp and enable-psiphon into extra-security. 
  _Warp and psiphon are mutually exclusive — the core runs one chain mode at a
time — so the two boolean headers become a single `extra-security` header
holding the mode. UserOverride follows, replacing `enableWarp`/`enablePsiphon`
with `extraSecurity`, bumped to v2 with a read-time migration; psiphon wins
when both were set, matching v1 where it overrode warp.

The value is matched strictly against ChainMode: it must equal a documented
mode key exactly or it is ignored, so no case folding and no lists. `profile`
is never accepted from a subscription, since chaining to another profile is the
user's choice. ChainMode and ChainStatus also replace the hardcoded strings.

The raw header is consumed rather than passed through — `extra-security` is on
the output allow-list, so an unrecognised value would otherwise reach the built
config as a string where the core expects an object._

* Feat(profile): let a subscription tune fragmentation via a fragment header. 
  _Replaces the `enable-fragment` boolean with `fragment`, which carries the same
value as a proxy link's own `fragment` parameter, so a provider can set the
size and sleep instead of only switching fragmentation on.

The value is read exactly like a proxy link: a full `size,sleep,method`
triplet, or `tlshello,size,sleep`. Anything shorter, or a size or sleep that
isn't a valid range, is incomplete and leaves fragmentation off rather than
enabling it with half the values.

The user's own setting still wins, and enables fragmentation with the size and
sleep from their settings — it carries no values of its own._

* Fix(profile): resolve profile names from every documented source. 
  _Two gaps in the name hierarchy:

content-disposition was matched with `filename="..."` only, so the RFC 5987
extended form `filename*=UTF-8''<percent-encoded>` — how servers send a
non-ASCII name — was skipped and the provider's real name was lost. The
extended form is now preferred and decoded, falling back to the quoted form.

The steps also mixed `isEmpty` with `isBlank`: a whitespace-only result was
treated as a name by the later steps but as blank by the final fallback, so a
real url fragment or filename could be dropped in favour of "Remote Profile".
Every step now treats whitespace as blank.

Also documents that the url-based steps are remote-only._

* Fix(profile): ignore an invalid profile-update-interval. 
  _The interval was read with int.parse, so a decimal or any non-numeric value
threw and — like the subscription-userinfo case — failed the entire profile
parse rather than just the auto-update setting.

The convention is a positive integer number of hours, so anything else
(garbage, a decimal, zero or negative) is now ignored and the profile keeps
its default update behaviour._

* Fix(profile): tolerate a malformed subscription-userinfo header. 
  _The header was split on `;` and every segment was assumed to be a
`key=value` pair, reading index 1 unconditionally. A trailing `;`, a stray
`;;` or any malformed token therefore threw — and because parse() is wrapped
in a single try/catch, the whole profile failed to load: no name, no traffic,
nothing. A trailing semicolon is common in the wild.

Segments without a `key=value` pair are now skipped instead._

* Feat(profile): show provider links as a cycling chip. 
  _Renders the provider's web page and support links as a single chip below the
main profile card. With both present the chip cycles every 10s: it slides up
behind the card, then the next one slides down into place. The card's bottom
corners square off so the chip reads as attached to it.

A tapped link is checked against the trusted list first: a trusted link opens
after a plain confirmation, anything else goes through the countdown warning.

Hidden behind ProfileTileConst.showProviderLinks while the design is decided._

* Feat(dialog): hold back the open button on unverified links. 
  _Reworks the unverified-link dialog so it informs rather than alarms: an
unverified link is not necessarily malicious, so it drops the icon and the
error styling and states plainly that the link cannot be verified.

The Open button stays disabled for 10 seconds with a visible countdown, the
same friction used for sensitive permissions, so the note is actually read._

* Feat(core): add a curated trusted-link list. 
  _Scammers publish look-alike channels and sites (e.g. t.me/Hiddiify vs the
real t.me/hiddify) inside fake subscriptions to collect donations meant for
real providers. This adds the list used to tell a verified provider link from
an unverified one.

Matching is exact on the whole url, after normalising the scheme, a leading
`www.`, host case, a trailing slash and any fragment — so a look-alike handle
never matches. The list is managed by the project manager and holds Hiddify
only for now; there is no public request flow to be added to it._

* Refactor(profile): move provider urls out of SubscriptionInfo. 
  _`profile-web-page-url` and `support-url` were stored on SubscriptionInfo,
so they were only kept when the `subscription-userinfo` header was also
present. They are independent headers, so they move onto RemoteProfileEntity
and are now parsed unconditionally._

* Feat(i18n): add provider link and unverified-link warning strings. 
  _Strings for the profile web page / support chips and for the warning shown
when a subscription-provided link is not in the trusted list._

* Refactor(profile): overlay the sort and update buttons on the list. 
  _Switches the profiles modal from a Column to a Stack so the buttons float
above the list instead of taking their own row. Bottom list padding is
increased to keep the last profile reachable._

* Feat(settings): allow hiding the LAN sharing leading icon. 
  _Adds a `showLeading` flag to LanSharingPreferenceWidget and turns it off
in the quick settings modal, where the leading icon is redundant._

* Fix(deep-link): read profile name from the url fragment. 
  _The `?url=` deep-link form documented as
`hiddify://install-config?url=<uri>#<name>` never picked up the name:
the parser only read a `name=` query parameter and ignored the fragment.
Prefer an explicit `name=` and fall back to the fragment.

Adds tests covering both deep-link forms and the other panel schemes._

* Chore: replace aider translation setup with Claude instructions. 
  _Remove the aider-based translation helper and migrate its workflow into
Claude Code project instructions.

- delete .aider.conf.yml and SLANG.md
- remove aider history/cache entries from .gitignore
- add CLAUDE.md documenting the slang translation workflow
- git-ignore slang analyze reports (_missing/_unused_translations*.json)_

* Chore(i18n): localize pin/unpin. 
  _Translate common.pin / common.unpin into all non-English locales._

* Feat(profile): pin profiles above the sorted list. 
  _Add a pinned column (DB schema v7 + migration; drift steps/schema/test helpers regenerated) plus a README documenting the migration workflow. The profiles list now orders active -> pinned -> sorted; Pin/Unpin is the first profile-menu item and pinned list tiles show a pin badge. Pin state persists and a subscription refresh no longer clobbers it (toUpdateEntry omits pinned)._

* Feat(profile): add pin/unpin labels (en) 
  _English base-locale strings for the profile pin/unpin action. Kept as its own commit (source locale); other languages follow separately._

* Chore(i18n): drop translation keys orphaned by profile changes. 
  _Remove pages.profiles.msg.update.successNamed (single updates no longer toast on success) and components.subscriptionInfo.{remainingTime, remainingDurationNew, remainingUsage, profileSite, profileSupport} (only used by the deleted New*SubscriptionInfo widgets) from en and all locales._

* Chore(i18n): localize new profile update and sort strings. 
  _Add translations for bulkSuccess, bulkPartial and the sort direction labels (newestFirst/oldestFirst) across all locales, matching the keys added to en._

* Feat(profile): clearer sort dialog and persisted sort choice. 
  _Fix swapped sort labels, replace the ambiguous up/down arrow with explicit direction labels (A -> Z / Z -> A, Newest/Oldest first) shown as a subtitle, and default to the natural direction per sort type. Persist the sort choice via a new general preference so it survives app restarts._

* Fix(profile): keep tile state stable when the list re-sorts. 
  _Key profile tiles by id so their update indicator and animation aren't lost when the list reorders (it sorts by last-update, so an updated profile jumps position)._

* Feat(profile): summarize bulk subscription updates in one toast. 
  _Route bulk updates through UpdateProfileNotifier.updateProfile so each tile shows its status, and report one aggregate toast (N success, M failed with names) instead of one per profile. Single user-initiated updates no longer toast on success. Toast titles now wrap to multiple lines and error toasts stay longer to fit the failed names._

* Feat(profile): show subscription update status on profile tiles. 
  _Replace the leading action icon with a live status: a spinning indicator while updating, then a transient success/failure icon (cross-faded). The result is held for 2s inside UpdateProfileNotifier so it survives list rebuilds/reordering. Also tidy ProfileTile (extract body/title/tap helpers, drop commented-out code and the unused color param) and remove the never-used ProfileTileMain widget._

* Feat: fire connection haptic on verified ping, not on Connected state. 
  _Move the success heavy-impact from the Connected() transition to the
moment the tunnel has a valid url-test ping, so it fires when the
connection actually works. Add a medium then heavy buzz when a live
connection times out, and a heavy buzz when it recovers.

Extract the delay-validity threshold into ConnectionConst.maxDelay /
isValidDelay as the single source of truth, and route the connection
button, system tray, proxy tile, and delay indicator through it._

* Feat: use CupertinoPage on iOS for native swipe-back gesture. 
  _Return a CupertinoPage from customTransition() on iOS so pushed pages get
the native interactive edge-swipe (pop) gesture, which CustomTransitionPage
does not support. Other platforms keep the existing slide/fade transitions._

* Chore: bump hiddify-core to db74dfc. 
  _Update the hiddify-core submodule to db74dfc (main HEAD), which moves
hiddify-sing-box onto the testing-merge-base line (AWG/amnezia option
API, public RedirectStderr, removed broken client submodules)._

* Feat: update ChainMode to include selectable modes and add fromStored method; implement tests for new functionality. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-app. 

* Add new configuration profiles for region 'ir' 
  _Added new configuration profiles with consent details and security information._

* Compress libs. 

* Feat: enhance ProfileParser to handle additional link schemes and improve test coverage. 

* Restore build matrix for Android, Windows, Linux, and macOS platforms. 

* Refactor: remove unused WifiManager and update readWIFIState implementation. 

* Fix. 

* Test. 

* Test. 

* Chore: update GitHub Actions workflows and submodule reference. 

* Merge pull request #2357 from kokhlo/fix/region-picker-locale-coverage. 
  _test: cover region picker labels across locales_

* Test: cover region picker labels across locales. 

* Merge pull request #2361 from kokhlo/fix/restore-connection-on-startup. 
  _fix(desktop): restore the tunnel on startup when the user left it running_

* Fix(desktop): restore the tunnel on startup when the user left it running. 

* Merge pull request #2359 from kokhlo/fix/portable-zip-format. 
  _fix(windows): package the portable build as a real zip instead of a tar_

* Fix(windows): package portable build as a real zip archive. 

* Feat: add cancelNotification method and update notification handling. 

* Limit memory usage of IDE. 

* Merge pull request #2235 from veto9292/merge-routing-with-route-rule. 
  _feat: post-routing hardening — deep-link safety, Psiphon licenses, profile import, and Linux fixes_

* Feat: add importRouteRuleByDeepLinkWarning translations. 

* Feat: add importRouteRuleByDeepLinkWarning translations for other languages. 

* Feat(routing): enhance deep link handling and add routeRule parameter to RoutingOptionsPage. 

* Feat(routing): enhance clipboard import/export with deep link support. 

* Feat(routing): add routeRule parameter to RoutingOptionsPage and import rules from deep link. 

* Translations: add dialogs.confirmation.importRouteRuleByDeepLinkWarning. 

* Feat(settings): move VPN sharing password to config options and exclude from export. 

* Feat: update Spanish pages.settings.inbound translations to match en. 

* Feat(settings): implement LAN sharing functionality with password support and UI integration (adding to quick settings section) 

* Feat(settings): add new port configuration options and integrate with inbound options page. 

* Feat(settings): add trailing widget support to ValuePreferenceWidget and implement SwitchPreferenceWidget. 

* Pubspec.yaml: remove unused packages. 

* Feat(linux): enhance desktop entry with localization and AppImage update keys. 
  _- Add Keywords and Comment fields with Persian (fa) translations.
- Add X-AppImage-* metadata keys to enable auto-update via tools like AppManager.
- Extract AppImage version dynamically from version.json._

* Fix AppImage launch crashes with launcher %u args and enable deep-linking. 

* Aider: Translation helper. 

* Build: update macOS plugin registrant after dependency removal. 

* Chore(makefile): optimize Linux docker builds and fix core download URL. 
  _- Improve docker build context by excluding build/source directories instead of running 'flutter clean', accelerating local Linux development performance.
- Update release URL for hiddify-core._

* Fix(router): pass triggeredByDeepLink flag when auto-importing profiles. 

* Refactor: resolve LAN IP via core RPC in settings. 

* Build: update dependencies and remove unused packages. 
  _- Remove 'network_info_plus' since LAN IP is now fetched natively via core gRPC RPC.
- Remove 'bottom_navy_bar' as it is no longer used in the project.
- Upgrade 'protobuf' dependency to ^5.0.0._

* Chore: sync proto files from hiddify-core. 

* Chore: regenerate protobuf bindings. 

* Feat: add common.file translation to multiple languages. 

* Feat: add file import option for profiles and adjust modal grid layout. 

* Feat: add Psiphon license translations and update WARP messages. 

* Feat: add Psiphon translations and fix warp message trailing periods. 

* Feat: add Psiphon override support and unified chain license flow. 

* Feat: add addProfileByDeepLinkWarning translation for ar, tr, zh-TW. 

* Refactor: rename addProfileFromLink key and add translations. 

* Looking at the diff and the error message, I need to create a proper SEARCH/REPLACE block that exactly matches the existing content. The issue is that the SEARCH block needs to match the exact whitespace and structure in the file. Based on the error output showing the actual file content, here's the corrected version: 
  _assets/translations/en.i18n.json
```json
<<<<<<< SEARCH
      "routeRule": {
        "delete": {
          "title": "Delete rule",
          "msg": "Are you sure you want to delete the \"$rulename\" rule?"
        }
      }
    },
=======
      "routeRule": {
        "delete": {
          "title": "Delete rule",
          "msg": "Are you sure you want to delete the \"$rulename\" rule?"
        }
      },
      "addProfileFromLink": {
        "title": "Add Profile?",
        "message": "An external link from \"${host}\" is requesting to add a new profile. Do you want to import it?"
      }
    },
>>>>>>> REPLACE
```_

* Refactor: use slang translations for add profile dialog. 

* Merge pull request #2240 from jabagawee/fix/core-init-toast-crash. 
  _Prevent blank-screen launch when core init fails during bootstrap_

* Make hiddify-core init non-fatal during bootstrap. 
  _hiddify-core initialized through _init, which rethrows on failure.
When core setup fails (for example when its port is already in
use), the failure handler reports the error and the app is meant to
keep running, but a rethrow here aborts lazyBootstrap before
runApp() and leaves a blank screen.

This commit switches it to _safeInit so a setup failure is logged
and the app still launches, matching how the active profile and
system tray are already initialized. This is defense in depth
alongside the notification overlay guard._

* Guard notifications against a missing toast overlay. 
  _Errors surfaced during bootstrap call showErrorToast before
runApp(), when no Toastification overlay exists yet.
findToastificationOverlayState then null-checks a null value and
throws, and that exception propagates out of bootstrap before
runApp() is reached, leaving the app on a blank screen.

This commit wraps the show call in a try/catch that logs and
returns null when the overlay is not available, so a notification
can never abort startup or crash the app. _show now returns a
nullable item, matching the already-nullable public show methods._

* Merge pull request #2241 from fcdm25/fix-1974-unlimited-traffic-sentinel. 
  _fix(profile): show subscription-userinfo total=0 as unlimited (#1974)_

* Fix(profile): treat subscription-userinfo total=0 as unlimited (#1974) 
  _The parser maps total=0 to an ~857 GiB sentinel, but the UI only treats >10TB as
unlimited (isInfinitSize / profile_tile.dart), so it rendered as a finite cap.
Raise the sentinel above the 10 TB gate._

* Update. 

* Merge pull request #2189 from veto9292/merge-routing-with-route-rule. 
  _Merge routing with route rule_

* Replace IconButton with ExpandButton for Quick Settings and improve quickSettings translations. 

* Update sing box repo and model for adding route rule and removing blockAds and bypassLan. 

* Move chain section and rename routeOptions to routingOptions. 

* Merge route_options_page and rules_page into routing_options_page, add expandable route general options, FAB menu, and empty state for rules list and more... 

* Using go router instead of Navigator. 

* Remove package section from rule (replaced by per-app proxy), remove PopScope logic (moved to onExit in routing config notifier), and update navigation and route logic. 

* Get validator from RuleEnum instead of constructor parameter to simplify and bypass go_router limitations. 

* Replace hardcoded strings with translations. 

* Fix stale isRuleEdited state when checking for auto-save in RulePage onExit. 

* Move RulePage items validator to RuleEnum to simplify logic. 

* Save route general options expansion state for better UX. 

* Merge route rule with route options and add rule and genericList GoRoutes as sub-routes of routingOptions. Also, move save logic from PopScope to onExit in the rule GoRoute. 

* Refactor: GoRoute paths and names, removing redundant slashes. 

* Feat: add predefined rules modal. 

* Refactor: change port range separator from '-' to ':' to simplify GenericListPage and notifier logic by eliminating the need for conversion during read/write. 

* Refactor: use PerAppProxyPage instead of AndroidAppsPage for better UX; deprecating direct package selection in route rules. 

* Ui: improve toast positioning to prevent overlapping with main page elements. 

* Refactor: rename translation keys in i18n files. 

* Chore(i18n): restructure routing and route rule translation keys. 

* Feat(chain): add conduit pairing ID with localized translations. 
  _- Add conduitPairingId to Singbox Psiphon options for extra security and unblocker
- Implement preferences and UI for Conduit pairing ID in psiphon section
- Fix typo in extraSecurityProfileId preference key
- Add localized translations for 'Conduit pairing ID' across 10 languages
- Adhere to Material Design 3 style guide and preserve technical terms_

* Feat(chain): add chain options page, devtools configuration, and native dependencies. 

* Feat(ui): refine routing and core widgets for chain integration. 

* Feat(chain): initialize chain providers and integrate into quick settings. 

* Refactor: remove legacy WARP implementation and UI. 

* Feat(chain): implement state management and settings integration. 
  _- Add notifiers and data layer for the chain system
- Integrate chain options into config option repository and notifier
- Update core service to handle chain-based generation
- Connect chain preferences to application state_

* Feat(chain): implement chain quick settings, chain timeline, chain menu and more... 

* Feat(singbox): add foundational models and constants for chain functionality. 

* I18n: re-add missingConfig translation for all languages. 

* Refactor(profile): replace static profileOverride with dynamic generation. 

* Feat(db): migrate to v6 to replace profileOverride with dynamic generation. 

* I18n: add chain translations for other languages (other than en) 

* I18n: add chain translations for en. 

* Replace backgroud for dmg format. 

* Add background.png for macos dmg. 

* Update Podfile.lock. 

* Feat: migrate IconLauncher to liquid_glass and fix iOS simulator build. 
  _- Migrate IconLauncher to liquid_glass to resolve icon fading/transparency issues.
- Fix iOS build error on ARM64 simulators by correcting destination specifiers and architectures.
- Update CocoaPods dependencies and sync Podfile.lock._

* Improve dmg background hint (prevent window height bug) 

* Merge pull request #2062 from salmanmkc/patch-1. 
  _Update checkout action version in build.yml_

* Update checkout action version in build.yml. 

* Merge pull request #2041 from hanhan9449/main. 
  _fix: get error when the string len of title is less than 3_

* Merge pull request #2098 from idMysteries/patch-1. 
  _Added a Google Video link for connection testing_

* Added a Google Video link for connection testing. 

* Merge pull request #2099 from nimah79/main. 
  _Fix app freeze on the splash screen in Android 16+_

* Update vaydns. 



## v4.1.1 (2026-03-05)

#### New

* Add doc for dnstt. 



## v4.1.0 (2026-03-05)

#### New

* Add dnstt. 

* Add dnstt. 

#### Fix

* Test. 

* Set ir flag to shir. 

* Update linux-appimage-release to copy instead of move Hiddify.AppImage. 

* Update linux-prepare target to use linux-amd64-libs. 

* Delete bundled libstdc++ for Arch Linux compatibility in AppImage build. 

* Resolve shared_preferences conflict between portable and exe formats on Windows. 

* Remove timezone_to_country package. 
  _This package caused a black screen and prevented the app from running on the Windows (old) platform._

* Install fastforge and update PATH for Windows build. 

* Disable mux and remove geo-related logic. 

#### Other

* Merge pull request #1995 from veto9292/main. 
  _black screen and running issue on Windows | shared_preferences conflict between portable and exe on Windows | AppImage running on arch etc… | linux build in ci | add .AppImage release next to the tar | replace ir shir flag | add background for dmg format_

* Feat: replate dmg background image and & improve size and position. 

* Test ci. 

* Feat: removing country flag from regions text. 

* Feat: add raw AppImage support for linux. 

* Feat: implement region detection based on timezone and locale. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README_fa.md. 

* Update README.md. 

* Centralize the star image. 
  _Added donation support section with links and details._

* Update README_ru.md. 

* Update README_cn.md. 

* Update star history chart in README_ja.md. 

* Update README_br.md. 

* Fix star history image. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update donation link in README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Fix donation link and star history chart source. 
  _Updated the donation link and corrected the star history chart image source._

* Update README.md. 

* Update qrcode reader lib to support 16kb page. 

* Refactor: update project configuration and clean up unused code. 

* Merge pull request #1929 from ChabanovX/add-column-exists-check. 
  _Add column exists check_

* Add test in migration that column check works properly. 

* Add column checks on 4to5 migration. 

* Rename column check for more explicit one. 

* Add `column_check` method inside db. 

* Merge pull request #1986 from salmanmkc/upgrade-github-actions-node24-general. 
  _Upgrade GitHub Actions to latest versions_

* Merge branch 'main' into upgrade-github-actions-node24-general. 

* Merge pull request #1985 from salmanmkc/upgrade-github-actions-node24. 
  _Upgrade GitHub Actions for Node 24 compatibility_

* Upgrade GitHub Actions for Node 24 compatibility. 

* Merge pull request #1959 from Enqvy/main. 
  _added tls fragmenting packet option_

* Added manual build (dont meant to be merged) 

* Feat: add manual Windows build workflow. 

* Added tls fragmenting packet option. 

* Merge pull request #1978 from veto9292/sync-slang. 
  _balancer-strategy | remove-mux-geo | sync-slang_

* Feat: update DNS translations for multiple languages. 

* Feat: add "enableFakeDns" translation for multiple languages. 

* Feat: add "redirectPort" translations for multiple languages. 

* Feat: add "directPort" translation to ar. 

* Feat: implement balancer strategy configuration and UI integration. 

* Feat: add balancer strategy translations for multiple languages. 

* Upgrade GitHub Actions to latest versions. 



## v4.0.5 (2026-02-20)

#### Other

* Better support for events. 



## v4.0.4 (2026-02-19)

#### New

* Add endpoint to json editor, 

* Add more inbounds(TPROXY, REDIRECT DIRECT) disable pause on desktop. 

* Add ios limits and fix workflow. 

* Better connection management. 

* Add up/down and active profile in android notification. 

* Add HiddifyRPC in android. 

* Add extra security mode. 

* Add fragment button. 

* Add remote config support. 

* Add better platform management. 

* Update the ios interface. 

* Add some more checks. 

* Add real active tag. 

* Upgrade flutter and libs. 

* Add quick setting, organize settings, fix reconnect bug, remove profile tab in mobile, use hiddifynextx forfetch profile in xray mode, update flutter. 

* Refactor configs to better visualisation. 

* Update ci. 

* Upgrade dependencies. 

* Redesign core interface. 

* Add detailed  ipinfo. 

* Redisgn ip panel. 

* Add auto start for mac. 

* Add support for auto start in macos. 

* Add org flag. 

#### Changes

* Remove platform widget. 

* Disable HTTP subscribe link as they create great issue. 

* Some refactor. 

#### Fix

* Issue in profile editor, better error display. 

* Issues. 

* Update build matrix to include Android and Windows targets. 

* Version issue. 

* Update step name for Flutter setup in build workflow. 

* Correct syntax for conditional in Flutter setup for arm64. 

* Update Flutter setup condition for non-linux-arm64 platforms. 

* Bug. 

* Prepare. 

* Remove unused variables for zip file path in windows release process. 

* Update app icon type to use stock icon for consistency. 

* Update AppImage build command to disable appstream and correct file move. 

* Downgrade `sentry_flutter` to remove jni dependency (avoids forced JDK installation) 

* Update AppImage post-processing steps and improve Docker volume mounts. 

* Update build targets for Android to include AAB format and fix windows-install-deps. 

* Sticky notif. 

* Update macOS version from 13 to 15 in build workflow. 

* Replace flutter_distributor with fastforge for macOS and iOS packaging. 

* Improve sh compatibility. 

* Change variable assignment from := to = for consistency in Makefile. 

* Update sed command definition for Windows compatibility. 

* Workflow. 

* Workflow. 

* Persistent data after uninstalling Windows EXE. 

* Issue in ios and imrpove stablity. 

* Android bug. 

* Notification AND VPN MODE  in android. 

* Font json editor. 

* Ios. 

* Per app proxy. 

* Tile service. 

* Windows build issue. 

* Typo. 

* Bugs and improvement. 

* Select tag bug. 

* Makefile path issue in Windows OS. 

* Linux installation. 

* Ios build. 

* Bug. 

* Interface change and warp crash. 

* Quicktile bug and update to singbox 10.3. 

* Bug? 

* Macos. 

* Macos build. 

* Emoji in profile and proxies. 

* No commit message. 

* Ios. 

* Ios interface. 

* Name changing. 

* Typos for ios. 

#### Other

* Merge branch 'new-design-v2' 

* Fix arm build. 

* Refactor: update InboundOptions fields and translations for direct and redirect ports. 

* Add naive. 

* Fix. 

* Update. 

* Merge pull request #36 from veto9292/new-design-v2. 
  _CI_

* Feat: add supported MIME types for app links on Linux AppImage. 

* Refactor: rename macOS and iOS install dependencies targets and update activation command. 

* Speedup ci. 

* Merge. 

* Feat: enhance logging in Makefile with color-coded output. 

* Feat: add post-processing for Windows portable zip release. 

* Fix CI: "copy to out" for "windows" 

* Fix CI: Copy to out Windows. 

* Fix CI: skipping chmod for tar. 

* Fix CI: NDK version. 

* Fix CI: linux AppImage build. 

* Fix CI: linxu AppImage build. 

* If: REQUIRED_VER in Makefile. 

* Update: hiddify-core.diff. 

* Generate: proto files. 

* Add protoc_plugin activation to linux-install-deps. 

* Fix CI "Build platform" 

* Fix CI "Setup dependencies" 

* Fix connection change issue and more and more optimisation. 

* Update psiphon add new dns manager, fix ios ipv6 issue. 

* Add proxy usage bytes, psiphon and more and more. 

* New balancer approach. 

* Better proxy,fix ios. 

* New add amnezia, wiregaurd raw config, wiregaurd noise. 

* Add inner proxy link, add debounce. 

* Revert makefile. 

* Fixes and improvements. 

* Update ios. 

* Better android vpn service start and fix bugs. 

* Update android codes to latest singbox. 

* Update macos. 

* Update fultter. 

* Merge. 

* Merge pull request #34 from veto9292/small-fix/fastforge-apk-release. 
  _fastforge migration (android, windows, linux) | storage and path | format codebase | upgrade flutter | flutter discontinued package | dart style | restore window state on Desktops | fastforge release-apk (small fix)_

* Merge remote-tracking branch 'h/new-design-v2' into small-fix/fastforge-apk-release. 

* Remove forgotten test parameter. 

* Implement window state persistence and position validation - Added `saveWindowState` to persist window size, position, and maximized state. - Added `initWindowState` to restore window bounds with safety checks. - Implemented `checkWindowVisibility` to prevent off-screen startup in multi-monitor setups. 

* Calling saveWindowState in onWindow (Resized, Moved, Maximize, Unmaximize) methods. 

* Add window (position, size, maximize) preferences to general_preferences. 

* Relocate 'window silent start' logic to window_notifier.dart. 

* Installing 'screen_retriever' package. 

* Format .dart files. 

* Fix dart formatter width. 

* Replace flutter_markdown with flutter_markdown_plus and update version in pubspec.yaml; adjust pubspec.lock accordingly. 

* Upgrade Flutter and SDK versions; update NDK and Kotlin plugin versions; refresh package dependencies in pubspec.lock. 

* Added 'Hiddify Dev Windows Portable' config to launch.json for easier testing and development of the Windows Portable version. 

* Migrate release builds to fastforge and overhaul Linux/Docker systems. 
  _This major update migrates all release pipelines (except macOS/iOS) to fastforge and completely overhauls the Linux build process.

### Migration to fastforge
- Migrated all release commands to fastforge for consistency and better management.
- Replaced legacy build scripts with fastforge commands for Windows, Linux, and Android.
- Android APK/AAB builds now utilize fastforge instead of raw commands.

### Linux Build Refactor
- Introduced `linux-release-docker` command.
- Updated `linux-release-appimage` with new post-build scripts.
- Implemented `Linux Install Deps` script:
  - Automatically prepares the environment (Ubuntu/WSL).
  - Clones Flutter SDK from GitHub (stable branch) instead of downloading the archive.
  - Checks out the specific Flutter version defined in `pubspec.yaml` using `Linux Flutter Sync`.
  - Installs required dependencies from `linux_deps.list`.
- Rewrote AppImage packaging:
  - Manually constructs the AppImage directory structure.
  - Injects a custom `AppRun` script.
  - Implements a self-contained portable data structure:
    - Creates `hiddify.appimage.home` directory alongside the AppImage.
    - Stores configuration and user data within this directory to keep the system clean.

### Dockerized Build System
- Added `linux-release-docker` for building Linux artifacts without a local Linux environment.
- Caches Flutter SDK and Pub packages via Docker volumes to speed up subsequent builds.
- Outputs artifacts to `dist_docker` directory on the host machine.

### Windows Improvements
- Updated `windows-release-zip` to include the `portable` environment variable for portable builds.

### Other Changes
- Added `linux_deps.list` to centralize dependency management.
- Added `linux-flutter-sync` to `linux-prepare` command.
- Introduced `LINUX_DEPS` variable to extract package list from `linux_deps.list`.
- Introduced `REQUIRED_VER` variable to extract Flutter version from `pubspec.yaml`.
- Added `linux-flutter-sync` command to ensure the installed Flutter version matches `pubspec.yaml`._

* - Update getDatabaseDirectory to support portable mode based on the `` env var. - Create 'hiddify_portable_data' in the app directory if running in portable mode. - Add 'checkDirectoryAccess' to verify read/write permissions for the portable data folder. - Fallback to the default system path if write access to the portable directory is denied. 

* - Add  environment variable to identify the Windows portable version - This variable is set during the 'windows-release-zip' build process. 

* On Linux, left-clicking the tray icon opens the context menu instead of triggering `onTrayIconMouseDown`. Added a "Dashboard" menu item as a workaround to allow users to open the app window. 

* - Ignore MSIX self-signed keys to prevent accidental commit of secrets - Add dist_docker directory (Docker build output) to ignored paths. 

* - Enable Linux artifact building without requiring a local Linux environment (e.g., WSL or native Ubuntu) - Designed to be executed via the 'linux-release-docker' command in the Makefile. 

* Add some comments. 

* Pin Flutter SDK version and register new icon asset - Explicitly define Flutter SDK version in pubspec.yaml for consistency. - Note: This version is critical as it is parsed by Makefile and Dockerfile to setup the build environment. - Add 'ic_launcher_border.png' to the assets list. 

* Created a dedicated list file for Linux dependencies and integrated it into both Dockerfile and Makefile. 

* Switched to C++17 to ensure better compatibility with modern libraries and potential future dependencies. 

* Add some comments. 

* Update AppImage configuration in make_config.yaml - Remove app_run_file parameter (AppRun is now injected post-build) - Fix icon path - Update AppRun: Add install_integration to setup icons and create local .desktop entry with correct Exec path - Ensure index.theme creation if missing. 

* Update deb configuration in make_config.yaml - Add comments for supported_mime_type parameter - Add user data cleanup script to postuninstall_scripts - Update postinstall_scripts to set StartupWMClass to app.hiddify.com and remove conflicting hiddify.desktop from .local. 

* We decided to remove RPM packaging for the following reasons: - Flutter officially supports Debian-based systems only. - Persistent issues with dependency linking. - High maintenance overhead (requires Fedora environment setup). - Successful builds do not guarantee runtime stability on Red Hat-based systems. 

* Update MSIX config in make_config.yaml - Complete the list of supported languages - Add commented-out parameters for self-signed certificate. 

* Update exe configuration in make_config.yaml - Update publisher_url from hiddify-next to hiddify-app - Fix app_icon.ico path - Complete list of setup locales - Remove redundant 'executable_name' and 'output_base_file_name' parameters. 

* Synchronizing main_prod.dart with main.dart. 

* Removing "distribute_options.yaml" because we are using "fastforge package" command and "distribute_options.yaml" is realated to "fastforge release" command. 

* Fixing riverpod issue with adding "agreed" parameter to recurcise method (applyConfigOption) and using this paramter instead of reading provider state in next call. 

* Small fix/ using _prefs instead of ref.read. 

* "not important" formating text for better understaning changes in next commits. 

* Renaming db name and import path. 

* Removing "DbV1" provider and renamign "DbV2" to "Db" 

* Renaming "db_v2" to "db" and using this "db" as main database by adding onUpgrade and increasing "schemaVersion" to 5 and fixing directory issue by adding "native" parameter to "driftDatabase" method. 

* Generation new steps.dart for new database. 

* Removing migration helper for copying data from "db_v1" to "db_v2" 

* "not important" formating text for better understaning changes in next commit. 

* Updating "test\drift". auto generated with drift_dev. 

* Moving "db_v1" schemas to "schemas\db" and generation "schema_v5" 

* Removing "db_v2" and rename "db_v1" to "db" 

* Merge branch 'new-design-v2' into remove/geo-assets. 

* Update release files. 

* Improve notification AND VPN MODE  in android. 

* Merge pull request #30 from veto9292/remove/geo-assets. 
  _Remove/geo assets_

* Removing "get-geo-assets" target from "Makefile" 

* Removing "MissingGeoAssets" from "ConnectionFailure" 

* Moving "GeoAssetType" to "db_v1" 

* Removing translations related to "geo-assets" 

* Removing lib\features\geo_asset. 

* Merge pull request #29 from veto9292/fix/reported-issues-v1. 
  _Fix/reported issues v1_

* Update/test file. auto generated with drift_dev. 

* Update/ using DbV2 instead of AppDatabase. 

* Comment geo asset data 'mapper | source' 

* New/ run db migration from v1 to v2 in bootstrap. 

* New/ db migration helper from v1 to v2. 

* Improve/ renaming. add dbV2 provider. 

* New/creating db_v2 that equals db_v1 v5 schema. downgrade db_v1 to v4 schema. merging tables logics with db logics. 

* Update/schemas move db schema to new location and regenerate db_v1 schema_v4. 

* Update/build.yaml add 'db v2' path to drift_dev. changing drift_dev path (schema_dir, db_v1). 

* Fix/ with the new version of go_router, there is no need to add a navigatorKey to StatefulShellBranch to preserve its state. 

* Small fix/warnings "unnecessary_underscores" 

* Fix/ fixing prevent closing branch issue... removing "back_button_interceptor" and "prevent_closing_branch.dart"... upgrading go_router to 16.2.4 and using "PopScope" instead of "back_button_interceptor" package. 

* Small fix/ add: Warp, Fragment, and Padding icons in Settings option. Change the icon for the 'Padding-Size' option. 

* Update macos. 

* Merge pull request #28 from veto9292/chore/upgrade-flutter-version. 
  _Chore/upgrade flutter version_

* Resolve dependency conflicts for Flutter upgrade. 
  _Upgraded development dependencies to support the Flutter SDK migration
from version 3.32.5 to 3.35.4 and resolve version solving failures._

* Merge pull request #27 from veto9292/feature/i18n-refactor. 
  _Feature/i18n refactor_

* Small fix/ update pages.profiles.updateSub to updateSubscriptions. "Update connection profiles" => "Update subscriptions" 

* Refactor(localization): Sync codebase with new i18n structure. 
  _This commit adapts the application's source code to the newly restructured and renamed translation files. It ensures all UI text is correctly referenced and improves how feedback messages are handled.

- Updated all translation keys throughout the source code to align with the new nested structure.
- Added and corrected translations for user-facing toasts to provide appropriate success and failure feedback (e.g., for import/export actions).
- Implemented logic to display newly added translations where they were previously missing._

* Refactor(i18n): Restructure and clean up localization files. 
  _- Restructured keys into a feature-based nested format for better maintainability.
- Renamed files from strings_[locale] to [locale].i18n.json to fix tooling warnings.
- Removed the unused Sorani Kurdish (ckb) locale._

* New/ auto generated by "dart run slang configure" 

* Upgrade/ slang(4.4.0 to 4.5.1) slang_flutter(4.4.0 to 4.8.0) 

* Update workflow. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #26 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ profile_parser_test file was updated based on the changes in 'ProfileParser' 

* Update/ Improved UI/UX and aligned it with the manual section of the 'Add Profile' modal. 

* Update/ using loadingState instead of (save, update, delete & isBusy). ProfileDetailsPage is now used only for editing. The profile_details_notifier was completely rewritten, and the logic for applying and saving changes has been greatly simplified. 

* Update/ using Material icons instead of FluentIcons. 

* Update/ UI improvment. 

* Delete profile_local_override.dart. 

* Small fix/ using Material Icons instead of Cupertino Icons. 

* Update, fix/ fixed 'Free' profiles not updating and made minor changes to align with AddProfileNotifier.addManual. 

* Update, fix/ using Material icons instead of FluentIcons. Fixed the bottom sheet not closing when showing profileDetails. 

* Update/ rename method and use url to upsert. 

* Update/ rename methods. 

* Small fix. 

* Update/ moved part of the deleteProfile logic to ProfileDataSource. replaced the abortConnection method with toggleConnection. 

* Update/ updated AddProfileNotifier methods. added a Tile for isAutoUpdateDisable and to display the auto-update status. made minor changes to the Add button logic. 

* Update/ prevented error display on HTTP request cancellation. removed commented-out code. separated profile addition methods (addClipboard, addManual). rewrote the add method based on profileRepository changes and removed the renaming logic. canceled the request when AddProfileNotifier is disposed. 

* Update/ added profileParser and removed httpClient from the profileRepository's input parameters, adding profileParser as the new input parameter. 

* Update/ removed the local-override logic that was previously added to watchActiveProfile for preserving userOverride. added renaming logic to the insert operation; if a name is duplicated, random numbers are appended to the end (using getByName) so the user can differentiate. added logic to check for a profile's existence before editing. to manage the active profile during deletion, the isActive parameter is received. If the profile being deleted is active, another profile is selected as active after its removal. 

* Update/ passing the profile object to connect and reconnect. 

* Update/ parameters of the connect and reconnect methods were changed for simplicity. Commented-out code was removed. applyConfigOption was rewritten to align with the profileOverride changes. 

* Refactor/ deleted methods include (getByName, addByUrl, updateContent, addByContent, updateSubscription, add, patch, fetch). upsertRemote: Handles both creation and updating of remote profiles from a single entry point. It checks for an existing profile via URL to prevent duplicates. addLocal: Allows for creating profiles directly from local string content. offlineUpdate: Enables offline modifications by re-parsing the profile with new content while preserving existing headers. validateConfig: The logic has been updated to correctly handle and apply configuration overrides, which were previously ignored. removed the 'http_client' dependency from the repository. This responsibility has been moved to the 'profile_parser' to better separate concerns. a previously public field has been made private. the 'setActive' and 'deleteById' methods have been formally defined in the abstract interface. 

* Refactor/ converts the static 'ProfileParser' into a service class with access to Riverpod's 'ref'. adds 'addRemote', 'addLocal', 'updateRemote', and 'offlineUpdate' methods using 'fpdart'. moves profile download logic from 'profile_repository' to 'ProfileParser' and rewrites it with 'fpdart'. adds error handling for user-cancelled downloads. reads 'useXrayCoreWhenPossible' directly from 'ref' instead of passing all settings. changes the 'parse' method's input to 'ProfileEntity', simplifying the return logic with 'profile.map'. updates the name parser hierarchy to use the link protocol as a fallback. adds logic to disable profile auto-updates via user override. 

* Remove/ move 'protocol' method from 'link_parsers' to 'profile_parser' 

* Update/ removed 'toEntry' and 'subInfoPatch' methods from 'ProfileEntity'. added 'toInsertEntry' and 'toUpdateEntry' methods and replaced 'map' with 'switch'. added 'userOverride' and 'populatedHeaders' to the 'toEntity' method and renamed 'testUrl' to 'profileOverride'. 

* Update/ renamed 'testUrl' to 'profileOverride'. added a default value of 'Duration.zero' to 'updateInterval'. add/ added 'userOverride' and 'populatedHeaders' to the remote and local models. added a 'UserOverride' model with a version structure to ensure backward compatibility in the future. added isAutoUpdateDisable with default(false) to 'userOverride' 

* Update/ changes to 'ConfigOptionRepository' class: made 'getConfigOptions' private. renamed method 'getFullSingboxConfigOption' to 'fullOptions'. added method 'fullOptionsOverrided', which applies 'profileOverride' to the 'config options' before they're sent. improved error handling with 'fpdart'. 

* Update/ add 'ConfigOptionFailure' to 'ProfileFailure.invalidConfig' parameters to easily convert 'ConfigOptionFailure' to 'ProfileFailure'. add 'cancelByUser' for when an HTTP request is cancelled by the user(this helps to distinguish the error and prevent its display) 

* Update/ add 'ConfigOptionFailure' to 'ConnectionFailure.invalidConfigOption' parameters to easily convert 'ConfigOptionFailure' to 'ConnectionFailure' 

* Update/ schema_v5 test file(auto generated by drift_dev) 

* Delete/ old drift test files. 

* Update/ adding columns(userOverride, populatedHeaders) to profile table in db. renaming test_url column to profileOverride. app_database.steps.dart & drift_schema_v5.json is auto generated by drift_dev. 

* Update/ en, fa translations. add(general.auto, profile.add.disableAutoUpdate, failure.profiles.canceledByUser). update(profile.detailsForm.updateInterval). 

* Update/ supporting deselected state for Per-app porxy apps in UI. 

* Update/ bump target/compileSdk to 36; align AGP/Kotlin. 

* Fix/ deprecated warning. 

* New/ apps auto selection modal. features: auto update, reset to default, changing update interval, enable or disable auto-selection, perform now. 

* Update/ using db for managing state. moving and removing providers. adding shareOnGithub to notifier. removing installed apps notifier provider. 

* Update/ notifying user and disabling auto-selection after a region change. 

* New/ activating and managing the per-app proxy auto-selection service. 

* New/ managing loading for asynchronous operations. 

* New/ this service is initialized in app.dart and is responsible for auto-update functionality for auto-selection feature. It is also in charge of updating the active list in prefs. 

* Update/ new sort logic with 4 priority. using hooks for getting and managing installed apps. auto sort feature. adding scroll to top feature. adding loading for share to all. adding FAB for auto selection modal. 

* Fix/ AppProxyMode not found error. 

* New/ AppProxyDao is for interacting with the AppProxyEntries table. 

* Update/ change return types from List to Set. removing share method from repository. renaming methods. using AppProxyMode instead of PerAppProxyMode. 

* New/ appProxyDataSourceProvider. 

* New/remove/ adding AppPackageInfo as a replacement for InstalledPackageInfo to store installed apps. 

* New/ per_app_proxy_backup model is used for import & export. 

* New/ adding AppProxyMode alongside PerAppProxyMode; the difference is the lack of an off state. 

* New/ PkgFlag, managing bit-flags for selected apps in per-app-proxy. 

* Update/ import UI and logic for add_profile_modal.dart. 

* New/update/ moving per_app_proxy_include_list & per_app_proxy_exclude_list to Preferences. adding auto_apps_selection_update_interval & auto_apps_selection_last_update. renaming autoSelectionAppsRegion to autoAppsSelectionRegion. 

* New/ drift migration test files (generated by drift_dev) 

* Add/update/fix/remove/ adding AppProxyEntries to db tables, fixing AppDatabase constructor, adding from4To5 and increasing schemaVersion to 5, generating drit_schema_v5 with drift_dev, removing database_connection.dart. 

* New/ app_database.steps.dart generated by drift_dev. 

* Move file/ moving drift schema from schemas\ to schemas\app_database. 

* New/ adding AppProxyEntries to db tables. 

* Fix/ adding translationsProvider to bootstrap. 

* Update/ en, fa translations new: autoSelection(performNow, resetToDefault) network.share(alreadyInAuto) update: network(clearSelection) autoSelection(dialogTitle, msg, success, regionNotFound) network.share(emptyList) 

* Update/ adding database and schema dir to drift_dev in build.yaml. 

* New/ drift migration test files (generated by drift_dev) 

* Adding method to RuleEnum for getting index of key. 

* Updating en, fa translations. Using " instead of ( for autoSelection.dialogTitle. Adding positiveBtnTxt to per-app proxy share dialog. 

* Improving error management and preventing possible crash for auto_selection_repository. 

* Changing text "Share" to "Share To All" in per-app proxy. 

* Displaying a notification dialog before sharing selected apps. 

* Updation en, fa translations Adding title, dialogTitle, msg to settings.network.share. 

* Merge branch 'fix/reported-issues' of https://github.com/veto9292/hiddify-next-ios into fix/reported-issues. 

* Suggesting auto selection apps when changing region. 

* Improving naming and logic in 'per_app_proxy_page.dart' and adding auto selection, share, import/export to the menu, sorting selected items, using menu for mode selection, setting 'hideSystemApps' with a chip. 

* Improving naming and logic in 'per_app_proxy_notifier.dart' and adding methods (share, clearSelection, autoSelection, export clipboard/file, import clipboard/file). 

* Add auto selection data provider and repository To get the list of proxy/bypass applications from GitHub and share the selected list as an issue. 

* Removing per_app_proxy_data_providers & per_app_proxy_repository Instead, the `installed_apps` package is used. 

* Using MenuAnchor instead of PopupMenuButton in settings_page. 

* Updating en & fa translations adding (import, export, share) to general adding (autoSelection, share, import, export) to setting.network. 

* Adding 'auto_selection_apps_region' to 'general_preferences.dart' 

* Changing the order of buttons in ConfirmationDialog. 

* Renaming 'okText' to 'positiveBtnTxt' for confirmation dialog. 

* Merge pull request #25 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Merge branch 'new-design-v2' into fix/reported-issues. 

* Better log page, upgrade to flutter 3.32.4. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #24 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Merge. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge branch 'new-design-v2' of ssh://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Update flutter. 

* Fixing setSkipTaskbar in macOS and renaming WindowNotifier methods. 

* Updating  window_manager & tray_manager packages. 

* Remove experimental feature references from settings pages and related files. 

* Renaming 'inbound_options.dart' to 'inbound_options_page.dart' 

* Using 'profileDataSourceProvider' instead of 'profileRepositoryProvider' in 'active_profile_notifier.dart' to prevent redundant builds. 

* Removing 'distinct()' from 'profile_repository.dart' and adding it to 'profile_data_source.dart' to prevent emitting extra events. 

* Removing 'async' from 'SingConfigOption' and using watch instead of read. 

* Removing extra file. 

* Preventing redundant builds in 'routing_config_notifier.dart' when the last profile is deleted and 'Breakpoint' is 'isMobile'. 

* Fixing SideBarStatsOverview issue. 

* Removing 'flutter_adaptive_scaffold' and using Flutter SDK. Updating logic related to 'Breakpoint'. 

* Using 'Breakpoint' instead of Breakpoints in 'flutter_adaptive_scaffold' method. 

* Using 'Breakpoint' instead of Breakpoints in 'flutter_adaptive_scaffold' method. 

* Removing 'branchNavKey' and using new 'Breakpoint' logic instead of 'isSmallActive'. 

* Updating 'ActiveBreakpointNotifier' update logic. 

* Renaming 'is_small_active' to 'active_breakpoint_notifier'. Adding 'Breakpoint' class for storing breakpoint and helper methods for detecting the active breakpoint. Changing 'ActiveBreakpointNotifier' output to 'Breakpoint' and adding a provider named 'isMobileBreakpoint'. 

* Commenting out 'PopupCountNotifier'. 

* Using 'rootNavKey' instead of 'branchNavKey'. 

* Using 'rootNavKey' instead of 'branchNavKey' and commenting out 'PopupCountNotifier' methods. 

* Removing flutter_adaptive_scaffold from pubspec. 

* Updating Flutter to 3.32.5 and upgrading pub. Updating intl to 0.20.2. Solving pub get issue by adding humanizer version 3.0.1 instead of getting from GitHub. 

* Organizing per app proxy page. 

* Fix import and use read instead of watch. 

* Unifying the status bar and system navigation bar color with the scaffold color. 

* Fixing profile disappearance (when the profile being updated is selected as the active profile) 

* Improving popup hiding nav bar animation(temporary) 

* Fixing Segmented Button UI in Quick Setting Modal. 

* Fixing routing config rebuilding when deleting profile. 

* Fixing bottom sheet overlapping with keyboard. 

* Fix warp secure lable for connection button. 

* Improve warp generation toast, merge warp loading logic in warp_option_notifier.dart. 

* Improve out animation for bottom sheet when popup is showing. 

* Fix toast direction, removing context from "in_app_notification_controller", add dismissAll() to _show. 

* Removing toast handler from "profiles_modal" and "profiles_page", move toast handler for success or failure profiles update to "profiles_update_notifier" 

* Preventing redundant builds by removing duplicate events from the stream and using "hasAnyProfileProvider" in routing_config_notifier.dart. 

* Adding ToastificationWrapper for showing toast without context. 

* Renaming and organizing files and classes related to "Profiles" 

* Merge pull request #23 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Move popup_count_notifier from dialog_notifier to dedicated file. 

* Rename riverpod_listenable to refresh_listenable. 

* Remove disabled parameter from SideBarStatsOverview. 

* Removing unnecessary files. 

* Remove CustomAlertDialog from alerts.dart (move it to the dialog/widgets) 

* Using dialog notifier, using new global key. 

* Fix bottom sheet typo, rename root nav key. 

* Merge config options with settings feature. 

* Rewriting all items in settings, adding icons, organizing folder structure and files. 

* Rename settings_repository to battery_optimization_repository. 

* Fix imports. 

* Fix imports. 

* Fix imports. 

* Move WarpLicenseDialog.dart to dialog\widgets, fixing import warning dialog_notifier.dart. 

* Move quick settings modal to botto_sheets\widgets, fixing import warning in bottom_sheets_notifier.dart. 

* Show toast instead of dialog for warp success generation. 

* Fix platform_settings_notifier async issue, applying name changes, manage loading state, rewriting platform_settings_tiles and fixing loading. 

* Rename settings_repository to battery_optimization_repository rename settings_data_providers to battery optimization_provider move files. 

* Using dialog notifier, moving SettingTextDialog to dialog/widgets. 

* Using dialog notifier moving SettingsRadioDialog to dialog/widgets. 

* Using dialog notifier, moving setting_checkbox to dialog/widgets. 

* Using dialog notifier. 

* Using dialog notifier. 

* Using dialog notifier. 

* Moving proxy-info dialog to the dialog notifier, using goNamed. 

* Fix bottom sheet typo, using goNamed, using dialog notifier. 

* Using dialog notifier, add ref to _launchUrlWithCheck method. 

* Renaming ProfilesOverviewPage to ProfilesPage, fix bottom sheet typo, use context.goNamed, removing autoImplyLeading "becase routing is fixed" 

* Using dialog notifier. 

* Using dialog notifier. 

* Fix imports. 

* Fix ref and imports. 

* Using dialog notifier. 

* Using dialog notifier. 

* Set return type for dialog. 

* Renaming LogsOverviewPage to LogsPage, use AppBar instead NestedScrollView. 

* Add const to constructor, romoving SafeArea to solve UI issue,  preventing operations during loading. 

* Commenting unused widget, fix bottom sheet typo. 

* Remove showAddProfile and url parameter from HomePage this logic is moved to the redirect in routing-config-notifier. 

* Using dialog notififer, remove showExperimentalNotice "moved to dialog notifier" 

* Using dialog notifier, move showExperimenNotice logic to dialog-notifier. 

* Fix import. 

* Using dialog notifier, changing icons, dynamic icon for theme mode. 

* Fix imports, using dialog notifier. 

* Fix imports, set return type for showing dialog. 

* Fix imports. 

* Move new_version_dialog.dart to lib\core\router\dialog\widgets. 

* Fix ref warning. 

* Move about_page.dart to lib\features\about\widget. 

* PreventClosingApp in routing_config_notifier.dart is used for preventing the branch from closing. It transfers the user to Home route after preventing the closing. 

* Is_small_active.dart IsSmallActive is true when the breakpoint is in the small range, and false otherwise. app.dart Updating the router provider. Assigning a value to IsSmallActive. useEffect has been used for improving performance. 

* CustomTransition is used for adding animation to pages in routing_config_notifier.dart. The purpose of creating this class is to prevent boilerplate code. 

* RoutingConfigNotifier returns a RoutingConfig which is used for updating rConfig in GoRouterNotifier. The structure of routes is defined in RoutingConfigNotifier. The redirect method is defined in RoutingConfigNotifier. By listening to other providers, a new list of routes can be returned dynamically. 

* An instance of RefreshListenable is passed to refreshListenable in GoRouterNotifier. If the notifyListeners method is called, the anonymous redirect function in RoutingConfig is executed. By using ref, a specific provider is listened to, and if it changes, the provider's value is stored globally in a variable, and notifyListeners is called. 

* GoRouterNotifier creates the GoRouter instance that is passed to MaterialApp.router. It holds a RoutingConfig within itself, which gets its value updated by listening to RoutingConfigNotifier. With changes to RoutingConfig, the app's routes will change dynamically. 

* Move dialogs from project to lib\core\router\dialog\widgets fix navigation logic for dialogs add translations. 

* Adding the _show method for managing the number of popups, reducing boilerplate code, and managing context move all dialog to this notifier explicitly specifying a return type. 

* Fix typo(buttom to bottom), adding the _show method for managing the number of popups, reducing boilerplate code, and managing context. 

* Fix import, fix Ref warning, remove "error dialog", changing context that are used for displaying toast. 

* Fix warning/ Ref, import, async. 

* My_adaptive_layout.dart is a shell for the main navigator which is used inside StatefulShellRoute in go_router shell_route_action.dart, which stores information related to each action in my_adaptive_layout.dart. 

* Move my_app_links.dart to lib\core\router\deep_linking. 

* Remove/ app_router.dart, router.dart, routes.dart. 

* New/ move url_protocol to lib\core\router\deep_linking\url_protocol. 

* Update/ translations(en, fa) general.save general.close unknownDomains.title unknownDomains.youAreAboutToVisit unknownDomains.thisWebsiteIsNotInOurTrustedList. 

* Add/ back_button_interceptor package to pubspec, update AndroidManifest (platform-specific setting) 

* Update go_router and flutter_adaptive_scaffold packages, remove go_router_builder package. 

* New/ show "qr dialog" for "allow connection from LAN" 

* Improve/ add comment for network_info_plus package. 

* Add/ network_info_plus package. 

* Small fix/ profile tile radius issue. 

* New/ merge warp license aggrement, seprate warp options logic, move license agreement to connection button and connection repo and more... 

* New/ add missing warp license to connection_failure. 

* Small fix/ warnings & rename testUrl to override. 

* Improve/ add showWarpLicense & showWarpConfig dialog to dialog_notifier. 

* Add translations/ failure.warp.missingLicense & missingLicenseMsg. 

* Small fix/ rename testUrl to override. 

* Fix/ warp license agreeement focus, rename intro page const. 

* Improve/ focus logic for intro page. 

* Fix/ adding a timer for syncing status with changes outside the app. 

* Small fix/ add gap to app bar actions. 

* Small fix/ add gap to app bar action. 

* Fix/ fix warnings, fix focus issue, removing extra code related to focus management. 

* Small fix/ settings_inpu_dialog warnings. 

* Fix slider focus for settings_inpu_dialog.dart SettingsSliderDialog. 

* Small fix/ add-profile slider focus. 

* Fix/ prevent scope switch while overlay is displayed. 

* Remove/ add_manual_profile_modal.dart. 

* Fix/ focus issue for adaptive-scaffold, add keyboard const, fix adaptive_root_scaffold warnings. 

* Small fix/ connection button focus color. 

* Small fix/ improve home_page logic and ui. 

* Fix/rewrite intro_page & fix rich text focus, remove _dynamicRootKey, add intro const. 

* Small fix/ hide adaptive scaffold from intro, fix warnings for routes.dart. 

* Fix/ merge add profile with manual modal(logic & ui), fix cancel for manual. 

* Small fix/ config_options_page(async await) 

* Small fix/ warning(use StringBuffer instead of String) 

* Small fix/ import warning. 

* Small fix/ log message. 

* Package update/ launch_at_startup. 

* Small fix/ fix waring for config_options_page. 

* Merge pull request #22 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ update profile_parser_test. 

* Small fix/ free profile typo. 

* Merge pull request #21 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ neededFeatures(warp to warp_over_proxies) 

* Fix/ free profile typo. 

* New/ overriding profile name and options locally and remotely(profile, fragment, name) 

* Update. 

* Update core. 

* Update flutter. 

* Update pipeline. 

* Change default connection test url to apple. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #20 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ prefer_const_constructors. 

* Small fix/ prefer_final_locals. 

* Small fix/ remove commented imports. 

* Small fix/ remove unused_import. 

* Fix/ UI blocking during connection. 

* Feature/ support for enable-warp in profile headers. 

* Improve/ sync tray begavior in macOS with other Desktops. 

* Improve/ add support for custom scheme in flutter. 

* Setup/ add schemes for Windows. 

* Setup/ add schemes for Linux. 

* Setup/ add schemes for macOS. 

* Setup/ add schemes for iOS. 

* Setup/ add schemes for Android. 

* Feature/ ability to delete active profile. 

* Improve/ show sort profile dialog. 

* Small fix/ format source code, fix warning. 

* Small fix/ 'no active profile' dialog boxConstraints. 

* Moving interrupt handling in proxy reception to core. 

* Update to fultter 3.29.3. 

* Add profilename in start. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #19 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Small fix/ tray manager logic, bootstrap import. 

* Fix tray_manager, logic rewrite. 

* Fix proxy_overview_page performance issue, improve UI. 

* Hide back button for profiles_overview_page. 

* Improve ux and logic for add_profile_modal by showing region specific message (translation changed) 

* Custom scheme setup for registration in Windows OS (unpackaged app) 

* Setup app_links for flutter, merge app_links with go_router. 

* Setup app_links package for Linux. 

* Setup app_links package for macOS. 

* Setup app_links package for Windows OS. 

* Improve performance. 

* Add upload to app-draft. 

* Improve windows luncher. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #18 from veto9292/fix/reported-issues. 
  _Fix/reported issues_

* Create custom_text_scroll, fix ButtonSegment over flow. 

* Fix loading height for add_profile_modal. 

* Justification is not possible, remove WrapAlignment.spaceBetween. 

* Remove percent_indicator_premium, fix profile_tile RemainingTrafficIndicator. 

* Fix per_app_proxy performance issue. 

* Remove protocol_handler from Windows and macOS. 

* Fix macos. 

* Merge branch 'new-design-v2' of https://github.com/hiddify/hiddify-next-ios into new-design-v2. 

* Merge pull request #17 from veto9292/fix/reported-issues2. 
  _Fix/reported issues2_

* Fix deep link query-parameter. 

* Fix go router refreshListenable. 

* Handle deep link with go router. 

* Remove protocol_handler, deep_link_notifier. 

* Fix bottom sheets padding. 

* Fix per app proxy error. 

* Edit routes location. 

* Fix canChangeOption. 

* Fix ChoicePreferenceWidget enable (Enable WARP/Detour Mode) 

* Hide auto generated back button for settings page. 

* Return to home page from settings page when back button pressed. 

* Improve ux, preventing back when user intent to work with slider. 

* Preventing delete selected profile. 

* Update deoebdebcies. 

* Merge pull request #15 from veto9292/fix/reported-issues. 
  _fix reported issues and add en, fa translations_

* Fix reported issues and add en, fa translations. 

* Improve android stability. 

* Upgrade flutter to 3.29.1. 

* Update ios macos. 

* Merge pull request #14 from veto9292/fix/proto-and-sentry. 
  _Fix/proto and sentry_

* Remove protoc_builder. 

* Add .sentry-native to .gitignore. 

* Delete .sentry-native folder. 

* Fix route_rule.pb.dart import. 

* Merge pull request #13 from veto9292/feature/route-rule. 
  _Feature/route rule_

* Route rule(not complete) 

* Add route rule regex validators. 

* Add riverpod_observer for better debugging. 

* Config-option file import/export. 

* Custom okText for confirmationDialog and fix content constraints. 

* Add package to pubspec.yaml(file_picker, installed_apps, recase) 

* Fix android. 

* Move proto to core. 

* Merge pull request #12 from veto9292/fix/add-profile. 
  _empty region in free config mean all, fix grid crossAxisCount for single item_

* Empty region mean all, fix grid crossAxisCount for single item. 

* Merge pull request #11 from veto9292/update/add-profile. 
  _update/add_profile_modal_

* Update/add_profile_modal add/free profiles to add_profile_modal remove/http package from pubspec.yaml. 

* Merge pull request #8 from veto9292/fix/makefile. 
  _fix: makefile path issue in Windows OS_

* Merge pull request #10 from veto9292/feature/route-rule. 
  _add: proto packages & route_rule.proto file_

* Add: proto packages & route_rule.proto file. 

* Fix windows compile. 

* Improve ios  and windows. 

* Disallow delete active profile. 

* Better connection management, add bounce and show connection error. 

* Make easier access for quick setuo. 

* Refactor config options. 

* Update pods. 

* Update sentry. 

* Update. 

* Update sqlite3 dependency. 

* Update flutter. 

* Handle profile size. 

* Support correctly ios. 

* Update android libs. 

* Update packages. 

* Show error incase of fail. 

* Upgrade flutter. 

* Some refactor. 

* Refactor router. 

* Refactor: routes. 

* Update. 

* Merge branch 'ios' into new-design-v2. 

* Update dialog to platform dialog. 

* Merge remote-tracking branch 'origin/main' into ios. 

* Update. 

* Update. 

* Merge branch 'fix-latest' into new-design. 

* Update packages and fix web issues. 

* V3. 

* New UI design. 

* Merge remote-tracking branch 'origin/main' into ios-pv. 

* Add make with love in intro. 

* Improve ios UI and integrate it with os. 

* Update. 

* Update ios. 

* Remove 'needed_features' from free_configs. 

* Update free_configs. 

* Update cron schedule and add operations limit. 

* Modify stale.yml for cron schedule and messages. 
  _Updated the stale issue workflow to change the cron schedule and modify the stale issue message and timing._

* Update warp configuration with new server entries. 

* Update profile title in warp configuration. 

* Add new warp configurations and psiphon links. 

* Update title in free_configs for Warp profile. 

* Remove unused configurations for Insta-Youtube and Ainita. 
  _Removed several configurations related to Insta-Youtube and Ainita.net, including their titles, sublinks, tags, and consent messages._

* Change region from '-' to 'k' in free_configs. 
  _Updated region values from '-' to 'k' for two configurations._

* Add Mahsa profile configuration file. 

* Add Mahsa configuration profile to free_configs. 

* Update free_configs. 

* Update warp configuration with new detour format. 

* Update free_configs. 

* Update free_configs. 

* Create ainita. 

* Update free_configs. 

* Chore: update translations with Fink 🐦 

* Update super_fragment. 

* Update super_fragment. 

* Update super_fragment. 

* Update super_fragment. 

* Rename super_fragment.json to super_fragment. 

* Update super_fragment.json. 

* Create super_fragment.json. 

* Update free_configs. 

* Update free_configs. 

* Create free_configs. 

* Update fragment. 

* Update fragment. 

* Update fragment. 

* Create fragment. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README_cn.md. 

* Update README_br.md. 

* Update README.md. 

* Merge pull request #1475 from simonkimi/main. 
  _Profile Tile InkWell Overflow Fix_

* Fix profile_tile clipBehavior. 

* Update README.md. 

* Merge pull request #1464 from kekomenos/patch-1. 
  _Update README.md_

* Update README.md. 
  _<!-- Copy-paste in your Readme.md file -->

<a href="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history?repo_id=643504282" target="_blank" style="display: block" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=643504282&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Star History of hiddify/hiddify-app" src="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=643504282&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->_

* Update README.md. 

* Create README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Merge pull request #1438 from proninyaroslav/linux-fix-silent. 
  _[Linux] Fix minimize to tray (silent start) option_

* [Linux] Fix minimize to tray if the option is enabled. 

* Update LICENSE.md. 

* Update CONTRIBUTING.md. 

* Update README.md. 

* Merge pull request #1403 from ldm0206/main. 
  _Update translations zh-CN_

* Chore: update translations with Fink 🐦 



## v2.5.7 (2024-10-03)

#### Other

* Merge pull request #1382 from TheLastFlame/main. 
  _Remembering window closing action_

* Feat: add action options for closing the application. 

* Chore: update .gitignore to exclude /data directory. 

* Refactor: replace HookConsumerWidget with ConsumerWidget and add ThemeModePrefTile. 



## v2.5.6 (2024-10-02)

#### Fix

* Version bug. 

* Version bug. 



## v2.5.5 (2024-09-29)

#### Other

* Merge pull request #1368 from tarzst/main. 
  _Update RU translations_

* Chore: update translations with Fink 🐦 



## v2.5.2 (2024-09-29)

#### Fix

* Typo. 



## v2.5.1 (2024-09-29)

#### Fix

* Exception. 

* Version. 



## v2.5.0 (2024-09-28)

#### Other

* Merge pull request #1335 from laperuz92/patch-1. 
  _Update russian translations_

* Update russian translations. 

* Merge pull request #1328 from yxiZo/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #1322 from andythesilly/main. 
  _set edgeToEdge ui mode_

* Chore: update translations with Fink 🐦 

* Set edgeToEdge ui mode. 



## v2.3.1 (2024-09-07)

#### Fix

* Android. 

#### Other

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Change name to hiddifypackettunnel. 

* Fix android build issue. 



## v2.3.0 (2024-09-02)

#### New

* Add brazil region. 

#### Fix

* Black screenn when press back button. 

#### Other

* Hide back icon when no back. 

* Merge pull request #1277 from sillydillydiddy/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #1282 from vedantmgoyal9/patch-1. 
  _Update winget-releaser to latest_

* Update winget.yml. 

* Update winget.yml. 

* Update winget-releaser to latest. 

* Merge pull request #1278 from tensionc/main. 
  _fix: Black screenn when press back button_

* Merge remote-tracking branch 'origin/main' 

* Update warp. 

* Update warp. 

* Revert: Keep button, add judgment. 



## v2.2.0 (2024-08-21)

#### New

* Add several values for dns and url test in auto complete mode. 

* Add use xray core option. 

#### Changes

* Default tun mode to gvisor. 

#### Fix

* Bug. 

* Some hard coded items. 

* Apple bug. 

* Bug of back button in rtl flutter 3.24. 

* Naming of links containing &&detour. 

#### Other

* Better auto complete. 

* Remove hindi. 

* Update flutter to 3.24. 

* Merge pull request #1217 from lexxfin/main. 
  _chore: update translations with Fink 🐦_

* Chore: update translations with Fink 🐦 

* Merge pull request #1210 from bLueriVerLHR/main. 
  _Fix typo in stats_repository.dart_

* Fix typo in stats_repository.dart. 

* Chore: update translations with Fink 🐦 

* Include app configs before validaing proxies. 

* Chore: update translations with Fink 🐦 

* Change default warp mode to m4. 



## v2.1.5 (2024-08-05)

#### Fix

* Vpn service issue. 

#### Other

* Revert android changes. 

* Fix warp generation. 

* Try fix vpn. 

* Check macos. 

* Disable mac. 

* Revert changes to android vpn service. 

* Better tryicons. 



## v2.1.4 (2024-08-05)

#### New

* Add exit dialog when press close button. 

* Colorized tray icon. 

#### Fix

* Some bugs. 

* Bugs in tray icon. 

* Fr trnalsation. 

* Translate bug. 

* Single instance flutter in linux? 

#### Other

* Less retry for ipinfo. 

* Add french lang. 

* Test icon linux? 

* Connection button by proxy status indicator, change connected to connecting when timeout. 

* Formated export in json editor. 

* Merge pull request #1174 from Hannisiddiqui/main. 
  _Wanted to add hindi language for indian users_

* Inlang/manage: add languageTag hi. 

* Inlang/manage: install module. 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Update warp. 

* Update release_message.md. 



## v2.1.1 (2024-08-02)

#### New

* Add turkey region. 

#### Other

* Add change log. 



## v2.1.0 (2024-08-02)

#### New

* Add invalid config label. 

#### Fix

* Error migrating from v3 to v4 database. 

* Url test issues, avoid multiple test, and change outbound on test. 

* Loop in android. 

#### Other

* Merge pull request #1162 from soyangelromero/main. 
  _Update translations EN - ES_

* Chore: update translations with Fink 🐦 

* Merge pull request #1154 from MR-TZ-dev/main. 
  _fix: error migrating from v3 to v4 database._

* Better get requests. 

* Fix; font. 



## v2.0.4 (2024-07-31)

#### New

* Add rich config editor. 



## v2.0.3 (2024-07-30)

#### Fix

* Bug. 



## v2.0.2 (2024-07-30)

#### Other

* Better editor. 



## v2.0.1 (2024-07-30)

#### Fix

* Ios build issue. 

* Ios bug. 

* Some bugs in configs and fix core bugs. 

* Editor text mode bug. 

#### Other

* Update. 

* Better json editor. 

* Test. 

* Use latest macos for build ios. 

* Test ios. 



## v2.0.0 (2024-07-30)

#### New

* Add json editor and editing configs <3. 

* Add custom url-test for each repository. 

#### Fix

* Link validator. 

* Provis? 

* Ios. 

#### Other

* Update warp. 

* Fix? 

* Ios? 

* Fix ios? 

* Fix bug. 



## v1.9.1 (2024-07-28)

#### New

* Add auto build for ios. 

* Add xray type. 

#### Fix

* Add warp issue. 

#### Other

* Revert to sdk 34. 

* Enable resolve-destination and ipv6 by default. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1108 from SonzaiEkkusu/main. 
  _Update Translations for Region Indonesia (id)_

* Update Translations for Region Indonesia (id) 

* Reset direct dns when region  change. 

* Update sdk to 35. 

* Better xray support. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1106 from amirsaam/main. 
  _General iOS Maintain_

* General iOS Maintain. 



## v1.9.0 (2024-07-25)

#### New

* Add10000 to all ports for prevenging permission error. add warp from github repository except for china. 

#### Fix

* Fixed problem not launching on Ubuntu 24.04 LTS. 

#### Other

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1084 from MR-TZ-dev/fix/linuxLaunchFix. 
  _fix: fixed problem not launching on Ubuntu 24.04 LTS._

* Merge pull request #1092 from Metozak/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #1097 from SonzaiEkkusu/main. 
  _Add Indonesia region_

* Add Indonesia region. 

* Add core to 1.9.0. 

* Upgrade flutter. 

* Merge pull request #1073 from keyang556/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Update warp. 

* Update warp2. 

* Update warp2. 



## v1.7.0 (2024-07-17)

#### New

* Add more warp modes, handle both ipv4 and ipv6 in wireguard, add customizable size and more. 

#### Other

* Update warp2. 

* Create warp2. 

* Update warp. 



## v1.6.3 (2024-07-14)

#### Other

* Make pre-release by default. 



## v1.6.2 (2024-07-14)

#### Fix

* Qrcode issue and update qrcode lib. 

* Scanner. 

#### Other

* Renew warp configs on adding. 



## v1.6.1 (2024-07-14)

#### New

* Add knocker parameters. 

#### Fix

* Release issue. 

* Qrcode issue. 

#### Other

* Android. 

* Upgrade flutter. 

* Update flutter and make connection more smooth. 

* Show info dialog when reconnecting. 

* Merge pull request #1050 from itispey/dev-test. 
  _Reconnect automatically after changing service-mode_

* Reconnect automatically after changing service-mode. 

* Merge pull request #1053 from maxyxyd/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Merge pull request #1043 from nidghogg/main. 
  _Fixed camera permission handling for QR_

* Merge branch 'main' of https://github.com/nidghogg/hiddify-next. 

* Fixed Camera permission handling for QR. 



## v1.5.0 (2024-07-09)

#### Fix

* Test bug for geoassets. 

* Remove geoassets. 

#### Other

* Fix intro page buug. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #1004 from Kianmehrgit/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #993 from fodhelper/fix-urltest-fails. 
  _Fix URLTest Fails_

* Update config_option_repository.dart. 

* Merge pull request #966 from SoranTabesh/main. 
  _Update translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #965 from SoranTabesh/patch-1. 
  _Update locale_extensions.dart_

* Update locale_extensions.dart. 

* Merge pull request #988 from Amirali-Amirifar/fix-changelog-update-years. 
  _Fix CHANGELOG year_

* Fix CHANGELOG year. 
  _see diff._

* Merge pull request #934 from amirsaam/main. 
  _General iOS Maintaining_

* General iOS Maintaining. 

* Refactor. 

* Add basic routing options, auto update routing assets,use ruleset, remove geo assets. 



## v1.4.0 (2024-06-02)

#### Fix

* Naming bug. 

* Bug. 

* Bug. 

* Ios. 

* Lang. 

* Bug. 

* Make dark tray icon windows-only. 

#### Other

* Merge pull request #817 from felixhaeberle/main. 
  _Update translations_

* Merge branch 'main' into main. 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Merge pull request #811 from amirsaam/main. 
  _New Bundle + Pods + PrivacyAPIs_

* Privacy Targets. 

* Privacy Declaration. 

* New Bundle + Pods. 

* Merge branch 'android-fix-action-bug' 

* Downgrade flutter. 

* Master. 

* Downgrade to 3.22.0. 

* Upgrade flutter. 

* Update to flutter 3.21. 

* Update. 

* Downgrade flutter. 

* Temporary disbale apk build. 

* Update. 

* Update. 

* Test. 

* Update. 

* Update. 

* Upgrade gradle version. 

* Tmp test. 

* Add more log. 

* Update flutter action. 

* Add debug and ios. 

* Fix lang update. 

* Merge pull request #778 from Pikman/main. 
  _Update translations_

* Merge branch 'main' into main. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Merge pull request #894 from xmha97/main. 
  _Capitalize the installation folder_

* Update make_config.yaml. 

* Merge pull request #902 from MrIbrahem/main. 
  _Update ar translations_

* Chore: update translations with Fink 🐦 

* Merge pull request #4 from MrIbrahem/patch-1. 
  _Patch 1_

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Update make_config.yaml. 

* Update settings.json. 

* Update locale_extensions.dart. 

* Merge pull request #3 from MrIbrahem/patch-1. 
  _Update strings_ar.i18n.json_

* Update strings_ar.i18n.json. 

* Update strings_ar.i18n.json. 

* Merge pull request #2 from MrIbrahem/patch-1. 
  _Create strings_ar.i18n.json_

* Create strings_ar.i18n.json. 

* Merge pull request #814 from keyang556/main. 
  _Update Traditional Chinese translations_

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Chore: update translations with Fink 🐦 

* Add warp config, update to flutter 1.22. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Merge pull request #770 from alkstsgv/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Test. 

* Merge pull request #751 from sky96111/main. 
  _fix: make auto dark tray icon windows-only_

* Merge pull request #737 from SoranTabesh/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Rename strings_ckb-KU.i18n.json to strings_ckb-KUR.i18n.json. 

* Update settings.json. 

* Fink 🐦: update translations. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update core. 

* Merge pull request #726 from HSSkyBoy/main. 
  _inlang: update zh-TW transition_

* Update zh-TW transition. 

* Merge pull request #705 from iamgiko/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 

* Update LICENSE.md. 

* Update LICENSE.md. 

* Update README_ru.md. 

* Update README_ja.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #698 from betaxab/p1. 
  _inlang: update translations_

* Inlang: update translations. 



## v1.1.1 (2024-03-20)

#### New

* Add tproxy. 

#### Fix

* Gvisor. 

* Issue. 

#### Other

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #696 from HSSkyBoy/main. 
  _Update translations (zh_TW and zh_CN)_

* 更新 strings_zh-TW.i18n.json. 

* 更新 strings_zh-TW.i18n.json. 

* Update strings_zh-TW.i18n.json. 

* 更新 strings_zh-TW.i18n.json. 

* Change APP name. 

* 更新 strings_zh-TW.i18n.json. 

* 更新 strings_zh-CN.i18n.json. 

* Bump version. 

* Merge pull request #692 from sky96111/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Merge pull request #686 from sky96111/main. 
  _feat: Use dark tray icon in light theme_

* Feat: dark tray icon in light theme. 

* Merge pull request #690 from imshahab/m3-dynamic-theme. 
  _Implement Material 3 dynamic theming_

* Implement Material 3 dynamic theming. 

* Merge pull request #685 from Nyar233/main. 
  _Update translations_

* Fink 🐦: update translations. 

* Merge pull request #682 from alirezafarvardin/main. 
  _Update translation (Persian)_

* Merge branch 'main' into main. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Update bug_report.yaml. 

* Fink 🐦: update translations. 

* Fink 🐦: update translations. 



## v1.0.0 (2024-03-18)

#### New

* Add review. 

#### Fix

* Isssue with singbox 1.8.9. 

* Ios. 

* Implementation. 

* Test, update to singbox 1.8.9. 

* Bug in warp config. 

#### Other

* Update release_message.md. 

* Update README.md. 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_br.md. 

* Update README.md. 

* Update release_message.md. 

* Update README.md. 

* Fix postServiceClose implementation. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Fink 🐦: update translations. 

* Remove mux. 

* Merge branch 'pr/alikhabazian/668-1' 

* Resolve qr code permssion issue. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #668 from alikhabazian/newyear. 
  _add image field to ConnectionButton_

* Add useImage feild for change image in every newyear and increase quality. 

* Add image field to ConnectionButton. 

* Update. 

* Merge pull request #653 from alirezafarvardin/main. 
  _Update translations_

* Inlang/manage: add languageTag zh-TW. 

* Inlang/manage: add languageTag zh-CN. 

* Inlang/manage: add languageTag tr. 

* Inlang/manage: add languageTag ru. 

* Inlang/manage: add languageTag pt-BR. 

* Inlang/manage: add languageTag id. 

* Inlang/manage: add languageTag es. 

* Inlang/manage: remove languageTag es. 

* Inlang/manage: add languageTag es. 

* Inlang/manage: remove languageTag zh-CN. 

* Inlang/manage: remove languageTag id. 

* Inlang/manage: remove languageTag ru. 

* Inlang/manage: remove languageTag tr. 

* Inlang/manage: remove languageTag es. 

* Inlang/manage: remove languageTag zh-TW. 

* Inlang/manage: remove languageTag pt-BR. 

* Merge branch 'hiddify:main' into main. 

* Fink 🐦: update translations. 

* Test flight only release. 

* Add core grpc server. 



## v0.17.12 (2024-03-14)

#### New

* Refactor testflight. 

* Add installation dependencies for apple. 

* Add ios build process. 

* Add Indonesian language. 

* Add hiddifycli and resolve all false positve from anti virus, auto exit during installation. 

* Add support for flag emoji in proxy names. 

* Add version draft. 

* Auto replace signed exec. 

* Update to singboc 1.8.7. 

* Enable tunnel service again, add signing, msix, more log less info. 

* Add ipwho.is. 

* Use timezone for location detector. 

* Add warp fake packet delay, add warp detour, add new ipinfo api. 

#### Fix

* Apple release. 

* Bug. 

* No commit message. 

* Release to ios. 

* Ios publishing. 

* Var. 

* Var. 

* Vaiable issue. 

* Potential fix to issue in some windows? 

* Msix package. 

* Signing. 

* Version. 

* Pub get issue? 

* Build. 

* Flag. 

* Ip flag. 

* Bug in versioned draft. 

* Invalid version string for draft. 

* Action bugs. 

* Signing. 

* Signing. 

* Cert? 

* Generate Warp Config on iOS. 
  _+ pod install new packages_

* Msix issue. 

* Appimage fixed. issue: #513. 

* Name. 

* Intro page bug and fakepacket delay bug. 

* Exception reporting on failing in getting ip. 

* Exception when there is no active profile. 

* Ip info. 

* Build bug. 

* Translation bug, disable signing for pull req. 

* Bug in change interface listener. 

* Update download paths in release page. 

* Logo, add name for hiddify warp sub. 

#### Other

* Update. 

* Update. 

* Update. 

* Update. 

* Update. 

* Disable: permission handler for windows. 

* Disable redundent action run for release. 

* Merge pull request #647 from hiddify/ios. 
  _Ios_

* Upload versioned. 

* Update. 

* Update. 

* Update ios release. 

* Upload to appstore in macos. 

* Test testflight upload. 

* Fix name issue. 

* Update. 

* Update. 

* Update. 

* Add provisioning profiles. 

* Add SingBoxPacketTunnel. 

* Update. 

* Update. 

* Add prereq of ios. 

* Allow ci build from all branches. 

* Revert changes for test. 

* Test disabling system tray. 

* A test for possible bug in some windows. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update signing. 

* Downgrade flutter action. 

* Merge pull request #621 from hei-hilman/main. 
  _add new translation (Indonesian)_

* Add indonesian translation. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Fix qr code scanner. 

* Change translation keys. 

* Change experimental feature notice. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Change sidebar stats. 

* Add emoji font for flags. 

* Use software rendering for windows. may resolve white screen? 

* Update README_br.md. 

* Update README_ja.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Refactor config options. 

* Merge branch 'be1c1bb580ec039044e8057ae1469153008cdb4d' 

* Add reconnect and animations to connection button. 

* Add quick settings. 

* Update release_message.md. 

* Bump Flutter (v3.19) and dependencies. 

* Remove redundant logs. 

* Change db initialization. 

* Remove draft version. 

* Make it universal for all os. 

* Add versioned draft. 

* Simple debug to bug of some windows. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Add Config options import. 

* Disable signing. 

* Add hide icon from dock on mac. 

* Add reconnect alert for config options. 

* Refactor preferences. 

* Merge pull request #585 from amirsaam/main. 

* Update msix. 

* Merge pull request #577 from Aryangh1379/Hiddify-develop. 

* Merge pull request #572 from Aryangh1379/Hiddify-develop. 
  _Hiddify develop_

* Forgot to remove -x from !#/bin/bash :) 

* Add AppRun parameters - provided a help menu. 

* Temporary disable windows service. 

* Update README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README_br.md. 

* Merge pull request #532 from mascenaa/main. 
  _Add README in Portuguese_

* Adding a README in Portuguese. 

* Merge pull request #556 from Aryangh1379/Hiddify-develop. 
  _AppRun file error fixed. AppImage now is usable_

* AppRun file error fixed. AppImage now is usable. 

* Merge pull request #549 from pierrot-p/main. 
  _[PT-BR]  inlang: Added missing translations_

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Merge pull request #546 from nya-main/main. 
  _update translations(CN)_

* Manually repair an entry. 

* Inlang: update translations. 

* Merge pull request #547 from amirsaam/main. 
  _macOS AppIcon_

* MacOS AppIcon. 

* Add timezone based region detection. 

* Url test is only valid for group not a single proxy. 

* Potentioal fix for crash in some windows. 

* Bump libcore. 

* Excluding aab from building draft. 

* Remove aab draft build. 

* Change warp options. 

* Fix Portuguese locale. 

* Add build test. 

* Update dependencies. 

* Change ip error. 

* Remove extra warp configs. 

* Update README_ru.md. 

* Merge pull request #509 from nevazno00/patch-1. 
  _Update README_ru.md_

* Update README_ru.md. 

* Merge pull request #527 from mascenaa/main. 
  _Add a PT-BR Translate file._

* Add a PT-BR Translate file. 

* Merge pull request #508 from kouhe3/zh-cn-i18n-patch-2. 
  _strings_zh-CN.i18n.json_

* Merge branch 'main' into zh-cn-i18n-patch-2. 

* Merge pull request #523 from nya-main/main. 
  _Update translations_

* Merge branch 'main' into main. 

* Merge pull request #528 from KintaMiao/main. 
  _Update translations_

* Inlang: update translations. 

* Inlang: update translations. 

* Fix build. 

* Add more haptic feedback. 

* Zh-cn translate. 

* Detailed subscription info. 

* Add detailed subscription info. 

* Fix test. 

* Add ci test. 

* Add warp config generator. 

* Update changelog. 

* Change ip refresh. 

* Add auto ip check option. 

* Change ip error refresh button. 

* Change mapping. 

* Fix issue in installing packages in ubuntu. 

* Fix connection on desktop. 

* Change interval mapping. 

* Fix chinese locale. 

* Add haptic feedback. 

* Format zh-CN.i18n.json And remove duplicate. 

* Merge pull request #410 from junlin03/main. 
  _更新繁體中文翻譯_

* Merge branch 'main' into main. 

* Merge pull request #482 from guoard/fix/downlaod_path. 
  _fix: update download paths in release page_

* Merge pull request #481 from amirsaam/main. 
  _Bugs in config_option_entity.dart_

* Update config_option_entity.dart. 

* Bugs in config_option_entity.dart. 

* Change mapping and bug fixes. 

* Change icons. 

* Improve ping indicator. 

* Change service mode choices. 

* Fix ip widget directionality. 

* Merge branch 'main' into main. 

* Inlang: update translations. 



## v0.15.8 (2024-02-14)

#### New

* Update icon. 

* Add seperated VPN service mode. 

* Add some example of new warp configs. 

* Update active profile and its ping, 

* Change app icon to stable. 

* Add unavailble mark, fix: windows release bug. 

#### Changes

* Change name to Hiddify. 

#### Fix

* Appimage tunnel service bug. 

#### Other

* Change ip obscure. 

* Improve accessibility. 

* Change service error handling. 

* Fix connection info. 

* Fix widget build conflict. 

* Revert build image for appimage to 22.04. 

* Update README_cn.md. 

* Update README.md. 

* Update README.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ja.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #454 from amirsaam/main. 
  _Update iOS Icons_

* AppIcon Update. 

* Update iOS Icons. 

* Add proxy http adapter. 

* Fix android service mode. 

* Merge pull request #453 from amirsaam/main. 
  _Update Makefile_

* Update Makefile. 

* Change routing setup. 

* Fix connection info ui. 

* Make ip private for both footer and sidebar. 

* Make ip anonymous. 

* Add syncthing ignore files. 

* Add desktop active proxy info. 

* Add active proxy delay indicator. 

* Fix commands. 

* Change translation fallback strategy. 

* Update CONTRIBUTING.md. 

* Merge pull request #439 from amirsaam/main. 
  _Fix iOS Logger_

* Fix iOS Logger. 



## v0.15.6 (2024-02-09)

#### New

* Add macos pkg file and remove zip wrapper. 

* Add custom AppRun: need forked distributor. 

* Add intro based on user lang and region. 

* Hide hidden nodes. 

* Move running admin service to core. 

* Display go errors. 

* Add tunnel service for windows and linux. 

* Show groups always on top. 

* Change update time when selected. 

* Make activated profile always in top. 

* Add postfix to name if it is not unique. 

* Add link parser and allow custom configs to be imported. 

#### Changes

* Use our flutter distrobutor version and downgrade windows version (possible fix of build error) 

#### Fix

* Unix copy bug. 

* Build linux. 

* Dynamic varible in github action. 

* Windows? 

* Windows build? 

* Typo. 

* Windows build. 

* Appimage build and add make req for linux. 

* Service location bug in linux. 

* Update of protocol handler. 

* Bug in logging go erros. 

* Check core before release. 

#### Other

* Refactor  build. 

* Add debug build for windows. 

* Rerun windows without cache. 

* Add ios connection info. 

* Fix ui inconsistency. 

* Fix local build commands. 

* Fix android bugs. 

* Add connection info footer. 

* Add ip info fetcher. 

* Merge pull request #416 from EbrahimTahernejad/patch-1. 
  _Make logger global_

* Use shared instance of logs to log. 

* Added shared instance for LogsEventHandler. 

* Merge pull request #414 from amirsaam/main. 
  _Log for iOS by @ Akuma_

* Log for iOS by @ Akuma. 

* Add ios command client. 

* Change make flags. 

* Change the name of tunnel service to HiddifyService. 

* Make makefile cross platform. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add cloudflare warp options. 

* Temporary disable app image build. 

* Change again to ubuntu 22.04. 

* Update ci.yml. 

* Disable tunnel service for mac. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Remove unnecessary dependencies. 

* Fix mobile routing behavior. 

* Bump java version. 

* Update dependencies. 

* Fix intro page margin. 

* Send panic to sentry. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #371 from eltociear/add_ja-readme. 
  _Add Japanese README_

* Add Japanese README. 

* Merge pull request #389 from leic4u/patch-1. 
  _Update README_cn.md_

* Update README_cn.md. 

* Update README.md. 

* Add mux to experiments && update translations. 



## v0.15.4 (2024-01-26)

#### Fix

* Fragment bug. 



## v0.15.3 (2024-01-26)

#### New

* Add warp option (experimental) 

#### Fix

* Typo. 

#### Other

* Bump to singbox 1.8.4, and fix bugs. 

* Refactor makefile. 

* Update Hiddify Packages. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update to core 0.12.1, singbox 1.8.2. 

* Update build.yml. 

* Make 1.1.1.1 as default dns server. 

* Speed up ping. 

* Update libcore. 



## v0.14.20 (2024-01-21)

#### Other

* Update feature_request.yaml. 

* Update bug_report.yaml. 



## v0.14.11 (2024-01-20)

#### New

* Add deb and rpm build. 

#### Fix

* Versioning issue in ios singbox platform extension. 

* Release bug. 

* Release bug. 

* Build linux. 

* Stats bug in iOS. 

* Some bugs in ios. 

#### Other

* Merge pull request #351 from amirsaam/main. 
  _use universal bundleid from base.xconfig_

* Use universal bundleid from base.xconfig. 

* Merge pull request #350 from amirsaam/main. 
  _ios log handler base functionality_

* Log handler base functionality. 
  _+ fix makefile ios-temp-prepare upgrading pub
+ remove tvOS from libcore local spm
+_

* Add mux options. 

* Add mux. 

* Update release_message.md. 

* Update build.yml. 

* Update changelog. 

* Update readme. 

* Fix ios stats. 

* Add reset tunnel option on ios. 

* Update build.yml. 

* Fix release. 

* Fix release. 

* FIX: RELEASE BUG. 

* Fix release bug in macos. 

* Update build.yml. 

* Update build.yml. 

* Update build.yml. 

* Update dependencies. 

* Fix not releasing linux packages. 

* Merge pull request #347 from amirsaam/main. 
  _fix connection bug after bundle update_

* Fix connection bug after bundle update. 

* Merge pull request #345 from amirsaam/main. 
  _update to latest itunes connect_

* Update to latest itunes connect. 

* Revert changes for swift package. 

* Merge pull request #344 from amirsaam/main. 
  _switch to local spm to load libcore_

* Merge branch 'main' of https://github.com/amirsaam/hiddify-next. 

* Merge branch 'hiddify:main' into main. 

* Remove tvOS in singbox target. 

* Remove tvOS, previously added apple vision for ipad. 

* Handle xcode crash. 

* Switch to local spm. 

* Fix make ios. 

* Bumpcore version to v0.11. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #343 from amirsaam/main. 
  _url scheme +  target dependency + general update_

* Merge branch 'hiddify:main' into main. 

* Add url scheme. 

* Update Package.resolved. 

* Target dependancy + pod update, package resolve. 

* Remove hiddify://import/ from export option. 

* Merge pull request #342 from amirsaam/main. 
  _getting libcore from spm, adding landscape mode_

* Merge branch 'main' of https://github.com/amirsaam/hiddify-next. 

* Delete pubspec.lock. 

* Revert some changers. 
  _This reverts some of commit dde7c2419a12e0f36976f4c0ff8e66d882ec62ac._

* Update pod, getting libcore from spm, adding landscape mode. 

* Change profile options modal. 

* Fix infinite sub expire date (#334) 
  _* Fix infinite sub expire date

* fix expire

* fix build

* refactor

* make it better readable

* Fix infinite sub

* Add test for infinite sub

---------_

* Fix fragment bugs. 

* Merge pull request #340 from amirsaam/main. 
  _fix ui not showing connected after relaunch_

* Fix ui not showing connected after relaunch. 

* Merge pull request #338 from amirsaam/main. 
  _add push notification entitlement_

* Merge branch 'main' of https://github.com/amirsaam/hiddify-next. 

* Add config export on ios. 

* Fix ios connection status on app restart. 

* Add push notification entitlement. 

* Fix attempt. 

* Fix. 

* Fix ci again. 

* Fix ci tag matching. 

* Fix ci. 

* Change logger to print in console. 

* Change routing assets order. 

* Change options description. 

* Fix ci tag pattern. 

* Fix ci. 

* Change workflows. 

* Add missing es translations. 

* Inlang: update translations. 

* Fix infinite sub traffic. 

* Fix bugs. 

* Fix modal text alignment. 

* Merge pull request #329 from amirsaam/newMain. 
  _revert landscape mode_

* Revert landscape mode. 

* Merge pull request #328 from amirsaam/main. 
  _remove unnecessary force unwrap, libcore linking add landscape mode_

* Remove unnecessary force unwrap, libcore linking add landscape mode, 

* Change ios method error handling. 

* Fix bugs. 

* Remove custom_lint. 

* Add vscode launch config macos designed for ipad. 

* Fix ios flutter plugins. 

* Fix ios core name. 

* Merge pull request #323 from amirsaam/main. 
  _better fix for vpn connecting_

* Better fix for vpn connecting. 

* Merge pull request #321 from amirsaam/main. 
  _match exportOptions identifiers with project_

* Fixing not connecting to vpn. 

* Match exportOptions identifiers with project. 

* Merge pull request #319 from amirsaam/main. 
  _fix vpn profile not being created + changing run to release_

* Fix vpn profile not being created + changing run to release. 

* Merge pull request #318 from amirsaam/main. 
  _ios fix?_

* Ios fix? 

* Fix build. 

* Fix windows deep link. 

* Merge pull request #316 from amirsaam/main. 
  _Update pubspec.lock_

* Update pubspec.lock. 

* Merge pull request #315 from amirsaam/main. 
  _add back cupertino_http_

* Add back cupertino_http. 

* Update. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Update appcast. 



## v0.13.6 (2024-01-07)

#### Other

* Fix build. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Fix qr scanner links. 

* Update changelog. 

* Update core (sing-box v1.7.8) 

* Update dependencies. 

* Remove unused dependencies. 

* Refactor service wrappers. 

* Update. 

* Update ios. 

* Change default connection test url. 

* Fix android service mode switch. 

* Add profile fetch cancel. 

* Add update all subscriptions. 

* Fix profile update service. 

* Inlang: update translations. 

* Change app http client. 

* Inlang: update translations. 

* Fix bugs. 

* Add experimental flag to new config options. 

* Add connection from lan option. 

* Add dns routing option. 

* Add bypass lan option. 

* Fix profile edit with new url. 

* Change tls tricks settings section name. 

* Fix db migration bug. 

* Bump version. 

* Fix minor bugs. 

* Remove desktop auto connect. 

* Add experimental feature notice. 

* Update README.md. 

* Update README.md. 

* Fix multi instance on windows. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update README_cn.md. 

* Update README_cn.md. 
  _Some proxy software such as clash do not have official Chinese names and use English by default._

* Add experimental flag in settings ui. 

* Fix inlang setup. 

* Remove robocopy. 

* Fix build. 

* Fix windows portable again. 

* Update changelog. 

* Add android high refresh rate support. 

* Refactor desktop window management and tray. 

* Fix macOS restore from dock. 

* Add desktop shortcuts. 



## v0.12.3 (2023-12-28)

#### Changes

* Fix inconsistent channel naming. 

#### Fix

* Set codec for stream handlers. 

* Ios launch bug. 

#### Other

* Add Afghanistan region. 

* Fix packaging bug. 

* Fix windows packaging. 

* Fix bugs. 

* Change minimum macos version in docs. 

* Add version to desktop window. 

* [fix]: SettingsPickerDialog pop exception. 

* Update ios. 

* Ios: add /platform event channel. 

* Feat: Added stats stream for ios. 

* Feat: Added stats stream for ios. 

* Update ios. 

* Update ios. 

* Update ios. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Ios update. 



## v0.12.2 (2023-12-23)

#### Other

* Remove native http client (temporarily) 

* Update dependencies. 

* Update core (sing-box v1.7.6) 

* Fix bugs. 

* Update core (sing-box v1.7.5) 

* Change initialization and logging. 



## v0.12.1 (2023-12-21)

#### Other

* Fix preferences initialization error. 

* Bump android sdk version. 

* Fix android service mode. 

* Change privacy policy url. 

* Update appcast. 



## v0.12.0 (2023-12-20)

#### New

* Add support for hysteria and wg. 

* Add user-agent like clash sing-box for better compatibility. 

* Send all releases to beta by default. 

#### Fix

* Bug in  windows portable. 

* Linux parse. 

#### Other

* Add hiddify/iimport schema. 

* Fix chinese inlang url. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README.md. 

* Update README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update changelog. 

* Change memory limit on desktop. 

* Remove locale name provider. 

* Fix service mode. 

* Add android dynamic notification. 

* Add android stats channel. 

* Fix translation generator. 

* Add config option reset. 

* Add missing routing asset warning. 

* Fix text input traversal. 

* Add basic d-pad support. 

* Fix tray initialization bug. 

* Update LICENSE.md. 

* Update LICENSE.md. 

* Update LICENSE.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README.md. 

* Add preferences migration. 

* Fix tray behavior. 

* Fix intro routing bug. 

* Fix macos build. 

* Fix macos name. 

* Fix macos icon. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update ios. 

* Update ios. 

* Update ios. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Fix build. 

* Change entrypoint. 

* Add TLS trick config options. 

* Update ios. 

* Update platform interface. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Update dev-i.yml. 

* Update dev-i.yml. 

* Update pubspec.yaml. 

* Create dev-i.yml. 

* Update changelog. 

* Update dependencies. 

* Update core (singbox v1.7) 

* Fix status mapper. 

* Refactor. 

* Refactor logs. 

* Remove unused clash api. 

* Update core (singbox 1.7.0-rc.2) 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Refactor router. 

* Refactor profiles. 

* Update changelog. 

* Fix chinese typography bug. 

* Add soffchen geo assets. 

* Refactor geo assets. 

* Update dependencies. 

* Bump ci sdk version. 

* Bump sdk version. 

* Update README.md. 

* Update README_fa.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README.md. 

* Update README.md. 

* Update release_message.md. 

* Update appcast. 

* Merge pull request #189 from jomertix/main. 
  _Update ru strings_

* Nothing changed strings_tr.i18n.json. 

* Nothing changed strings_fa.i18n.json. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update. 



## v0.11.1 (2023-11-19)

#### Other

* Fix android manifest. 

* Fix documentation. 

* Update release_message.md. 



## v0.11.0 (2023-11-19)

#### New

* Add ic_launcher for android tv. 

* Publish dev release to seperate channel. 

* Add winget. 

* Add prepare to make file. 

#### Fix

* Build-linux-libs. 

* Build. 

* Naming issue. 

* Winget release. 

* Action version. 

* Winget publish. 

* Build error. 

* No commit message. 

* Build. 

* Bug. 

* Build. 

* Distutils. 

* No commit message. 

#### Other

* Change default direct dns. 

* Revert "new: add ic_launcher for android tv" 
  _This reverts commit 49bb62c8289d0885a762e01b7f0785690a7d3af7._

* Change ir region rules. 

* Merge pull request #179 from betaxab/main. 
  _Update translations_

* Inlang: update translations. 

* Add recommended geo assets. 

* Add error handling for geo assets. 

* Fix build. 

* Add geo assets settings. 

* Fix bug in strings_tr.i18n.json. 

* Merge pull request #173 from hasankarli/main. 
  _Update Turkish translations_

* Inlang: update translations. 

* Merge pull request #169 from solokot/main. 
  _Update Russian translation_

* Merge branch 'main' into main. 

* Merge pull request #168 from jomertix/main. 
  _inlang: update translations_

* Inlang: update translations. 

* Merge pull request #172 from Locas56227/main. 
  _Fix and improve Chinese README_

* Fix and improve Chinese README. 

* Update build.yml. 

* Update appcast. 

* Add navigation to system tray. 

* Update Russian translation. 
  _and partially revert ugly inlang changes_

* Change http adapter. 

* Add independent dns cache option. 

* Fix bottom navigation bar accessibility. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update release_message.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #165 from huajizhige/main. 
  _Improve translation_

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Update appcast. 

* Fix release command. 

* Add subscription qr code share. 

* Improve qr code scanner ux. 

* Fix code typo. 

* Ci: ignore appcast. 

* Merge pull request #164 from jomertix/main. 
  _Update ru string_

* Update strings_ru.i18n.json. 
  _Fix translation_

* Update strings_ru.i18n.json. 
  _Fix translate_

* Merge pull request #162 from solokot/main. 
  _Update strings_ru_

* Update strings_ru. 
  _Fix google translate_

* Merge pull request #161 from Aloxaf/Aloxaf-patch-1. 
  _fix: build-linux-libs_

* Add sub link share. 

* Fix bootstrap bug. 

* Add proxy tag dialog. 

* Add export config to clipboard. 

* Add geoassessts to makefile prepare. 

* Merge pull request #155 from solokot/main. 
  _Update strings_ru_

* Update strings_ru. 

* Add service mode and strict route. 

* Add basic privilege check. 

* Fix ui bugs. 

* Remove unnecessary preferences. 

* Fix config preferences. 

* Update changelog. 

* Update core to v0.8.0. 

* Fix manual update checker. 

* Fix logs page scroll. 

* Fix android service restart. 

* Fix android service revoke. 

* Change toast. 

* Fix linting and cleanup. 

* Remove execute config as is. 

* Update dependencies. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #138 from huajizhige/main. 
  _inlang: update translations_

* Inlang: update translations. 

* Update. 

* Fix. 

* Fix. 

* Test. 

* Merge pull request #137 from huajizhige/patch-1. 
  _Update README_cn.md_

* Update README_cn.md. 
  _Improve translation_

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Fix. 

* Update. 

* Fix. 

* Fix build. 

* Add distutils. 

* Improve Android TV. 

* Update. 

* Add. 

* Fix appcast url. 

* Add appcast. 

* Add auto connect on start. 

* Merge pull request #123 from Nyar233/main. 
  _Update translations_

* Inlang: update translations. 

* Update release_message.md. 

* Update release_message.md. 

* Merge pull request #115 from solokot/main. 
  _Update Russian: fix google translate_

* Update Russian: fix google translate. 

* Merge pull request #113 from Nyar233/main. 
  _inlang: update translations_

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Inlang: update translations. 

* Change system tray options. 

* Add core mode. 

* Add sidebar stats for large screens. 

* Update dependencies. 

* Change router for different screen size. 

* Merge pull request #108 from Hiiirad/patch-1. 
  _Update auto_translator.py to fix the Path Traversal Vulnerability_

* Update auto_translator.py to fix the Path Traversal Vulnerability. 



## v0.10.0 (2023-10-27)

#### New

* Add ios core library to the project. 

#### Fix

* Ipa. 

#### Other

* Remove reconnect on auto profile update. 

* Update changelog. 

* Add selected tag for selector outbounds. 

* Add core debug flag. 

* Add url test delay color. 

* Change info logs. 

* Delete .github/help/linux/آموزش هیدیفای‌نکست فارسی لینوکس.desktop. 

* Delete .github/help/mac-windows/آموزش هیدیفای‌نکست فارسی.url. 

* Update dependencies. 

* Change pre release update checking off. 

* Add terms and privacy to about page. 

* Add memory limit option. 

* Change directory management. 

* Comment ios. 

* Change app id. 

* Merge pull request #98 from GFWFighter/main. 
  _Initial iOS version_

* Merge pull request #1 from GFWFighter/ios. 
  _iOS_

* Merge branch 'main' into ios. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Merge pull request #95 from solokot/main. 
  _Update Russian_

* Update Russian. 
  _Mainly fix google translate of  new worlds_

* Change logging. 

* Change changelog workflow. 

* Add russia region. 

* Change theme prefs. 

* Merge pull request #90 from solokot/main. 
  _Russian translation: fix some mistakes_

* Russian translation: fix some mistakes. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Add rules. 

* Update LICENSE.md. 

* Inlang: update translations. 

* Merge pull request #85 from leic4u/main. 
  _Update README_cn.md_

* Update README_cn.md. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add inlang translations. 

* Add inlang project and remove localize. 

* Merge pull request #82 from Iam54r1n4/main. 
  _add inlang translator_

* Update: fr_FR.json. 

* Add: french language. 

* Add: inlang translation files(incomplete) 

* Add: setup inlang translation. 

* Merge pull request #74 from lifeindarkside/patch-1. 
  _Update strings_ru.i18n.json_

* Update strings_ru.i18n.json. 
  _Update some wrong interpretation_

* Update README_ru.md. 

* Update README_cn.md. 

* Update README.md. 

* First working version. 

* Underlying VPN Logic. 

* Initialize Packet Tunnel + Config. 

* Update Tutorial_For_HiddifyNext_Linux.desktop. 

* Update Tutorial_For_HiddifyNext.url. 

* Update آموزش هیدیفای‌نکست فارسی.url. 

* Update آموزش هیدیفای‌نکست فارسی لینوکس.desktop. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_ru.md. 

* Update README_cn.md. 



## v0.9.2 (2023-10-15)

#### Other

* Fix ndk setup. 

* Fix android arm bug. 



## v0.9.1 (2023-10-15)

#### Other

* Update README_cn.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Delete docs/file. 

* Google play badge. 

* Delete docs/google-play-badge1.png. 

* Upload google play badge. 

* Create file. 

* Delete docs/google-play-badge.png. 

* Fix ci. 

* Change ndk setup. 

* Update dependencies. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Change desktop error handling. 

* Fix android bugs. 

* Update README.md. 

* Update README_cn.md. 

* Update README_ru.md. 

* Update README_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Delete Russian_Flag.png. 

* Add Russian flag. 

* Delete docs/file. 

* Create README_ru.md. 

* Delete REAMME_ru.md. 

* Create REAMME_ru.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_cn.md. 

* Update README_cn.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update file. 

* Uplaod a badge for google play. 

* Delete google-play-badge.png. 

* Add files via upload. 

* Create file. 

* Delete docs/google-play-badge.png. 

* Delete google-play-badge.png. 

* Add files via upload. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Create Chinese README_cn.md. 



## v0.8.12 (2023-10-13)

#### Fix

* Typo. 

* Bug. 

* Release names. 

#### Other

* Update readme. 

* Update core. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Merge pull request #56 from solokot/main. 
  _Improvement of Russian translation_

* Improvement of Russian translation. 
  _Basically a replacement for machine automatic translation_

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Fix bugs. 

* Change android signing. 

* Update README.md. 

* Update readme. 

* Update contribution guide. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update release_message.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update release template. 



## v0.8.11 (2023-10-08)

#### Changes

* Remove auto release message. 



## v0.8.10 (2023-10-08)

#### Fix

* Release changelog. 



## v0.8.9 (2023-10-08)

#### Fix

* Missing libs. 



## v0.8.8 (2023-10-08)

#### Fix

* Release bug. 



## v0.8.7 (2023-10-08)

#### Fix

* Release message. 



## v0.8.6 (2023-10-08)

#### Fix

* Windows build. 

* Build issue. 

#### Other

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Update release_message.md. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Update release_message.md. 

* Update README.md. 

* Update README_fa.md. 

* Delete docs/note. 

* Add files via upload. 

* Create note. 

* Update contribute.md. 

* Update README.md. 

* Delete assets/images/google-play-badge.png. 

* Update README_fa.md. 

* Update README.md. 

* Update release_message.md. 

* Update release_message.md. 

* Update release_message.md. 

* Fix build. 



## v0.8.5 (2023-10-07)

#### Fix

* Bug. 



## v0.8.4 (2023-10-07)

#### Fix

* Translate. 



## v0.8.3 (2023-10-07)

#### Other

* Add release message  and help. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Fix bugs. 

* Update release_message.md. 

* Update release_message.md. 

* Update README_fa.md. 

* Update README.md. 

* Update release_message.md. 

* Update release_message.md. 

* Create release_message.md. 

* Add google play badge to assets. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Create contribute.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README_fa.md. 

* Add feature request template. 

* Fix issue template. 

* Add issue template. 



## v0.8.2 (2023-10-07)

#### Fix

* Hysteria2 and some links. 

#### Other

* Update README_fa.md. 

* Update README_fa.md. 

* Update README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 

* Create README_fa.md. 

* Update README.md. 

* Update README.md. 

* Update README.md. 
  _Add some features to the readme_

* Add debug export to clipboard. 



## v0.8.1 (2023-10-06)

#### New

* Add chinese lang. 

#### Fix

* Chinese translation. 

#### Other

* Update core 0.5.1. 

* Fix floating number sub info header. 

* Add russian. 

* Add google play descriptions. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 



## v0.8.0 (2023-10-05)

#### New

* Add russian lang. 

#### Other

* Add proxy tag sanitization. 

* Fix bugs. 

* Add ignore app update version. 

* Add new protocols to link parser. 

* Auto update translations on release. 

* Update translation. 

* Remove param in ru translation. 



## v0.7.2 (2023-10-04)

#### Other

* Fix bugs. 



## v0.7.1 (2023-10-03)

#### Other

* Fix log and analytics bugs. 



## v0.7.0 (2023-10-03)

#### New

* Add support of some exception panel with zero usage. 

#### Other

* Fix translation bug. 

* Improve error handling and presentation. 

* Add retry for network ops. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add local profile. 

* Add auto translator. 

* Add auto translate. 



## v0.6.0 (2023-09-30)

#### Other

* Fix minor bugs. 

* Add scheduled profile update. 

* Update dependencies. 

* Refactor profile details page. 



## v0.5.11 (2023-09-22)

#### Other

* Fix android bundle abi. 

* Bump core version. 



## v0.5.10 (2023-09-22)

#### Other

* Fix minor bugs. 

* Fix profile update bug. 



## v0.5.9 (2023-09-22)

#### Other

* Add build number. 



## v0.5.8 (2023-09-22)

#### New

* Add crashlytics. 

* Add support for base64 sublink for header from content. 

* Add profile headers from comments in response! good for hosting in github and show information. 

* Automated version release. 

* Send release versions only to play market add pre-release version. 

#### Changes

* Change invalid dns 235.5.5.5 to 8.8.8.8. 

#### Fix

* Improve routing accessibility and logs. 

* Minor bugs. 

* Prefs persistence. 

* Crashlytics. 

* App update url. 

* Small profiles. 

* Makefile vars. 

* Adaptive icon. 

* Pre-release. 

* Typo in adaptive icon. 

* If .dev is exist in the version do not show update needed. 

* Keep the link as it is. fix the issue with & 

* Dependency issue. 

* Remove extra print. 

* Bug in get headers from body. 

* Bug ini ci to google play. 

* Tag version issue. 

* Ci bug. 

* Remove comments. 

* Bug. 

#### Other

* Fix ci. 

* Fix false-positive error reports. 

* Change build setup. 

* Fix minor bugs. 

* Refactor app update. 

* Fix sentry dart plugin upload. 

* Fix ci debug symbols upload. 

* Add sentry provider observer. 

* Ci: add sentry debug info upload. 

* Update dependencies and general fixes. 

* Chore: bump agp version. 

* Ci: fix env. 

* Ci: add dsn env. 

* Feat: add region and terms to intro. 

* Update ci.yml. 

* Build: add sentry dsn. 

* Feat: add intro screen. 

* Feat: add sentry. 

* Ci: bump macos version. 

* Feat: update profile when adding preexisting url. 

* Publish draft even with error. 

* Update version of core. 

* Merge branch 'main' of hiddify-github:hiddify/hiddify-next. 

* Add firebase. 

* Update translation. 

* Refactor: version presentation. 

* Perf: improve header parser. 

* Feat: remove check for updates in market releases. 

* Better manage the market release. 

* Update. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Improve accessability. 

* Fix per-app proxy selection. 

* Add android per-app proxy. 

* Add basic flavors. 

* Update Makefile. 

* Update ci.yml. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update ci.yml. 

* Update README.md. 

* Add accessability semantics. 

* Add support for fragment in the url. 



## v0.1.0 (2023-09-11)

#### New

* Add signing to android. 

* Add android universal build also. 

* Add change in network entitlements. 

* Change logo icon to next. 

* Add cache for speed up build process. 

* Add windows portable version. 

* Add libclash. 

* Add as draft release. 

* Make better ci and building applications. 

#### Changes

* Change windows logo. 

* Change macos build  to flutter_distributor. 

* Remove x86 builds since flutter does not support. 

* Add x64 to the name. 

* Update makefile. 

#### Fix

* Space bugs in some panels. 

* Aab. 

* Aab build. 

* Universal sign. 

* KeystoreProperties. 

* Name issue. 

* Revert package name change. 

* Name. 

* Geosite download. 

* Windows portable bug. 

* Change name bug. 

* Setup exe files. 

* Libclash.so. 

* Linux AppImage. 

* Error. 

* Category in linux. 

* Add fuse for linux. 

* Icon. 

* Linux logo. 

* Android. 

* Makefile error. 

#### Other

* Release v0.1.0. 

* Fix ci build. 

* Update ci. 

* Add core version. 

* Fix barrel file. 

* Change proxies lifecycle. 

* Add service restart. 

* Remove notification service. 

* Change android notification permission. 

* Add android service restart. 

* Change mark new profile active. 

* Handle unlimited. 

* Update upload download link stats. 

* Update Translations. 

* Remove // TODO add content disposition parsing. 

* Add content-disposition for profile title. 

* Update README.md. 

* Add hysteria2. 

* Fix android build connection. 

* Add android connection shortcut. 

* Add desktop autostart. 

* Add android boot receiver. 

* Add android proxy service. 

* Add android battery optimizations settings. 

* Change sharedpreferences to unify with android. 

* Add vclibs. 

* Update dependencies. 

* Add submodule. 

* Fix translation code gen. 

* Change prefs. 

* Change default config options. 

* Remove string casing. 

* Update ci.yml. 

* Remove caching. 

* Change core prefs to use code generation. 

* Fix custom lint. 

* Fix general issues. 

* Remove vclibs. 

* Update README.md. 

* Fix blank screen. 

* Add proxies sort. 

* Refactor preferences. 

* Update dependencies. 

* Add more config options to settings. 

* Add tun implementation option. 

* Add android power manager. 

* Add android quick tile. 

* Fix macos dependencies. 

* Fix mac build. 

* Fix build. 

* Change system tray icon. 

* Fix riverpod code generation. 

* Remove unnecessary config options. 

* Add accessability semantics. 

* Update dependencies. 

* Add config options. 

* Add pref utilities. 

* Add stats overview. 

* Update Translations. 

* Fix android outbounds view. 

* Remove unnecessary options. 

* Change proxies flow. 

* Add android command client support. 

* Update README.md. 

* Add status command receiver. 

* Add hiddify deeplink. 

* Add macos deeplink support. 

* Add singbox deeplink. 

* Change error prompts. 

* Fix url parser. 

* Remove unnecessary prefs. 

* Update dependencies. 

* Make AppImage zipped for preserving permission in linux. 

* Add user agent. 

* Fix uri launch. 

* Update ci flutter version. 

* Fix macos silent start. 

* Change proxies page. 

* Fix desktop connection error msg. 

* Add button tooltips. 

* Fix logging. 

* Create dependabot.yml. 

* Create CODE_OF_CONDUCT.md. 

* Fix aab. 

* Add aab file. 

* Change windows-portable name to HiddifyNext-portable. 

* Add debug mode. 

* Add misc settings ui. 

* Remote unnecessary logs. 

* Add misc preferences. 

* Add directory options. 

* Fix linux build. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Fix android builds. 

* Fix android splash screen. 

* Update icons. 

* Fix windows executable build. 

* Remove unnecessary build steps. 

* Remove build number from appbar. 

* Update readme. 

* Change desktop directories. 

* Remove desktop notifications. 

* Force same version code for all platforms. 

* Add more logs. 

* Add log timestamp. 

* Update icons. 

* Remove drawer branding. 

* Add download section in readme. 

* Fix name of universal apk. 

* Fix order. 

* Update readme. 

* Update logging. 

* Update geo assets url. 

* Change linux directories. 

* Update icon. 

* Update icon. 

* Update logo for all platforms. 

* Revert name in macos. 

* Temporary disable app sandbox. 

* Change name. 

* Update Release.entitlements to fix binding issue. 

* Merge pull request #5 from evstegneych/main. 
  _add macos option_

* Add macos option. 

* Update ci flutter version. 

* Update kotlin version. 

* Update other dependencies. 

* Update dependencies. 

* Update flutter version. 

* Update LICENSE.md. 

* Add build option for ios but not tested. 

* Return: build for all. 

* Fix build for macos. 

* Fix ci. 

* Migrate to singbox. 

* Fix routing. 

* Fix connection button text casing. 

* Add update checking. 

* Add separate page for clash overrides. 

* Add version number to appbar. 

* Add more icons. 

* Add sort limited profiles last. 

* Fix profile sort icon. 

* Fix profile traffic ratio. 

* Add profiles sort option. 

* Refactor profile addition flow. 

* Add extra profile metadata. 

* Fix linux deep link service. 

* Refactor profile tile. 

* Add locale based font. 

* Fix linux startup. 

* Update dependencies. 

* Add about page. 

* Fix linux notifications. 

* Build all. 

* Hard coding. 

* Add png. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update ci.yml. 

* Update Makefile. 

* Update ci.yml. 

* Update Makefile. 

* Fix makefile. 

* Fix actions. 

* Fix actions. 

* Fix actions. 

* Update build setup. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Create LICENSE.md. 

* Add core submodule. 

* Remove core libs. 

* Update Makefile. 

* Update Makefile. 

* Remove c install. 

* Update make. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Add Persian font. 

* Update dependencies. 

* Update to libclash. 

* Add cache. 

* Add: new action. 

* Add write permission. 

* Fix. 

* Modify. 

* Fix. 

* Update. 

* Fix android build. 

* Fix code gen bug. 

* Update ci.yml. 

* Update ci.yml. 

* Fix CI. 

* Fix CI. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Update ci.yml. 

* Update ci.yml. 

* Fix CI. 

* Update ci.yml. 

* Update ci.yml. 

* Add CI. 

* Add silent start for desktop. 

* Update readme. 

* Add headless mode to desktop. 

* Update dependencies. 

* Add distribution setup for windows. 

* Add Farsi(fa) language. 

* Merge branch 'main' of https://github.com/hiddify/hiddify-next. 

* Initial commit. 

* Initial. 



