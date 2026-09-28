# macOS VPN system extension

VPN mode runs the core in `HiddifyPacketTunnel.systemextension`. Runner uses
`NETunnelProviderManager` to create, save, start and stop its VPN configuration.
The normal Flutter app runs as the logged-in user. macOS manages the extension
process and the utun interface. Proxy and system-proxy modes use the app core.

The saved VPN configuration contains the profile content, connection settings,
local rule-set/certificate snapshots and control credentials. It does not depend
on a profile path inside Runner's container. VPN can reconnect on demand with
Runner closed. Quit leaves a system VPN connected; Disconnect disables on demand
and stops it. Reopening Runner restores the VPN status, statistics and proxy
selection. Changing modes or profiles stops the previous engine first.

## Build prerequisites

Use macOS 12 or newer, Xcode, Flutter, CocoaPods and Go with toolchain downloads
enabled. The first build needs internet access to download pinned source and Go
dependencies. From the repository root:

```sh
flutter pub get
make macos-libs
cd macos
pod install
cd ..
```

`make macos-libs` prepares both the existing desktop dylib and the extension's
`Frameworks/HiddifyTunnelCore.xcframework`. Xcode's Build Tunnel Core phase keeps
the latter current. Generated frameworks and source/tool caches are ignored.
The extension uses the exact core 4.1.0 release and its submodule commits, with
Go 1.25.6, independently of the development core checkout. To upgrade it, update
the commits in `scripts/prepare-tunnel-source.sh`, its revision marker, the wrapper
Go dependencies/toolchain and `dependencies.properties` together.

## Development without VPN entitlements

Debug defaults to `HIDDIFY_NETWORK_EXTENSION_ENABLED=NO`. It compiles the
extension but omits it from Runner and signs Runner with Developer.entitlements,
which contain no restricted Network Extension capabilities. Ordinary Debug
development and proxy modes remain available. Selecting VPN shows a signing
requirement instead of attempting the old root TUN implementation.

```sh
flutter build macos --debug
```

On toolchains where Flutter cannot interpret a universal Xcode ARCHS value, use
Xcode's My Mac destination, or specify one architecture explicitly for a compile:

```sh
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build
```

## Signed VPN development and distribution

With normal macOS security enabled, Network Extension activation requires an
authorized Apple Developer Program team. An ad hoc signature or Personal Team
cannot authorize this system extension.

1. Copy `Runner/Configs/NetworkExtension.local.xcconfig.example` to
   `Runner/Configs/NetworkExtension.local.xcconfig`, enter your team, and enable
   the Debug overrides. The local file is ignored by Git. Open Runner.xcworkspace.
2. Enable Network Extensions (Packet Tunnel) for Runner and HiddifyPacketTunnel,
   and System Extension installation for Runner, using the same team. Their
   Debug entitlements use `packet-tunnel-provider` and the same
   team-prefixed `app.hiddify.com.vpn` group. Keep NEMachServiceName under that group.
3. Keep `HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER` and your registered extension App ID in
   agreement. Give both targets valid signing identities/profiles. Profile and
   Release include the system extension by default; for direct distribution use
   Developer ID Application signing, the required profiles and notarization.
   These configurations default to `packet-tunnel-provider-systemextension`.
   For Apple Development or App Store signing in another configuration, set
   `HIDDIFY_NETWORK_EXTENSION_ENTITLEMENT=packet-tunnel-provider` instead.
4. Install the signed app in `/Applications`, start it normally and select VPN.
   Approve system extension installation in System Settings if prompted, then
   connect again. Accept the separate VPN configuration permission. If macOS
   requests a reboot for an upgrade, reboot before reconnecting.

Activation, approval, reboot, connection and startup failures are returned through
the Flutter bridge. Extension diagnostics appear in Console under
HiddifyPacketTunnel. Do not log providerConfiguration: it contains credentials.

An unsigned compilation with `CODE_SIGNING_ALLOWED=NO` verifies compilation and
packaging only; it does not authorize installation or a live VPN connection.

## CI and release signing

PR builds compile and embed the extension with `CODE_SIGNING_ALLOWED=NO`.
They check compilation and packaging, and cannot activate a VPN.
The workflow installs the pinned Go toolchain before building the tunnel core.

Published macOS builds require the existing certificate/profile secrets plus
`APPLE_MACOS_SIGNING_XCCONFIG`, containing the release settings for both targets:

```xcconfig
DEVELOPMENT_TEAM = YOURTEAMID
HIDDIFY_CODE_SIGN_STYLE = Manual
HIDDIFY_CODE_SIGN_IDENTITY = Developer ID Application
HIDDIFY_HOST_PROVISIONING_PROFILE = YOUR_HOST_PROFILE_NAME
HIDDIFY_TUNNEL_PROVISIONING_PROFILE = YOUR_TUNNEL_PROFILE_NAME
```

Both profiles must authorize the entitlements and bundle IDs above, and match
the imported Developer ID identity. Profile and Release enable hardened runtime
for Runner and the extension and disable injected development entitlements.
Debug keeps hardened runtime disabled for ordinary local development.

### Maintainer setup for published releases

The repository contains build settings and release automation. The Hiddify
release maintainers must supply their team's certificates, private keys,
provisioning profiles and notarization credentials; contributors do not need
access to these to build or submit a PR.

Configure these GitHub Actions secrets before publishing macOS artifacts:

| Secret | Required value |
| --- | --- |
| `APPLE_CERTIFICATE_P12` | Base64 PKCS#12 export containing the team's Developer ID Application and Developer ID Installer certificates **with their private keys**. |
| `APPLE_CERTIFICATE_P12_PASSWORD` | Password protecting that PKCS#12 export. |
| `APPLE_MOBILE_PROVISIONING_PROFILES_TARGZ_BASE64` | Existing base64 tar.gz secret, including the native macOS Developer ID profiles for both Runner and HiddifyPacketTunnel. |
| `APPLE_MACOS_SIGNING_XCCONFIG` | The team, manual signing and profile settings shown above. |
| `APPLE_MACOS_INSTALLER_SIGN_IDENTITY` | Full installer identity, for example `Developer ID Installer: YOUR ORGANIZATION (YOURTEAMID)`. |
| `APPLE_NOTARIZATION_APPLE_ID` | Apple ID authorized to notarize for the release team. |
| `APPLE_NOTARIZATION_TEAM_ID` | The same team ID used for signing. |
| `APPLE_NOTARIZATION_PASSWORD` | An app-specific password for that Apple ID, generated through the Apple Account site. |

Register both App IDs and their shared app group for that team. The Runner
profile needs Network Extensions and System Extension installation; the tunnel
profile needs Network Extensions. Both must authorize the same team-prefixed
`app.hiddify.com.vpn` group and `packet-tunnel-provider-systemextension` value.
iOS certificates and profiles do not authorize a native macOS system extension.

The workflow signs the installer with Developer ID Installer, submits both DMG
and PKG to Apple's notary service, requires an `Accepted` result, then staples and
validates their tickets before uploading the macOS artifact. A missing secret,
signing failure, rejected submission or timeout fails that macOS build and prevents
uploading its packages. PR builds skip signing and notarization and need no secrets.

For a local maintainer release, build with the ignored local signing xcconfig,
set the four installer/notarization environment variables listed above, and run:

```sh
bash macos/scripts/notarize-release.sh path/to/Hiddify-MacOS.dmg path/to/Hiddify-MacOS-Installer.pkg
```

Keep credentials in CI secrets, a password manager or the ignored local xcconfig.
Do not commit certificates, private keys, passwords or provisioning profiles.
Before distributing a release, maintainers must verify the signed app on a Mac
with normal security settings: install in `/Applications`, approve the extension
and VPN configuration, connect, disconnect, change modes and reopen the app.
Unsigned compilation cannot verify signing, OS approval or live tunnel behavior.

Apple documents the requirements in [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
and [Network Extensions entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.networkextension).

## Implementation boundaries

* The extension's loopback gRPC service authenticates unary and streaming calls
  using a random 256-bit secret. It allows statistics, logs, URL tests and proxy
  selection. Lifecycle, arbitrary paths/configuration, system proxy and unknown
  RPCs are denied. Start/stop/configuration changes go through NetworkExtension.
* The extension writes its own private working/cache files. Local rule sets and
  TLS/SSH key paths are copied into a snapshot, limited to 32 MB in total. Use
  remote rule sets for larger resources. HTTP transport paths are not file paths.
* Routing, IPv4/IPv6 addresses and DNS come from libbox TunOptions. The platform
  adapter supplies the utun descriptor, interfaces and network-change monitoring.
  It excludes utun from the underlying interface used to reach the VPN server.
* Process ownership and Wi-Fi SSID rules are not available through this adapter.
  `includeAllNetworks` is false; this implementation makes no kill-switch claim.
* This target is a macOS system extension for the native app. The iOS/iPadOS
  App Store packet-tunnel extension and the Windows/Linux paths are unchanged.

## Compilation and stability checks

```sh
bash macos/scripts/build-tunnel-core.sh
xcodebuild -project macos/Runner.xcodeproj -target HiddifyPacketTunnel \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
cd macos/NetworkExtensionCore
GOTOOLCHAIN=go1.25.6 go test \
  -tags 'with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,with_grpc,with_awg,tfogo_checklinkname0,with_naive_outbound,with_conntrack,with_dhcp' \
  -ldflags '-checklinkname=0' .
```

The Go tests validate startup compatibility, authentication and the privileged
RPC boundary without opening a tunnel. Live routing/DNS, reconnection, upgrades
and OS approval still need an accepted installation on a Mac. Production
validation requires authorized signing and normal macOS security enabled.
