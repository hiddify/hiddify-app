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
the imported Developer ID identity. The workflow fails explicitly if the signing
configuration is absent. Signing credentials and personal overrides belong in
CI secrets or the ignored local xcconfig, never in the repository. Release owners
must notarize the signed app before distributing it; the existing packaging
workflow does not perform notarization. iOS certificates and profiles do not
establish authorization for a native macOS system extension.

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
