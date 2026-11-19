#!/usr/bin/env bash
# Hiddify installer for Linux and macOS, made for one release (@TAG@):
#
#   bash <(curl -fsSL https://github.com/hiddify/hiddify-app/releases/download/@TAG@/install.sh)
#
# Downloads the build for this system from the release, checks its SHA-256 against the one
# written here when the release was made, and installs it. Steps that need root run through sudo
# (or directly, when the script runs as root).
#   macOS                           Hiddify.app from the disk image into /Applications, without the
#                                   quarantine flag, so it opens without the "downloaded from the
#                                   Internet" prompt
#   Linux, per CPU (x64 or arm64), asks which one when the system has more than one:
#     Debian/Ubuntu                 the .deb (apt installs its dependencies) or the AppImage
#     Fedora/RHEL/openSUSE          the .rpm or the AppImage
#     any other system              the AppImage in ~/.local/bin, with FUSE and the libraries it uses
# Only the formats the release has are offered; a single one is installed without asking, and
# without a terminal to ask on, the first (recommended) one is.
#
# Options (after the command: bash <(curl ...) --appimage):
#   --macos                         macOS: Hiddify.app from the disk image
#   --appimage | --deb | --rpm      Linux: install that format without asking
#   --no-start                      do not start Hiddify after installing (macOS, AppImage)
#   -h | --help                     a short help
#
# CI fills this file in (.github/scripts/make_installer.sh): the release tag and the SHA-256 of
# each file of that release the installer can use. Do not run the template itself.
set -euo pipefail

REPO=hiddify/hiddify-app
TAG=@TAG@
# "<sha256>  <file name>", one line per release file the installer can use
SUMS='
@SHA256SUMS@
'

say() { printf '%s\n' "$*"; }
step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }
root() { if [ "$(id -u)" = 0 ]; then "$@"; elif has sudo; then sudo "$@"; else die "run this as root, or install sudo"; fi; }

case "$TAG" in @*) die "this is the installer template; use the install.sh of a release" ;; esac

mode=auto start=1
for arg in "$@"; do
  case "$arg" in
    --macos | --dmg) mode=--macos ;;
    --appimage | --deb | --rpm) mode=$arg ;;
    --no-start) start=0 ;;
    -h | --help)
      say "Installs Hiddify $TAG for this system, after checking the download's SHA-256."
      say "  (no option)                finds the system, and asks which format to install when it has"
      say "                             more than one (Debian/Ubuntu: .deb or AppImage, Fedora/RHEL/"
      say "                             openSUSE: .rpm or AppImage); a single one is installed directly"
      say "  --macos                    macOS: Hiddify.app from the disk image"
      say "  --appimage | --deb | --rpm Linux: that format"
      say "  --no-start                 do not start Hiddify after installing (macOS, AppImage)"
      exit 0 ;;
    *) die "unknown option $arg (see --help)" ;;
  esac
done

sum_of() { awk -v f="$1" '$2 == f { print $1; exit }' <<<"$SUMS"; }

# The formats this system can install, best first: "<option> <file> <description>" per line.
# Only those the release has (a SHA-256 is written here for them) are offered.
options=""
offer() { [ -z "$(sum_of "$2")" ] || options+="$1 $2 $3"$'\n'; }
case "$(uname -s)" in
  Darwin)
    # one universal app for Apple silicon and Intel
    cpu=universal
    offer --macos Hiddify-MacOS.dmg "Hiddify.app in /Applications" ;;
  Linux)
    case "$(uname -m)" in
      x86_64 | amd64) cpu=x64 ;;
      aarch64 | arm64) cpu=arm64 ;;
      *) die "Hiddify has no build for this CPU ($(uname -m)); builds exist for x64 and arm64" ;;
    esac
    # deb and rpm install the VPN service; the AppImage asks for the password at each VPN start
    if has dpkg && has apt-get; then
      offer --deb "Hiddify-Debian-$cpu.deb" "Debian package (.deb), installed for all users with its VPN service"
    fi
    if has dnf || has yum || has zypper; then
      offer --rpm "Hiddify-rpm-$cpu.rpm" "RPM package (.rpm), installed for all users with its VPN service"
    fi
    offer --appimage "Hiddify-Linux-$cpu.AppImage" "AppImage in ~/.local/bin, for this user only" ;;
  *) die "this installer is for Linux and macOS; other systems: https://github.com/$REPO/releases/tag/$TAG" ;;
esac
options=${options%$'\n'}
[ -n "$options" ] || die "release $TAG has nothing for this system; see https://github.com/$REPO/releases/tag/$TAG"

if [ "$mode" != auto ]; then
  # an option given on the command line must be one this system can install
  line=$(awk -v m="$mode" '$1 == m' <<<"$options")
  [ -n "$line" ] || die "$mode can not be installed here; this system can install: $(awk '{printf "%s ", $1}' <<<"$options")"
elif [ "$(wc -l <<<"$options")" -eq 1 ]; then
  line=$options
else
  say "Hiddify $TAG can be installed here as:"
  awk '{ n++; d = $0; sub(/^[^ ]+ [^ ]+ /, "", d); printf "  %d) %s%s\n", n, d, n == 1 ? " (recommended)" : "" }' <<<"$options"
  count=$(wc -l <<<"$options" | tr -d ' ')
  choice=1
  # the terminal, also when the script itself comes on stdin (curl ... | bash)
  if { exec 3</dev/tty; } 2>/dev/null; then
    while :; do
      printf 'Choose 1-%s [1]: ' "$count"
      read -r choice <&3 || choice=1
      choice=${choice:-1}
      case "$choice" in *[!0-9]*) ;; *) [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ] && break ;; esac
      say "    Type a number from 1 to $count."
    done
    exec 3<&-
  else
    say "No terminal to ask on; installing the recommended one (1)."
  fi
  line=$(sed -n "${choice}p" <<<"$options")
fi
mode=$(awk '{print $1}' <<<"$line")
file=$(awk '{print $2}' <<<"$line")
want=$(sum_of "$file")

# --- download and verify ---------------------------------------------------------------------
work=$(mktemp -d)
mnt=$work/mnt
# the disk image, if one is still attached, then the download
trap '[ -d "$mnt" ] && hdiutil detach -quiet -force "$mnt" 2>/dev/null; rm -rf -- "$work"' EXIT
# apt reads the .deb as its own _apt user
chmod 755 "$work"
url=https://github.com/$REPO/releases/download/$TAG/$file
step "Downloading $file ($TAG, $cpu)"
if has curl; then curl -fL --retry 3 --progress-bar -o "$work/$file" "$url"
elif has wget; then wget -q --show-progress -O "$work/$file" "$url"
else die "needs curl or wget to download"; fi

step "Checking its SHA-256"
if has sha256sum; then got=$(sha256sum "$work/$file" | awk '{print $1}')
elif has shasum; then got=$(shasum -a 256 "$work/$file" | awk '{print $1}')
elif has openssl; then got=$(openssl dgst -sha256 -r "$work/$file" | awk '{print $1}')
else die "needs sha256sum, shasum or openssl to check the download"; fi
[ "$got" = "$want" ] || die "$file does not match the release: SHA-256 is $got, expected $want. Nothing was installed."
say "    $got  OK"
chmod 644 "$work/$file"

# --- install ---------------------------------------------------------------------------------
# The first name of each "a|b" a package manager knows (Debian renamed libraries for 64-bit time).
apt_pick() {
  local alt
  for alt in ${1//|/ }; do
    apt-cache show "$alt" >/dev/null 2>&1 && { printf '%s\n' "$alt"; return; }
  done
  return 0
}

appimage_deps() {
  # The AppImage's runtime is static: FUSE only needs the fusermount tool. GTK 3 and the tray
  # library are what the app links from the system.
  local libs
  libs=$(PATH=$PATH:/sbin:/usr/sbin ldconfig -p 2>/dev/null || true)
  if { has fusermount3 || has fusermount; } && grep -q 'libgtk-3\.so\.0' <<<"$libs" \
     && grep -q 'libayatana-appindicator3\.so\.1' <<<"$libs"; then
    return
  fi
  step "Installing what the AppImage needs (FUSE, GTK 3, tray library)"
  if has apt-get; then
    root apt-get update -qq || true
    local pkgs=() p
    for p in "fuse3|fuse" "libgtk-3-0t64|libgtk-3-0" "libayatana-appindicator3-1"; do
      p=$(apt_pick "$p"); [ -z "$p" ] || pkgs+=("$p")
    done
    [ ${#pkgs[@]} -eq 0 ] || root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
  elif has dnf; then root dnf install -y fuse3 gtk3 libayatana-appindicator-gtk3
  elif has yum; then root yum install -y fuse gtk3 libayatana-appindicator-gtk3
  elif has zypper; then root zypper --non-interactive install fuse3 gtk3 libayatana-appindicator3-1
  elif has pacman; then root pacman -S --needed --noconfirm fuse3 gtk3 libayatana-appindicator
  elif has apk; then root apk add fuse3 gtk+3.0 libayatana-appindicator
  elif has xbps-install; then root xbps-install -Sy fuse3 gtk+3 libayatana-appindicator
  elif has emerge; then root emerge --noreplace sys-fs/fuse:3 x11-libs/gtk+:3 dev-libs/libayatana-appindicator
  else say "    Unknown package manager: install FUSE (fusermount), GTK 3 and libayatana-appindicator yourself."
  fi || say "    Some of them could not be installed; Hiddify may not start without them."
  if ! has fusermount3 && ! has fusermount; then
    say "    No FUSE here: Hiddify.AppImage --appimage-extract-and-run starts it without FUSE."
  fi
}

# The user the app is for: the one who ran sudo, or the one at the screen when root runs it.
target_user() {
  if [ "$(id -u)" != 0 ]; then id -un
  elif [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then printf '%s\n' "$SUDO_USER"
  elif [ "$(uname -s)" = Darwin ]; then stat -f %Su /dev/console
  else id -un; fi
}
# Runs a command as that user (the app must not run as root).
as_user() { if [ "$(id -un)" = "$user" ]; then "$@"; else sudo -u "$user" "$@"; fi; }

install_macos() {
  local app dest=/Applications/Hiddify.app i
  step "Opening the disk image"
  mkdir "$mnt"
  hdiutil attach -quiet -nobrowse -readonly -noautoopen -mountpoint "$mnt" "$work/$file" \
    || die "could not open $file"
  app="$mnt/Hiddify.app"
  [ -d "$app" ] || die "$file has no Hiddify.app"
  codesign --verify --deep --strict "$app" 2>/dev/null \
    || say "    Note: the app's code signature does not verify; macOS may ask before opening it."

  # The app and its core (also named Hiddify) are replaced while they are not running: asked to
  # quit first, so the core turns off the system proxy and the VPN on its way out.
  if pgrep -x Hiddify >/dev/null 2>&1; then
    step "Quitting the running Hiddify"
    as_user osascript -e 'quit app "Hiddify"' >/dev/null 2>&1 || true
    for i in 1 2 3 4 5 6 7 8 9 10; do pgrep -x Hiddify >/dev/null 2>&1 || break; sleep 1; done
    pgrep -x Hiddify >/dev/null 2>&1 && root pkill -x Hiddify || true
  fi

  step "Installing $dest"
  root rm -rf "$dest.new"
  # ditto keeps the code signature, extended attributes and symlinks of the bundle
  root ditto "$app" "$dest.new"
  root rm -rf "$dest"
  root mv "$dest.new" "$dest"
  hdiutil detach -quiet "$mnt" || true
  # A download from a browser is quarantined, and Gatekeeper asks before its first start;
  # this one was checked against the release's SHA-256 above.
  root xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true
  # owned like an app dragged in from the disk image, so the in-app update can replace it
  root chown -R "$user:staff" "$dest"
  # Launch Services learns the hiddify:// and other links the app opens
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$dest" >/dev/null 2>&1 || true
  say "Done. Hiddify is in Applications."
  if [ "$start" = 1 ]; then
    step "Starting Hiddify"
    as_user open "$dest" || true
  fi
}

user=$(target_user)
case "$mode" in
  --macos) install_macos ;;
  --deb)
    step "Installing the Debian package"
    root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$work/$file"
    say "Done. Start Hiddify from the app menu."
    ;;
  --rpm)
    step "Installing the RPM package"
    if has dnf; then root dnf install -y "$work/$file"
    elif has zypper; then root zypper --non-interactive install --allow-unsigned-rpm "$work/$file"
    elif has yum; then root yum install -y "$work/$file"
    else die "needs dnf, zypper or yum to install the .rpm (or use --appimage)"; fi
    say "Done. Start Hiddify from the app menu."
    ;;
  --appimage)
    appimage_deps
    # As root through sudo, the AppImage is the user's, not root's.
    home=$HOME
    [ "$user" = "$(id -un)" ] || home=$(getent passwd "$user" | cut -d: -f6)
    bin=${XDG_BIN_HOME:-$home/.local/bin}
    step "Installing $bin/Hiddify.AppImage"
    mkdir -p "$bin"
    # a new file renamed over the old one: a running Hiddify keeps its own copy
    cp "$work/$file" "$bin/.Hiddify.AppImage.new"
    chmod 755 "$bin/.Hiddify.AppImage.new"
    mv -f "$bin/.Hiddify.AppImage.new" "$bin/Hiddify.AppImage"
    [ "$user" = "$(id -un)" ] || chown "$user:" "$bin" "$bin/Hiddify.AppImage"
    say "Done. Start Hiddify with $bin/Hiddify.AppImage; its first start adds it to the app menu."
    if [ "$start" = 1 ] && [ "$(id -u)" != 0 ] && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
      step "Starting Hiddify"
      nohup "$bin/Hiddify.AppImage" >/dev/null 2>&1 &
    fi
    ;;
esac
