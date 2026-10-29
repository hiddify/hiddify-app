#!/bin/bash
set -euo pipefail

# Removes the VPN service that install-admin-bgservice.sh installed:
#   sudo "…/Resources/TunnelService/uninstall-tunnel-service.sh"

task_destination="/Library/Application Support/Hiddify/AdminBgService/Hiddify.app"
task_legacy="/Library/Application Support/Hiddify/TunnelService/Hiddify.app"

if [[ "$(id -u)" != 0 ]]; then
  echo 'error: run this script with sudo.' >&2
  exit 1
fi
if [[ -x "$task_destination/Contents/MacOS/Hiddify" ]]; then
  "$task_destination/Contents/MacOS/Hiddify" --tunnel uninstall || true
elif [[ -x "$task_legacy/Contents/MacOS/Hiddify" ]]; then
  "$task_legacy/Contents/MacOS/Hiddify" --tunnel uninstall || true
fi
# Drop both the current and pre-rename install trees.
rm -rf "/Library/Application Support/Hiddify/AdminBgService" \
  "/Library/Application Support/Hiddify/TunnelService"
rmdir "/Library/Application Support/Hiddify" 2>/dev/null || true
echo 'Hiddify VPN service removed.'
