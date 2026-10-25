#!/usr/bin/env bash
set -euo pipefail

bundle_id="apple.hiddify.com"
app_bundle="build/ios/iphonesimulator/Runner.app"

make ios-simulator-validate

if [[ ! -d "$app_bundle" ]]; then
  echo "Simulator app bundle not found: $app_bundle" >&2
  exit 1
fi

device_id="$({ xcrun simctl list devices available --json; } | python3 -c '
import json
import re
import sys

devices = json.load(sys.stdin).get("devices", {})

def version(runtime):
    values = re.findall(r"\d+", runtime)
    return tuple(int(value) for value in values)

for runtime in sorted(devices, key=version, reverse=True):
    if "iOS" not in runtime:
        continue
    for device in devices[runtime]:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            print(device["udid"])
            raise SystemExit
')"

if [[ -z "$device_id" ]]; then
  echo "No available iPhone Simulator was found" >&2
  exit 1
fi

cleanup() {
  xcrun simctl terminate "$device_id" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl shutdown "$device_id" >/dev/null 2>&1 || true
}
trap cleanup EXIT

xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$device_id" -b
xcrun simctl install "$device_id" "$app_bundle"
launch_output="$(xcrun simctl launch --terminate-running-process "$device_id" "$bundle_id")"
echo "$launch_output"
sleep 10

if ! xcrun simctl spawn "$device_id" launchctl list |
  awk -v bundle_id="$bundle_id" '$1 ~ /^[0-9]+$/ && index($3, bundle_id) { found = 1 } END { exit !found }'; then
  echo "The production app exited after launch" >&2
  xcrun simctl spawn "$device_id" log show --last 30s --style compact \
    --predicate 'process == "Runner"' || true
  exit 1
fi

echo "iOS Simulator smoke test passed for $bundle_id"
