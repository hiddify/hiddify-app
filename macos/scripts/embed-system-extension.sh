#!/bin/bash
set -euo pipefail
task_destination="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Library/SystemExtensions"
if [[ "${HIDDIFY_NETWORK_EXTENSION_ENABLED:-NO}" != YES ]]; then
  # Remove only a stale generated bundle when changing from VPN to local Debug.
  if [[ -d "$task_destination/${HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER}.systemextension" ]]; then
    rm -rf "$task_destination/${HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER}.systemextension"
  fi
  exit 0
fi
task_source="$BUILT_PRODUCTS_DIR/${HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER}.systemextension"
if [[ ! -d "$task_source" ]]; then
  echo "error: Packet tunnel extension was not built: $task_source" >&2
  exit 1
fi
mkdir -p "$task_destination"
ditto "$task_source" "$task_destination/${HIDDIFY_TUNNEL_BUNDLE_IDENTIFIER}.systemextension"
