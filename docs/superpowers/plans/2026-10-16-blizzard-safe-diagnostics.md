# Blizzard safe diagnostics implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Ship the authorized iOS safe-logging batch to existing private TestFlight group Test with proven privacy boundaries and unchanged VPN behavior.

**Architecture:** A closed local journal observes an iOS-only repository decorator. Existing Loggy/Sentry and native writers receive rebuilt safe records; the Logs entry presents/copies only the closed journal. Existing persistent signing delivers the reviewed SHA.

**Tech Stack:** Pinned Flutter 3.38.5/Dart, hooks_riverpod, existing SharedPreferences, Swift/Foundation, existing GitHub iOS release controller. No added or upgraded dependencies.

## Global constraints

- Base source da5d55860171df26b92950d0658439248c8e0293; preserve working TestFlight 0.0.1 (5) and IPA.
- Tests first: behavior-based RED, minimum implementation, GREEN, relevant regressions.
- iOS only; no VPN/network/import policy, signing-identity, certificate, entitlement or native-core changes.
- Journal max128 events / 64KiB; native entry max256 bytes / file64KiB. Closed enums; no secret-bearing strings.
- One final candidate after a complete batch; one upload. Apple validity/group/beta readiness and physical-device proof are separate.

### Task 1: Closed local journal

**Files:** lib/features/diagnostics/safe_diagnostic_event.dart; safe_diagnostic_journal.dart; test/features/diagnostics/safe_diagnostic_journal_test.dart.

**Interface:** DiagnosticOperation(setup/connect/reconnect/disconnect/tunnel), DiagnosticStage(requested/accepted/failed/state), DiagnosticCode closed typed-failure/state vocabulary; diagnosticCodeForFailure(ConnectionFailure). SafeDiagnosticJournal(restored,persist,capacity) provides nextOperationId, record, immutable events, broadcast changes, clear, flush, dispose, persistenceFailed and exportJson(version,buildNumber).

- [x] Write and run RED tests for poison failure payloads, enum-only schema, invalid restores, bounded/immutable events, duration clamp, ordered persistence and contained storage failure.
- [x] Implement the smallest journal and classifier satisfying those tests; no raw logger/Sentry imports.
- [x] Run focused tests; inspect a synthetic exported JSON and retained event count. Commit this logical fix with its tests when integrated.

### Task 2: Native and SDK output privacy

**Files:** ios/HiddifyPacketTunnel/Logger.swift; SingBox/ExtensionProvider.swift; ios/Runner/VPN/VPNManager.swift (logging expressions); test/security/native_diagnostics_privacy_test.sh and .swift. lib/core/logger/safe_log_record.dart and logger_controller.dart; lib/core/analytics/analytics_filter.dart and analytics_controller.dart; test/core/logger/safe_log_record_test.dart; test/core/analytics/safe_analytics_filter_test.dart.

- [x] Reproduce RED using synthetic credential/URL/config/path/stack data against the real output boundaries before changing production.
- [x] Implement fixed native codes/caps/reset and central iOS-only Loggy reconstruction. Rebuild direct Sentry events/breadcrumbs from allowlisted data; disable iOS automatic payload channels outside that validation.
- [x] Verify native concurrency, rollover, write failure and unchanged control calls; verify actual outgoing printer/event JSON contains none of the canaries. Preserve other-platform behavior.
- [x] Run Swift writer tests and syntax parsing; run focused Dart sink/SDK tests. Commit logical fixes separately within this batch.

### Task 3: Observe connection actions and present report

**Files:** new lib/features/diagnostics/diagnostic_providers.dart, observed_connection_repository.dart, safe_diagnostics_page.dart; lib/features/connection/data/connection_data_providers.dart; lib/features/log/overview/logs_page.dart; localized copy; new tests under test/features/diagnostics/.

- [x] Write RED tests using RecordingConnectionRepository, deterministic monotonic time, synthetic profile, typed/poison errors, returned Left and thrown object. Verify no delegation before run, identical arguments/results and one subscription with preserved data/errors.
- [x] Write RED widget tests for preview, exact clipboard payload, empty/clear and copy failure. Check that raw-log providers are not consulted.
- [x] Implement the decorator, one-key persistence provider and safe iOS report page. Keep ConnectionRepositoryImpl, ConnectionNotifier and core/native transport semantics unchanged.
- [x] Run focused tests including the current profile-privacy and connection-preservation suites.

### Task 4: Guard, review and publish

**Files:** test/ci/blizzard_runtime_boundary_test.rb and new narrow diagnostics boundary tests; docs/verification/blizzard/safe-diagnostics.md; release-controller pin only after final application SHA exists.

- [x] Retain original runtime/dependency/identity/core invariants and add exact reviewed diagnostic scope; test rejection of unapproved source/native/workflow changes.
- [x] Run complete Flutter tests, analyzer on changed Dart files, Ruby contracts and native privacy checks; inspect source/lock/identity diff. Resolve failures before publication.
- [x] Obtain independent spec/correctness/privacy review of the final diff and integrate the batch.
- [ ] Bind reviewed application SHA in the existing controller, verify live next-free build, sign using existing materials and publish one exact IPA to Test.
- [ ] Verify Apple VALID, assigned=true, READY_FOR_BETA_TESTING/IN_BETA_TESTING; close signing gate; save provenance/receipt and physical-iPhone acceptance checklist.

## Authorization and execution

The user approved the design outline with «Давай» and then explicitly requested /goal completion including TestFlight publication. Execute this plan in this session using focused delegated scopes and parent integration; do not re-ask for routine implementation or the already authorized private release. New certificate/key/revocation, production App Store submission and automatic physical-device installation are excluded.
