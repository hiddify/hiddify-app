#!/usr/bin/env python3
"""Reproducible iOS Simulator capture runner for Blizzard visual review.

The runner produces capture evidence only.  It deliberately cannot issue a
visual PASS; a reviewer must compare the frozen artifacts with the independently
pinned design manifest.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import pathlib
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import time
import zlib
from typing import Any, Iterable


REQUIRED_COVERAGE = (
    "home_initial",
    "home_600ms",
    "home_loop_16s",
    "settings",
    "servers",
    "profiles",
    "add_profile",
    "quick_settings",
    "lifecycle_return",
    "tab_return",
)

REQUIRED_SCREENSHOTS = REQUIRED_COVERAGE
VIDEO_NAMES = {"home_loop_16s", "lifecycle_tab_return"}
MAX_PNG_BYTES = 50 * 1024 * 1024
MAX_VIDEO_BYTES = 512 * 1024 * 1024
MAX_LOG_BYTES = 10 * 1024 * 1024

MEDIA_PROBE_SWIFT = r'''import AVFoundation
import CoreMedia
import Foundation

guard CommandLine.arguments.count == 2 else { exit(64) }
let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let tracks = asset.tracks(withMediaType: .video)
guard let track = tracks.first else { exit(65) }
do {
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(
        track: track,
        outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    )
    guard reader.canAdd(output) else { exit(66) }
    reader.add(output)
    guard reader.startReading() else { exit(67) }
    var frameCount = 0
    var first = CMTime.invalid
    var lastEnd = CMTime.invalid
    while let sample = output.copyNextSampleBuffer() {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sample)
        let sampleDuration = CMSampleBufferGetDuration(sample)
        guard timestamp.isValid, timestamp.isNumeric else { exit(68) }
        if !first.isValid || CMTimeCompare(timestamp, first) < 0 { first = timestamp }
        let end = sampleDuration.isValid && sampleDuration.isNumeric && CMTimeCompare(sampleDuration, .zero) > 0
            ? CMTimeAdd(timestamp, sampleDuration)
            : timestamp
        if !lastEnd.isValid || CMTimeCompare(end, lastEnd) > 0 { lastEnd = end }
        frameCount += 1
    }
    guard reader.status == .completed, frameCount > 0, first.isValid, lastEnd.isValid else { exit(69) }
    let decodedSpan = CMTimeGetSeconds(CMTimeSubtract(lastEnd, first))
    let mediaDuration = CMTimeGetSeconds(asset.duration)
    let durationSeconds = max(decodedSpan, mediaDuration)
    guard durationSeconds.isFinite, durationSeconds > 0 else { exit(70) }
    let json: [String: Any] = [
        "duration_seconds": durationSeconds,
        "frame_count": frameCount,
        "decoded_span_seconds": max(0, decodedSpan),
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([0x0a]))
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(71)
}
'''

SOURCE_DIRS = ("lib", "test", "integration_test", "assets")
SOURCE_IGNORES = shutil.ignore_patterns(
    ".git",
    "build",
    ".dart_tool",
    ".idea",
    "DerivedData",
    "*.xcresult",
    "*.log",
    "Pods",
    ".symlinks",
    ".plugin_symlinks",
)
HOST_IGNORES = shutil.ignore_patterns(
    ".git",
    "build",
    ".dart_tool",
    ".idea",
    "DerivedData",
    "*.xcresult",
    "*.log",
    "lib",
    "test",
    "integration_test",
    "assets",
)


class AcceptanceError(RuntimeError):
    pass


def _validate_ack_path(reported: str, data_container: pathlib.Path, filename: str) -> pathlib.Path:
    expected = (data_container / "tmp" / filename).resolve()
    actual = pathlib.Path(reported).resolve()
    if actual != expected:
        raise AcceptanceError("stage ack path escaped the Simulator app container")
    return expected


def parse_stage_marker(line: str, marker: str) -> tuple[str, str, str]:
    parts = line.strip().split(" ", 3)
    if len(parts) != 4 or parts[0] != marker or re.fullmatch(r"[0-9a-f]{6,32}", parts[2]) is None:
        raise AcceptanceError("stage marker is missing or malformed")
    return parts[1], parts[2], parts[3]


def validate_video_ack_path(
    reported: str,
    data_container: pathlib.Path,
    name: str,
    run_id: str,
) -> pathlib.Path:
    return _validate_ack_path(reported, data_container, f"blizzard_video_{name}_{run_id}.ack")


def validate_capture_ack_path(
    reported: str,
    data_container: pathlib.Path,
    name: str,
    run_id: str,
) -> pathlib.Path:
    return _validate_ack_path(reported, data_container, f"blizzard_capture_{name}_{run_id}.ack")


def _bundle_identifier(run_root: pathlib.Path) -> str:
    for line in (run_root / "ios" / "Base.xcconfig").read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator and key.strip() == "BASE_BUNDLE_IDENTIFIER" and value.strip():
            return value.strip()
    raise AcceptanceError("native host is missing BASE_BUNDLE_IDENTIFIER")


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _regular_files(root: pathlib.Path) -> Iterable[pathlib.Path]:
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix()):
        if path.is_symlink():
            raise AcceptanceError(f"candidate contains symlink: {path}")
        if path.is_file():
            yield path


def tree_sha256(root: pathlib.Path) -> str:
    digest = hashlib.sha256()
    for path in _regular_files(root):
        relative = path.relative_to(root).as_posix().encode()
        digest.update(len(relative).to_bytes(8, "big"))
        digest.update(relative)
        digest.update(bytes.fromhex(sha256_file(path)))
    return digest.hexdigest()


def paths_sha256(root: pathlib.Path, relative_paths: Iterable[str]) -> str:
    digest = hashlib.sha256()
    for relative_name in sorted(relative_paths):
        path = root / relative_name
        candidates = _regular_files(path) if path.is_dir() else (path,)
        for candidate in candidates:
            if not candidate.is_file() or candidate.is_symlink():
                raise AcceptanceError(f"native input is missing or linked: {candidate}")
            relative = candidate.relative_to(root).as_posix().encode()
            digest.update(len(relative).to_bytes(8, "big"))
            digest.update(relative)
            digest.update(bytes.fromhex(sha256_file(candidate)))
    return digest.hexdigest()


def copy_candidate_snapshot(source: pathlib.Path, destination: pathlib.Path) -> str:
    source = source.absolute()
    if source.is_symlink():
        raise AcceptanceError(f"candidate source root is a symlink: {source}")
    if not source.is_dir():
        raise AcceptanceError(f"candidate source root is not a directory: {source}")
    if destination.exists():
        raise AcceptanceError(f"snapshot destination already exists: {destination}")
    # Dereference any non-derived internal links into the frozen copy; the gate
    # hashes regular bytes and never runs from the mutable linked checkout.
    shutil.copytree(source, destination, symlinks=False, ignore=SOURCE_IGNORES)
    return tree_sha256(destination)


def prepare_regular_host(candidate: pathlib.Path, template: pathlib.Path, destination: pathlib.Path) -> None:
    if template.is_symlink() or not template.is_dir():
        raise AcceptanceError("host template must be a regular directory")
    if destination.exists():
        raise AcceptanceError(f"host destination already exists: {destination}")
    shutil.copytree(template, destination, symlinks=False, ignore=HOST_IGNORES)
    package_state = destination / ".dart_tool"
    package_state.mkdir()
    for name in ("package_config.json", "package_graph.json", "version"):
        source = template / ".dart_tool" / name
        if source.is_file():
            shutil.copy2(source, package_state / name)
    for name in SOURCE_DIRS:
        target = destination / name
        if target.exists() or target.is_symlink():
            if target.is_dir() and not target.is_symlink():
                shutil.rmtree(target)
            else:
                target.unlink()
        source = candidate / name
        if not source.is_dir():
            raise AcceptanceError(f"candidate is missing required directory: {name}")
        shutil.copytree(source, target, symlinks=False)
    candidate_glass = candidate / "ios" / "Runner" / "BlizzardNativeGlass.swift"
    host_glass = destination / "ios" / "Runner" / "BlizzardNativeGlass.swift"
    if not candidate_glass.is_file() or candidate_glass.is_symlink():
        raise AcceptanceError("candidate native glass is missing or linked")
    host_glass.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(candidate_glass, host_glass)
    if sha256_file(candidate_glass) != sha256_file(host_glass):
        raise AcceptanceError("candidate native glass did not reach the regular host")
    app_delegate = destination / "ios" / "Runner" / "AppDelegate.swift"
    if not app_delegate.is_file() or 'registrar(forPlugin: "BlizzardNativeGlass")?.register(' not in app_delegate.read_text():
        raise AcceptanceError("QA native host is missing native glass registration")
    list(_regular_files(destination))


def _artifact_map(receipt: dict[str, Any]) -> list[dict[str, Any]]:
    artifacts = receipt.get("artifacts")
    if not isinstance(artifacts, list):
        raise AcceptanceError("artifacts must be a list")
    return artifacts


def _checked_regular_file(path_value: Any, *, maximum_bytes: int, label: str) -> pathlib.Path:
    path = pathlib.Path(str(path_value))
    if not path.is_absolute() or path.is_symlink() or not path.is_file():
        raise AcceptanceError(f"{label} must be an absolute regular file: {path}")
    size = path.stat().st_size
    if size <= 0 or size > maximum_bytes:
        raise AcceptanceError(f"{label} has an invalid size: {path}")
    return path.resolve()


def _decoded_png_pixels(path: pathlib.Path) -> tuple[int, int]:
    payload = path.read_bytes()
    if not payload.startswith(b"\x89PNG\r\n\x1a\n"):
        raise AcceptanceError(f"artifact is not a valid PNG: {path}")
    offset = 8
    ihdr: bytes | None = None
    compressed = bytearray()
    saw_end = False
    while offset < len(payload):
        if offset + 12 > len(payload):
            raise AcceptanceError(f"artifact is not a valid PNG: {path}")
        length = struct.unpack(">I", payload[offset : offset + 4])[0]
        kind = payload[offset + 4 : offset + 8]
        end = offset + 12 + length
        if end > len(payload):
            raise AcceptanceError(f"artifact is not a valid PNG: {path}")
        data = payload[offset + 8 : offset + 8 + length]
        expected_crc = struct.unpack(">I", payload[offset + 8 + length : end])[0]
        if zlib.crc32(kind + data) & 0xFFFFFFFF != expected_crc:
            raise AcceptanceError(f"artifact is not a valid PNG: {path}")
        if kind == b"IHDR":
            if ihdr is not None or length != 13:
                raise AcceptanceError(f"artifact is not a valid PNG: {path}")
            ihdr = data
        elif kind == b"IDAT":
            compressed.extend(data)
        elif kind == b"IEND":
            if length != 0:
                raise AcceptanceError(f"artifact is not a valid PNG: {path}")
            saw_end = True
            if end != len(payload):
                raise AcceptanceError(f"artifact is not a valid PNG: {path}")
            break
        offset = end
    if ihdr is None or not compressed or not saw_end:
        raise AcceptanceError(f"artifact is not a valid PNG: {path}")
    width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", ihdr)
    channels = {0: 1, 2: 3, 4: 2, 6: 4}.get(color_type)
    if not width or not height or bit_depth != 8 or channels is None or compression or filtering or interlace:
        raise AcceptanceError(f"artifact is not a supported valid PNG: {path}")
    try:
        decoded = zlib.decompress(bytes(compressed))
    except zlib.error as error:
        raise AcceptanceError(f"artifact is not a valid PNG: {path}") from error
    row_bytes = width * channels
    if len(decoded) != (row_bytes + 1) * height:
        raise AcceptanceError(f"artifact is not a valid PNG: {path}")
    if any(decoded[row * (row_bytes + 1)] > 4 for row in range(height)):
        raise AcceptanceError(f"artifact is not a valid PNG: {path}")
    return width, height


def _probe_video(path: pathlib.Path) -> dict[str, float | int]:
    with tempfile.TemporaryDirectory(prefix="blizzard-media-probe-") as temporary:
        script = pathlib.Path(temporary) / "probe.swift"
        script.write_text(MEDIA_PROBE_SWIFT)
        result = _run(["xcrun", "swift", str(script), str(path)], timeout_seconds=180)
    try:
        payload = json.loads(result.stdout)
        duration = float(payload["duration_seconds"])
        frame_count = int(payload["frame_count"])
        decoded_span = float(payload["decoded_span_seconds"])
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        raise AcceptanceError(f"video probe returned invalid frame data: {path}") from error
    if frame_count <= 0 or not all(math.isfinite(value) for value in (duration, decoded_span)) or duration <= 0:
        raise AcceptanceError(f"video contains no decodable video frames: {path}")
    return {"duration_seconds": duration, "frame_count": frame_count, "decoded_span_seconds": decoded_span}


def validate_receipt(
    receipt: dict[str, Any],
    expected_source_sha: str,
    expected_design_sha256: str,
) -> None:
    if receipt.get("schema") != "blizzard-visual-capture-v1":
        raise AcceptanceError("unsupported receipt schema")
    if receipt.get("result") != "CAPTURE_COMPLETE":
        raise AcceptanceError("capture result is not complete")
    if "visual_verdict" in receipt or receipt.get("result") == "PASS":
        raise AcceptanceError("capture job must not self-approve visual output")
    source = receipt.get("source", {})
    if source.get("git_sha") != expected_source_sha:
        raise AcceptanceError("source SHA does not match external expectation")
    if source.get("tree_sha256_before") != source.get("tree_sha256_after"):
        raise AcceptanceError("source changed during capture")
    if receipt.get("design", {}).get("manifest_sha256") != expected_design_sha256:
        raise AcceptanceError("design manifest does not match external expectation")
    runtime = receipt.get("runtime", {})
    if runtime.get("platform") != "ios" or runtime.get("target_kind") != "simulator":
        raise AcceptanceError("capture did not run on an actual iOS Simulator process")
    if runtime.get("capture_exit_code") != 0:
        raise AcceptanceError("capture exit was nonzero")
    if runtime.get("semantics_leak") is not False:
        raise AcceptanceError("semantics leak was reported or not proven absent")
    if runtime.get("native_tree_sha256_before") != runtime.get("native_tree_sha256_after"):
        raise AcceptanceError("native host changed during capture")
    candidate_native_glass = source.get("native_glass_sha256")
    if (
        not candidate_native_glass
        or runtime.get("native_glass_sha256_before") != candidate_native_glass
        or runtime.get("native_glass_sha256_after") != candidate_native_glass
    ):
        raise AcceptanceError("regular host did not preserve the candidate native glass")
    if runtime.get("native_glass_registration") is not True:
        raise AcceptanceError("QA host did not prove native glass registration")
    if runtime.get("native_host_adapter") != "qa_no_vpn_app_delegate":
        raise AcceptanceError("native host adapter scope is missing or overstated")
    if runtime.get("native_host_adapter_sha256_before") != runtime.get("native_host_adapter_sha256_after"):
        raise AcceptanceError("QA native adapter changed during capture")
    frame_interval = float(runtime.get("home_frame_interval_seconds", 0))
    if not 0.55 <= frame_interval <= 0.75:
        raise AcceptanceError("Home comparison frames were not sampled 600 ms apart")
    if runtime.get("home_frame_interval_basis") != "native_io_start_to_start":
        raise AcceptanceError("Home comparison timing must use native screenshot I/O start-to-start")
    if runtime.get("viewport_points") != [393, 852]:
        raise AcceptanceError("required 393x852 comparison viewport was not captured")
    if runtime.get("lifecycle_driver") != "framework_fixture":
        raise AcceptanceError("lifecycle evidence must be identified as a framework fixture")
    if runtime.get("app_metadata_source") != "synthetic_fixture":
        raise AcceptanceError("capture must identify synthetic app metadata")
    if runtime.get("navigation_evidence") != "rendered_state_fixture":
        raise AcceptanceError("navigation evidence must be identified as a rendered-state fixture")
    if runtime.get("recorder_readiness_signal") != "simctl_stderr_recording_started":
        raise AcceptanceError("recorder readiness signal is missing or untrusted")
    if runtime.get("video_duration_basis") != "avfoundation_asset_duration_after_full_frame_decode":
        raise AcceptanceError("video duration basis is missing or untrusted")
    if float(runtime.get("home_video_wall_seconds", 0)) <= 0 or float(runtime.get("lifecycle_video_wall_seconds", 0)) <= 0:
        raise AcceptanceError("video wall durations must be recorded separately")
    coverage = receipt.get("coverage", {})
    missing = [name for name in REQUIRED_COVERAGE if coverage.get(name) != "CAPTURED"]
    if missing:
        raise AcceptanceError(f"coverage is incomplete: {', '.join(missing)}")
    artifacts = _artifact_map(receipt)
    if not artifacts:
        raise AcceptanceError("capture contains no artifacts")
    seen_paths: set[pathlib.Path] = set()
    seen_files: set[tuple[int, int]] = set()
    screenshots: dict[str, dict[str, Any]] = {}
    videos: dict[str, dict[str, Any]] = {}
    for artifact in artifacts:
        kind = artifact.get("kind")
        maximum = MAX_PNG_BYTES if kind == "png" else MAX_VIDEO_BYTES if kind == "video" else 0
        if not maximum:
            raise AcceptanceError(f"unsupported artifact kind: {kind}")
        path = _checked_regular_file(artifact.get("path"), maximum_bytes=maximum, label="artifact")
        identity = (path.stat().st_dev, path.stat().st_ino)
        if path in seen_paths or identity in seen_files:
            raise AcceptanceError(f"duplicate artifact path or file: {path}")
        seen_paths.add(path)
        seen_files.add(identity)
        if artifact.get("sha256") != sha256_file(path):
            raise AcceptanceError(f"artifact hash mismatch: {path}")
        name = str(artifact.get("name", ""))
        if kind == "png":
            if name not in REQUIRED_SCREENSHOTS or name in screenshots:
                raise AcceptanceError(f"unexpected or duplicate screenshot artifact: {name}")
            width, height = _decoded_png_pixels(path)
            if [width, height] != artifact.get("pixels") or [width, height] not in ([786, 1704], [1179, 2556]):
                raise AcceptanceError(f"screenshot artifact has wrong pixels: {name}")
            screenshots[name] = artifact
        elif kind == "video":
            if name in videos:
                raise AcceptanceError(f"duplicate video artifact: {name}")
            probe = _probe_video(path)
            if artifact.get("readiness") != "simctl_stderr_recording_started":
                raise AcceptanceError(f"video readiness evidence is missing: {name}")
            if int(probe["frame_count"]) <= 0 or float(probe["duration_seconds"]) <= 0:
                raise AcceptanceError(f"video contains no decodable video frames: {name}")
            if int(artifact.get("frame_count", 0)) != probe["frame_count"]:
                raise AcceptanceError(f"video frame count does not match decoded media: {name}")
            if abs(float(artifact.get("duration_seconds", 0)) - float(probe["duration_seconds"])) > 0.01:
                raise AcceptanceError(f"video duration does not match decoded media: {name}")
            if abs(float(artifact.get("decoded_span_seconds", -1)) - float(probe["decoded_span_seconds"])) > 0.01:
                raise AcceptanceError(f"video decoded span does not match decoded media: {name}")
            videos[name] = artifact
    if set(screenshots) != set(REQUIRED_SCREENSHOTS):
        raise AcceptanceError("required screenshot artifacts are incomplete")
    if set(videos) != VIDEO_NAMES:
        raise AcceptanceError("capture must contain separate Home and lifecycle/tab videos")
    if float(videos["home_loop_16s"].get("duration_seconds", 0)) < 16:
        raise AcceptanceError("Home video is shorter than 16 seconds")
    if int(videos["home_loop_16s"].get("frame_count", 0)) < 2:
        raise AcceptanceError("Home video has fewer than two decoded frames")
    if float(videos["home_loop_16s"].get("decoded_span_seconds", 0)) < 16:
        raise AcceptanceError("Home video decoded frame span is shorter than 16 seconds")
    if float(videos["lifecycle_tab_return"].get("duration_seconds", 0)) <= 0:
        raise AcceptanceError("lifecycle/tab video is empty")
    capture_log = receipt.get("capture_log", {})
    log_path = _checked_regular_file(capture_log.get("path"), maximum_bytes=MAX_LOG_BYTES, label="capture log")
    if capture_log.get("sha256") != sha256_file(log_path):
        raise AcceptanceError("capture log hash mismatch")


def _png_pixels(path: pathlib.Path) -> tuple[int, int]:
    with path.open("rb") as source:
        header = source.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise AcceptanceError(f"native screenshot is not a PNG: {path}")
    return struct.unpack(">II", header[16:24])


def _run(
    command: list[str],
    *,
    cwd: pathlib.Path | None = None,
    timeout_seconds: float = 60,
) -> subprocess.CompletedProcess[str]:
    try:
        result = subprocess.run(command, cwd=cwd, text=True, capture_output=True, timeout=timeout_seconds)
    except subprocess.TimeoutExpired as error:
        raise AcceptanceError(f"command timed out: {' '.join(command)}") from error
    if result.returncode:
        detail = (result.stderr or result.stdout).strip()
        raise AcceptanceError(f"command failed ({result.returncode}): {' '.join(command)}\n{detail}")
    return result


def verify_source_sha(source_root: pathlib.Path, expected_source_sha: str) -> str:
    actual = _run(["git", "-C", str(source_root), "rev-parse", "HEAD"]).stdout.strip()
    if actual != expected_source_sha:
        raise AcceptanceError("source SHA does not match external expectation before capture")
    return actual


def _simulator_record(simulator: str) -> dict[str, Any]:
    payload = json.loads(_run(["xcrun", "simctl", "list", "devices", "--json"]).stdout)
    for runtime, devices in payload.get("devices", {}).items():
        for device in devices:
            if device.get("udid") == simulator:
                if not runtime.startswith("com.apple.CoreSimulator.SimRuntime.iOS-"):
                    raise AcceptanceError("selected target is not an iOS Simulator")
                if device.get("state") != "Booted" or not device.get("isAvailable", False):
                    raise AcceptanceError("selected iOS Simulator must be available and Booted")
                return {"runtime": runtime.rsplit("iOS-", 1)[-1].replace("-", "."), "name": device.get("name")}
    raise AcceptanceError("selected iOS Simulator was not found")


def _capture_png(simulator: str, path: pathlib.Path, name: str) -> dict[str, Any]:
    _run(["xcrun", "simctl", "io", simulator, "screenshot", str(path)])
    width, height = _png_pixels(path)
    if width % 393 or height % 852 or width // 393 != height // 852 or width // 393 not in (2, 3):
        raise AcceptanceError(f"native screenshot has wrong viewport: {width}x{height}px, expected 393x852pt")
    return {"kind": "png", "name": name, "path": str(path), "sha256": sha256_file(path), "pixels": [width, height]}


def _iter_lines_with_timeout(stream: Any, *, idle_timeout_seconds: float = 180) -> Iterable[str]:
    descriptor = stream.fileno()
    buffer = bytearray()
    while True:
        newline = buffer.find(b"\n")
        if newline >= 0:
            line = bytes(buffer[: newline + 1])
            del buffer[: newline + 1]
            yield line.decode("utf-8", errors="replace")
            continue
        readable, _, _ = select.select([descriptor], [], [], idle_timeout_seconds)
        if not readable:
            raise AcceptanceError("capture process produced no output before idle timeout")
        chunk = os.read(descriptor, 65536)
        if not chunk:
            if buffer:
                yield bytes(buffer).decode("utf-8", errors="replace")
            return
        buffer.extend(chunk)


def _wait_for_recorder_ready(
    recorder: subprocess.Popen[str],
    *,
    timeout_seconds: float = 20,
    read_line: Any | None = None,
) -> None:
    deadline = time.monotonic() + timeout_seconds
    if read_line is None:
        descriptor = recorder.stderr.fileno()
        buffer = bytearray()
        while time.monotonic() < deadline:
            if recorder.poll() is not None:
                raise AcceptanceError("video recorder exited before 'Recording started'")
            if b"Recording started" in buffer:
                return
            readable, _, _ = select.select([descriptor], [], [], max(0.0, deadline - time.monotonic()))
            if not readable:
                break
            chunk = os.read(descriptor, 4096)
            if not chunk:
                break
            buffer.extend(chunk)
        raise AcceptanceError("video recorder did not emit 'Recording started' before timeout")
    while time.monotonic() < deadline:
        if recorder.poll() is not None:
            raise AcceptanceError("video recorder exited before 'Recording started'")
        line = read_line(recorder.stderr, max(0.01, deadline - time.monotonic()))
        if line and "Recording started" in line:
            return
    raise AcceptanceError("video recorder did not emit 'Recording started' before timeout")


def _stop_owned_process(
    process: subprocess.Popen[str],
    stop_signal: int,
    *,
    timeout_seconds: float = 20,
) -> int:
    current = process.poll()
    if current is not None:
        return current
    process.send_signal(stop_signal)
    try:
        return process.wait(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        process.kill()
        return process.wait(timeout=5)


def _cleanup_owned_process(process: subprocess.Popen[str], stop_signal: int, *, timeout_seconds: float) -> None:
    try:
        _stop_owned_process(process, stop_signal, timeout_seconds=timeout_seconds)
    except (OSError, subprocess.SubprocessError):
        pass


def _capture_process(
    command: list[str],
    run_root: pathlib.Path,
    simulator: str,
    artifacts_dir: pathlib.Path,
    log_path: pathlib.Path,
) -> tuple[int, dict[str, str], list[dict[str, Any]], dict[str, float], float, bool]:
    markers: dict[str, str] = {}
    artifacts: list[dict[str, Any]] = []
    recorder: subprocess.Popen[str] | None = None
    recorder_name: str | None = None
    video_started = 0.0
    video_wall_durations: dict[str, float] = {}
    home_frame_interval = 0.0
    semantics_leak = False
    stage_run_id: str | None = None
    process = subprocess.Popen(
        command,
        cwd=run_root,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=0,
    )
    assert process.stdout is not None
    try:
        with log_path.open("w") as log:
            for line in _iter_lines_with_timeout(process.stdout):
                log.write(line)
                log.flush()
                if "A SemanticsHandle was active at the end of the test" in line:
                    semantics_leak = True
                if line.startswith("BLIZZARD_CAPTURE_READY "):
                    name, run_id, reported_ack = parse_stage_marker(line, "BLIZZARD_CAPTURE_READY")
                    if stage_run_id is None:
                        stage_run_id = run_id
                    elif stage_run_id != run_id:
                        raise AcceptanceError("stage marker run id changed during capture")
                    if name not in REQUIRED_SCREENSHOTS or name == "home_600ms" or name in markers:
                        raise AcceptanceError(f"unexpected or duplicate capture marker: {name}")
                    data_container = pathlib.Path(
                        _run(
                            [
                                "xcrun",
                                "simctl",
                                "get_app_container",
                                simulator,
                                _bundle_identifier(run_root),
                                "data",
                            ]
                        ).stdout.strip()
                    )
                    ack_path = validate_capture_ack_path(reported_ack, data_container, name, run_id)
                    path = artifacts_dir / f"{name}.png"
                    first_requested = time.monotonic()
                    artifacts.append(_capture_png(simulator, path, name))
                    markers[name] = "CAPTURED"
                    if name == "home_initial":
                        time.sleep(max(0.0, first_requested + 0.6 - time.monotonic()))
                        second_requested = time.monotonic()
                        second_path = artifacts_dir / "home_600ms.png"
                        artifacts.append(_capture_png(simulator, second_path, "home_600ms"))
                        markers["home_600ms"] = "CAPTURED"
                        home_frame_interval = second_requested - first_requested
                    ack_path.write_text("captured\n")
                elif line.startswith("BLIZZARD_VIDEO_START"):
                    if recorder is not None:
                        raise AcceptanceError("duplicate video start marker")
                    recorder_name, run_id, reported_ack = parse_stage_marker(line, "BLIZZARD_VIDEO_START")
                    if stage_run_id is None:
                        stage_run_id = run_id
                    elif stage_run_id != run_id:
                        raise AcceptanceError("stage marker run id changed during capture")
                    if recorder_name not in VIDEO_NAMES:
                        raise AcceptanceError(f"unexpected video marker: {recorder_name}")
                    data_container = pathlib.Path(
                        _run(
                            [
                                "xcrun",
                                "simctl",
                                "get_app_container",
                                simulator,
                                _bundle_identifier(run_root),
                                "data",
                            ]
                        ).stdout.strip()
                    )
                    ack_path = validate_video_ack_path(reported_ack, data_container, recorder_name, run_id)
                    video_path = artifacts_dir / f"{recorder_name}.mp4"
                    recorder = subprocess.Popen(
                        ["xcrun", "simctl", "io", simulator, "recordVideo", "--codec=h264", str(video_path)],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.PIPE,
                        bufsize=0,
                    )
                    _wait_for_recorder_ready(recorder)
                    log.write(f"BLIZZARD_RECORDER_READY {recorder_name} simctl_stderr_recording_started\n")
                    log.flush()
                    video_started = time.monotonic()
                    ack_path.write_text("recording\n")
                elif line.startswith("BLIZZARD_VIDEO_END"):
                    if recorder is None:
                        raise AcceptanceError("video end marker arrived without start")
                    end_name = line.strip().split(" ", 1)[1]
                    if end_name != recorder_name:
                        raise AcceptanceError(f"video marker mismatch: {recorder_name} != {end_name}")
                    wall_duration = time.monotonic() - video_started
                    exit_code = _stop_owned_process(recorder, signal.SIGINT)
                    if exit_code != 0:
                        raise AcceptanceError(f"video recorder exited with status {exit_code}: {recorder_name}")
                    assert recorder_name is not None
                    video_wall_durations[recorder_name] = wall_duration
                    video_path = artifacts_dir / f"{recorder_name}.mp4"
                    probe = _probe_video(video_path)
                    artifacts.append(
                        {
                            "kind": "video",
                            "name": recorder_name,
                            "path": str(video_path),
                            "sha256": sha256_file(video_path),
                            "duration_seconds": round(float(probe["duration_seconds"]), 3),
                            "frame_count": int(probe["frame_count"]),
                            "decoded_span_seconds": round(float(probe["decoded_span_seconds"]), 3),
                            "readiness": "simctl_stderr_recording_started",
                        }
                    )
                    recorder = None
                    recorder_name = None
            return_code = process.wait(timeout=30)
        return return_code, markers, artifacts, video_wall_durations, home_frame_interval, semantics_leak
    finally:
        if recorder is not None:
            _cleanup_owned_process(recorder, signal.SIGINT, timeout_seconds=20)
        if process.poll() is None:
            _cleanup_owned_process(process, signal.SIGTERM, timeout_seconds=10)


def capture(args: argparse.Namespace) -> pathlib.Path:
    output = args.output_dir.absolute()
    output.mkdir(parents=True, exist_ok=False)
    actual_source_sha = verify_source_sha(args.source_root, args.expected_source_sha)
    source_status = _run(["git", "-C", str(args.source_root), "status", "--porcelain=v1", "--untracked-files=all"]).stdout
    tracked_diff = _run(["git", "-C", str(args.source_root), "diff", "--binary", "HEAD"]).stdout
    design_digest = sha256_file(args.design_manifest)
    if design_digest != args.expected_design_sha256:
        raise AcceptanceError("design manifest does not match external expectation before capture")
    snapshot = output / "candidate-source"
    before = copy_candidate_snapshot(args.source_root, snapshot)
    run_root = output / "ios-test-host"
    prepare_regular_host(snapshot, args.host_template, run_root)
    native_inputs = ("ios/Runner", "ios/Podfile", "ios/Podfile.lock")
    candidate_native_glass = snapshot / "ios" / "Runner" / "BlizzardNativeGlass.swift"
    host_native_glass = run_root / "ios" / "Runner" / "BlizzardNativeGlass.swift"
    host_app_delegate = run_root / "ios" / "Runner" / "AppDelegate.swift"
    native_glass_before = sha256_file(host_native_glass)
    native_adapter_before = sha256_file(host_app_delegate)
    native_before = paths_sha256(run_root, native_inputs)
    simulator_info = _simulator_record(args.simulator_id)
    flutter_version = json.loads(_run([str(args.flutter), "--version", "--machine"]).stdout)
    xcode_version = _run(["xcodebuild", "-version"]).stdout.strip().splitlines()
    artifacts_dir = output / "artifacts"
    artifacts_dir.mkdir()
    log_path = output / "capture.log"
    command = [
        str(args.flutter),
        "test",
        "--no-pub",
        "-d",
        args.simulator_id,
        "integration_test/blizzard_visual_acceptance_test.dart",
        "--dart-define=BLIZZARD_CAPTURE_MODE=full",
    ]
    exit_code, coverage, artifacts, video_durations, home_frame_interval, semantics_leak = _capture_process(
        command, run_root, args.simulator_id, artifacts_dir, log_path
    )
    after = tree_sha256(snapshot)
    native_after = paths_sha256(run_root, native_inputs)
    native_glass_after = sha256_file(host_native_glass)
    native_adapter_after = sha256_file(host_app_delegate)
    identity_files = {}
    for relative in (
        "integration_test/blizzard_visual_acceptance_test.dart",
        "test/support/blizzard_visual_acceptance_fixture.dart",
        "test/support/home_fixture.dart",
        "scripts/blizzard_visual_acceptance.py",
    ):
        identity_files[relative] = sha256_file(snapshot / relative)
    receipt = {
        "schema": "blizzard-visual-capture-v1",
        "result": "CAPTURE_COMPLETE" if exit_code == 0 else "CAPTURE_FAILED",
        "source": {
            "git_sha": actual_source_sha,
            "status_sha256": hashlib.sha256(source_status.encode()).hexdigest(),
            "tracked_diff_sha256": hashlib.sha256(tracked_diff.encode()).hexdigest(),
            "tree_sha256_before": before,
            "tree_sha256_after": after,
            "native_glass_sha256": sha256_file(candidate_native_glass),
            "identity_files": identity_files,
        },
        "design": {
            "manifest_path": str(args.design_manifest.absolute()),
            "manifest_sha256": design_digest,
        },
        "runtime": {
            "platform": "ios",
            "target_kind": "simulator",
            "simulator": simulator_info,
            "capture_exit_code": exit_code,
            "semantics_leak": semantics_leak,
            "viewport_points": [393, 852],
            "lifecycle_driver": "framework_fixture",
            "app_metadata_source": "synthetic_fixture",
            "navigation_evidence": "rendered_state_fixture",
            "recorder_readiness_signal": "simctl_stderr_recording_started",
            "video_duration_basis": "avfoundation_asset_duration_after_full_frame_decode",
            "native_tree_sha256_before": native_before,
            "native_tree_sha256_after": native_after,
            "native_glass_sha256_before": native_glass_before,
            "native_glass_sha256_after": native_glass_after,
            "native_host_adapter": "qa_no_vpn_app_delegate",
            "native_host_adapter_sha256_before": native_adapter_before,
            "native_host_adapter_sha256_after": native_adapter_after,
            "native_glass_registration": True,
            "flutter": flutter_version,
            "xcode": xcode_version,
            "command": [part if part != args.simulator_id else "<selected-simulator>" for part in command],
            "home_video_wall_seconds": round(video_durations.get("home_loop_16s", 0), 3),
            "lifecycle_video_wall_seconds": round(video_durations.get("lifecycle_tab_return", 0), 3),
            "home_frame_interval_seconds": round(home_frame_interval, 3),
            "home_frame_interval_basis": "native_io_start_to_start",
        },
        "coverage": {name: coverage.get(name, "NOT_RUN") for name in REQUIRED_COVERAGE},
        "artifacts": artifacts,
        "capture_log": {"path": str(log_path), "sha256": sha256_file(log_path)},
    }
    receipt_path = output / "capture-receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    validate_receipt(receipt, args.expected_source_sha, args.expected_design_sha256)
    return receipt_path


def parser() -> argparse.ArgumentParser:
    command = argparse.ArgumentParser(description=__doc__)
    sub = command.add_subparsers(dest="action", required=True)
    capture_parser = sub.add_parser("capture")
    capture_parser.add_argument("--source-root", type=pathlib.Path, required=True)
    capture_parser.add_argument("--host-template", type=pathlib.Path, required=True)
    capture_parser.add_argument("--output-dir", type=pathlib.Path, required=True)
    capture_parser.add_argument("--design-manifest", type=pathlib.Path, required=True)
    capture_parser.add_argument("--expected-design-sha256", required=True)
    capture_parser.add_argument("--expected-source-sha", required=True)
    capture_parser.add_argument("--simulator-id", required=True)
    capture_parser.add_argument("--flutter", type=pathlib.Path, required=True)
    validate_parser = sub.add_parser("validate-capture")
    validate_parser.add_argument("--receipt", type=pathlib.Path, required=True)
    validate_parser.add_argument("--expected-design-sha256", required=True)
    validate_parser.add_argument("--expected-source-sha", required=True)
    return command


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.action == "capture":
            receipt = capture(args)
            print(f"CAPTURE_COMPLETE receipt={receipt}")
        else:
            validate_receipt(
                json.loads(args.receipt.read_text()),
                args.expected_source_sha,
                args.expected_design_sha256,
            )
            print("CAPTURE_RECEIPT_VALID result=CAPTURE_COMPLETE visual_verdict=EXTERNAL_REVIEW_REQUIRED")
        return 0
    except (AcceptanceError, OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"CAPTURE_BLOCKED {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
