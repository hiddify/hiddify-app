# Combined release validation — 2026-10-22

Source base: `3092d6e0644996b2d219f63774aca897eade9ebd`. Candidate release: 0.0.1 (22), selected from live Apple inventory observed 2026-10-22T12:51:17Z (builds 1–21 occupied).

## Executed checks

- Full Flutter suite: 775 passed, 4 host-only skips. Log `/private/tmp/blizzard-final-full-tests.txt`.
- Observability suite: 49 passed, including restore corruption/read failure and overlapping manual tests. Exact HTTP acknowledgement remains separate from search ingress.
- Native iOS geometry: 5 passed on iOS 26.5, including 320×568 / 430×932 and text scale 2. RED reproduced actual overflow; GREEN follows dynamic text slots.
- Native compositor capture fixture: 6 passed (geometry plus capture). `v3-runtime-captures/native-compositor.png` includes actual UIKit glass; Flutter boundary captures omit native views. Fixture metadata/profile/ping are synthetic (4.1.1 (1), Unknown) and are not installed release metadata or traffic evidence.
- Live text-scale transition in dock: RED reproduced two 5px overflows; immediate sizing with animated decoration passes 2/2 dock tests.
- Wave: exact transparent export of Pencil `BiRLT` (1059×780, 3x), rendered 353×260 with the existing lifecycle-aware 12s clock. Reduced motion/accessibility freezes it; inactive/background stops it. Five envelope tests passed.
- Runtime boundary: 36 tests / 1053 assertions passed; release contract 28 / 309 passed. Exact asset and dock file allowances retain dependency/native/identity guards.
- Independent source review at `b5cb85f`: four confirmed findings, all addressed in followup changes. Followup review checked lifecycle, legacy labels, connected guard, and accessibility transitions.

## Native test host provenance

An isolated Flutter iOS host was created at `/private/tmp/blizzard-v3-qa-20261022`, using pinned Flutter 3.38.5, Xcode 26.6 (17F113), iOS SDK 26.5. It links canonical Dart source/assets/tests and copies the exact native glass implementation/registration. It has its own `dev.blizzard.v3qa.hiddify` identity and no VPN extension, App Group, subscription or customer data. Its generated plugin/pod configuration differs from the production host. It proves UI layout and UIKit composition only.

Canonical config-only preparation hydrated the unchanged native core; CocoaPods locally generated a lock delta (integration_test + podspec checksums), captured separately and the tracked production lock restored byte-for-byte. Do not describe the isolated host as a full production/physical VPN validation.

## Remaining acceptance

Actual iPhone traffic after unlock, VoiceOver gestures, native material on older physical iOS, and fresh Better Stack receipt for build 22 require the delivered build and device scenario. The root cause of absent build-21 events was not established; the new sender exposes storage/budget/retry/request outcomes instead of claiming queueing proves delivery. Free caps remain 64 KiB/install/UTC day including retries and Sentry 10/install/month; no paid settings changed.
