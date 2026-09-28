#!/bin/bash
# An opt-in, ad hoc signed Debug build for experiments on a SIP-disabled Mac.
# This script never changes SIP, AMFI, boot arguments or system-extension mode.
set -euo pipefail

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_output="$task_root/build/macos/local-vpn"
task_app="$task_output/HiddifyLocalVPN.app"
task_app_id=app.hiddify.com.local
task_extension_id=app.hiddify.com.local.HiddifyPacketTunnel
task_group=group.app.hiddify.com.local.vpn
task_action="${1:---build}"

fail() { echo "error: $*" >&2; exit 1; }

check_test_environment() {
  local task_sip
  task_sip="$(/usr/bin/csrutil status)"
  echo "$task_sip"
  case "$task_sip" in
    *"status: disabled."*) ;;
    *) fail "Local ad hoc VPN testing requires a SIP-disabled test Mac. See macos/NETWORK_EXTENSION.md. No system settings were changed." ;;
  esac
  echo 'SIP is disabled. macOS may still reject the ad hoc provider; live activation is experimental.'
}

verify_app() {
  [[ -d "$task_app" ]] || fail "Build the test app first: bash macos/scripts/local-vpn.sh --build"
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$task_app/Contents/Info.plist")" == "$task_app_id" ]] || fail 'Unexpected test app identifier.'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :HiddifyLocalNetworkExtensionBuild' "$task_app/Contents/Info.plist")" == YES ]] || fail 'This is not a local VPN test build.'
  /usr/bin/codesign --verify --deep --strict "$task_app"
}

case "$task_action" in
  --check)
    check_test_environment
    exit 0
    ;;
  --install)
    check_test_environment
    verify_app
    task_destination=/Applications/HiddifyLocalVPN.app
    if [[ -e "$task_destination" ]]; then
      [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$task_destination/Contents/Info.plist")" == "$task_app_id" ]] || fail "Refusing to replace another app at $task_destination."
      mv "$task_destination" "$task_output/previous-installed-$(date +%s).app"
    fi
    /usr/bin/ditto "$task_app" "$task_destination"
    printf 'Installed %s.\nLaunch it normally (without sudo), approve its extension and VPN configuration, then connect.\n' "$task_destination"
    exit 0
    ;;
  --build) ;;
  *) fail 'Usage: bash macos/scripts/local-vpn.sh [--build | --check | --install]' ;;
esac

[[ "$(uname -s)" == Darwin ]] || fail 'The local VPN build requires macOS.'
task_arch="$(uname -m)"
case "$task_arch" in arm64|x86_64) ;; *) fail "Unsupported Mac architecture: $task_arch" ;; esac
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
mkdir -p "$task_output"
cd "$task_root"
flutter pub get > "$task_output/flutter-pub.log" 2>&1 || { cat "$task_output/flutter-pub.log" >&2; exit 1; }
if [[ ! -f "$task_root/hiddify-core/bin/hiddify-core.dylib" ]]; then
  make macos-libs
fi
bash macos/scripts/build-tunnel-core.sh
(cd macos && pod install) > "$task_output/pods.log" 2>&1 || { cat "$task_output/pods.log" >&2; exit 1; }

# Command-line settings take precedence over optional personal signing overrides.
# Xcode compiles unsigned; below we sign the test bundle ourselves, with no team.
echo "Building the local VPN app for $task_arch. Log: $task_output/build.log"
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination "platform=macOS,arch=$task_arch" \
  -derivedDataPath "$task_output/DerivedData" \
  "ARCHS=$task_arch" ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- \
  DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER= \
  HIDDIFY_NETWORK_EXTENSION_ENABLED=YES \
  HIDDIFY_HOST_ENTITLEMENTS=Runner/DebugProfile.entitlements \
  HIDDIFY_LOCAL_NETWORK_EXTENSION_BUILD=YES \
  "HIDDIFY_APP_BUNDLE_IDENTIFIER=$task_app_id" \
  "HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER=$task_extension_id" \
  "HIDDIFY_VPN_APP_GROUP=$task_group" \
  HIDDIFY_NETWORK_EXTENSION_ENTITLEMENT=packet-tunnel-provider \
  'OTHER_SWIFT_FLAGS=$(inherited) -D HIDDIFY_LOCAL_NETWORK_EXTENSION' \
  build > "$task_output/build.log" 2>&1 || { tail -n 100 "$task_output/build.log" >&2; exit 1; }

task_built_app="$task_output/DerivedData/Build/Products/Debug/Hiddify.app"
[[ -d "$task_built_app" ]] || fail "Xcode did not produce $task_built_app."
# Replace only this script's generated artifact, never an installed application.
rm -rf "$task_app"
/usr/bin/ditto "$task_built_app" "$task_app"

/usr/bin/python3 - "$task_root" "$task_app" "$task_output" "$task_extension_id" "$task_group" <<'PY'
import pathlib
import plistlib
import subprocess
import sys

root, app, output = map(pathlib.Path, sys.argv[1:4])
extension_id, group = sys.argv[4:6]
extension = app / 'Contents/Library/SystemExtensions' / (extension_id + '.systemextension')
if not extension.is_dir():
    raise SystemExit('The local packet tunnel extension was not embedded.')

replacements = {
    '$(HIDDIFY_NETWORK_EXTENSION_ENTITLEMENT)': 'packet-tunnel-provider',
    '$(HIDDIFY_VPN_APP_GROUP)': group,
}

def expand(value):
    if isinstance(value, dict):
        return {key: expand(item) for key, item in value.items()}
    if isinstance(value, list):
        return [expand(item) for item in value]
    if isinstance(value, str):
        for key, item in replacements.items():
            value = value.replace(key, item)
        if '$(' in value:
            raise ValueError('Unexpanded entitlement: ' + value)
    return value

def entitlements(source, filename):
    with source.open('rb') as stream:
        values = expand(plistlib.load(stream))
    path = output / filename
    with path.open('wb') as stream:
        plistlib.dump(values, stream)
    return path

host_entitlements = entitlements(root / 'macos/Runner/DebugProfile.entitlements', 'host.entitlements')
tunnel_entitlements = entitlements(root / 'macos/HiddifyPacketTunnel/HiddifyPacketTunnel.entitlements', 'tunnel.entitlements')

with (app / 'Contents/Info.plist').open('rb') as stream:
    info = plistlib.load(stream)
if info.get('CFBundleIdentifier') != 'app.hiddify.com.local' or info.get('HiddifyLocalNetworkExtensionBuild') != 'YES':
    raise SystemExit('Unexpected local build settings; refusing to sign.')
info['CFBundleDisplayName'] = 'Hiddify Local VPN'
with (app / 'Contents/Info.plist').open('wb') as stream:
    plistlib.dump(info, stream)

with (extension / 'Contents/Info.plist').open('rb') as stream:
    tunnel_info = plistlib.load(stream)
if tunnel_info.get('CFBundleIdentifier') != extension_id or tunnel_info['NetworkExtension']['NEMachServiceName'] != group + '.HiddifyPacketTunnel':
    raise SystemExit('Unexpected local extension identifier or Mach service.')

def sign(path, entitlement_file=None):
    command = ['/usr/bin/codesign', '--force', '--sign', '-', '--timestamp=none']
    if entitlement_file:
        command += ['--entitlements', str(entitlement_file)]
    else:
        command += ['--preserve-metadata=entitlements']
    subprocess.run(command + [str(path)], check=True, stdout=subprocess.DEVNULL)

# Sign nested executable bundles and libraries inside-out. Do not use --deep
# signing, which would give the provider the host's different entitlements.
objects = set()
for path in app.rglob('*'):
    if path.is_symlink():
        continue
    if path.is_file() and path.suffix == '.dylib':
        objects.add(path)
    elif path.is_dir() and path.suffix in {'.app', '.framework', '.xpc', '.appex', '.bundle'}:
        for plist in (path / 'Contents/Info.plist', path / 'Resources/Info.plist', path / 'Info.plist'):
            if plist.exists():
                with plist.open('rb') as stream:
                    nested_info = plistlib.load(stream)
                if nested_info.get('CFBundleExecutable'):
                    objects.add(path)
                break
for path in sorted(objects, key=lambda item: len(item.parts), reverse=True):
    sign(path)
sign(extension, tunnel_entitlements)
sign(app, host_entitlements)
PY

verify_app
printf '\nBuilt %s\nNo app was launched or installed; no system settings were changed.\n' "$task_app"
echo 'On your test Mac, check the environment and install with:'
echo '  bash macos/scripts/local-vpn.sh --check'
echo '  bash macos/scripts/local-vpn.sh --install'
