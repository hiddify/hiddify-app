# Woman in Red Dark Theme Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the reviewed dark-only Woman in Red UI into the current iOS MVP without losing access, identity, empty-profile, proxy-selection, routing, or connection-error behavior.

**Architecture:** Preserve the dirty MVP as an immutable checkpoint, then work in an isolated integration worktree. Apply the approved theme snapshot as a curated squash rather than merging the 22-commit feature history; reconcile Home and Proxies manually, and drive the two confirmed Home state fixes through failing tests before production edits.

**Tech Stack:** Flutter 3.38.5, Dart 3.10.4, Riverpod, go_router, flutter_test, Xcode iOS Simulator.

## Global Constraints

- Runtime is dark-only with `#FF2D3E` as the ordinary interactive accent.
- Exclude Matrix loading commit `64665e7c`, design-prototype commits `e804c468..d2ea08a5`, and `.superpowers/sdd/*.md`.
- Preserve every current MVP file and behavior unless a reviewed theme change intentionally replaces presentation only.
- Keep connection, profile, proxy, access, identity, routing, persistence, and subscription behavior truthful under loading and error states.
- Use TDD for behavior changes and fresh full verification before completion.

---

### Task 1: Preserve the current MVP and create isolation

**Files:**
- Preserve: all tracked and untracked files currently present in the main checkout
- Create: `docs/superpowers/plans/2026-07-15-dark-theme-integration.md`

**Interfaces:**
- Produces: branch `checkpoint/mvp-before-dark-theme` containing the complete current MVP snapshot.
- Produces: worktree `.worktrees/dark-theme-integration` on branch `codex/dark-theme-integration`.

- [ ] **Step 1: Create a checkpoint branch and commit the complete current tree**

```bash
git switch -c checkpoint/mvp-before-dark-theme
git add -A
git commit -m "chore: checkpoint iOS MVP before dark theme integration"
```

- [ ] **Step 2: Create the isolated integration worktree**

```bash
git worktree add .worktrees/dark-theme-integration -b codex/dark-theme-integration
```

- [ ] **Step 3: Verify the checkpoint and clean integration baseline**

```bash
git status --short --branch
fvm flutter test
```

Expected: clean integration worktree and zero failing baseline tests. If baseline tests fail, stop and report the exact failures before applying theme commits.

---

### Task 2: Apply the curated dark-theme snapshot

**Files:**
- Apply: `docs/superpowers/specs/2026-07-14-woman-in-red-dark-theme-design.md`
- Modify: theme, app, navigation, Home, proxy, settings, overlay, and corresponding test files present in the reviewed runtime chain
- Exclude: `.superpowers/sdd/task-3-report.md`
- Exclude: `.superpowers/sdd/final-review-fix-report.md`

**Interfaces:**
- Consumes: reviewed runtime commits `a96021bf`, `15e3b404`, `3bfb49bc`, `3304655d`, and `ee7c1fe0..f0466d60` excluding `64665e7c`.
- Produces: one curated runtime diff on top of the MVP checkpoint.

- [ ] **Step 1: Bring in the approved design contract**

```bash
git cherry-pick 6f1d791e
```

- [ ] **Step 2: Apply runtime commits without preserving noisy history**

```bash
git cherry-pick --no-commit a96021bf 15e3b404 3bfb49bc 3304655d ee7c1fe0 de31714b 808d7c9e 76dc96a3 3a8e0f2f bf4ef651 a05bec92 b87bce11 57ba8461 411359b2 e1ef2482 f0466d60
```

Resolve Home and Proxies in favor of the final reviewed presentation first so later fix commits apply, then restore current MVP behavior during Task 3. Delete both SDD report files before staging.

- [ ] **Step 3: Verify the curated patch is mechanically clean**

```bash
git diff --check
git status --short
```

Expected: no Matrix/design/SDD artifacts and no whitespace errors.

---

### Task 3: Reconcile MVP behavior and fix Home state truthfulness

**Files:**
- Modify: `lib/features/home/widget/home_page.dart`
- Modify: `lib/features/proxy/overview/proxies_overview_page.dart`
- Modify: `test/features/home/widget/home_production_integration_test.dart`
- Modify or create focused Home state tests in `test/features/home/widget/`

**Interfaces:**
- Produces: `novaRitualStateForConnection(AsyncValue<ConnectionStatus>) -> NovaRitualState`.
- Produces: `novaHomeServerActionForStates(profileState, proxyState) -> NovaHomeServerAction?`, returning null while the required state is loading or errored.

- [ ] **Step 1: Write failing tests for the confirmed bugs**

Add assertions that:

```dart
expect(
  novaRitualStateForConnection(
    AsyncData(Disconnected(ConnectionFailure.unexpected())),
  ),
  NovaRitualState.error,
);
```

and that initial `AsyncLoading` / `AsyncError` profile or proxy states return no server-card action instead of `addProfile` or `showProfiles`.

- [ ] **Step 2: Run the focused tests and observe RED**

```bash
fvm flutter test test/features/home/widget/home_production_integration_test.dart
```

Expected: failure because the reviewed Home switch maps only `AsyncError` to ritual error and collapses provider state with `valueOrNull`.

- [ ] **Step 3: Implement the minimal state mapping**

Keep `AsyncValue` objects until action/state selection. Map `Disconnected(connectionFailure: non-null)` to `NovaRitualState.error`; return no server action for unresolved/failed profile or proxy state. Render a disabled/loading or explicit error card rather than a misleading action.

- [ ] **Step 4: Restore current MVP behavior in the Nova Home**

Restore installation identity initialization, the identity-profile action, access expiration messaging, and the current no-profile contract while retaining the reviewed dark Nova layout.

- [ ] **Step 5: Combine proxy behaviors**

Keep `NovaGroupedScaffold` and the reviewed dark styling while restoring `AutoModeSelection` result handling and user feedback.

- [ ] **Step 6: Run focused tests and observe GREEN**

```bash
fvm flutter test test/features/home/widget test/features/proxy
```

Expected: all focused tests pass.

- [ ] **Step 7: Commit the curated integration**

```bash
git add -A
git commit -m "feat(theme): integrate dark Woman in Red experience"
```

---

### Task 4: Replace false-green integration checks

**Files:**
- Modify: `test/features/home/widget/home_production_integration_test.dart`
- Modify: `test/core/theme/dark_component_theme_test.dart`

**Interfaces:**
- Produces: widget-level coverage that pumps real changed widgets/routes instead of only scanning Dart source strings.

- [ ] **Step 1: Add production widget assertions**

Pump the production Home state adapters and changed grouped surfaces with real provider values. Exercise connection failure, profile loading/error, proxy loading/error, and at least one navigation selection/reselection path.

- [ ] **Step 2: Run the tests and verify they fail if production wiring is removed**

```bash
fvm flutter test test/features/home/widget/home_production_integration_test.dart test/core/theme/dark_component_theme_test.dart
```

Expected: tests pass with production wiring and fail when the exercised widget/route is disconnected; source-text assertions are not the primary proof.

---

### Task 5: Full verification and visual QA

**Files:**
- Modify only if verification exposes a scoped integration regression.

- [ ] **Step 1: Format and run static checks**

```bash
fvm dart format lib test
git diff --check
fvm flutter analyze
```

- [ ] **Step 2: Run the full suite**

```bash
fvm flutter test
```

Expected: zero failed tests.

- [ ] **Step 3: Build and run the iOS app on iPhone 17 Pro**

Build the `Runner` scheme from `ios/Runner.xcworkspace`, launch `com.womaninred.app`, and inspect Home, Servers, Rules, Settings, identity access, and one bottom sheet.

- [ ] **Step 4: Inspect logs and final diff**

Search for Flutter exceptions, overflow, ParentData, SIGABRT, and fatal errors. Confirm the final branch contains no Matrix/design/SDD artifacts and that the checkpoint branch still preserves the original MVP snapshot.

---

## Completion checklist

- [ ] Original MVP snapshot is recoverable from `checkpoint/mvp-before-dark-theme`.
- [ ] Integration work is isolated on `codex/dark-theme-integration`.
- [ ] Dark-only Woman in Red UI is present without unrelated Matrix/design/SDD history.
- [ ] Access, identity, empty-profile, AutoModeSelection, routing, and connection behavior are preserved.
- [ ] Disconnected failures and loading/error provider states render truthfully.
- [ ] Focused tests, full tests, analyzer, iOS build, screenshots, and logs are verified fresh.
