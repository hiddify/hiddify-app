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

## Local development without a paid Apple team

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
cannot authorize this system extension. The experimental local build below is
separate from this supported signing path.

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

## Experimental local VPN testing without a paid team

`scripts/local-vpn.sh` builds a separate ad hoc signed Debug app with the provider
embedded and restricted entitlements present. It uses app identifier
`app.hiddify.com.local`, extension identifier
`app.hiddify.com.local.HiddifyPacketTunnel` and group
`group.app.hiddify.com.local.vpn`. Your ordinary Hiddify installation and VPN
configuration have different identifiers. Import a test profile into this app.

The Swift signing exception requires the explicit
`HIDDIFY_LOCAL_NETWORK_EXTENSION` compilation flag, `DEBUG`, a local-build
marker and an ad hoc signature. A non-Debug build with that flag fails to compile.
An ordinary Debug, Profile or Release build keeps the team requirement.
No local machine xcconfig is created or modified by the script.

This is an experiment, not a verified replacement for Apple provisioning. It
requires relaxing validation on the test Mac. SIP being disabled does not promise
that NetworkExtension or AMFI will accept an ad hoc provider on every macOS
version. Apple documents development validation switches in
[Debugging and testing system extensions](https://developer.apple.com/documentation/driverkit/debugging-and-testing-system-extensions).
The script never changes SIP, AMFI, boot arguments or developer mode, and never
launches the app.

1. Prepare the app while normal security is still enabled:

   ```sh
   bash macos/scripts/local-vpn.sh --build
   ```

   It prepares Flutter/Pods and the tunnel framework, compiles into an isolated
   DerivedData directory, signs nested code and verifies the bundle. Output:
   `build/macos/local-vpn/HiddifyLocalVPN.app`. Build log:
   `build/macos/local-vpn/build.log`. Signing does not authorize activation.

2. On an Apple silicon test Mac, shut down, hold the power button until startup
   options appear, select Options and enter Recovery. Open Utilities > Terminal,
   run `csrutil disable`, follow its prompts, then restart. On Intel, use
   Command-R to enter Recovery. These are temporary system security changes;
   use a disposable machine or VM where possible. Recovery can reject this
   change on some OS/security configurations; stop if it does.

3. Back in macOS, from the repository root:

   ```sh
   bash macos/scripts/local-vpn.sh --check
   sudo systemextensionsctl developer on
   bash macos/scripts/local-vpn.sh --install
   open /Applications/HiddifyLocalVPN.app
   ```

   Developer mode permits activation outside `/Applications` and simplifies
   development updates; it does not grant Network Extension entitlements.
   The install step requires SIP to be disabled, verifies the build and copies
   only the test app. It backs up a previous installation of this same test app.
   Launch the app as your user, without sudo. Approve the system extension in
   System Settings, connect again, and approve the VPN configuration prompt.
   Settings locations vary by macOS version; follow the activation prompt.

4. Verify actual VPN behavior. In VPN mode, `systemextensionsctl list` should
   show `app.hiddify.com.local.HiddifyPacketTunnel` activated and enabled.
   Confirm traffic follows your profile, DNS works, and the tunnel stays
   connected after quitting the app. Reopen it to check status restoration,
   disconnect, then reconnect. Record the OS version and observed results in
   your PR. Do not describe compilation alone as live VPN validation.

5. If macOS refuses to launch or activate the provider, do not assume the VPN
   engine is broken. Collect the signing/activation error before making further
   system changes:

   ```sh
   log show --last 5m --style compact \
     --predicate 'process == "sysextd" OR process == "amfid" OR process == "taskgated-helper" OR process == "nesessionmanager" OR subsystem == "com.apple.networkextension"'
   ```

   Review logs for private network information before attaching them to a PR.
   A signature/provisioning rejection means the local experiment has not
   reached the provider. The script does not disable AMFI to work around it.

6. When finished, disconnect the test VPN and remove its VPN configuration and
   test network extension in System Settings. Turn off development mode with
   `sudo systemextensionsctl developer off`, remove only
   `/Applications/HiddifyLocalVPN.app`, then return to Recovery, run
   `csrutil enable` and restart. Confirm `csrutil status` reports enabled.
   Remove the test provider before restoring security because its ad hoc
   signature is not valid for ordinary deployment.

Upstream users still require valid signing/provisioning. The local signing
exception is not enabled by the default project configuration; production
validation must use a signed installation with normal macOS security enabled.

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
