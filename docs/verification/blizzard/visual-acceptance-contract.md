# Blizzard visual acceptance

Build 22 was delivered, but its visual acceptance was insufficient. A transfer map,
matching dimensions, a native material class, or successful compilation is not
evidence that an implemented screen matches the design. The user's device captures
showed fused settings rows, an almost static wave, and a weak glass appearance.

## Required evidence before a visual OK

1. Freeze the reviewed design inputs: Pencil file, exact node IDs, exported images,
   export scale, and hashes. Current reference screens are Home `QjgLs` and Settings
   `cIxE0`. An automatic runtime golden is a separate reference, not a replacement
   for these design inputs.
2. Capture the actual application UI on iOS, using deterministic synthetic profiles,
   VPN states, locale, text scale, viewport, and OS version. Exercise real routes,
   sheets, controls, and settings. Record the exact source SHA plus dirty-diff hash,
   fixture identity, native source hash, and capture command. Fixture captures do
   not establish physical VPN traffic or installed-release behavior.
3. Use OS compositor screenshots for native glass. Flutter RepaintBoundary images
   omit UIKit platform views and cannot approve their optical appearance. Compare
   controlled contrast behind each material in at least two phases, then compare
   its appearance over the real application background.
4. Inspect design and runtime side by side and with aligned regional overlays:
   header, status, main action, wave, server/profile cards, navigation, settings
   groups, and open sheets. Check geometry, grouping, typography, color, transparency,
   clipping, and hit targets. Record every difference with PASS/FAIL/BLOCKED. Do not
   mask failed regions or regenerate a baseline merely to accept a change.
5. Inspect a short motion recording or sequence of actual frames: normal motion,
   reduced motion, background/resume, and tab return. A pixel change alone does
   not establish visible snowfall, a continuous backdrop, or fluid animation.
6. Run targeted behavior, layout, accessibility, and pixel regression tests. Include
   compact and normal iPhone viewports, long names, large text, loading/error/empty
   states, and Reduce Transparency. Runtime goldens must come from an already
   visually approved implementation; font/native-material differences need explicit
   bounded tolerances rather than a blanket percentage for the whole screen.
7. Publish a review report with links to design exports, runtime images, comparison
   images, motion evidence, test results, source/design identities, reviewer, and
   unresolved differences. Any missing required evidence is BLOCKED. Any unresolved
   material mismatch is FAIL. Only all required checks passing permits visual OK.

## Release enforcement

The visual verdict must bind to the exact reviewed source and design inputs. A new
source/design diff invalidates the prior verdict for affected screens. Collecting
screenshots may be automated during a build; accepting them requires actual visual
review. A green capture job alone must never emit visual OK.

Start with local iOS capture and review to avoid repeated paid services or cloud
runner usage. CI can later retain the same artifacts and require the matching
review verdict before signing/upload. This document defines that contract; it does
not claim that an enforced CI release gate already exists.

Keep separate statuses for compilation/tests, visual acceptance, TestFlight
availability, physical VPN behavior, and remote diagnostic receipt. None implies
the others passed.
