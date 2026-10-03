#!/usr/bin/env python3
"""Verify signing and provisioning of the release IPA."""

from datetime import datetime, timezone
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]


def fail(message: str) -> None:
    print(f"IPA verification: {message}", file=sys.stderr)
    raise SystemExit(1)


def run(*args: str) -> bytes:
    result = subprocess.run(args, check=False, capture_output=True)
    if result.returncode:
        fail(f"{' '.join(args)} failed:\n{result.stderr.decode(errors='replace')}")
    return result.stdout


def plist_output(data: bytes) -> dict:
    xml_start = data.find(b"<?xml")
    binary_start = data.find(b"bplist00")
    starts = [value for value in (xml_start, binary_start) if value >= 0]
    if not starts:
        fail("command did not return a property list")
    return plistlib.loads(data[min(starts) :])


def xcconfig_value(name: str) -> str:
    content = (ROOT / "ios/Base.xcconfig").read_text()
    match = re.search(rf"^{re.escape(name)}\s*=\s*(\S+)\s*$", content, re.MULTILINE)
    if not match:
        fail(f"{name} is missing from ios/Base.xcconfig")
    return match.group(1)


def verify_bundle(path: Path, expected_bundle_id: str, expected_team_id: str) -> None:
    with (path / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    if info.get("CFBundleIdentifier") != expected_bundle_id:
        fail(f"{path.name} has bundle ID {info.get('CFBundleIdentifier')}")

    run("codesign", "--verify", "--strict", "--verbose=2", str(path))
    entitlements = plist_output(run("codesign", "-d", "--entitlements", ":-", str(path)))
    if entitlements.get("com.apple.developer.team-identifier") != expected_team_id:
        fail(f"{path.name} has the wrong signing team")
    if not entitlements.get("application-identifier", "").endswith(f".{expected_bundle_id}"):
        fail(f"{path.name} has the wrong application identifier")
    if entitlements.get("get-task-allow", False):
        fail(f"{path.name} is signed as a development build")

    profile_path = path / "embedded.mobileprovision"
    if not profile_path.is_file():
        fail(f"{path.name} has no embedded provisioning profile")
    profile = plist_output(run("security", "cms", "-D", "-i", str(profile_path)))
    if expected_team_id not in profile.get("TeamIdentifier", []):
        fail(f"{path.name} provisioning profile belongs to another team")
    if profile.get("ProvisionedDevices"):
        fail(f"{path.name} uses an Ad Hoc provisioning profile")
    if profile.get("ProvisionsAllDevices", False):
        fail(f"{path.name} uses an enterprise provisioning profile")
    expiration = profile.get("ExpirationDate")
    if not isinstance(expiration, datetime) or expiration.replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
        fail(f"{path.name} provisioning profile is expired")
    profile_entitlements = profile.get("Entitlements", {})
    if not profile_entitlements.get("beta-reports-active", False):
        fail(f"{path.name} profile is not enabled for App Store distribution")
    if profile_entitlements.get("get-task-allow", False):
        fail(f"{path.name} uses a development provisioning profile")
    if not profile_entitlements.get("application-identifier", "").endswith(f".{expected_bundle_id}"):
        fail(f"{path.name} provisioning profile has the wrong application identifier")

    expected_group = f"group.{xcconfig_value('BASE_BUNDLE_IDENTIFIER')}"
    if expected_group not in entitlements.get("com.apple.security.application-groups", []):
        fail(f"{path.name} is missing App Group {expected_group}")
    if expected_group not in profile_entitlements.get("com.apple.security.application-groups", []):
        fail(f"{path.name} profile is missing App Group {expected_group}")

    network_extensions = entitlements.get("com.apple.developer.networking.networkextension", [])
    if network_extensions != ["packet-tunnel-provider"]:
        fail(f"{path.name} has unexpected Network Extension entitlements: {network_extensions}")
    if "packet-tunnel-provider" not in profile_entitlements.get(
        "com.apple.developer.networking.networkextension", []
    ):
        fail(f"{path.name} profile does not allow Packet Tunnel Network Extension")
    if "allow-vpn" not in profile_entitlements.get("com.apple.developer.networking.vpn.api", []):
        fail(f"{path.name} profile does not allow the VPN API")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: verify_signed_ipa.py path/to/app.ipa")
    ipa_path = Path(sys.argv[1]).resolve()
    if not ipa_path.is_file():
        fail(f"{ipa_path} does not exist")

    bundle_id = xcconfig_value("BASE_BUNDLE_IDENTIFIER")
    team_id = xcconfig_value("DEVELOPMENT_TEAM")
    with tempfile.TemporaryDirectory() as temporary_directory:
        output = Path(temporary_directory)
        run("ditto", "-x", "-k", str(ipa_path), str(output))
        apps = list((output / "Payload").glob("*.app"))
        if len(apps) != 1:
            fail(f"expected one app bundle, found {len(apps)}")
        app = apps[0]
        extensions = list((app / "PlugIns").glob("*.appex"))
        if len(extensions) != 1:
            fail(f"expected one app extension, found {len(extensions)}")

        verify_bundle(app, bundle_id, team_id)
        verify_bundle(extensions[0], f"{bundle_id}.HiddifyPacketTunnel", team_id)
        run("codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app))
        if not (app / "PrivacyInfo.xcprivacy").is_file():
            fail("PrivacyInfo.xcprivacy is missing from the app bundle")

    print(f"IPA verification passed: {bundle_id}, team {team_id}")


if __name__ == "__main__":
    main()
