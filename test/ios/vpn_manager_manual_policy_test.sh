#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/wir-vpn-manager-manual-policy-test.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

mkdir -p "$build_dir/module-cache"

swiftc \
  -module-cache-path "$build_dir/module-cache" \
  -emit-module \
  -emit-library \
  -module-name NetworkExtension \
  "$repo_root/test/ios/fixtures/NetworkExtension.swift" \
  -o "$build_dir/libNetworkExtension.dylib" \
  -emit-module-path "$build_dir/NetworkExtension.swiftmodule"

swiftc \
  -module-cache-path "$build_dir/module-cache" \
  -I "$build_dir" \
  -L "$build_dir" \
  -lNetworkExtension \
  -Xlinker -rpath \
  -Xlinker "$build_dir" \
  "$repo_root/ios/Runner/VPN/VPNManager.swift" \
  "$repo_root/test/ios/fixtures/VPNManagerDependencies.swift" \
  "$repo_root/test/ios/VPNManagerManualPolicyTests.swift" \
  -o "$build_dir/VPNManagerManualPolicyTests"

"$build_dir/VPNManagerManualPolicyTests"
