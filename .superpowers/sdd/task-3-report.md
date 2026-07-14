# Task 3 Report: Inherited Home and Nova theming

## Status

Implemented the Task 3 Home/Nova migration onto inherited Woman in Red dark semantics. Home no longer creates a private `ThemeData` or system-overlay wrapper; the dock, connection control, and ritual read `NovaThemeData.of(context)`. The initial `ee7c1fe0` commit also captured a pre-existing, inherited full Home rewrite that was already dirty when Task 3 began. Task 3 did not author that product rewrite, but the earlier report incorrectly described the resulting commit as leaving the Home content tree and route decisions unchanged. The review fix keeps the inherited design, integrates it into production, and adds regression coverage for its provider/action contracts.

## TDD evidence

### RED

Command:

```bash
fvm flutter test test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

The first sandboxed attempt could not update the pinned Flutter cache (`engine.stamp: Operation not permitted`), so the exact command was rerun with the required filesystem permission. Expected RED evidence:

```text
nova_glass_tab_bar_test.dart: Bad state: No element
  `nova_dock_surface` did not exist.

nova_ritual_hero_test.dart:
  Expected inheritedTheme.tertiaryText (0xFF909090)
  Actual NovaColors.tertiaryText (0xFF6E6E73)

00:03 +2 -2: Some tests failed.
```

The connection contract was then extended to inspect the actual disconnected radial gradient, and failed for the intended reason:

```text
Expected: [inheritedTheme.elevatedSurface, inheritedTheme.background]
Actual: [NovaColors.elevatedSurface, NovaColors.voidBackground]
00:01 +0 -1: Some tests failed.
```

Additional accessibility RED assertions confirmed the disabled icon still used `secondaryText` and the dock surface/accessibility key was absent.

### Pre-review GREEN history

Final focused command:

```bash
fvm flutter test test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

Output summary:

```text
00:02 +6: All tests passed!
```

## Pre-review static-analysis history

Command:

```bash
fvm flutter analyze lib/features/home/widget/home_page.dart lib/core/widget/nova_glass_tab_bar.dart lib/features/home/widget/nova_connection_control.dart lib/features/home/widget/nova_ritual_hero.dart test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

Final output:

```text
Analyzing 7 items...
No issues found! (ran in 3.0s)
```

The first analyzer pass reported style/deprecation infos. Replacing deprecated semantics flag access initially exposed the new typed `SemanticsFlags` API; the tests now use `flagsCollection.isSelected` and `flagsCollection.isButton`. The final scoped analyzer is clean.

## Pre-review full-suite history

Command:

```bash
fvm flutter test
```

Output summary:

```text
00:09 +43: All tests passed!
```

This result predates both review-fix rounds and the later uncommitted Matrix tests in the shared worktree. It is retained as historical evidence only; the latest verification at the end of this report is authoritative.

## Implementation

- Removed Home's local dark `ThemeData`, `Theme`, and `AnnotatedRegion` wrappers; the existing scaffold now uses inherited `nova.background`.
- Replaced Home's semantic progress value with inherited `pressedSurface`; decorative brand copy and neutral traffic metrics use label semantics rather than accent/status colors.
- Added `nova_dock_surface`; the dock now inherits glass/elevated/border/separator colors and preserves all four destination semantics.
- High contrast and reduced-effects modes remove dock blur and use the opaque inherited elevated surface; reduced motion makes dock animation duration zero.
- The connection control keeps a 168-by-168 target, inherits disconnected gradient colors, uses `disabled` for unavailable state, and disables animation when requested.
- The ritual painter receives inherited accent/separator/disabled colors and includes all painter inputs in `shouldRepaint`; status, glyph, and connecting-symbol colors are semantic.
- `disableAnimations` and `accessibleNavigation` are used as the available Flutter reduced-effects signals. Flutter 3.38 does not expose a separate reduce-transparency `MediaQueryData` field, so these settings conservatively disable both nonessential motion and dock translucency; `highContrast` independently forces the same opaque treatment.

## Files

- `lib/features/home/widget/home_page.dart`
- `lib/core/widget/nova_glass_tab_bar.dart`
- `lib/features/home/widget/nova_connection_control.dart`
- `lib/features/home/widget/nova_ritual_hero.dart`
- `lib/features/home/widget/connection_button.dart`
- `lib/core/router/adaptive_layout/my_adaptive_layout.dart`
- `lib/core/router/adaptive_layout/nova_tab_route.dart`
- `test/core/nova_tab_route_test.dart`
- `test/core/widget/nova_glass_tab_bar_test.dart`
- `test/features/home/widget/home_production_integration_test.dart`
- `test/features/home/widget/nova_connection_control_test.dart`
- `test/features/home/widget/nova_ritual_hero_test.dart`
- `.superpowers/sdd/task-3-report.md`

Aggregate Task 3 scope is the 13 paths listed above. `ee7c1fe0` contained 8 paths; `de31714b` contained all 13 integration/review paths; `808d7c9e` contained 7 focus/semantics paths; the destination-aware follow-up contains 5 existing paths. Unrelated Matrix loading and dependency work remains outside every Task 3 commit.

## Self-review

- Re-read the Task 3 brief and approved design spec after implementation.
- Confirmed no scoped widget references `NovaThemeData.dark`, creates a private `ThemeData`, or wraps Home in its own `Theme`/`AnnotatedRegion`.
- Confirmed the inherited Home rewrite landed inside `ee7c1fe0`; added explicit regression coverage for server-card route decisions, quick settings/profile actions, and the connection provider adapter instead of claiming the entire content tree was unchanged.
- Confirmed the connection control remains at least 44 points and all four dock semantics nodes remain present.
- Confirmed high-contrast surfaces use inherited `elevatedSurface` plus `separator`, and reduced-motion animation durations are zero.
- Ran `git diff --check`; no whitespace errors were reported.
- Verified each commit's staged file list against its declared scope; the aggregate path list above contains 13 unique paths.

## Concerns

- No Task 3 test, analyzer, or implementation blocker remains.
- Flutter 3.38 has no dedicated reduce-transparency media flag. The conservative reduced-effects mapping is documented above and covered by widget tests.
- The Home/Nova files contained inherited uncommitted implementation work at task start. They were intentionally modified in place per the brief; unrelated files remain unstaged.

## Review fix after `ee7c1fe0`

### RED evidence

The review tests failed for the intended missing behavior:

```text
nova_connection_control_test.dart:
Expected: true
Actual: false
```

The outer connection semantics node announced a button but did not expose `SemanticsAction.tap`.

```text
nova_ritual_hero_test.dart:
Expected: no matching candidates
Actual: Found RichText "ア"
```

Decorative ritual glyphs were present in the semantics tree.

```text
home_production_integration_test.dart:
Error: Method not found: 'novaHomeServerAction'
Error: Undefined name 'NovaHomeServerAction'
```

The inherited server-card branching had no isolated regression contract. The production integration test also identified that the already-written `ConnectionButton`/adaptive-layout adapters were still dirty rather than committed.

### Review implementation choices

- Committed the inherited production adapters: `ConnectionButton` renders `NovaConnectionControl`; the mobile adaptive layout renders `NovaGlassTabBar`; `novaTabForLocation` maps existing production routes. Desktop `NavigationRail` remains unchanged.
- Added `Semantics.onTap` only when the connection is enabled. Pointer activation stays on the inner `InkWell`; assistive activation stays on the outer semantics node, so each input path invokes the callback once. Disabled controls expose no tap action.
- Added a pure, behavior-preserving `novaHomeServerAction` decision function covering add-profile, profiles-overview, and proxies navigation. Source-contract tests retain quick-settings/profile calls and connection provider decisions.
- Removed raw `NovaColors`, fixed hex shadows, and white glow values from Home/Nova widgets. Connected effects derive from inherited accent/fill/surface roles; generic shadows derive from `ThemeData.shadowColor`.
- Rendered `Woman in Red`, download, and upload metrics with neutral primary-label semantics instead of decorative red.
- Wrapped decorative ritual glyphs in `ExcludeSemantics` while retaining the meaningful status/control nodes.
- Verified the Flutter 3.38 SDK source has no Reduce Transparency field in `MediaQueryData` or `AccessibilityFeatures`. Product waiver: no new platform channel is introduced in this scoped theme migration. All available conservative signals (`disableAnimations`, `accessibleNavigation`, and `highContrast`) independently force the dock opaque; tests cover each signal.

### Review verification

Focused command:

```bash
fvm flutter test test/core/nova_tab_route_test.dart test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/home_production_integration_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

First-review focused result:

```text
00:13 +14: All tests passed!
```

Scoped analyzer command:

```bash
fvm flutter analyze lib/core/router/adaptive_layout/my_adaptive_layout.dart lib/core/router/adaptive_layout/nova_tab_route.dart lib/core/widget/nova_glass_tab_bar.dart lib/features/home/widget/connection_button.dart lib/features/home/widget/home_page.dart lib/features/home/widget/nova_connection_control.dart lib/features/home/widget/nova_ritual_hero.dart test/core/nova_tab_route_test.dart test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/home_production_integration_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

```text
Analyzing 12 items...
No issues found! (ran in 3.9s)
```

The first review's full-suite failure was later superseded by changes in the unrelated Matrix work. See the authoritative re-review verification below.

## Re-review fix after `de31714b`

### RED evidence

Dock semantics and reselection tests failed for the intended missing behavior:

```text
Expected SemanticsAction.tap: true
Actual: false

Expected selected Home re-tap: [NovaTab.home]
Actual: []
```

The production contracts also failed because `shouldResetNovaBranch` and the mobile `FocusScope(node: navScopeNode)` wrapper were absent.

### Implementation

- Added `Semantics.onTap` to each outer dock destination node. Pointer input remains on the inner `InkWell`; assistive input uses the outer semantics action. Tests invoke both paths independently and observe one callback per activation.
- Removed the selected-tab early return from the dock so reselection reaches the navigation adapter. Haptic selection remains limited to a changed destination.
- Restored the mobile navigation focus scope around a nested Stack containing the positioned dock. The nested Stack preserves `PositionedDirectional` parent-data correctness while keeping only dock controls inside `navScopeNode`.
- Added `shouldResetNovaBranch`; reselecting the current Nova tab now calls `navigationShell.goBranch(navigationShell.currentIndex, initialLocation: true)`. Selecting a different tab preserves the existing named-route navigation.

### Authoritative verification

Focused Task 3 command:

```bash
fvm flutter test test/core/nova_tab_route_test.dart test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/home_production_integration_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

```text
00:04 +16: All tests passed!
```

Scoped analyzer:

```text
Analyzing 12 items...
No issues found! (ran in 3.7s)
```

All tests except the unrelated uncommitted Matrix-loading paths:

```text
00:06 +52: All tests passed!
```

The full command `fvm flutter test` produced 59 passing tests and one unrelated uncommitted Matrix asset failure at this point in history. That result is superseded by the destination-aware verification below.

## Destination-aware re-review fix after `808d7c9e`

### RED evidence

The route-unit test did not compile after adding the four required reselection expectations because `NovaTabReselectionAction` and `novaTabReselectionAction` did not yet exist. The production source contract also lacked a destination-aware reselection switch.

### Implementation

- Kept route-location mapping as the selected-dock source of truth, including nested `/home/proxies/...` routes.
- Added an explicit reselection action for every Nova destination. Home and Settings reset their shell branch; Servers navigates to the `proxies` root; Rules navigates to the `routingOptions` root.
- Preserved existing named-route behavior when selecting a different dock destination.

### Latest authoritative verification

Focused Task 3 command:

```bash
fvm flutter test test/core/nova_tab_route_test.dart test/core/widget/nova_glass_tab_bar_test.dart test/features/home/widget/home_production_integration_test.dart test/features/home/widget/nova_connection_control_test.dart test/features/home/widget/nova_ritual_hero_test.dart
```

```text
00:13 +17: All tests passed!
```

Scoped analyzer:

```text
Analyzing 12 items...
No issues found! (ran in 14.8s)
```

All tests except the unrelated uncommitted Matrix-loading paths:

```text
00:29 +53: All tests passed!
```

The full command `fvm flutter test` now passes all 60 tests. The previously recorded Matrix asset mismatch was resolved by concurrent Matrix changes already present in the shared worktree; this Task 3 follow-up did not modify or stage those files.
