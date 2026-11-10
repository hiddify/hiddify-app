#!/usr/bin/env python3
"""Print the build number for the next iOS upload of a version.

TestFlight lets a later build of a version that is already approved reach external testers without
waiting for review again, so every upload of a version gets the next whole number: one more than the
highest build App Store Connect has for that version, and never less than pubspec's build number.

It signs in with an Apple ID and an app-specific password, no App Store Connect API key: Transporter's
statusAll mode lists every package uploaded for the app. altool cannot list builds, and since Xcode
26.6 its --build-status only takes the delivery ID of an upload.

usage: next_build_number.py <bundle id> <version> <pubspec build number>
env:   APPLE_UPLOAD_APPLE_ID, APPLE_UPLOAD_APP_PASSWORD
       NEXT_BUILD_RAW_OUTPUT   optional file to save Transporter's reply in

Standard library and Xcode only, so it runs on a bare macOS runner.
"""

import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

AUTH_ERROR_CODES = {"1235", "-22938"}

# Names Transporter may give the two numbers; matched against attribute, element and label names
# with case and punctuation removed.
SHORT_VERSION_KEYS = {"bundleshortversionstring", "shortversion", "shortversionstring", "versionstring", "appversion"}
BUILD_KEYS = {"bundleversion", "buildversion", "buildnumber", "build", "cfbundleversion"}


def norm(name: str) -> str:
    return re.sub(r"[^a-z]", "", name.lower())


def app_apple_id(bundle_id: str) -> str:
    """The app's numeric Apple ID, from the public store lookup: Transporter wants it, not the bundle ID."""
    url = f"https://itunes.apple.com/lookup?{urllib.parse.urlencode({'bundleId': bundle_id})}"
    with urllib.request.urlopen(url, timeout=60) as response:
        results = json.load(response).get("results", [])
    for result in results:
        if result.get("bundleId") == bundle_id:
            return str(result["trackId"])
    raise SystemExit(f"The App Store has no app with the bundle ID {bundle_id}")


def transporter_status(apple_id: str) -> str:
    args = [
        "xcrun", "iTMSTransporter", "-m", "statusAll",
        "-apple_id", apple_id,
        "-u", os.environ["APPLE_UPLOAD_APPLE_ID"],
        "-p", os.environ["APPLE_UPLOAD_APP_PASSWORD"],
        "-outputFormat", "xml",
        "-v", "critical",
    ]
    result = subprocess.run(args, capture_output=True, text=True, timeout=600)
    output = result.stdout + result.stderr
    raw = os.environ.get("NEXT_BUILD_RAW_OUTPUT")
    if raw:
        with open(raw, "w") as f:
            f.write(output)
    if any(f"({code})" in output for code in AUTH_ERROR_CODES):
        raise SystemExit(
            f"Transporter could not sign in as {os.environ['APPLE_UPLOAD_APPLE_ID']}: check"
            " APPLE_UPLOAD_APPLE_ID and APPLE_UPLOAD_APP_PASSWORD (an app-specific password from"
            f" account.apple.com, not the account password).\n{output[-3000:]}"
        )
    if result.returncode != 0:
        raise SystemExit(f"iTMSTransporter -m statusAll failed (exit {result.returncode}):\n{output[-6000:]}")
    return output


def builds_from_xml(output: str) -> list[tuple[str, str]]:
    """(version, build) pairs from every XML element that names both, as attributes or children."""
    start = output.find("<?xml")
    if start < 0:
        start = output.find("<itunes_transporter")
    end = output.rfind("</itunes_transporter>")
    if start < 0 or end < 0:
        return []
    try:
        root = ET.fromstring(output[start : end + len("</itunes_transporter>")])
    except ET.ParseError:
        return []
    pairs = []
    for element in root.iter():
        fields = {norm(k): v for k, v in element.attrib.items()}
        for child in element:
            if child.text and child.text.strip():
                fields.setdefault(norm(child.tag), child.text.strip())
            for k, v in child.attrib.items():
                if norm(k) in ("key", "name") and "value" in child.attrib:
                    fields.setdefault(norm(v), child.attrib["value"])
        version = next((fields[k] for k in SHORT_VERSION_KEYS if k in fields), None)
        build = next((fields[k] for k in BUILD_KEYS if k in fields), None)
        if version and build:
            pairs.append((version, build))
    return pairs


def builds_from_text(output: str) -> list[tuple[str, str]]:
    """(version, build) pairs from "Label: value" lines, a version label followed by a build label."""
    pairs, version = [], None
    for line in output.splitlines():
        match = re.match(r"\s*([A-Za-z][A-Za-z ._-]*?)\s*[:=]\s*(\S+)\s*$", line)
        if not match:
            continue
        key, value = norm(match.group(1)), match.group(2)
        if key in SHORT_VERSION_KEYS:
            version = value
        elif key in BUILD_KEYS and version:
            pairs.append((version, value))
            version = None
    return pairs


def main() -> None:
    bundle_id, version, pubspec_build = sys.argv[1], sys.argv[2], int(sys.argv[3])
    for name in ("APPLE_UPLOAD_APPLE_ID", "APPLE_UPLOAD_APP_PASSWORD"):
        if not os.environ.get(name, "").strip():
            raise SystemExit(f"{name} is not set")

    apple_id = app_apple_id(bundle_id)
    print(f"{bundle_id} is app {apple_id}", file=sys.stderr)
    output = transporter_status(apple_id)

    pairs = builds_from_xml(output) or builds_from_text(output)
    if not pairs:
        # An app with releases always has uploads: nothing recognised means the reply's format is
        # not the one this script reads, and "no builds" would reuse a number already taken.
        raise SystemExit(
            "Found no builds in Transporter's reply; its format is not what this script reads."
            f"\n{output[-6000:]}"
        )
    versions = sorted({v for v, _ in pairs})
    uploaded = sorted({int(b) for v, b in pairs if v == version and b.isdigit()})
    print(f"Transporter lists {len(pairs)} uploads, versions {', '.join(versions)}", file=sys.stderr)

    highest = max(uploaded, default=None)
    build = pubspec_build if highest is None else max(pubspec_build, highest + 1)
    print(f"{version}: uploaded builds {uploaded or 'none'}, next {build}", file=sys.stderr)
    print(build)


if __name__ == "__main__":
    main()
