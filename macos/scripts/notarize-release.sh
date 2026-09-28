#!/bin/bash
set -euo pipefail

# Release credentials are provided by maintainers through CI secrets.
for task_variable in APPLE_MACOS_INSTALLER_SIGN_IDENTITY APPLE_NOTARIZATION_APPLE_ID \
  APPLE_NOTARIZATION_TEAM_ID APPLE_NOTARIZATION_PASSWORD; do
  if [[ -z "${!task_variable:-}" ]]; then
    echo "error: Set $task_variable before distributing macOS releases. See macos/NETWORK_EXTENSION.md." >&2
    exit 1
  fi
done
if [[ "$APPLE_MACOS_INSTALLER_SIGN_IDENTITY" != "Developer ID Installer:"* ]]; then
  echo 'error: APPLE_MACOS_INSTALLER_SIGN_IDENTITY must name a Developer ID Installer certificate.' >&2
  exit 1
fi
if [[ $# -eq 0 ]]; then
  echo 'usage: notarize-release.sh artifact.dmg artifact.pkg' >&2
  exit 1
fi
for task_artifact in "$@"; do
  if [[ ! -f "$task_artifact" ]]; then
    echo "error: Missing macOS release artifact: $task_artifact" >&2
    exit 1
  fi
  case "$task_artifact" in
    *.dmg|*.pkg) ;;
    *) echo "error: Unsupported macOS release artifact: $task_artifact" >&2; exit 1 ;;
  esac
done

task_work="$(mktemp -d "${TMPDIR:-/tmp}/hiddify-notarize.XXXXXX")"
trap 'rm -rf "$task_work"' EXIT
task_credentials=(--apple-id "$APPLE_NOTARIZATION_APPLE_ID" --team-id "$APPLE_NOTARIZATION_TEAM_ID" \
  --password "$APPLE_NOTARIZATION_PASSWORD")

for task_artifact in "$@"; do
  if [[ "$task_artifact" == *.pkg ]]; then
    # fastforge's package contains the signed app, but needs its own installer signature.
    productsign --sign "$APPLE_MACOS_INSTALLER_SIGN_IDENTITY" --timestamp \
      "$task_artifact" "$task_work/signed.pkg"
    mv "$task_work/signed.pkg" "$task_artifact"
    pkgutil --check-signature "$task_artifact"
  fi
  xcrun notarytool submit "$task_artifact" "${task_credentials[@]}" \
    --wait --timeout 30m --output-format json > "$task_work/result.json"
  # notarytool can finish successfully with an Invalid submission. Do not publish it.
  python3 - "$task_work/result.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as result_file:
    result = json.load(result_file)
print(f"Notarization {result.get('id', 'unknown')}: {result.get('status', 'unknown')}")
if result.get("status") != "Accepted":
    sys.exit("error: macOS notarization was not accepted. Inspect this submission with notarytool log.")
PY
  xcrun stapler staple "$task_artifact"
  xcrun stapler validate "$task_artifact"
done
