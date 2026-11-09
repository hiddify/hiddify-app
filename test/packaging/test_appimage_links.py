"""Validate generated desktop integration with the system's GIO implementation."""

import configparser
import ctypes
import ctypes.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCHEMES = {"hiddify", "v2ray", "v2rayn", "v2rayng", "clash", "clashmeta", "sing-box"}


class AppImageLinksTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bundle = self.root / "bundle"
        self.bundle.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        shutil.copyfile(ROOT / "linux/packaging/appimage/AppRun", self.bundle / "AppRun")
        for name in ("gtk-update-icon-cache", "update-desktop-database"):
            self.executable(self.bin / name, "#!/bin/sh\nexit 0\n")
        self.executable(self.bin / "getent", "#!/bin/sh\nprintf 'review:x:1000:1000::%s:/bin/sh\\n' \"$HOME\"\n")
        self.executable(self.bundle / "hiddify", "#!/bin/sh\nexit 0\n")
        assets = self.bundle / "data/flutter_assets"
        assets.mkdir(parents=True)
        (assets / "version.json").write_text('{"version":"test"}')
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(self.root / "no-session-bus"))
        self.desktop = self.home / ".local/share/applications/hiddify.desktop"

    @staticmethod
    def executable(path, contents):
        path.write_text(contents)
        path.chmod(0o755)

    def integrate(self, name="Hiddify.AppImage"):
        image = self.root / name
        self.recorded = self.root / "argv.json"
        self.executable(image, "#!/usr/bin/env python3\nimport json,os,sys\n"
                        "with open(os.environ['RECORDED_ARGV'], 'w') as f: json.dump(sys.argv, f)\n")
        self.env.update(APPIMAGE=str(image), RECORDED_ARGV=str(self.recorded))
        result = subprocess.run(["bash", str(self.bundle / "AppRun")],
                                env=self.env, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.desktop.is_file(), "Desktop entry was not created")
        return image

    def test_registers_all_supported_schemes(self):
        self.integrate()
        entry = configparser.ConfigParser(interpolation=None)
        entry.read(self.desktop)
        actual = set(entry["Desktop Entry"].get("MimeType", "").strip(";").split(";"))
        self.assertEqual(actual, {"x-scheme-handler/" + scheme for scheme in SCHEMES})

    def test_gio_recognizes_uri_support(self):
        self.integrate()
        gio = ctypes.CDLL(ctypes.util.find_library("gio-2.0"))
        gio.g_desktop_app_info_new_from_filename.argtypes = [ctypes.c_char_p]
        gio.g_desktop_app_info_new_from_filename.restype = ctypes.c_void_p
        gio.g_app_info_supports_uris.argtypes = [ctypes.c_void_p]
        gio.g_app_info_supports_uris.restype = ctypes.c_int
        gio.g_object_unref.argtypes = [ctypes.c_void_p]
        app = gio.g_desktop_app_info_new_from_filename(os.fsencode(self.desktop))
        self.assertTrue(app, "GIO rejected the desktop entry")
        try:
            self.assertTrue(gio.g_app_info_supports_uris(app))
        finally:
            gio.g_object_unref(app)

    def test_url_and_quoted_executable_path_round_trip(self):
        image = self.integrate('Hiddify with spaces \\"$`%u.AppImage')
        uri = "hiddify://import/https://example.invalid/profile#name%20with%20spaces"
        result = subprocess.run(["gio", "launch", str(self.desktop), uri],
                                env=self.env, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        deadline = time.monotonic() + 3
        while not self.recorded.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertTrue(self.recorded.exists(), "The registered executable did not start")
        self.assertEqual(json.loads(self.recorded.read_text()), [str(image), uri])


if __name__ == "__main__":
    unittest.main()
