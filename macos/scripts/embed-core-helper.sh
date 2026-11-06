#!/bin/bash
set -euo pipefail

# Builds Contents/Helpers/Hiddify Core.app: the app's core in a process of its own. The app starts
# its executable as `Hiddify core …` (lib/hiddifycore/core_interface/core_process.dart). It is the
# launcher every desktop build shares (hiddify-core/cmd/launcher/main.c), which loads
# hiddify-core.dylib from the app's Frameworks. The bundle gives the process the name Hiddify and
# the core icon in Activity Monitor: the launcher checks in as a background-only app, the only kind
# Activity Monitor shows an icon for, and holds a user-initiated activity so App Nap does not slow it
# down while the app is in the background.

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_helper="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Helpers/Hiddify Core.app"

# Built again only when what it is made from changed. Xcode does not know this phase writes into the
# app, so an incremental build does not sign the app again: a helper replaced on every build would
# leave the app's signature behind ("nested code is modified or invalid").
task_stamp="$DERIVED_FILE_DIR/HiddifyCore.stamp"
task_inputs="$(
  cat "$0" "$task_root/hiddify-core/cmd/launcher/main.c" "$task_root/macos/CoreHelper/CoreIcon.icon/icon.json" \
    "$task_root"/macos/CoreHelper/CoreIcon.icon/Assets/*
  echo "${ARCHS:-} ${EXPANDED_CODE_SIGN_IDENTITY:-} ${ENABLE_HARDENED_RUNTIME:-} ${PRODUCT_BUNDLE_IDENTIFIER:-}"
  echo "${CODE_SIGN_ENTITLEMENTS:-}"
  cat "$PROJECT_DIR/${CODE_SIGN_ENTITLEMENTS:-none}" 2>/dev/null
  echo "${MARKETING_VERSION:-} ${CURRENT_PROJECT_VERSION:-} ${MACOSX_DEPLOYMENT_TARGET:-}"
)"
task_digest="$(printf '%s' "$task_inputs" | shasum -a 256 | cut -d' ' -f1)"
if [[ -x "$task_helper/Contents/MacOS/Hiddify" && -f "$task_stamp" && "$(cat "$task_stamp")" == "$task_digest" ]] &&
  codesign --verify --strict "$task_helper" 2>/dev/null; then
  exit 0
fi

rm -rf "$task_helper" "$task_stamp"
mkdir -p "$task_helper/Contents/MacOS" "$task_helper/Contents/Resources"

task_arch_flags=()
for task_arch in ${ARCHS:-$(uname -m)}; do
  task_arch_flags+=(-arch "$task_arch")
done
xcrun clang -O2 -Wall "${task_arch_flags[@]}" \
  -mmacosx-version-min="${MACOSX_DEPLOYMENT_TARGET:-12.0}" \
  -DHIDDIFY_LAUNCHER_LIBRARY='"../../../../Frameworks/hiddify-core.dylib"' -DHIDDIFY_LAUNCHER_MACOS_APP \
  -framework AppKit -framework Foundation \
  -o "$task_helper/Contents/MacOS/Hiddify" "$task_root/hiddify-core/cmd/launcher/main.c"

# The core icon: the app's icon with its colors swapped (macos/CoreHelper/CoreIcon.icon).
mkdir -p "$DERIVED_FILE_DIR"
xcrun actool "$task_root/macos/CoreHelper/CoreIcon.icon" --compile "$task_helper/Contents/Resources" \
  --app-icon CoreIcon --platform macosx --minimum-deployment-target "${MACOSX_DEPLOYMENT_TARGET:-12.0}" \
  --output-partial-info-plist "$DERIVED_FILE_DIR/HiddifyCoreIcon.plist" > /dev/null
cat > "$task_helper/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Hiddify</string>
  <key>CFBundleIdentifier</key><string>${PRODUCT_BUNDLE_IDENTIFIER}.core</string>
  <key>CFBundleName</key><string>Hiddify</string>
  <key>CFBundleDisplayName</key><string>Hiddify</string>
  <key>CFBundleIconFile</key><string>CoreIcon</string>
  <key>CFBundleIconName</key><string>CoreIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${MARKETING_VERSION:-1.0}</string>
  <key>CFBundleVersion</key><string>${CURRENT_PROJECT_VERSION:-1}</string>
  <key>LSMinimumSystemVersion</key><string>${MACOSX_DEPLOYMENT_TARGET:-12.0}</string>
  <key>LSBackgroundOnly</key><true/>
  <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

# A sandboxed app may only start a program that takes its sandbox: these two entitlements and no
# others. Only the App Store build is sandboxed (app-sandbox is false in the Developer ID and
# development entitlements), and a helper asking to inherit a sandbox its app does not have is
# stopped at launch ("Process is not in an inherited sandbox"). So it follows the app's entitlements.
task_app_entitlements="$PROJECT_DIR/${CODE_SIGN_ENTITLEMENTS:-}"
task_app_sandboxed=false
if [[ -n "${CODE_SIGN_ENTITLEMENTS:-}" && -f "$task_app_entitlements" ]]; then
  task_app_sandboxed="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$task_app_entitlements" 2>/dev/null || echo false)"
fi
task_identity="${EXPANDED_CODE_SIGN_IDENTITY:--}"
task_sign_flags=(--force --sign "$task_identity")
if [[ "$task_app_sandboxed" == true ]]; then
  task_entitlements="$DERIVED_FILE_DIR/HiddifyCore.entitlements"
  mkdir -p "$DERIVED_FILE_DIR"
  cat > "$task_entitlements" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key><true/>
  <key>com.apple.security.inherit</key><true/>
</dict>
</plist>
EOF
  task_sign_flags+=(--entitlements "$task_entitlements")
fi

# Signed before Xcode signs the app around it, by the same identity: the app's hardened runtime
# only lets the helper load hiddify-core.dylib when both come from the same team.
if [[ "${ENABLE_HARDENED_RUNTIME:-NO}" == YES ]]; then
  task_sign_flags+=(--options runtime --timestamp)
else
  task_sign_flags+=(--timestamp=none)
fi
codesign "${task_sign_flags[@]}" "$task_helper"
printf '%s' "$task_digest" > "$task_stamp"

# An incremental build does not sign the app again (see above). When the app already has a signature,
# it is renewed as it was, so it covers the new helper. A full build signs the app after this phase.
task_app="$TARGET_BUILD_DIR/$WRAPPER_NAME"
if codesign -d "$task_app" 2>/dev/null; then
  task_app_flags=(--force --sign "$task_identity" --preserve-metadata=entitlements,requirements,flags,runtime)
  if [[ "${ENABLE_HARDENED_RUNTIME:-NO}" == YES ]]; then
    task_app_flags+=(--timestamp)
  else
    task_app_flags+=(--timestamp=none)
  fi
  codesign "${task_app_flags[@]}" "$task_app"
fi
