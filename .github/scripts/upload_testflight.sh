#!/usr/bin/env bash
# Uploads an IPA or a Mac App Store pkg to App Store Connect (TestFlight) with an
# Apple ID and an app-specific password instead of an App Store Connect API key.
# API keys cannot be limited to particular apps; a team member can. Use a dedicated
# Apple ID with the Developer or App Manager role and access to the Hiddify apps only.
#
# usage: upload_testflight.sh ios|macos <file>
# env:   APPLE_UPLOAD_APPLE_ID      the Apple ID (email)
#        APPLE_UPLOAD_APP_PASSWORD  app-specific password of that Apple ID
#        APPLE_UPLOAD_ASC_PROVIDER  optional: provider short name, needed only when
#                                   the Apple ID belongs to more than one team
#                                   (xcrun altool --list-providers -u ... -p ...)
set -euo pipefail

platform="${1:?usage: upload_testflight.sh ios|macos <file>}"
file="${2:?usage: upload_testflight.sh ios|macos <file>}"
: "${APPLE_UPLOAD_APPLE_ID:?APPLE_UPLOAD_APPLE_ID is not set}"
: "${APPLE_UPLOAD_APP_PASSWORD:?APPLE_UPLOAD_APP_PASSWORD is not set}"

args=(--upload-app -t "$platform" -f "$file"
      -u "$APPLE_UPLOAD_APPLE_ID" -p @env:APPLE_UPLOAD_APP_PASSWORD
      --output-format normal)
if [[ -n "${APPLE_UPLOAD_ASC_PROVIDER:-}" ]]; then
  args+=(--asc-provider "$APPLE_UPLOAD_ASC_PROVIDER")
fi

echo "Uploading $file ($platform) to App Store Connect as $APPLE_UPLOAD_APPLE_ID"
xcrun altool "${args[@]}"
