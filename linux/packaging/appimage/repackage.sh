#!/usr/bin/env bash
# Replaces the AppRun of the AppImage fastforge built for the current version, and makes the
# portable archive next to it. Run from the repository root: repackage.sh DIST_DIRECTORY
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dist=${1:?Usage: repackage.sh DIST_DIRECTORY}

# fastforge writes to dist/<pubspec version>/, and dist/ keeps the folders of earlier versions:
# only the one just built is repackaged.
version=$(sed -n 's/^version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$script_dir/../../../pubspec.yaml")
if [[ -z "$version" ]]; then
    echo "No version in pubspec.yaml" >&2
    exit 1
fi
output_dir="$dist/$version"
if [[ ! -d "$output_dir" ]]; then
    echo "No build output in $output_dir" >&2
    exit 1
fi
output_dir=$(cd -- "$output_dir" && pwd)

# Hiddify.AppImage is this script's own output from an earlier run of the same version.
shopt -s nullglob
images=()
for image in "$output_dir"/*.AppImage; do
    [[ "$(basename -- "$image")" != Hiddify.AppImage ]] && images+=("$image")
done
if (( ${#images[@]} != 1 )); then
    printf 'Expected one AppImage in %s; found %s.\n' "$output_dir" "${#images[@]}" >&2
    exit 1
fi
input=${images[0]}

stage=$(mktemp -d "$output_dir/.appimage-stage.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT

echo "Extracting $(basename -- "$input")"
# The squashfs starts where the ELF runtime ends: e_shoff + e_shentsize * e_shnum. unsquashfs,
# rather than --appimage-extract, also works for an image of another architecture.
offset=$(python3 -c 'import struct,sys; h=open(sys.argv[1],"rb").read(64); print(struct.unpack_from("<Q",h,0x28)[0] + struct.unpack_from("<H",h,0x3A)[0]*struct.unpack_from("<H",h,0x3C)[0])' "$input")
app_dir="$stage/squashfs-root"
# A new, empty stage: a failed extraction never falls back to an earlier squashfs-root.
unsquashfs -q -n -o "$offset" -d "$app_dir" "$input" > /dev/null

echo "Replacing AppRun"
cp -- "$script_dir/AppRun" "$app_dir/AppRun"
chmod -R a+rX "$app_dir"
chmod a+rx "$app_dir/AppRun"
desktop="$app_dir/hiddify.desktop"
sed '/^\[Desktop Entry\]/a\
StartupWMClass=app.hiddify.com
' "$desktop" > "$stage/hiddify.desktop"
mv -f -- "$stage/hiddify.desktop" "$desktop"
# The host's libstdc++, for Arch Linux compatibility.
find "$app_dir/usr/lib" -name 'libstdc++.so.6' -delete

echo "Rebuilding AppImage"
rebuilt="$stage/Hiddify.AppImage"
ARCH=$(uname -m) appimagetool --no-appstream "$app_dir" "$rebuilt" > /dev/null
test -s "$rebuilt"

echo "Creating portable package"
portable_name=hiddify-linux-appimage
mkdir -p "$stage/$portable_name/Hiddify.AppImage.home"
cp -p -- "$rebuilt" "$stage/$portable_name/Hiddify.AppImage"
tar -czf "$stage/$portable_name.tar.gz" -C "$stage" "$portable_name"

# The input is kept until both the rebuilt image and the portable archive exist.
mv -f -- "$rebuilt" "$output_dir/Hiddify.AppImage"
mv -f -- "$stage/$portable_name.tar.gz" "$output_dir/$portable_name.tar.gz"
rm -- "$input"
echo "AppImage and portable archive created in $output_dir"
