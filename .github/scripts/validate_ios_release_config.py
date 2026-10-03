#!/usr/bin/env python3
"""Fail CI when the iOS archive, signing, or version settings drift apart."""

from pathlib import Path
import plistlib
import re
import sys


ROOT = Path(__file__).resolve().parents[2]


def fail(message: str) -> None:
    print(f"iOS release configuration: {message}", file=sys.stderr)
    raise SystemExit(1)


def xcconfig_value(name: str) -> str:
    content = (ROOT / "ios/Base.xcconfig").read_text()
    match = re.search(rf"^{re.escape(name)}\s*=\s*(\S+)\s*$", content, re.MULTILINE)
    if not match:
        fail(f"{name} is missing from ios/Base.xcconfig")
    return match.group(1)


def main() -> None:
    bundle_id = xcconfig_value("BASE_BUNDLE_IDENTIFIER")
    team_id = xcconfig_value("DEVELOPMENT_TEAM")
    project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text()

    project_teams = set(re.findall(r"DEVELOPMENT_TEAM\s*=\s*([A-Z0-9]+);", project))
    if project_teams != {team_id}:
        fail(f"Xcode Team IDs {sorted(project_teams)} do not match {team_id}")

    pubspec = (ROOT / "pubspec.yaml").read_text()
    version_match = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", pubspec, re.MULTILINE)
    if not version_match:
        fail("pubspec.yaml must contain a semantic version and numeric build number")
    marketing_version, build_number = version_match.groups()
    project_versions = set(re.findall(r"MARKETING_VERSION\s*=\s*([^;]+);", project))
    project_builds = set(re.findall(r"CURRENT_PROJECT_VERSION\s*=\s*(\d+);", project))
    if project_versions != {marketing_version} or project_builds != {build_number}:
        fail("pubspec and Xcode target versions are inconsistent")

    with (ROOT / "ios/exportOptions.plist").open("rb") as handle:
        export_options = plistlib.load(handle)
    if export_options.get("teamID") != team_id:
        fail("exportOptions.plist Team ID does not match ios/Base.xcconfig")

    expected_profiles = {bundle_id, f"{bundle_id}.HiddifyPacketTunnel"}
    actual_profiles = set(export_options.get("provisioningProfiles", {}))
    if actual_profiles != expected_profiles:
        fail(
            "exportOptions.plist provisioning profile bundle IDs must be "
            f"{sorted(expected_profiles)}, got {sorted(actual_profiles)}"
        )

    for relative_path in (
        "ios/Runner/Runner.entitlements",
        "ios/HiddifyPacketTunnel/HiddifyPacketTunnel.entitlements",
        "ios/Runner/Info.plist",
        "ios/HiddifyPacketTunnel/Info.plist",
        "ios/Runner/PrivacyInfo.xcprivacy",
        "ios/HiddifyPacketTunnel/PrivacyInfo.xcprivacy",
    ):
        with (ROOT / relative_path).open("rb") as handle:
            plistlib.load(handle)

    print(
        f"iOS release configuration is consistent: {bundle_id}, "
        f"team {team_id}, version {marketing_version} ({build_number})"
    )


if __name__ == "__main__":
    main()
