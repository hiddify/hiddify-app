# Combined release validation — 2026-10-22

Post-delivery correction: build 22 is delivered to TestFlight, but **visual acceptance is FAIL** after the user's device screenshots and comparison with the actual v3 designs. The checks below establish only their stated code/runtime properties; they do not establish complete visual fidelity. See [the visual acceptance contract](visual-acceptance-contract.md). Remote receipt of a build-22 device event remains unconfirmed; live source queries on 22 October returned no events in the recent two-hour window.

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

## Release-run fixture failure and isolated diagnosis

Upload workflow `39784317705` failed before preflight/sign/upload twice on the same source, with 775 passed / 1 failed / 4 skipped. `ios_live_system_status_test.dart` expected Starting while its Start RPC remained under fixture control, but the client RPC had already failed. No binary was uploaded and build 22 was not consumed by these attempts.

The native/start runtime and the test were unchanged from build-21 source. A focused local test initially passed; replacing time-based waiting with real native-event and server-listener barriers made the failure reproducible locally. Closed diagnostic evidence: gRPC UNKNOWN (2), HTTP/2 connection terminated with PROTOCOL_ERROR (1).

A pure gRPC reproduction removed HiddifyCoreService, native channels and UI. With the same cancel/resubscribe/concurrent-Start ordering, an immediately empty LogListener reproduced the protocol error; an open broadcast log stream passed. The fixture returned `const Stream.empty()` for a stream the real core keeps open. grpc 4.0.1 can send its empty completion as a headers/trailers-only frame after cancellation; http2 2.3.1 rejects late headers for the removed stream and terminates the shared connection. Adding an initial status event did not fix the reproducer, ruling out that proposed workaround.

The correction is confined to the test fixture: keep the log stream open until explicit cleanup and await actual native-event/listener barriers. Preserve Starting-before-response and successful-result assertions. No VPN runtime, transport dependency, route or identity change is part of this correction. Scratch protocol probes are retained outside the release test suite.

Final fixture cleanup owns explicit test ClientChannels, terminates them after subscription cancellation, then closes and awaits tracked server streams. Target test: 1/1 passed; complete live status file: 12/12 passed; final full local suite: 776 passed / 4 host-only skips. Independent followup review found no weakened assertions or production changes.
