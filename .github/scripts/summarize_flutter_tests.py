"""Render Flutter's machine reporter into the Actions job summary, including failures.

This is diagnostic only: flutter test's exit status still controls the build.
Input may include non-JSON native library output. Never print raw test streams.
"""

import collections
import html
import json
from pathlib import Path
import re
import sys


def safe_text(value):
    text = str(value)
    text = re.sub(r"[a-zA-Z][a-zA-Z0-9+.-]*://[^\s\"'<>]+", "[URL redacted]", text)
    text = re.sub(r"\b[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\b", "[UUID redacted]", text)
    text = re.sub(r"[A-Za-z0-9_+/=-]{40,}", "[long value redacted]", text)
    return html.escape(text[:3000])


def summarize(path):
    print(f"<h3>{html.escape(path.name)}</h3>")
    if not path.exists():
        print("<p>Not run (no report produced).</p>")
        return
    names = {}
    results = collections.Counter()
    errors = []
    framework_errors = {}
    finished = set()
    completed = False
    for line in path.read_text(errors="replace").splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict):
            continue
        kind = event.get("type")
        if kind == "testStart":
            test = event["test"]
            names[test["id"]] = test["name"]
        elif kind == "testDone":
            finished.add(event["testID"])
            if not event.get("hidden"):
                results["skipped" if event.get("skipped") else event["result"]] += 1
        elif kind == "error":
            errors.append((event.get("testID"), event.get("error", "Unknown test error")))
        elif kind == "print" and "EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK" in str(event.get("message", "")):
            # Flutter emits assertion details as a print event, followed by an
            # otherwise unhelpful generic "Test failed" error. Publish only the
            # sanitized exception for a failed test, never the raw test stream.
            framework_errors[event.get("testID")] = str(event["message"])[:8000]
        elif kind == "done":
            completed = True
    if not completed:
        for test_id, name in names.items():
            if test_id not in finished:
                errors.append((test_id, "Runner stopped before this test completed."))
    print(f"<p>Reporter completed: {completed}. Outcomes: {html.escape(str(dict(results)))}</p>")
    for test_id, error in errors[:20]:
        name = names.get(test_id, 'Test loading/runner')
        error = framework_errors.get(test_id, error)
        print(f"<h4>{safe_text(name)}</h4>")
        print(f"<pre>{safe_text(error)}</pre>")
        # Public run annotations remain readable when full job logs/summaries
        # require GitHub login. Escape workflow-command separators as well.
        message = safe_text(f"{name}: {error}")
        message = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
        print(f"::error title=Flutter test::{message}", file=sys.stderr)
    if len(errors) > 20:
        print(f"<p>{len(errors) - 20} more errors in the authenticated job logs.</p>")


def summarize_build(path):
    if not path.exists():
        return
    lines = path.read_text(errors="replace").splitlines()
    start = next((i for i, line in enumerate(lines) if '* What went wrong:' in line), None)
    compiler = [line for line in lines if re.match(r'\s*(e:|error:|Error:|.*\.dart:\d+:\d+: Error:)', line)]
    selected = compiler[:10] + (lines[start:start + 35] if start is not None else lines[-45:])
    message = safe_text('\n'.join(selected))
    print(f'<h3>Android build failure</h3><pre>{message}</pre>')
    escaped = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    print(f'::error title=Android build::{escaped}', file=sys.stderr)


def summarize_analysis(path):
    if not path.exists():
        return
    lines = path.read_text(errors="replace").splitlines()
    errors = [line for line in lines if re.search(r"\berror\s+[•-]", line)]
    for line in (errors or lines[-8:])[:20]:
        message = safe_text(line)
        print(f'<pre>{message}</pre>')
        escaped = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
        print(f'::error title=Flutter analysis::{escaped}', file=sys.stderr)


def summarize_prepare(path):
    if not path.exists():
        return
    # Dependency/toolchain/generator failures occur before test reports exist.
    # Keep public diagnostics bounded and use the same redaction as test output.
    lines = path.read_text(errors='replace').splitlines()
    selected = [line for line in lines if re.search(r'(?i)error|failed|exception|expected|could not|version solving', line)]
    message = safe_text('\n'.join((selected or lines[-20:])[-20:]))
    print(f'<h3>Preparation failure</h3><pre>{message}</pre>')
    escaped = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    print(f'::error title=Preparation::{escaped}', file=sys.stderr)


if __name__ == "__main__":
    if sys.argv[1:2] == ['--flutter-analyze']:
        summarize_analysis(Path(sys.argv[2]))
    elif sys.argv[1:2] == ['--android-build']:
        summarize_build(Path(sys.argv[2]))
    elif sys.argv[1:2] == ['--prepare']:
        summarize_prepare(Path(sys.argv[2]))
    else:
        for argument in sys.argv[1:]:
            summarize(Path(argument))
