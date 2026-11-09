#!/bin/bash
# make_linux_bundle.sh <dir-with-release-files> <out-dir>
# Packs each CPU's Linux release files into a download of its own, Hiddify-Linux-<cpu>.tar.gz
# (x64 and arm64):
#   Hiddify-Linux-<cpu>/install.sh    picks the package format the system uses
#   Hiddify-Linux-<cpu>/{hiddify.deb,hiddify.rpm,Hiddify.AppImage}
# A CPU the build did not produce gets no download, and a format it did not produce is left
# out; install.sh says so when it is needed.
set -euo pipefail
src=$1 out=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -r "$work"' EXIT
mkdir -p "$out"
made=0
for arch in x64 arm64; do
  name=Hiddify-Linux-$arch
  b=$work/$name
  mkdir -p "$b"
  found=0
  for pair in "Hiddify-Debian-$arch.deb:hiddify.deb" "Hiddify-rpm-$arch.rpm:hiddify.rpm" \
              "Hiddify-Linux-$arch-AppImage.AppImage:Hiddify.AppImage"; do
    f=$(find "$src" -name "${pair%%:*}" -print -quit)
    [ -n "$f" ] || continue
    cp "$f" "$b/${pair#*:}"
    found=$((found + 1))
  done
  [ "$found" -gt 0 ] || { echo "no $arch Linux release files in $src, skipping $name.tar.gz"; continue; }
  # the installer knows which CPU its files are for
  sed "s/@ARCH@/$arch/g" "$here/linux/packaging/bundle/install.sh" > "$b/install.sh"
  chmod 755 "$b/install.sh"
  chmod +x "$b/Hiddify.AppImage" 2>/dev/null || true
  tar -C "$work" -czf "$out/$name.tar.gz" "$name"
  echo "$out/$name.tar.gz:"; tar -tzvf "$out/$name.tar.gz" | awk '{print $3, $6}'
  made=$((made + 1))
done
[ "$made" -gt 0 ] || { echo "no Linux release files in $src" >&2; exit 1; }
