#!/bin/sh
# fastforge `--hook-pre` (see WINDOWS_PACKAGE_HOOK in the Makefile): runs after fastforge's
# own `flutter build windows` and before Inno Setup / msix read the Release tree, so the
# plugin DLLs that the rebuild re-copied get their Authenticode signature back.
# With SignPath (SIGNPATH_SIGNED_DIR set by build-windows.yml) the files were signed once on
# SignPath's servers and are copied back; otherwise they are signed here.
# Kept as a file (no spaces/quotes in the make recipe) so GNU make on Windows does not
# route the fastforge call through sh, where fastforge.bat is not resolvable.
set -e
if [ -n "$SIGNPATH_SIGNED_DIR" ]; then
  exec pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File windows/scripts/signpath_tree.ps1 -Mode Apply -Tree build/windows/x64/runner/Release
fi
exec pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File windows/scripts/sign_windows_artifacts.ps1 -Path build/windows/x64/runner/Release
