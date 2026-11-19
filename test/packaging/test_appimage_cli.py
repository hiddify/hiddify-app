"""Exercise the shipped AppRun against disposable argv-recording executables."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class AppImageCliTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.bundle = Path(self.temporary.name)
        shutil.copyfile(ROOT / "linux/packaging/appimage/AppRun", self.bundle / "AppRun")
        recorder = (
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "print(json.dumps({'program': os.path.basename(sys.argv[0]), 'args': sys.argv[1:]}))\n"
            "sys.exit(int(os.environ.get('RECORDER_EXIT', '0')))\n"
        )
        for name in ("HiddifyCli", "hiddify"):
            executable = self.bundle / name
            executable.write_text(recorder)
            executable.chmod(0o755)
        (self.bundle / "glob-hit.json").touch()
        self.environment = dict(os.environ, APPIMAGE="", HOME=str(self.bundle))

    def launch(self, *arguments, exit_code=0):
        result = subprocess.run(
            ["bash", str(self.bundle / "AppRun"), *arguments],
            env=dict(self.environment, RECORDER_EXIT=str(exit_code)),
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, exit_code, result.stderr)
        return json.loads(result.stdout)

    def test_cli_receives_its_first_argument(self):
        self.assertEqual(self.launch("HiddifyCli", "version"),
                         {"program": "HiddifyCli", "args": ["version"]})

    def test_cli_without_arguments(self):
        self.assertEqual(self.launch("HiddifyCli"),
                         {"program": "HiddifyCli", "args": []})

    def test_cli_preserves_argument_boundaries_and_literals(self):
        args = ["run", "--config", "/tmp/profile name.json", "*.json", "", "a'$`\\\"b", "%u", "%F"]
        self.assertEqual(self.launch("HiddifyCli", *args),
                         {"program": "HiddifyCli", "args": args})

    def test_cli_accepts_optional_dispatch_separator(self):
        args = ["run", "--config", "/tmp/profile name.json", "--", "*.json"]
        self.assertEqual(self.launch("HiddifyCli", "--", *args),
                         {"program": "HiddifyCli", "args": args})

    def test_cli_preserves_exit_status(self):
        self.assertEqual(self.launch("HiddifyCli", "version", exit_code=23)["args"], ["version"])

    def test_gui_still_receives_links_and_filters_desktop_placeholders(self):
        link = "hiddify://import/https://example.invalid/profile#name with spaces"
        self.assertEqual(self.launch("%u", link, "%U", "%f", "%F"),
                         {"program": "hiddify", "args": [link]})

    def test_no_arguments_still_launches_gui(self):
        self.assertEqual(self.launch(), {"program": "hiddify", "args": []})


if __name__ == "__main__":
    unittest.main()
