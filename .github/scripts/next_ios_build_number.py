#!/usr/bin/env python3
"""Print the build number for the next iOS upload of a version.

TestFlight lets a later build of a version that is already approved reach external testers without
waiting for review again, so every upload of a version gets the next whole number: the first build
number from pubspec's upward that App Store Connect does not have yet for that version.

It signs in with the same Apple ID and app-specific password as upload_testflight.sh. altool cannot
list a version's builds, so it asks for the status of one build number at a time; the uploads of a
version start at pubspec's number and go up by one, so the first number App Store Connect does not
know is the next one.

usage: next_ios_build_number.py <bundle id> <version> <pubspec build number>
env:   APPLE_UPLOAD_APPLE_ID, APPLE_UPLOAD_APP_PASSWORD (altool finds the team from the app)

Standard library and xcrun altool only, so it runs on a bare macOS runner.
"""

import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request

# More uploads of one version than this means something is wrong, not that the version is busy.
MAX_PROBES = 100

# altool's message when the Apple ID or the app-specific password is wrong.
AUTH_ERROR_CODES = {1235, -22938}


def app_apple_id(bundle_id: str) -> str:
    """The app's numeric Apple ID, from the public store lookup: altool wants it, not the bundle ID."""
    url = f"https://itunes.apple.com/lookup?{urllib.parse.urlencode({'bundleId': bundle_id})}"
    with urllib.request.urlopen(url, timeout=60) as response:
        results = json.load(response).get("results", [])
    for result in results:
        if result.get("bundleId") == bundle_id:
            return str(result["trackId"])
    raise SystemExit(f"The App Store has no app with the bundle ID {bundle_id}")


def build_status(apple_id: str, version: str, build: int) -> tuple[bool, str]:
    """Whether App Store Connect has this build of the version, and altool's output."""
    args = [
        "xcrun", "altool", "--build-status",
        "--apple-id", apple_id,
        "--bundle-version", str(build),
        "--bundle-short-version-string", version,
        "--platform", "ios",
        "-u", os.environ["APPLE_UPLOAD_APPLE_ID"],
        "-p", "@env:APPLE_UPLOAD_APP_PASSWORD",
        "--output-format", "json",
    ]
    result = subprocess.run(args, capture_output=True, text=True)
    output = (result.stdout + result.stderr).strip()
    if result.returncode == 0:
        return True, output

    codes = {int(c) for c in re.findall(r'(?:"code"\s*:\s*|\bCode=)(-?\d+)', output)}
    if codes & AUTH_ERROR_CODES:
        raise SystemExit(
            f"altool could not sign in as {os.environ['APPLE_UPLOAD_APPLE_ID']}: check"
            " APPLE_UPLOAD_APPLE_ID and APPLE_UPLOAD_APP_PASSWORD (an app-specific password from"
            f" account.apple.com, not the account password).\n{output}"
        )
    # A build number App Store Connect has never seen; anything else is an error we must not read
    # as "free", or the upload would fail later on a number that is already taken.
    if re.search(r"not (be )?found|could not find|couldn't find|no build|does not exist", output, re.I):
        return False, output
    raise SystemExit(f"altool --build-status failed for {version} ({build}):\n{output}")


def main() -> None:
    bundle_id, version, pubspec_build = sys.argv[1], sys.argv[2], int(sys.argv[3])
    for name in ("APPLE_UPLOAD_APPLE_ID", "APPLE_UPLOAD_APP_PASSWORD"):
        if not os.environ.get(name, "").strip():
            raise SystemExit(f"{name} is not set")

    apple_id = app_apple_id(bundle_id)
    print(f"{bundle_id} is app {apple_id}", file=sys.stderr)

    uploaded = []
    for build in range(pubspec_build, pubspec_build + MAX_PROBES):
        exists, output = build_status(apple_id, version, build)
        if not exists:
            print(
                f"{version}: uploaded builds {uploaded or 'none'} from {pubspec_build}, next {build}",
                file=sys.stderr,
            )
            print(build)
            return
        uploaded.append(build)
    raise SystemExit(f"{version} already has builds {pubspec_build} to {build}; raise pubspec's build number")


if __name__ == "__main__":
    main()
