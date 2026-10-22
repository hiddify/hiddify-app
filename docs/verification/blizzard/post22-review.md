# Post-build-22 review — 22 October 2026

**Overall visual acceptance: NOT APPROVED. Remote build-22 ingress: NOT CONFIRMED.**
The changes described here are local and have not been uploaded to TestFlight.
Base source is `f485e7b2671f94256da3b13714ff0501594a11c7`; runtime-diff SHA-256:
`f51c6259685935a1ca482bcf39997b01833123aa3ca2c7673be973a7e67d5f30`.

## Implemented corrections

- Settings now uses the v3 Application/Connection/Diagnostics groups, 18px group
  corners, 48px minimum rows, 13px headings, and the separate red reset action.
  Dividers consume no layout height. Large text can expand rows.
- The exact v3 wave asset remains in its approved slot. A continuous particle
  field now moves behind it and through its transparent center. Integer travel
  periods remove the particle jump at the twelve-second loop seam.
- Reduce Motion no longer incorrectly forces opaque glass. UIKit still handles
  Reduce Transparency. Native regular glass now has a visible translucent
  highlight and rim; the native material and its transmission are retained.
- Blizzard's main control uses the approved 48px power icon and cyan action text.
- Manual diagnostic tests preserve the actual retry/budget/storage blocker instead
  of overwriting it with pending. Retry counters and free-tier caps are unchanged.

## Evidence and limits

| Check | Result |
| --- | --- |
| Full Flutter suite | 800 passed; 4 existing host-only skips |
| Actual iOS Home control integration | PASS: eligibility, power icon/color, 148px control, action color, real toggle callback |
| Settings dimensions, groups, reset, large text | PASS targeted renderer tests; final native screenshot inspected |
| Native glass transmission | PASS on controlled checkerboard and moving snow inside the real Home lens |
| Motion | Actual OS recording 15.755 seconds; parent inspected 600ms pair and frames at 1s/14s; pixel regression covers loop continuity, lifecycle, Reduce Motion |
| Final diagnostic capture harness | FAIL at teardown: `A SemanticsHandle was active at the end of the test`; assertions were not weakened |
| Static analysis | Eight existing ConnectionButton warnings reproduced on exact base source; no cleanup bundled |
| Physical iPhone/network/VoiceOver | Not accepted by these simulator fixtures |
| Remote diagnostics | No build-22 event received in queried source |

Design references are Pencil `QjgLs` and `cIxE0`, exported at 3x. Captures use
iOS 26.5 at 402×874 logical pixels; reference artboards are 393×852. Comparison
therefore checks responsive geometry and individual regions, not zero-error
whole-image equality. Fixture metadata/profile/ping are synthetic: `4.1.1 (1)`,
`Synthetic profile`, and unavailable ping do not describe the released app.

The main reported layout/motion/material defects are addressed, but full v3
fidelity is not approved: profile-card treatment, Settings icon shapes, and status
wording still differ; the realistic connected-server/profile states also need
matching fixture data. The capture harness teardown must be resolved separately
before its job can become a release gate. Neither screenshots nor successful unit
tests turn this capture job green.

Evidence is saved at
`/Users/stasyudkin/Documents/KVN/review-evidence/2026-10-22/blizzard-post22/`:
design exports, final Home/Settings/optics PNGs, motion MP4, selected motion frames,
and hashed manifests. Both parent and specialist inspected the final screenshots.

## Remote receipt check

Read-only Better Stack query, source 2805644, window
`2026-10-22T00:00:00Z` through `2026-10-22T16:14:17Z`:
99 events, all version 0.0.1 build 20; latest `2026-10-22T10:05:42.858685Z`.
No build-22 receipt. Device-local delivery fields are still required to determine
whether the original transport failure was a timeout, HTTP rejection, cooldown,
or another cause. The proven status repair does not establish end-to-end delivery.

### Device evidence received after the initial review

The user's build-22 screenshot at 19:47 Moscow time shows `budgetLimited`, 100
queued events, oldest age 3026 seconds, 74880 used bytes, zero remaining, and next
attempt no earlier than `2026-10-23T00:00:00Z` (03:00 Moscow). No last-request or
HTTP value is displayed. This proves the immediate local blocker; it does not
prove which requests were attempted or accepted earlier.

The counter reserves bytes before network I/O, including failed attempts. Its
persistent key is shared across upgrades. Historical source `8841314e` used a
256 KiB daily cap; the current 64 KiB cap intentionally preserves larger legacy
counters without resetting them. The existing `read-only log snapshot preserves
legacy use without resetting it` regression covers that migration. Thus 74880
bytes is compatible with inherited usage; the screenshot alone does not prove
that build 22 exceeded its own cap. Exact origin of that usage is not established.

This is the application's per-installation safety budget, not evidence that the
Better Stack account's free quota is exhausted. No quota reset or increase was
performed. End-to-end delivery still needs a successful request after allowance
renewal; the displayed date is a not-before boundary, not a guaranteed delivery
time.

Follow [the visual acceptance contract](visual-acceptance-contract.md) before
marking a future release visually ready. Automated capture was exercised locally;
an enforced CI visual-approval gate has not yet been implemented.
