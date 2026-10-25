#!/bin/bash
set -euo pipefail

# Upload a Mac App Store .pkg to App Store Connect / TestFlight via altool.
# Requires: APPSTORE_ISSUER_ID, APPSTORE_API_KEY_ID, APPSTORE_API_PRIVATE_KEY
# APPSTORE_API_PRIVATE_KEY is the full AuthKey_<ID>.p8 text (BEGIN/END lines included).
# Literal "\n" sequences (common when pasting into GitHub secrets) are expanded to newlines.

task_pkg="${1:-}"
if [[ -z "$task_pkg" || ! -f "$task_pkg" ]]; then
  echo "usage: upload-appstore.sh path/to/app.pkg" >&2
  exit 2
fi

: "${APPSTORE_ISSUER_ID:?set APPSTORE_ISSUER_ID (App Store Connect → Users and Access → Integrations → Issuer ID)}"
: "${APPSTORE_API_KEY_ID:?set APPSTORE_API_KEY_ID (the Key ID of the .p8)}"
: "${APPSTORE_API_PRIVATE_KEY:?set APPSTORE_API_PRIVATE_KEY (full AuthKey_<ID>.p8 text)}"

# GitHub secrets often store the PEM with literal \n instead of real newlines.
task_key="${APPSTORE_API_PRIVATE_KEY//$'\r'/}"
if [[ "$task_key" != *$'\n'* ]]; then
  task_key="${task_key//\\n/$'\n'}"
fi
task_key="$(printf '%s' "$task_key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
if [[ "$task_key" != *"BEGIN PRIVATE KEY"* || "$task_key" != *"END PRIVATE KEY"* ]]; then
  echo 'error: APPSTORE_API_PRIVATE_KEY must be the full .p8 PEM (including -----BEGIN PRIVATE KEY----- / -----END PRIVATE KEY-----).' >&2
  exit 1
fi

task_dir="$HOME/.appstoreconnect/private_keys"
mkdir -p "$task_dir"
task_path="$task_dir/AuthKey_${APPSTORE_API_KEY_ID}.p8"
printf '%s\n' "$task_key" >"$task_path"
chmod 600 "$task_path"

echo "Uploading $task_pkg to App Store Connect (key ${APPSTORE_API_KEY_ID})..."
xcrun altool --upload-app --type macos --file "$task_pkg" \
  --apiKey "$APPSTORE_API_KEY_ID" --apiIssuer "$APPSTORE_ISSUER_ID"
echo "Upload finished."
