#!/usr/bin/env python3
"""Summarize VirusTotal verdicts for the release assets in a directory.

Writes a Markdown table to $GITHUB_STEP_SUMMARY (and stdout) with, per file, the
detection count, the engines that flag it, and what VirusTotal says about the
Authenticode signature. Flagged files also get a `::warning::` annotation.

Never fails the job: the report is informational and feeds the false-positive
dispute routine in docs/windows-code-signing.md.

With --json, also writes {sha256: {"count": n, "total": t}} (null while VirusTotal has
no finished analysis), which prepare_release_notes.py --vt-results turns into the
release badges.

Usage: virustotal_report.py <assets-dir> [--json <results.json>]   (env: VIRUS_TOTAL_API_KEY)
"""
from __future__ import annotations

import hashlib
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

API = "https://www.virustotal.com/api/v3/files/"
# Public API quota is 4 requests/minute.
REQUEST_INTERVAL_SECONDS = 16
# Large files are still being analysed after the first pass; look once more.
RETRY_DELAY_SECONDS = 180


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fetch(api_key: str, digest: str) -> dict | None:
    request = urllib.request.Request(API + digest, headers={"x-apikey": api_key, "accept": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        print(f"::warning::VirusTotal API error {error.code} for {digest}")
        return None
    except (urllib.error.URLError, TimeoutError) as error:
        print(f"::warning::VirusTotal API unreachable for {digest}: {error}")
        return None


def signature_summary(attributes: dict) -> str:
    info = attributes.get("signature_info") or {}
    verified = info.get("verified")
    signers = info.get("signers")
    if not verified and not signers:
        return "unsigned / n.a."
    text = str(verified or "?")
    if signers:
        text += f" ({signers.split(';')[0].strip()})"
    return text


def stats_of(report: dict | None) -> tuple[dict, dict] | None:
    """(last_analysis_stats, last_analysis_results), or None while no analysis has finished."""
    if report is None:
        return None
    attributes = report.get("data", {}).get("attributes", {})
    stats = attributes.get("last_analysis_stats") or {}
    if not any(stats.get(key) for key in ("malicious", "suspicious", "undetected", "harmless")):
        return None
    return attributes, attributes.get("last_analysis_results") or {}


def main() -> int:
    args = sys.argv[1:]
    json_path = None
    if len(args) == 3 and args[1] == "--json":
        json_path = pathlib.Path(args[2])
        args = args[:1]
    if len(args) != 1:
        print(__doc__)
        return 2
    api_key = os.environ.get("VIRUS_TOTAL_API_KEY", "")
    if not api_key:
        print("VIRUS_TOTAL_API_KEY not set; skipping VirusTotal report")
        return 0

    files = sorted(p for p in pathlib.Path(args[0]).iterdir() if p.is_file())
    digests = {path: sha256(path) for path in files}
    reports: dict[pathlib.Path, tuple[dict, dict] | None] = {}
    requests = 0
    for attempt in range(2):
        pending = [path for path in files if reports.get(path) is None]
        if not pending:
            break
        if attempt:
            print(f"{len(pending)} files still being analysed; retrying in {RETRY_DELAY_SECONDS}s")
            time.sleep(RETRY_DELAY_SECONDS)
        for path in pending:
            if requests:
                time.sleep(REQUEST_INTERVAL_SECONDS)
            requests += 1
            reports[path] = stats_of(fetch(api_key, digests[path]))

    rows: list[str] = ["| File | Detections | Flagged by | Signature (VT) | Report |", "|---|---|---|---|---|"]
    results: dict[str, dict | None] = {}
    flagged_total = 0
    for path in files:
        digest = digests[path]
        link = f"https://www.virustotal.com/gui/file/{digest}/detection"
        report = reports.get(path)
        if report is None:
            results[digest] = None
            rows.append(f"| {path.name} | pending | | | [open]({link}) |")
            continue

        attributes, analysis = report
        stats = attributes.get("last_analysis_stats", {})
        flagged = [
            f"{engine} ({result.get('result') or result.get('category')})"
            for engine, result in sorted(analysis.items())
            if result.get("category") in ("malicious", "suspicious")
        ]
        total = sum(stats.get(key, 0) for key in ("malicious", "suspicious", "undetected", "harmless"))
        count = len(flagged)
        flagged_total += count
        results[digest] = {"count": count, "total": total}
        rows.append(
            f"| {path.name} | {count}/{total} | {', '.join(flagged) or '-'} | {signature_summary(attributes)} | [open]({link}) |"
        )
        if count:
            print(f"::warning::{path.name}: {count}/{total} VirusTotal engines flag it: {', '.join(flagged)} -> {link}")

    if json_path:
        json_path.write_text(json.dumps(results, indent=2) + "\n")

    header = "### VirusTotal detections\n"
    footer = (
        "\nDetections on signed, CI-built files are false positives. Dispute them with the vendors "
        "listed in docs/windows-code-signing.md (hashes above).\n"
        if flagged_total
        else "\nNo engine flags any asset.\n"
    )
    text = header + "\n".join(rows) + "\n" + footer
    print(text)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
