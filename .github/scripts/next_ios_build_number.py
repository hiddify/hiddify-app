#!/usr/bin/env python3
"""Print the build number for the next iOS upload of a version.

TestFlight lets a later build of a version that is already approved reach external testers without
waiting for review again, so every upload of a version gets the next whole number: one more than the
highest build App Store Connect has for that version, and never less than pubspec's build number.

usage: next_ios_build_number.py <bundle id> <version> <pubspec build number>
env:   APPSTORE_ISSUER_ID, APPSTORE_API_KEY_ID, APPSTORE_API_PRIVATE_KEY (the .p8 key's text)

Standard library and the openssl command only, so it runs on a bare runner.
"""

import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request

API = "https://api.appstoreconnect.apple.com/v1"


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der: bytes) -> bytes:
    """openssl writes an ECDSA signature as DER; a JWT carries r and s as 32 bytes each."""

    def read_int(offset: int) -> tuple[bytes, int]:
        if der[offset] != 0x02:
            raise ValueError("unexpected ECDSA signature encoding")
        length = der[offset + 1]
        value = der[offset + 2 : offset + 2 + length]
        return value.lstrip(b"\0").rjust(32, b"\0"), offset + 2 + length

    if der[0] != 0x30:
        raise ValueError("unexpected ECDSA signature encoding")
    offset = 3 if der[1] & 0x80 else 2
    r, offset = read_int(offset)
    s, _ = read_int(offset)
    return r + s


def private_key_pem() -> str:
    key = os.environ["APPSTORE_API_PRIVATE_KEY"].strip()
    if "BEGIN" not in key:
        key = base64.b64decode(key).decode()
    return key + "\n"


def token() -> str:
    header = {"alg": "ES256", "kid": os.environ["APPSTORE_API_KEY_ID"].strip(), "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iss": os.environ["APPSTORE_ISSUER_ID"].strip(),
        "iat": now,
        "exp": now + 600,
        "aud": "appstoreconnect-v1",
    }
    signing_input = f"{b64url(json.dumps(header).encode())}.{b64url(json.dumps(payload).encode())}"
    with tempfile.NamedTemporaryFile("w", suffix=".p8") as key_file:
        key_file.write(private_key_pem())
        key_file.flush()
        der = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_file.name],
            input=signing_input.encode(),
            capture_output=True,
            check=True,
        ).stdout
    return f"{signing_input}.{b64url(der_to_raw(der))}"


def get(path: str, params: dict[str, str], auth: str) -> dict:
    url = f"{API}/{path}?{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {auth}"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def main() -> None:
    bundle_id, version, pubspec_build = sys.argv[1], sys.argv[2], int(sys.argv[3])
    auth = token()

    apps = get("apps", {"filter[bundleId]": bundle_id, "fields[apps]": "bundleId"}, auth)["data"]
    app = next((a for a in apps if a["attributes"]["bundleId"] == bundle_id), None)
    if app is None:
        raise SystemExit(f"App Store Connect has no app with the bundle ID {bundle_id}")

    builds = []
    params = {
        "filter[app]": app["id"],
        "filter[preReleaseVersion.version]": version,
        "filter[preReleaseVersion.platform]": "IOS",
        "fields[builds]": "version",
        "limit": "200",
    }
    page = get("builds", params, auth)
    while True:
        builds += [b["attributes"]["version"] for b in page["data"]]
        next_url = page.get("links", {}).get("next")
        if not next_url:
            break
        request = urllib.request.Request(next_url, headers={"Authorization": f"Bearer {auth}"})
        with urllib.request.urlopen(request, timeout=60) as response:
            page = json.load(response)

    uploaded = [int(b) for b in builds if b.isdigit()]
    highest = max(uploaded, default=None)
    build = pubspec_build if highest is None else max(pubspec_build, highest + 1)
    print(
        f"{version}: uploaded builds {sorted(uploaded) or 'none'}, next {build}",
        file=sys.stderr,
    )
    print(build)


if __name__ == "__main__":
    main()
