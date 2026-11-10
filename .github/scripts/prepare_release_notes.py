#!/usr/bin/env python3
"""Build a short GitHub release body: download + count + VirusTotal for existing assets.

Usage:
  prepare_release_notes.py <release.md> <assets-dir> [tag]
  prepare_release_notes.py <body.md> --release-json <release.json> <tag>
  prepare_release_notes.py <body.md> --vt-results <results.json>

The first form fills <!-- ASSET_LINKS --> in the template with rows only for files
that exist under assets-dir. The second form rewrites only the download table of an
already published body (between the ASSETS markers), taking names and sha256 digests
from the GitHub API release JSON, so nothing needs to be downloaded and manual edits
to the rest of the notes survive. A VirusTotal badge already in that body is kept.
The third form writes the detection counts from virustotal_report.py --json into the
VirusTotal badges of a published body.

The VirusTotal badges are static shields.io images with the count baked in, set by CI
with its own API key. Live badge services query VirusTotal with one shared key and show
"Error 429" whenever that key is over its quota.
"""

from __future__ import annotations

import hashlib
import json
import random
import re
import sys
import time
from pathlib import Path
from urllib.parse import quote

# (OS group, filename, link label, badge color, badge logo) — only rows whose file exists
# are emitted. The label's first word is the badge's left half, the rest its right half.
ASSET_CATALOG: list[tuple[str, str, str, str, str]] = [
    ("Android", "Hiddify-Android-universal.apk", "APK Universal", "044d29", "android"),
    ("Android", "Hiddify-Android-arm64.apk", "APK ARMv8", "168039", "android"),
    ("Android", "Hiddify-Android-arm7.apk", "APK ARMv7", "45bf55", "android"),
    ("Android", "Hiddify-Android-x86_64.apk", "APK x64", "96ed89", "android"),
    # Attached by windows-store-sync.yml once the Microsoft Store has signed it.
    ("Windows", "Hiddify-Windows-Setup-x64.Msix", "MSIX x64", "0078d7", "windows"),
    ("Windows", "Hiddify-Windows-Setup-x64.exe", "Setup x64", "2d7d9a", "windows"),
    ("Windows", "Hiddify-Windows-Portable-x64.zip", "Portable x64", "67b7d1", "windows"),
    ("macOS (v10.15+)", "Hiddify-MacOS.dmg", "DMG Universal", "ea005e", "apple"),
    ("macOS (v10.15+)", "Hiddify-MacOS-Installer.pkg", "PKG Universal", "bc544b", "apple"),
    ("iOS", "Hiddify-iOS.ipa", "IPA iOS", "0a84ff", "apple"),
    ("Linux", "Hiddify-Linux-x64-AppImage.AppImage", "AppImage x64", "f84e29", "linux"),
    ("Linux", "Hiddify-Linux-x64-AppImage.tar.gz", "AppImage x64 (tar.gz)", "f84e29", "linux"),
    ("Linux", "Hiddify-Debian-x64.deb", "DebPackage x64", "FF9966", "debian"),
    ("Linux", "Hiddify-rpm-x64.rpm", "RpmPackage x64", "F1B42F", "redhat"),
    ("Linux", "Hiddify-Linux-x64.tar.gz", "All-in-one x64 (install.sh)", "6e7781", "linux"),
    ("Linux", "Hiddify-Linux-arm64-AppImage.AppImage", "AppImage ARM64", "f84e29", "linux"),
    ("Linux", "Hiddify-Linux-arm64-AppImage.tar.gz", "AppImage ARM64 (tar.gz)", "f84e29", "linux"),
    ("Linux", "Hiddify-Linux-arm64.tar.gz", "All-in-one ARM64 (install.sh)", "6e7781", "linux"),
    ("Linux", "Hiddify-Debian-arm64.deb", "DebPackage ARM64", "FF9966", "debian"),
    ("Linux", "Hiddify-rpm-arm64.rpm", "RpmPackage ARM64", "F1B42F", "redhat"),
]

# Not sent to VirusTotal: it rejects the IPA upload (HTTP 409), and an iOS app cannot
# run outside the App Store or a sideloading tool anyway.
NO_VT_SCAN = {"Hiddify-iOS.ipa"}

ASSET_MARKER = "<!-- ASSET_LINKS -->"
TABLE_BEGIN = "<!-- ASSETS:BEGIN -->"
TABLE_END = "<!-- ASSETS:END -->"
REPO = "hiddify/hiddify-app"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_assets(assets_dir: Path) -> dict[str, Path]:
    """Map basename -> path (first wins). Prefer shallower paths on collision."""
    by_name: dict[str, Path] = {}
    for path in sorted(assets_dir.rglob("*"), key=lambda p: (len(p.parts), str(p))):
        if not path.is_file():
            continue
        if path.name.endswith(".sha256") or path.name in {"SHA256SUMS", "checksums.txt"}:
            continue
        by_name.setdefault(path.name, path)
    return by_name


def find_asset(assets: dict, name: str):
    if name in assets:
        return assets[name]
    lower = name.lower()
    for key, path in assets.items():
        if key.lower() == lower:
            return path
    return None


def cache_bust() -> str:
    """Unique-enough query value so badge / GitHub image caches miss."""
    return f"{int(time.time())}{random.randint(1000, 9999)}"


def downloads_badge_img(tag: str, filename: str, bust: str) -> str:
    # shields.io per-asset download count; &v= busts GitHub's cached badge image.
    src = (
        f"https://img.shields.io/github/downloads/{REPO}/{tag}/{filename}"
        f"?displayAssetName=false&label=%20&color=green&v={bust}"
    )
    return f'<img src="{src}" alt="downloads">'


def shield_text(text: str) -> str:
    """Text for a shields.io static badge path: its own escapes, then URL encoding."""
    return quote(text.replace("-", "--").replace("_", "__"), safe="")


def shield_src(left: str, right: str, color: str, logo: str = "") -> str:
    src = f"https://img.shields.io/badge/{shield_text(left)}-{shield_text(right)}-{color}"
    return f"{src}?logo={logo}" if logo else src


def download_badge_img(label: str, color: str, logo: str) -> str:
    left, _, right = label.partition(" ")
    return f'<img src="{shield_src(left, right, color, logo)}" alt="{label}">'


def vt_badge_src(result: dict | None) -> str:
    """Static badge for a virustotal_report.py result: {"count": n, "total": t} or None.

    Fewer than 2 engines is a clean result (one engine alone is routinely a false positive)."""
    if not result or not result.get("total"):
        return "https://img.shields.io/badge/scanning-lightgrey"
    count, total = result["count"], result["total"]
    if count < 2:
        return f"https://img.shields.io/badge/{shield_text(f'✅ Safe: {count}/{total}')}-brightgreen"
    color = "yellow" if count <= 3 else "red"
    return f"https://img.shields.io/badge/{shield_text(f'{count}/{total}')}-{color}"


def vt_badge_img(sha256: str, src: str) -> str:
    href = f"https://www.virustotal.com/gui/file/{sha256}/detection"
    return f'<a href="{href}"><img src="{src}" alt="VirusTotal"></a>'


def vt_badge_pattern(sha256: str) -> re.Pattern:
    href = re.escape(f"https://www.virustotal.com/gui/file/{sha256}/detection")
    return re.compile(rf'<a href="{href}"><img src="([^"]*)" alt="VirusTotal"></a>')


def existing_vt_src(body: str, sha256: str) -> str | None:
    """The badge an earlier scan set for this file, unless it is a live-service badge."""
    match = vt_badge_pattern(sha256).search(body)
    if match and match.group(1).startswith("https://img.shields.io/"):
        return match.group(1)
    return None


def apply_vt_results(body: str, results: dict[str, dict | None]) -> str:
    for sha256, result in results.items():
        body = vt_badge_pattern(sha256).sub(lambda _: vt_badge_img(sha256, vt_badge_src(result)), body)
    return body


def render_links(tag: str, assets: dict[str, "Path | str"], bust: str, old_body: str = "") -> str:
    """assets maps file name -> local Path (hashed here) or a known sha256 hex string.

    old_body: a published body whose VirusTotal badges are kept for unchanged files."""
    rowspan_pending: dict[str, int] = {}
    for os_name, filename, *_ in ASSET_CATALOG:
        if find_asset(assets, filename) is None:
            continue
        rowspan_pending[os_name] = rowspan_pending.get(os_name, 0) + 1

    rows: list[str] = []
    os_emitted: dict[str, int] = {}
    for os_name, filename, label, color, logo in ASSET_CATALOG:
        path = find_asset(assets, filename)
        if path is None:
            continue
        digest = path if isinstance(path, str) else sha256_file(path)
        print(f"{filename}: {digest}")
        url = f"https://github.com/{REPO}/releases/download/{tag}/{filename}"
        download = f'<a href="{url}">{download_badge_img(label, color, logo)}</a>'
        downloads = f'<a href="{url}">{downloads_badge_img(tag, filename, bust)}</a>'
        if filename in NO_VT_SCAN:
            vt = "-"
        else:
            vt = vt_badge_img(digest, existing_vt_src(old_body, digest) or vt_badge_src(None))

        cells: list[str] = []
        first = os_emitted.get(os_name, 0) == 0
        os_emitted[os_name] = os_emitted.get(os_name, 0) + 1
        if first:
            span = rowspan_pending[os_name]
            if span > 1:
                cells.append(f'<td rowspan="{span}">{os_name}</td>')
            else:
                cells.append(f"<td>{os_name}</td>")
        cells.append(f"<td>{download}</td>")
        cells.append(f"<td>{downloads}</td>")
        cells.append(f"<td>{vt}</td>")
        rows.append("<tr>\n  " + "\n  ".join(cells) + "\n</tr>")

    if not rows:
        return "_No release assets found in the build output._\n"

    return "\n".join(
        [
            "<table>",
            "<thead><tr><th>OS</th><th>Download</th><th>Downloads</th><th>VirusTotal</th></tr></thead>",
            "<tbody>",
            *rows,
            "</tbody>",
            "</table>",
            "",
        ]
    )


def wrap_table(links: str) -> str:
    return f"{TABLE_BEGIN}\n{links.rstrip()}\n{TABLE_END}\n"


def assets_from_release_json(path: Path) -> dict[str, str]:
    """name -> sha256 from `gh api repos/{repo}/releases/tags/{tag}` output."""
    data = json.loads(path.read_text())
    assets: dict[str, str] = {}
    for asset in data.get("assets", []):
        digest = asset.get("digest") or ""
        if digest.startswith("sha256:"):
            assets[asset["name"]] = digest.split(":", 1)[1]
        else:
            print(f"warning: no sha256 digest for {asset['name']}", file=sys.stderr)
    return assets


def replace_table(body: str, links: str) -> str:
    block = wrap_table(links)
    pattern = re.compile(re.escape(TABLE_BEGIN) + r".*?" + re.escape(TABLE_END) + r"\n?", re.DOTALL)
    if pattern.search(body):
        return pattern.sub(lambda _: block, body, count=1)
    # Bodies published before the markers existed: replace the first table.
    table = re.compile(r"<table>.*?</table>\n?", re.DOTALL)
    if table.search(body):
        return table.sub(lambda _: block, body, count=1)
    return body.rstrip() + "\n\n## Downloads\n\n" + block


def main() -> int:
    args = sys.argv[1:]
    if len(args) >= 3 and args[1] == "--release-json":
        notes_path, release_json, tag = Path(args[0]), Path(args[2]), (args[3] if len(args) > 3 else "")
        if not tag:
            tag = json.loads(release_json.read_text())["tag_name"]
        assets = assets_from_release_json(release_json)
        body = notes_path.read_text()
        links = render_links(tag, assets, cache_bust(), old_body=body)
        notes_path.write_text(replace_table(body, links).strip() + "\n")
        present = sum(1 for _, name, *_ in ASSET_CATALOG if find_asset(assets, name))
        print(f"rewrote download table with {present} rows for tag {tag}")
        return 0

    if len(args) == 3 and args[1] == "--vt-results":
        notes_path, results_path = Path(args[0]), Path(args[2])
        results = json.loads(results_path.read_text())
        notes_path.write_text(apply_vt_results(notes_path.read_text(), results))
        print(f"wrote VirusTotal results for {len(results)} files")
        return 0

    if len(args) < 2:
        print(
            f"usage: {sys.argv[0]} <release.md> <assets-dir> [tag]\n"
            f"       {sys.argv[0]} <body.md> --release-json <release.json> [tag]\n"
            f"       {sys.argv[0]} <body.md> --vt-results <results.json>",
            file=sys.stderr,
        )
        return 2

    notes_path = Path(args[0])
    assets_dir = Path(args[1])
    tag = args[2] if len(args) > 2 else "RELEASE_TAG"

    if not notes_path.is_file():
        print(f"error: {notes_path} does not exist", file=sys.stderr)
        return 1
    if not assets_dir.is_dir():
        print(f"error: {assets_dir} is not a directory", file=sys.stderr)
        return 1

    assets = collect_assets(assets_dir)
    bust = cache_bust()
    print(f"badge cache-bust v={bust}")

    text = notes_path.read_text()
    text = text.replace("RELEASE_TAG", tag)
    links = render_links(tag, assets, bust)
    # Strip the template's own comments first; the ASSETS markers are added after
    # and stay in the body so the table can be rewritten later.
    text = re.sub(r"<!--(?!.*?ASSET_LINKS).*?-->\n?", "", text, flags=re.DOTALL)
    if ASSET_MARKER in text:
        text = text.replace(ASSET_MARKER, wrap_table(links))
    else:
        text = text.rstrip() + "\n\n## Downloads\n\n" + wrap_table(links)

    notes_path.write_text(text.strip() + "\n")
    present = sum(1 for _, name, *_ in ASSET_CATALOG if find_asset(assets, name))
    print(f"wrote {present} download rows for tag {tag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
