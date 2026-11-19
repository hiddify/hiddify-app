#!/bin/bash
# make_installer.sh <release-files-dir> <tag>
# Writes <release-files-dir>/install.sh, the Linux and macOS installer of release <tag>: the
# template linux/packaging/install.sh with the tag and the SHA-256 of each file it can install
# filled in (the macOS disk image, and the AppImage, .deb and .rpm of each Linux CPU). The
# installer downloads the file for the system from the release and refuses it when its SHA-256
# differs. A file the build did not produce is left out, and the installer says so when needed.
set -euo pipefail
dir=$1 tag=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
sums=""
names=(Hiddify-MacOS.dmg)
for arch in x64 arm64; do
  names+=("Hiddify-Linux-$arch.AppImage" "Hiddify-Debian-$arch.deb" "Hiddify-rpm-$arch.rpm")
done
for name in "${names[@]}"; do
  f=$(find "$dir" -name "$name" -type f -print -quit)
  [ -n "$f" ] || { echo "no $name in $dir"; continue; }
  sums+="$(sha256sum "$f" | awk '{print $1}')  $name"$'\n'
done
[ -n "$sums" ] || { echo "no macOS or Linux release files in $dir, so no install.sh"; exit 0; }
SUMS=${sums%$'\n'} TAG=$tag python3 - "$here/linux/packaging/install.sh" "$dir/install.sh" <<'PY'
import os, sys
text = open(sys.argv[1]).read()
text = text.replace("@SHA256SUMS@", os.environ["SUMS"]).replace("@TAG@", os.environ["TAG"])
assert "@" + "TAG@" not in text and "@SHA256SUMS@" not in text
open(sys.argv[2], "w").write(text)
PY
chmod 755 "$dir/install.sh"
echo "$dir/install.sh for $tag:"; printf '%s' "$sums"
