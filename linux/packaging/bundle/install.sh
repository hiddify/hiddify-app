#!/bin/sh
# Installs Hiddify from this download (Hiddify-Linux-@ARCH@.tar.gz) in the package format this
# system uses.
#
#   ./install.sh             Debian/Ubuntu: the .deb, Fedora/RHEL/openSUSE: the .rpm, else the AppImage
#   ./install.sh --appimage  the AppImage in ~/.local/bin (no root needed)
#   ./install.sh --deb | --rpm
set -eu

dir=$(cd "$(dirname "$0")" && pwd)
arch=@ARCH@
say() { printf '%s\n' "$*"; }
die() { say "error: $*" >&2; exit 1; }

case "$(uname -m)" in
  x86_64 | amd64) cpu=x64 ;;
  aarch64 | arm64) cpu=arm64 ;;
  *) die "no Hiddify build for this CPU ($(uname -m)); builds exist for x64 and arm64" ;;
esac
[ "$cpu" = "$arch" ] || die "this download is for $arch, but this computer is $cpu: download Hiddify-Linux-$cpu.tar.gz instead"

sudo_() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo "$@"; fi; }
has() { command -v "$1" >/dev/null 2>&1; }

mode=${1:-auto}
case "$mode" in
  auto)
    if has dpkg && has apt-get && [ -f "$dir/hiddify.deb" ]; then mode=--deb
    elif { has dnf || has yum || has zypper; } && [ -f "$dir/hiddify.rpm" ]; then mode=--rpm
    else mode=--appimage; fi ;;
  --deb | --rpm | --appimage) ;;
  -h | --help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die "unknown option $mode (see --help)" ;;
esac

case "$mode" in
  --deb)
    [ -f "$dir/hiddify.deb" ] || die "this download has no .deb"
    say "Installing the Debian package ($arch)..."
    # apt (not dpkg) so missing dependencies are installed too
    sudo_ apt-get install -y "$dir/hiddify.deb" ;;
  --rpm)
    [ -f "$dir/hiddify.rpm" ] || die "this download has no .rpm"
    say "Installing the RPM package ($arch)..."
    if has dnf; then sudo_ dnf install -y "$dir/hiddify.rpm"
    elif has zypper; then sudo_ zypper --non-interactive install --allow-unsigned-rpm "$dir/hiddify.rpm"
    else sudo_ yum install -y "$dir/hiddify.rpm"; fi ;;
  --appimage)
    [ -f "$dir/Hiddify.AppImage" ] || die "this download has no AppImage"
    bin=${XDG_BIN_HOME:-$HOME/.local/bin}
    mkdir -p "$bin"
    cp "$dir/Hiddify.AppImage" "$bin/Hiddify.AppImage"
    chmod +x "$bin/Hiddify.AppImage"
    say "Installed $bin/Hiddify.AppImage ($arch). Its first start adds Hiddify to the app menu."
    has fusermount || has fusermount3 || say "Note: AppImages need FUSE (package fuse or libfuse2)." ;;
esac
say "Done. Start Hiddify from the app menu."
