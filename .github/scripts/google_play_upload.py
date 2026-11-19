#!/usr/bin/env python3
"""Uploads the Google Play bundle and puts it on a track (build.yml, job google-play).

- dev (a `draft` run or a .dev tag): open testing (the `beta` track), sent for review. A dev build
  still in review is replaced: its review is cancelled and the new one sent.
- release (a version tag): production, not released - saved but not sent for review, or, when Play
  sends every change for review by itself (the app has no managed publishing), a draft release,
  which is neither reviewed nor rolled out. Someone releases it from Play Console. While another
  release is in review, closed testing (the `alpha` track) instead, so the one in review is left
  alone.

Play reviews an app's changes together and its API does not say what is in review. When a commit
is refused because something is, the newest release on any track (the highest version code) is
taken as the one in review, and its name tells a dev build from a release: release names are
plain version tags (v5.5.6).

The service account JSON is read from GOOGLE_PLAY_SERVICE_ACCOUNT_JSON. Writes version_code,
track and state (sent, unsent or draft) to GITHUB_OUTPUT; with a version code Play has seen before it writes
version_code and code_used=true and exits 3, so the workflow records the code and moves past it.
"""

import argparse
import json
import os
import re
import sys

import httplib2
from google.oauth2 import service_account
from google_auth_httplib2 import AuthorizedHttp
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

RELEASE_NAME = re.compile(r"^v?\d+\.\d+\.\d+$")
OPEN_TESTING, CLOSED_TESTING, PRODUCTION = "beta", "alpha", "production"


def output(**values):
    path = os.environ.get("GITHUB_OUTPUT")
    for key, value in values.items():
        print(f"{key}={value}")
        if path:
            with open(path, "a") as f:
                f.write(f"{key}={value}\n")


def summary(text):
    print(text)
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a") as f:
            f.write(text + "\n")


def message(error):
    try:
        return json.loads(error.content)["error"]["message"]
    except Exception:
        return str(error)


def in_review(error):
    return "review" in message(error).lower() and "changesnotsentforreview" not in message(error).lower()


def auto_sent(error):
    # "Changes are sent for review automatically. The query parameter changesNotSentForReview must not be set."
    return "must not be set" in message(error).lower()


def needs_not_sent(error):
    # other changes wait unsent (a production release saved for later): sending would send them too
    return "changesnotsentforreview" in message(error).lower() and not auto_sent(error)


def service():
    creds = service_account.Credentials.from_service_account_info(
        json.loads(os.environ["GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"]),
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    # Play checks the bundle after the last chunk, which takes minutes for one this size
    http = httplib2.Http(timeout=900)
    # httplib2 takes 308, the resumable upload's "send the next chunk", for a redirect
    http.redirect_codes = http.redirect_codes - {308}
    return build("androidpublisher", "v3", http=AuthorizedHttp(creds, http=http), cache_discovery=False)


def newest_release(edits, package, edit_id, skip_code):
    """The name of the newest release on any track (not a draft, not ours): the one in review."""
    newest = None
    for track in edits.tracks().list(packageName=package, editId=edit_id).execute().get("tracks", []):
        for release in track.get("releases", []):
            if release.get("status") == "draft":
                continue
            codes = [int(c) for c in release.get("versionCodes", []) if int(c) != skip_code]
            if codes and (newest is None or max(codes) > newest[0]):
                newest = (max(codes), release.get("name", ""), track["track"])
    return newest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--aab", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--kind", choices=["dev", "release"], required=True)
    parser.add_argument("--release-name", required=True)
    args = parser.parse_args()

    edits = service().edits()
    pkg = args.package
    edit_id = edits.insert(packageName=pkg, body={}).execute()["id"]
    try:
        media = MediaFileUpload(args.aab, mimetype="application/octet-stream", resumable=True, chunksize=32 << 20)
        request = edits.bundles().upload(packageName=pkg, editId=edit_id, media_body=media)
        response = None
        while response is None:
            status, response = request.next_chunk(num_retries=3)
            if status:
                print(f"uploading {int(status.progress() * 100)}%", flush=True)
    except HttpError as e:
        edits.delete(packageName=pkg, editId=edit_id).execute()
        if "version code" in message(e).lower() and "already been used" in message(e).lower():
            code = re.search(r"\d+", message(e))
            output(code_used="true", version_code=code.group(0) if code else "")
            summary(f"Google Play: the version code was used already ({message(e)}); the next run moves past it.")
            sys.exit(3)
        raise
    code = int(response["versionCode"])
    output(version_code=code)

    def put_on(track, status="completed"):
        release = {"name": args.release_name, "versionCodes": [str(code)], "status": status}
        edits.tracks().update(packageName=pkg, editId=edit_id, track=track, body={"track": track, "releases": [release]}).execute()

    def commit(**options):
        edits.commit(packageName=pkg, editId=edit_id, **options).execute()

    def try_commit(**options):
        try:
            commit(**options)
            return None
        except HttpError as e:
            print(f"commit {options}: {message(e)}")
            return e

    def keep_unreleased(track, **options):
        """Commits the release on track without releasing it: saved unsent, else as a draft."""
        error = try_commit(changesNotSentForReview=True, **options)
        if error is None:
            return "unsent", None
        if not auto_sent(error):
            return "unsent", error
        put_on(track, status="draft")
        return "draft", try_commit(**options)

    def what_is_in_review():
        newest = newest_release(edits, pkg, edit_id, code)
        if newest:
            print(f"in review: {newest[1] or '(no name)'} ({newest[0]}) on {newest[2]}")
        return newest

    if args.kind == "dev":
        track, state = OPEN_TESTING, "sent"
        put_on(track)
        error = try_commit(changesInReviewBehavior="ERROR_IF_IN_REVIEW")
        if error is not None and in_review(error):
            newest = what_is_in_review()
            if newest is None or not RELEASE_NAME.match(newest[1]):
                # an older dev build: cancel its review and send this one
                error = try_commit(changesInReviewBehavior="CANCEL_IN_REVIEW_AND_SUBMIT")
            else:
                # a release is in review: leave it, keep this one to send later
                state, error = keep_unreleased(track)
        if error is not None and needs_not_sent(error):
            state, error = "unsent", try_commit(changesNotSentForReview=True)
        if error is not None:
            raise error
    else:
        track = PRODUCTION
        before = edits.tracks().get(packageName=pkg, editId=edit_id, track=PRODUCTION).execute()
        put_on(track)
        state, error = keep_unreleased(track, changesInReviewBehavior="ERROR_IF_IN_REVIEW")
        if error is not None and in_review(error):
            newest = what_is_in_review()
            if newest is not None and RELEASE_NAME.match(newest[1]):
                # another release is in review: production stays as it is, this goes to closed testing
                edits.tracks().update(packageName=pkg, editId=edit_id, track=PRODUCTION, body={"track": PRODUCTION, "releases": before.get("releases", [])}).execute()
                track = CLOSED_TESTING
                put_on(track)
                state, error = keep_unreleased(track)
            else:
                # a dev build is in review: it goes on, this release waits
                state, error = keep_unreleased(track)
        if error is not None:
            raise error

    output(track=track, state=state)
    names = {OPEN_TESTING: "open testing", CLOSED_TESTING: "closed testing", PRODUCTION: "production"}
    done = {
        "sent": "sent for review.",
        "unsent": "saved, not sent for review: send it from Play Console (Publishing overview).",
        "draft": "saved as a draft release: review and roll it out from Play Console.",
    }
    summary(f"Google Play: {args.release_name} ({code}) on {names[track]}, {done[state]}")


if __name__ == "__main__":
    main()
