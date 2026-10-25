#!/bin/bash
set -euo pipefail

# Builds a macOS release on this Mac, as CI does:
#   dist.sh unsigned               dmg and pkg signed ad hoc; the VPN runs in hiddify-core's tunnel
#                                  service, installed with an administrator password.
#   dist.sh developer-id           dmg and pkg signed with the Developer ID and notarized; the VPN runs
#                                  in the system extension. NetworkExtension.local.xcconfig names the
#                                  Developer ID profiles, and Notarization.local.env (or the
#                                  environment) holds APPLE_MACOS_INSTALLER_SIGN_IDENTITY and the
#                                  APPLE_NOTARIZATION_* values.
#   dist.sh app-store [--upload]   the sandboxed Mac App Store pkg and a companion dmg
#                                  (AppStore.xcconfig names its profiles). --upload sends the pkg to
#                                  App Store Connect / TestFlight. The upload reads APPSTORE_API_KEY_ID,
#                                  APPSTORE_ISSUER_ID and either APPSTORE_API_PRIVATE_KEY or
#                                  ~/.appstoreconnect/private_keys/AuthKey_<id>.p8, from the environment
#                                  or AppStore.local.env.
# Other arguments go to fastforge. SENTRY_DSN, when set, is compiled in.

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_mode="${1:-}"
shift || true
cd "$task_root"

load_env() {
  if [[ -f "$1" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "$1"
    set +a
  fi
}

task_version="$(grep '^version:' pubspec.yaml | sed -E 's/version: *//')"
task_out="$task_root/dist/$task_version"
task_app="build/macos/Build/Products/Release/Hiddify.app"

bash macos/scripts/build-admin-bgservice-core.sh
case "$task_mode" in
  unsigned)
    export XCODE_XCCONFIG_FILE="$task_root/macos/Runner/Configs/Unsigned.xcconfig"
    ;;
  developer-id)
    load_env "$task_root/macos/Runner/Configs/Notarization.local.env"
    unset XCODE_XCCONFIG_FILE
    ;;
  app-store)
    load_env "$task_root/macos/Runner/Configs/AppStore.local.env"
    task_upload=false
    [[ "${1:-}" == --upload ]] && task_upload=true
    export XCODE_XCCONFIG_FILE="$task_root/macos/Runner/Configs/AppStore.xcconfig"
    task_identity="${APPLE_MAS_INSTALLER_SIGN_IDENTITY:-$(security find-identity -v | sed -nE 's/.*"(3rd Party Mac Developer Installer: [^"]*)".*/\1/p' | head -1)}"
    if [[ -z "$task_identity" ]]; then
      echo 'error: Import the "3rd Party Mac Developer Installer" certificate, or set APPLE_MAS_INSTALLER_SIGN_IDENTITY.' >&2
      exit 1
    fi
    "${FLUTTER:-flutter}" build macos --release --dart-define release=app-store --dart-define "sentry_dsn=${SENTRY_DSN:-}"
    mkdir -p "$task_out"
    task_pkg="$task_out/hiddify-$task_version-macos-appstore.pkg"
    task_dmg="$task_out/hiddify-$task_version-macos-appstore.dmg"
    productbuild --component "$task_app" /Applications --sign "$task_identity" "$task_pkg"
    task_stage="$(mktemp -d)"
    trap 'rm -rf "$task_stage"' EXIT
    ditto "$task_app" "$task_stage/Hiddify.app"
    ln -s /Applications "$task_stage/Applications"
    hdiutil create -volname Hiddify -srcfolder "$task_stage" -format UDZO -ov "$task_dmg" >/dev/null
    rm -rf "$task_stage"
    trap - EXIT
    echo "Built $task_pkg"
    echo "Built $task_dmg"
    if [[ "$task_upload" == true ]]; then
      bash "$task_root/macos/scripts/upload-appstore.sh" "$task_pkg"
    fi
    exit 0
    ;;
  *)
    echo 'usage: dist.sh unsigned|developer-id|app-store [--upload] [fastforge arguments]' >&2
    exit 2
    ;;
esac

rm -rf "$task_out"/*macos*.dmg "$task_out"/*macos*.pkg "$task_out"/*macos_dmg "$task_out"/*macos_pkg
fastforge package --platform macos --targets pkg "$@"
task_pkg="$(ls "$task_out"/*macos.pkg)"
# CI makes the dmg with fastforge's appdmg, which current Node versions cannot run; hdiutil needs nothing.
task_dmg="${task_pkg%.pkg}.dmg"
task_stage="$(mktemp -d)"
trap 'rm -rf "$task_stage"' EXIT
ditto "$task_app" "$task_stage/Hiddify.app"
ln -s /Applications "$task_stage/Applications"
hdiutil create -volname Hiddify -srcfolder "$task_stage" -format UDZO -ov "$task_dmg" >/dev/null
if [[ "$task_mode" == developer-id ]]; then
  bash macos/scripts/notarize-release.sh "$task_dmg" "$task_pkg"
fi
echo "Built $task_dmg"
echo "Built $task_pkg"
