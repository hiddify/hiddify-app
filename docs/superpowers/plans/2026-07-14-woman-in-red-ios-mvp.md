# Woman in Red iOS MVP Implementation Plan

**Goal:** Deliver the independently implementable production customer loop on top of Hiddify's existing Flutter, profile-import, proxy, persistence, and iOS tunnel layers, while recording external verification gates honestly.

**Architecture:** The confirmed access mechanism is private profile import by URL, QR/deep link, or local file. Email is optional local recovery metadata and never authorizes access because no verified backend contract exists. New identity and access-state logic stays in focused Flutter feature files and consumes the existing Riverpod and SharedPreferences infrastructure.

**Tech stack:** Flutter 3.38.5, Dart 3.10.4, Riverpod, go_router, SharedPreferences, Hiddify profile/proxy/connection layers, iOS Network Extension.

## Global constraints

- Do not add billing, StoreKit, prices, trials, purchases, or upgrades.
- Do not log email, private subscription URLs, tokens, credentials, or VPN configuration.
- Do not invent a Remnawave or email-verification API.
- Preserve user changes in `ios/Podfile.lock` and `ios/Runner.xcodeproj/project.pbxproj`.
- Do not commit, push, submit, or change external systems.

## Task 1: Identity and access domain

**Files:**
- Create `lib/features/identity/model/email_address.dart`
- Create `lib/features/identity/data/installation_identity_store.dart`
- Create `lib/features/access/model/access_state.dart`
- Test `test/features/identity/email_address_test.dart`
- Test `test/features/identity/installation_identity_store_test.dart`
- Test `test/features/access/access_state_test.dart`

- [ ] Write focused failing tests for email normalization/validation, stable generated installation IDs, and no/loading/active/expired/unavailable access mapping.
- [ ] Run each focused test and verify the expected red failure.
- [ ] Implement the smallest pure domain/store code needed for green tests.
- [ ] Re-run focused tests.

## Task 2: Local profile and honest access entry

**Files:**
- Create `lib/features/identity/overview/identity_profile_page.dart`
- Modify `lib/core/preferences/general_preferences.dart`
- Modify `lib/core/router/go_router/routing_config_notifier.dart`
- Modify `lib/features/home/widget/home_page.dart`
- Modify `lib/features/intro/widget/intro_page.dart`
- Modify `assets/translations/en.i18n.json`
- Modify `assets/translations/ru.i18n.json`

- [ ] Persist optional normalized email and local avatar path; display email as unverified because no backend verifier exists.
- [ ] Generate and persist an anonymous installation ID without displaying or logging it.
- [ ] Use the existing iOS document/photo picker path for local avatar choice; support replace and remove.
- [ ] Route Home and Settings to the profile page.
- [ ] Make Home render a real no-access action instead of a connection control that silently no-ops.
- [ ] Update English and Russian onboarding/access copy and regenerate Slang output.

## Task 3: Auto Mode and connection safety

**Files:**
- Create `lib/features/proxy/model/auto_mode_selection.dart`
- Test `test/features/proxy/model/auto_mode_selection_test.dart`
- Modify only the existing proxy notifier/repository integration if the live `OutboundGroup` contract exposes candidates before connection.

- [ ] Test authorization filtering, health filtering, measured-latency ordering, deterministic fallback, and structured reasons.
- [ ] Reuse existing core URL testing and `selectProxy`; do not add a second ping engine.
- [ ] If candidate data is unavailable until the tunnel starts, retain the core selector and document this exact integration gate instead of inventing data.

## Task 4: Release and privacy evidence

**Files:**
- Create `docs/privacy-data-inventory.md`
- Create `docs/release/ios-mvp-verification.md`

- [ ] Inventory identity, email, avatar, subscription secrets, configuration, credentials, logs, and crash reporting.
- [ ] Record baseline and final test/analyze/build evidence, simulator/device status, and external owner actions.
- [ ] Run focused tests, full `flutter test`, scoped analyze, full `flutter analyze`, and `flutter build ios --release --no-codesign`.
- [ ] Attempt simulator launch if an iOS simulator runtime is available.
- [ ] Mark signed real-device tunnel verification blocked unless signing team, entitlements, device, and a private test subscription are actually available.
