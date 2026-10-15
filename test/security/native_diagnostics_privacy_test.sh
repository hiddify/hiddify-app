#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
provider="$repo_root/ios/HiddifyPacketTunnel/SingBox/ExtensionProvider.swift"
logger="$repo_root/ios/HiddifyPacketTunnel/Logger.swift"
vpn_manager="$repo_root/ios/Runner/VPN/VPNManager.swift"
fixture="$repo_root/test/security/native_diagnostics_privacy_test.swift"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/native-diagnostics-privacy.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

failures=()

if grep -Fq 'messageWithNewline' "$provider"; then
  failures+=("packet tunnel persists native messages verbatim")
fi

if grep -F 'logger.' "$provider" | grep -Fq '\(message'; then
  failures+=("packet tunnel forwards native messages to unified logging")
fi

if grep -Fq 'NSLocalizedDescriptionKey: message' "$provider"; then
  failures+=("packet tunnel forwards raw messages to the system error boundary")
fi

if grep -Eq 'func writeError|writeError\(' "$provider"; then
  failures+=("packet tunnel retains a raw file writer")
fi

if grep -Eq 'logger\.(debug|error|fault).*localizedDescription' "$provider"; then
  failures+=("packet tunnel forwards localized native errors to unified logging")
fi

if ! grep -Fq 'NativeDiagnosticLog.Code.nativeFailure.rawValue' "$provider"; then
  failures+=("packet tunnel setup logging is outside the closed native code vocabulary")
fi

if ! grep -Fq 'NativeDiagnosticLog.Code.ioFailure.rawValue' "$provider"; then
  failures+=("packet tunnel directory logging is outside the closed native code vocabulary")
fi

if grep -Eq 'print.*(localizedDescription|, *error)' "$vpn_manager"; then
  failures+=("VPN manager forwards native errors to the console")
fi

required_vpn_codes=(
  'stage=vpn_setup code=preferences_load_failed'
  'stage=vpn_preferences_load code=load_failed'
  'stage=vpn_preferences_enable code=save_or_load_failed'
  'stage=vpn_reset code=preferences_reset_failed'
  'stage=vpn_stats code=provider_message_failed'
  'stage=vpn_connect code=start_failed'
  'stage=vpn_disconnect code=preferences_save_failed'
)
for code in "${required_vpn_codes[@]}"; do
  if ! grep -Fq "$code" "$vpn_manager"; then
    failures+=("VPN manager is missing fixed diagnostic: $code")
  fi
done

if ! grep -Fq 'final class NativeDiagnosticLog' "$logger"; then
  failures+=("bounded native diagnostic writer is missing")
fi

if ((${#failures[@]} > 0)); then
  printf '%s\n' "${failures[@]}" >&2
  exit 1
fi

xcrun swiftc -swift-version 5 \
  -module-cache-path "$work_dir/module-cache" \
  "$logger" \
  "$fixture" \
  -o "$work_dir/native-diagnostics-privacy-test"

"$work_dir/native-diagnostics-privacy-test"
