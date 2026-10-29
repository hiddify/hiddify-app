#!/bin/bash
set -euo pipefail

# Embeds the one VPN engine this build uses, and removes the others a previous build left:
#   Developer ID       packet tunnel system extension, in Contents/Library/SystemExtensions
#   Mac App Store      packet tunnel app extension, in Contents/PlugIns (AppStore.xcconfig)
#   no Developer ID    install scripts of hiddify-core's tunnel service, in Contents/Resources/TunnelService

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_resources="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
task_system_extension="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Library/SystemExtensions/${HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER}.systemextension"
task_app_extension="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/PlugIns/HiddifyPacketTunnel.appex"
task_service_destination="$task_resources/TunnelService"
task_migration="$task_resources/container-migration.plist"

# LaunchAtLogin rewrites its helper's bundle identifier, then re-signs it by the signing identity's
# name. That fails without a name (ad hoc) or when two certificates share it, leaving a signature
# that no longer matches. Sign it again by the identity's hash before Xcode signs the app around it.
task_login_helper="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Library/LoginItems/LaunchAtLoginHelper.app"
if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && -d "$task_login_helper" ]]; then
  task_login_entitlements="$BUILT_PRODUCTS_DIR/LaunchAtLogin_LaunchAtLogin.bundle/Contents/Resources/LaunchAtLogin.entitlements"
  if [[ -f "$task_login_entitlements" ]]; then
    codesign --force --deep --options=runtime --entitlements "$task_login_entitlements" \
      --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$task_login_helper"
  else
    codesign --force --deep --options=runtime --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$task_login_helper"
  fi
fi

if [[ "${HIDDIFY_NETWORK_EXTENSION_ENABLED:-NO}" != YES ]]; then
  rm -rf "$task_system_extension" "$task_app_extension" "$task_migration" "$task_resources/TunnelHelper"
  rmdir "$(dirname "$task_system_extension")" "$(dirname "$task_app_extension")" 2>/dev/null || true
  # Without a Network Extension the VPN runs in hiddify-core's tunnel service: the app's executable
  # as `Hiddify --tunnel run`, installed as root from the app with an administrator password.
  mkdir -p "$task_service_destination"
  # Bundle under Resources/TunnelService so existing installs and method-channel paths stay stable.
  install -m 755 "$task_root/macos/AdminBgService/install-admin-bgservice.sh" \
    "$task_service_destination/install-tunnel-service.sh"
  install -m 755 "$task_root/macos/AdminBgService/uninstall-admin-bgservice.sh" \
    "$task_service_destination/uninstall-tunnel-service.sh"
  exit 0
fi

# Signed builds have a Network Extension instead of the tunnel service.
rm -rf "$task_service_destination"

if [[ "${HIDDIFY_TUNNEL_KIND:-system-extension}" == app-extension ]]; then
  rm -rf "$task_system_extension"
  rmdir "$(dirname "$task_system_extension")" 2>/dev/null || true
  task_source="$BUILT_PRODUCTS_DIR/HiddifyPacketTunnel.appex"
  if [[ ! -d "$task_source" ]]; then
    echo "error: Packet tunnel app extension was not built: $task_source" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$task_app_extension")"
  ditto "$task_source" "$task_app_extension"
  # The sandboxed app moves the data of an earlier unsandboxed install into its container.
  install -m 644 "$task_root/macos/Runner/container-migration.plist" "$task_migration"
  exit 0
fi

rm -rf "$task_app_extension" "$task_migration"
rmdir "$(dirname "$task_app_extension")" 2>/dev/null || true
task_source="$BUILT_PRODUCTS_DIR/${HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER}.systemextension"
if [[ ! -d "$task_source" ]]; then
  echo "error: Packet tunnel extension was not built: $task_source" >&2
  exit 1
fi
mkdir -p "$(dirname "$task_system_extension")"
ditto "$task_source" "$task_system_extension"
