#!/usr/bin/env python3
"""Build a short GitHub release body: download + count + VirusTotal for existing assets.

Usage:
  prepare_release_notes.py <release.md> <assets-dir> [tag]

Fills <!-- ASSET_LINKS --> with rows only for files that exist under assets-dir.
VirusTotal badge <img> URLs include a random &v=… query so GitHub / CDN caches
do not keep a stale “Error 404” after a new scan.
"""

from __future__ import annotations

import hashlib
import random
import re
import sys
import time
from pathlib import Path

# (OS group, filename, link label) — only rows whose file exists are emitted.
ASSET_CATALOG: list[tuple[str, str, str]] = [
    ("Android", "Hiddify-Android-universal.apk", "APK Universal"),
    ("Android", "Hiddify-Android-arm64.apk", "APK ARMv8"),
    ("Android", "Hiddify-Android-arm7.apk", "APK ARMv7"),
    ("Android", "Hiddify-Android-x86_64.apk", "APK x64"),
    ("Windows", "Hiddify-Windows-Setup-x64.Msix", "OfficialSetup x64"),
    ("Windows", "Hiddify-Windows-Setup-x64.exe", "Setup x64"),
    ("Windows", "Hiddify-Windows-Portable-x64.zip", "Portable x64"),
    ("macOS (v10.15+)", "Hiddify-MacOS.dmg", "DMG Universal"),
    ("macOS (v10.15+)", "Hiddify-MacOS-Installer.pkg", "PKG Universal"),
    ("macOS (v10.15+)", "Hiddify-MacOS-AppStore.dmg", "App Store DMG Universal"),
    ("macOS (v10.15+)", "Hiddify-MacOS-AppStore.pkg", "App Store PKG Universal"),
    ("iOS", "Hiddify-iOS.ipa", "IPA iOS"),
    ("Linux", "Hiddify-Linux-x64.AppImage", "AppImage x64"),
    ("Linux", "Hiddify-Debian-x64.deb", "DebPackage x64"),
    ("Linux", "Hiddify-rpm-x64.rpm", "RpmPackage x64"),
]

ASSET_MARKER = "<!-- ASSET_LINKS -->"
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


def find_asset(assets: dict[str, Path], name: str) -> Path | None:
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


def vt_badge_img(sha256: str, bust: str) -> str:
    # Random number at the end busts GitHub's cached badge image.
    src = f"https://badges.cssnr.com/vt/id/{sha256}?start=green&end=red&n=8&v={bust}"
    href = f"https://www.virustotal.com/gui/file/{sha256}/detection"
    return f'<a href="{href}"><img src="{src}" alt="VirusTotal"></a>'


def render_links(tag: str, assets: dict[str, Path], bust: str) -> str:
    rowspan_pending: dict[str, int] = {}
    for os_name, filename, _ in ASSET_CATALOG:
        if find_asset(assets, filename) is None:
            continue
        rowspan_pending[os_name] = rowspan_pending.get(os_name, 0) + 1

    rows: list[str] = []
    os_emitted: dict[str, int] = {}
    for os_name, filename, label in ASSET_CATALOG:
        path = find_asset(assets, filename)
        if path is None:
            continue
        digest = sha256_file(path)
        print(f"{filename}: {digest}")
        url = f"https://github.com/{REPO}/releases/download/{tag}/{filename}"
        download = f'<a href="{url}">{label}</a>'
        downloads = f'<a href="{url}">{downloads_badge_img(tag, filename, bust)}</a>'
        vt = vt_badge_img(digest, bust)

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


def main() -> int:
    if len(sys.argv) < 3:
        print(
            f"usage: {sys.argv[0]} <release.md> <assets-dir> [tag]",
            file=sys.stderr,
        )
        return 2

    notes_path = Path(sys.argv[1])
    assets_dir = Path(sys.argv[2])
    tag = sys.argv[3] if len(sys.argv) > 3 else "RELEASE_TAG"

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
    if ASSET_MARKER in text:
        text = text.replace(ASSET_MARKER, links)
    else:
        text = text.rstrip() + "\n\n## Downloads\n\n" + links

    text = re.sub(r"<!--.*?-->\n?", "", text, flags=re.DOTALL)
    notes_path.write_text(text.strip() + "\n")
    present = sum(1 for _, name, _ in ASSET_CATALOG if find_asset(assets, name))
    print(f"wrote {present} download rows for tag {tag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
