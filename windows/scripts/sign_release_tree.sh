#!/bin/sh
# fastforge `--hook-pre` (see WINDOWS_PACKAGE_HOOK in the Makefile): runs after fastforge's
# own `flutter build windows` and before Inno Setup / msix read the Release tree, so the
# plugin DLLs that the rebuild re-copied get their Authenticode signature back.
# With SignPath (USE_SIGNPATH, build-windows.yml) the files were signed once on SignPath's
# servers and are copied back once SIGNPATH_SIGNED_DIR exists; before that (the run that only
# produces the Inno uninstaller) the tree is left as it is, so it still matches what is sent.
# Otherwise they are signed here.
# Kept as a file (no spaces/quotes in the make recipe) so GNU make on Windows does not
# route the fastforge call through sh, where fastforge.bat is not resolvable.
set -e
if [ "$USE_SIGNPATH" = "true" ]; then
  if [ -z "$SIGNPATH_SIGNED_DIR" ]; then
    echo "SignPath: tree not signed yet, leaving it unsigned"
    exit 0
  fi
  exec pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File windows/scripts/signpath_tree.ps1 -Mode Apply -Tree build/windows/x64/runner/Release
fi
exec pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File windows/scripts/sign_windows_artifacts.ps1 -Path build/windows/x64/runner/Release
