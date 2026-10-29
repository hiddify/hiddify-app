#!/bin/bash
set -euo pipefail

# HiddifyTunnelCore.xcframework is built only in hiddify-core (gomobile bind).
# Place it here via:
#   make macos-libs              # from hiddify-lib-macos.tar.gz
#   make build-macos-libs        # full local build (lipo + xcframework)
#   make build-lite-macos-libs   # host-arch dylib only; keeps an existing framework

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_framework="$task_root/macos/Frameworks/HiddifyTunnelCore.xcframework"

if [[ -d "$task_framework" ]]; then
  echo "using $task_framework"
  exit 0
fi

echo "error: missing macos/Frameworks/HiddifyTunnelCore.xcframework" >&2
echo "  make macos-libs            # download from hiddify-core releases" >&2
echo "  make build-macos-libs      # full local build in hiddify-core" >&2
echo "  (lite builds reuse an existing framework; download once with make macos-libs)" >&2
exit 1
