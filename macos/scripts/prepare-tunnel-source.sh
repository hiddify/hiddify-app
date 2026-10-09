#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_source="$task_root/build/macos/tunnel-core/source"

# Match dependencies.properties core.version=4.1.0. Its git submodules and Go
# requirements form a compatible set; the development submodule can move on.
task_core_commit=c9d6f0f00b2eda34e4fb71863e4e0a62b3e931a0
task_box_commit=0a02b7729f6a211436bb8bdcd8696c283eb27767
task_ray_commit=f58be84e30d946915a1de437fbcc3d3ffca18a23
task_revision="$task_core_commit-$task_box_commit-$task_ray_commit-2"
if [[ -f "$task_source/.revision" && "$(cat "$task_source/.revision")" == "$task_revision" ]]; then
  exit 0
fi
if [[ -d "$task_source" ]]; then
  mv "$task_source" "$task_source.previous-$(date +%s)"
fi
mkdir -p "$task_source/hiddify-sing-box" "$task_source/ray2sing"
task_archive="$(mktemp -t hiddify-tunnel-source)"
trap 'rm -f "$task_archive"' EXIT
download_source() {
  curl --fail --location --retry 3 "https://codeload.github.com/hiddify/$1/tar.gz/$2" -o "$task_archive"
  tar -xzf "$task_archive" --strip-components=1 -C "$3"
}
download_source hiddify-core "$task_core_commit" "$task_source"
download_source hiddify-sing-box "$task_box_commit" "$task_source/hiddify-sing-box"
download_source ray2sing "$task_ray_commit" "$task_source/ray2sing"
for task_module in psiphon-quic-go psiphon-tls tailscale wireguard-go; do
  mkdir -p "$task_source/hiddify-sing-box/replace/$task_module"
done
download_source psiphon-quic-go 47042a7c2475c081b370b8c9da2c22525774b27b "$task_source/hiddify-sing-box/replace/psiphon-quic-go"
download_source psiphon-tls 4af85c2fb9f25576c15ccdb71d8299581dcd47fd "$task_source/hiddify-sing-box/replace/psiphon-tls"
download_source tailscale 788aa623edebf3e9918919cee4c590b177c61ec4 "$task_source/hiddify-sing-box/replace/tailscale"
download_source wireguard-go b12022450359150cfb54790bc7316dee899e2336 "$task_source/hiddify-sing-box/replace/wireguard-go"
echo "$task_revision" > "$task_source/.revision"
