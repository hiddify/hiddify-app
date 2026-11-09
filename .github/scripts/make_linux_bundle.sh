#!/bin/bash
# make_linux_bundle.sh <dir-with-release-files> <out-dir>
# Packs the Linux release files of both CPUs into one download, Hiddify-Linux.tar.gz:
#   Hiddify-Linux/install.sh          picks the CPU and the system's package format
#   Hiddify-Linux/{x64,arm64}/{hiddify.deb,hiddify.rpm,Hiddify.AppImage}
# A CPU or format the build did not produce is left out; install.sh says so when it is needed.
set -euo pipefail
src=$1 out=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -r "$work"' EXIT
b=$work/Hiddify-Linux
mkdir -p "$b"
found=0
for arch in x64 arm64; do
  for pair in "Hiddify-Debian-$arch.deb:hiddify.deb" "Hiddify-rpm-$arch.rpm:hiddify.rpm" \
              "Hiddify-Linux-$arch-AppImage.AppImage:Hiddify.AppImage"; do
    f=$(find "$src" -name "${pair%%:*}" -print -quit)
    [ -n "$f" ] || continue
    mkdir -p "$b/$arch"
    cp "$f" "$b/$arch/${pair#*:}"
    found=$((found + 1))
  done
done
[ "$found" -gt 0 ] || { echo "no Linux release files in $src" >&2; exit 1; }
install -m 755 "$here/linux/packaging/bundle/install.sh" "$b/install.sh"
chmod +x "$b"/*/Hiddify.AppImage 2>/dev/null || true
mkdir -p "$out"
tar -C "$work" -czf "$out/Hiddify-Linux.tar.gz" Hiddify-Linux
echo "$out/Hiddify-Linux.tar.gz:"; tar -tzvf "$out/Hiddify-Linux.tar.gz" | awk '{print $3, $6}'
