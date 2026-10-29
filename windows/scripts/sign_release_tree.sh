#!/bin/sh
# fastforge `--hook-pre` (see WINDOWS_PACKAGE_HOOK in the Makefile): runs after fastforge's
# own `flutter build windows` and before Inno Setup / msix read the Release tree, so the
# plugin DLLs that the rebuild re-copied get their Authenticode signature back.
# Kept as a file (no spaces/quotes in the make recipe) so GNU make on Windows does not
# route the fastforge call through sh, where fastforge.bat is not resolvable.
set -e
exec pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File windows/scripts/sign_windows_artifacts.ps1 -Path build/windows/x64/runner/Release
