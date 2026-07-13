---
title: "feat: Rebrand Hiddify build to Woman in Red (isolated, rebase-friendly)"
date: 2026-07-13
type: feat
status: ready
origin:
  - BOOTSTRAP_CLAUDE_CODE.md
  - docs/plans/2026-07-13-001-feat-hiddify-woman-in-red-mac-build-plan.md
  - docs/gpl-compliance.md
target_repo: maikrais98/hiddify-app (branch brand/main)
---

# feat: Rebrand Hiddify build to Woman in Red

## Summary

Rebrand the **already-building** Hiddify fork into **"Woman in Red"** — app name, bundle identifiers, App Group, signing team, icons, and brand accent color — while keeping the change **isolated in a few files** so upstream Hiddify can still be rebased in cleanly. After the edits, the app must **still build** (`flutter build ios --no-codesign` green, `flutter test` green).

This runs on the Mac clone (`~/Documents/KVN/hiddify-app`, branch `brand/main`) where the compile gate already passed. The design layer (`design/`, red Nova tokens) is now on `brand/main` (commit `bcebe17e`) — `git pull` first.

**Deliberately NOT in this plan:** Remnawave subscription wiring, TestFlight/App Store submission, and a full UI reskin to the Nova screens. The brand pass here is **identity + accent color**, not a screen-by-screen redesign — that keeps the diff small and rebase-safe. Full Nova UI is a later, separate effort using `design/` as the reference.

The mechanical edits are provided as a **Codex-runnable block** (Appendix A). Two steps need human input: your **Apple Developer Team ID** and a **source brand logo** for icon generation.

---

## Problem Frame

The build gate (plan 001) proved the Hiddify base compiles unmodified. Now we apply the brand. Two constraints shape *how*:

1. **Rebase-friendliness (bootstrap invariant).** Keep edits in dedicated config/asset files; do not restructure app code or rename the Dart package. When upstream Hiddify releases, `git rebase upstream/main` should apply our brand commits with minimal conflicts.
2. **License compliance (Hiddify Extended GPLv3, see docs/gpl-compliance.md).** The new name/UI must NOT resemble Hiddify (condition 5 — "Woman in Red" + red Nova UI is fine), README must credit Hiddify (condition 3), the fork stays public (1 & 7), and releases go through GitHub Actions (2). Non-commercial only (6).

The rebrand levers were located in research and are unusually clean on iOS: everything keys off one xcconfig variable.

---

## Scope Boundaries

**In scope**
- iOS bundle identity via `ios/Base.xcconfig` (`BASE_BUNDLE_IDENTIFIER`, `SERVICE_IDENTIFIER`, `DEVELOPMENT_TEAM`).
- App display name → "Woman in Red" (iOS `CFBundleDisplayName`, Android `android:label`).
- Android `applicationId` → `com.womaninred`.
- App icons → Woman in Red set (iOS `Assets.xcassets/AppIcon`, Android `mipmap`).
- Brand accent color in the Flutter theme → red `#FF2D3E` from `design/tokens/colors.css`.
- README attribution + changelog (license condition 3).
- Grep sweep for residual `hiddify.com` ids / Hiddify team id; rebuild to confirm still green.

**Out of scope — later plans**
- Remnawave subscription onboarding/wiring.
- Apple signing end-to-end, Network Extension entitlement request, TestFlight distribution (the `DEVELOPMENT_TEAM` change here is prep; actual signing/entitlement is the release plan).
- Full UI reskin to the Nova screens (`design/ui_kits/nova-ios/` is the reference for that later effort).
- Android/desktop release.

**Deferred to Follow-Up Work**
- Retire the abandoned local Karing repo on Windows once brand work is consolidated on the fork.

---

## Key Technical Decisions

**KTD-1 — One lever rebrands iOS identity.** `ios/Base.xcconfig` defines `BASE_BUNDLE_IDENTIFIER=apple.hiddify.com`. The main app, the `HiddifyPacketTunnel` NE (`$(BASE_BUNDLE_IDENTIFIER).HiddifyPacketTunnel`), and the App Group in BOTH entitlements (`group.$(BASE_BUNDLE_IDENTIFIER)`) all derive from it. Changing it to `com.womaninred.app` cascades everywhere — no per-target editing.

**KTD-2 — Keep the Dart package name `hiddify`.** Renaming the pubspec `name:` cascades into every Dart import and guarantees rebase conflicts. Change only display-facing strings and platform ids. Internal package identity stays `hiddify`.

**KTD-3 — `DEVELOPMENT_TEAM` must become your own Apple Team ID.** Currently `3JFTY5BP58` (Hiddify's). Real-device/TestFlight signing fails until this is your team id. `--no-codesign` simulator builds work regardless, so the brand pass stays verifiable without it.

**KTD-4 — Brand = identity + accent, not a screen redesign (yet).** This pass changes name/ids/icons/seed-color only. The Nova screens in `design/` are the blueprint for a later, separate UI reskin. Bundling a full reskin here would bloat the diff and wreck rebase-ability.

**KTD-5 — Leave the NE target name `HiddifyPacketTunnel` as-is (internal).** Renaming the Xcode target is churn-heavy (scheme, build phases, embed rules) for zero user-visible benefit — the NE bundle id already rebrands via KTD-1. Only its id changes, not the target name. (Revisit only if a reviewer objects.)

---

## Toolchain

Same as plan 001: **Flutter 3.38.5, Dart 3.10.x, Xcode 16.x, no Go** (core is downloaded prebuilt — pin core `v4.1.0` / `CHANNEL=prod`). Icon generation needs a source PNG logo; `flutter_launcher_icons` is not currently configured in pubspec, so icons are replaced in the asset catalogs directly (or a generator is added — see U4).

---

## Rebrand Map

| Surface | File | From | To |
|---|---|---|---|
| iOS bundle id (app + NE + App Group) | `ios/Base.xcconfig` | `BASE_BUNDLE_IDENTIFIER=apple.hiddify.com` | `com.womaninred.app` |
| iOS service id | `ios/Base.xcconfig` | `SERVICE_IDENTIFIER=com.hiddify.app` | `com.womaninred.app` |
| iOS signing team | `ios/Base.xcconfig` | `DEVELOPMENT_TEAM=3JFTY5BP58` | `<YOUR_APPLE_TEAM_ID>` |
| iOS display name | `ios/Runner/Info.plist` | `CFBundleDisplayName = Hiddify` | `Woman in Red` |
| Android app id | `android/app/build.gradle` | `applicationId "app.hiddify.com"` | `com.womaninred` |
| Android label | `android/app/src/main/AndroidManifest.xml` | `android:label="Hiddify"` | `Woman in Red` |
| Brand accent | Flutter theme (locate in `lib/`) | Hiddify seed/primary | `#FF2D3E` (red-500) |
| Icons | `ios/.../Assets.xcassets/AppIcon`, `android/.../mipmap-*` | Hiddify | Woman in Red |
| Attribution | `README.md` | — | credit + changelog (license) |

---

## Implementation Units

### U1. iOS bundle identity via Base.xcconfig
**Goal:** app, NE, and App Group all rebranded to `com.womaninred.app`; signing team set to yours.
**Files:** `ios/Base.xcconfig`.
**Approach:** set `BASE_BUNDLE_IDENTIFIER=com.womaninred.app`, `SERVICE_IDENTIFIER=com.womaninred.app`, `DEVELOPMENT_TEAM=<YOUR_APPLE_TEAM_ID>`. Nothing else on iOS needs touching for ids (KTD-1) — entitlements use the variable.
**Verification:** `grep -r apple.hiddify.com ios/` returns nothing; `flutter build ios --no-codesign` still succeeds; the built app's Info shows `com.womaninred.app`.
**Test expectation:** none — config; covered by the U7 rebuild.

### U2. Display name → Woman in Red
**Goal:** user-visible app name is "Woman in Red" on both platforms.
**Files:** `ios/Runner/Info.plist` (`CFBundleDisplayName`), `android/app/src/main/AndroidManifest.xml` (`android:label`). Check localization/`strings` files for a hardcoded "Hiddify" title too.
**Approach:** replace the "Hiddify" strings. Leave `CFBundleName`/`PRODUCT_NAME` (build artifact name) unless it surfaces in UI.
**Verification:** launch shows "Woman in Red" under the icon; `grep -ri ">Hiddify<" ios/ android/` clean (excluding attribution).
**Test expectation:** none — string change.

### U3. Android applicationId
**Goal:** Android store identity is `com.womaninred`.
**Files:** `android/app/build.gradle` (`applicationId`). Decide on `namespace` (`com.hiddify.hiddify`): keep to avoid R-class churn, or align later.
**Approach:** set `applicationId "com.womaninred"`. Keep `namespace` for now (KTD-2 spirit).
**Verification:** `./gradlew :app:assembleDebug` (or `flutter build apk --debug`) succeeds with the new id. (Android is sanity-only; iOS is the target.)
**Test expectation:** none.

### U4. App icons → Woman in Red
**Goal:** brand icon on home screen, both platforms.
**Files:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`, `android/app/src/main/res/mipmap-*/*`. Optionally add a `flutter_launcher_icons` config to `pubspec.yaml`.
**Approach:** generate the icon set from a **source Woman in Red logo (PNG, ≥1024²)** — needs a brand asset from the user. Either add `flutter_launcher_icons` + `dart run flutter_launcher_icons`, or drop generated sizes into the catalogs directly.
**Verification:** installed app shows the new icon; no default Flutter icon remains.
**Test expectation:** none — assets. **Blocked on:** source logo (see Open Questions).

### U5. Brand accent color in the Flutter theme
**Goal:** the app's primary/seed color is the Woman in Red red `#FF2D3E`.
**Files:** the theme definition in `lib/` — locate with `grep -rniE "seedColor|ColorScheme|primary|MaterialTheme|ThemeData" lib/ | head`.
**Approach:** set the seed/primary to `#FF2D3E` (red-500 from `design/tokens/colors.css`). Change tokens only — do not restructure widgets (KTD-4). Keep the change in as few theme files as possible for rebase safety.
**Verification:** primary buttons / active states render red; screenshot the home screen.
**Test expectation:** if the theme has a unit test, keep it green; otherwise none (visual).

### U6. License attribution + changelog
**Goal:** satisfy Hiddify Extended GPLv3 condition 3.
**Files:** `README.md` (or a `README` section), keep fork public.
**Approach:** add a short section crediting Hiddify (`https://github.com/hiddify/hiddify-app`), linking the license, and listing our changes (rebrand, later Remnawave). Reference `docs/gpl-compliance.md`.
**Verification:** README shows attribution + change list; fork is public.
**Test expectation:** none — docs.

### U7. Grep sweep + rebuild (verification gate)
**Goal:** no residual Hiddify identity leaks; app still builds and tests pass.
**Files:** whole tree (read-only sweep), then rebuild.
**Approach:** `grep -rniE "apple.hiddify.com|3JFTY5BP58|com.hiddify.app" ios/ android/` (allow only intentional/attribution hits). Rebuild: `flutter build ios --debug --no-codesign`; `flutter test`.
**Verification (gate):** grep clean of bundle-id/team leaks; iOS build exits 0; tests green (expect 25/25 as before). Commit the brand changes on `brand/main`.
**Test scenarios:** build succeeds post-rebrand; `flutter test` still 25/25; launching shows "Woman in Red" + red accent + new icon.

---

## Risks & Mitigations
- **Apple Team ID unknown (blocks device signing).** → U1 uses a `<YOUR_APPLE_TEAM_ID>` placeholder; `--no-codesign` verifies the rebrand without it. Provide the id when ready.
- **No source logo (blocks U4).** → Provide a ≥1024² PNG; until then U4 is deferred, rest proceeds.
- **Theme reskin scope creep.** → KTD-4: accent only now; full Nova UI later.
- **Rebase friction.** → Keep edits in `Base.xcconfig`, Info.plist, build.gradle, one theme file, assets, README — all dedicated surfaces.
- **License naming term.** → "Woman in Red" + red UI do not resemble Hiddify; compliant.
- **Draft core drift.** → Keep core pinned `v4.1.0` / `CHANNEL=prod` when rebuilding (plan 001 KTD-5).

---

## Open Questions
- **Apple Developer Team ID** for `DEVELOPMENT_TEAM` (U1) — needed for real-device/TestFlight; not needed for the `--no-codesign` verification.
- **Source brand logo** (≥1024² PNG) for icon generation (U4).
- **UI reskin depth** — accent-only now (recommended) vs. begin porting Nova screens. Default: accent-only.

---

## Appendix A — Codex-ready rebrand block (mechanical parts)

> Run on the Mac in the `hiddify-app` repo, branch `brand/main`, AFTER `git pull`. Replace `<YOUR_APPLE_TEAM_ID>`. Icons (U4) and theme color (U5) have manual/asset steps noted inline. Do NOT rename the Dart package or the NE target. Keep core pinned (`CHANNEL=prod` / v4.1.0) when rebuilding.

```bash
cd ~/Documents/KVN/hiddify-app
git checkout brand/main && git pull

# U1 — iOS identity (one lever cascades app + NE + App Group)
sed -i '' 's/^BASE_BUNDLE_IDENTIFIER=.*/BASE_BUNDLE_IDENTIFIER=com.womaninred.app/' ios/Base.xcconfig
sed -i '' 's/^SERVICE_IDENTIFIER=.*/SERVICE_IDENTIFIER=com.womaninred.app/'          ios/Base.xcconfig
sed -i '' 's/^DEVELOPMENT_TEAM=.*/DEVELOPMENT_TEAM=<YOUR_APPLE_TEAM_ID>/'            ios/Base.xcconfig

# U2 — iOS display name  (edit the CFBundleDisplayName value to: Woman in Red)
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Woman in Red" ios/Runner/Info.plist

# U2 — Android label
sed -i '' 's/android:label="Hiddify"/android:label="Woman in Red"/' android/app/src/main/AndroidManifest.xml

# U3 — Android applicationId
sed -i '' 's/applicationId "app.hiddify.com"/applicationId "com.womaninred"/' android/app/build.gradle

# U5 — locate the theme to set the red accent (#FF2D3E) — inspect, then edit by hand
grep -rniE "seedColor|ColorScheme|primary|ThemeData" lib/ | head -20

# U7 — sweep for leaks (only attribution hits allowed)
grep -rniE "apple.hiddify.com|3JFTY5BP58|com.hiddify.app" ios/ android/

# U7 — rebuild + test (must stay green)
flutter build ios --debug --no-codesign
flutter test
```

Manual steps not scriptable here:
- **U4 icons:** generate from a Woman in Red logo (≥1024² PNG) and replace `ios/Runner/Assets.xcassets/AppIcon.appiconset` + `android/app/src/main/res/mipmap-*` (or add `flutter_launcher_icons` to pubspec and run it).
- **U5 theme:** after the grep, set the seed/primary color to `#FF2D3E` in the theme file(s) — red-500 from `design/tokens/colors.css`.
- **U6 README:** add Hiddify attribution + changelog per `docs/gpl-compliance.md`.

**Success = `flutter build ios --no-codesign` green + `flutter test` green + app shows "Woman in Red", red accent, new icon.** Then commit on `brand/main`. Next plan: Remnawave wiring.
