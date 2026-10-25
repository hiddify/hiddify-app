#!/bin/bash
set -euo pipefail

# Installs the VPN service of builds without a Developer ID: the app's own executable, run as
# `Hiddify --tunnel run` by launchd with administrator rights, which runs the full core. Hiddify runs
# this with an administrator password; by hand:
#   sudo "/Applications/Hiddify.app/Contents/Resources/TunnelService/install-tunnel-service.sh" \
#     /Applications/Hiddify.app "$USER"

task_source="${1:-}"
task_owner="${2:-${SUDO_USER:-}}"
# Copied app + data live under AdminBgService (matches Go controlDataDir / serviceDataDirectory).
task_destination="/Library/Application Support/Hiddify/AdminBgService/Hiddify.app"

if [[ "$(id -u)" != 0 ]]; then
  echo 'error: run this script with sudo.' >&2
  exit 1
fi
if [[ ! -x "$task_source/Contents/MacOS/Hiddify" ]]; then
  echo 'error: pass the path of Hiddify.app.' >&2
  exit 1
fi

# The root helper of earlier builds.
launchctl bootout system/com.hiddify.tunnel-helper 2>/dev/null || true
rm -f /Library/LaunchDaemons/com.hiddify.tunnel-helper.plist /Library/PrivilegedHelperTools/com.hiddify.tunnel-helper \
  /var/run/hiddify-tunnel-helper.sock
rm -rf "/Library/Application Support/Hiddify/TunnelHelper"

task_legacy="/Library/Application Support/Hiddify/TunnelService/Hiddify.app"
for task_existing in "$task_destination" "$task_legacy"; do
  if [[ -x "$task_existing/Contents/MacOS/Hiddify" ]]; then
    "$task_existing/Contents/MacOS/Hiddify" --tunnel uninstall || true
  fi
done
# A root daemon must not run files its user can change, so it runs a root-owned copy of the app.
rm -rf "$task_destination" "/Library/Application Support/Hiddify/TunnelService"
mkdir -p "$(dirname "$task_destination")"
ditto "$task_source" "$task_destination"
xattr -cr "$task_destination"
chown -R root:wheel "$task_destination"
chmod -R go-w "$task_destination"
# Create the control secret for the installing user before the daemon starts listening.
export HIDDIFY_TUNNEL_OWNER="$task_owner"
export HIDDIFY_ADMIN_BG_OWNER="$task_owner"
"$task_destination/Contents/MacOS/Hiddify" --tunnel install
echo 'Hiddify VPN service installed.'
