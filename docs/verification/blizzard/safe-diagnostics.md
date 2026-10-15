# Blizzard iOS: safe diagnostics release batch

## Scope and baseline

This batch starts from working TestFlight 0.0.1 (5), application source `da5d55860171df26b92950d0658439248c8e0293`. It addresses the current logging audit. The signed baseline IPA is preserved outside the repository. Application identity, entitlements, core framework, dependencies, VPN/import policies and control flow are unchanged.

## Output boundaries

- iOS Loggy records are rebuilt before console, optional file and analytics printers. Only fixed severity codes and a constant logger name reach those printers. Raw message/object/error/stack/caller/zone fields are discarded. Other platforms retain their prior records.
- iOS Sentry events and breadcrumbs use a closed vocabulary. The final transport removes attachments, scope enrichment, tracing and non-event items. The native SDK is not initialized, so its cached envelopes cannot bypass the Dart boundary; safe events use the built-in Dart HTTP transport with the existing DSN. Automatic crash/performance paths outside the verified boundary are disabled. Synthetic markers, never real subscriptions or private logs, exercise these boundaries.
- The packet-tunnel writer emits only timestamp, severity and a closed code. Each entry is capped at 256 bytes and the file at 64 KiB, with synchronized rollover/reset and nonthrowing I/O failures. Classification reads only the first 4096 UTF-8 bytes. Runner error prints use fixed stage/code strings.
- The existing iOS Logs entry shows only the safe journal. It does not read the raw core/app log providers or offer their file-sharing actions. Copy is explicit and uses the exact displayed JSON.

These claims apply to the reviewed application output paths. They do not claim to erase historical raw files, inspect a binary framework's internal memory, or verify physical-device VPN traffic.

## Journal and observer contract

The journal stores at most 128 immutable events and exports at most 64 KiB. Fields are closed enums and bounded numbers. Restore rejects malformed data, unknown fields/codes and oversized documents. App version/build metadata is validated. Persistence uses one in-flight write and one replaceable latest snapshot; storage failures are contained and shown with fixed wording.

The repository decorator preserves the original method construction, lazy task execution, arguments, returned Either identity, thrown objects and stream data/error ordering. `accepted` means command completion, not working traffic. Unsolicited tunnel state uses operation id zero and `reachability=not_checked`.

The existing connection repository, connection notifier, core service and native method/status transport are unchanged. Existing issues such as ignored changeOptions Left and swallowed native start errors remain outside this batch; the report must not hide their acceptance/traffic distinction.

## Verification protocol

Tests were introduced before production changes. Expected RED runs demonstrated missing safe boundaries, raw output, unbounded classifier input and queued persistence growth and reentrant clear restoring a stale snapshot. GREEN checks exercise the real Swift writer, real SDK envelope serialization, actual printer records, repository observation, one-key persistence, exact preview/copy/clear and raw-provider isolation. Existing notifier scenarios run both with and without the decorator.

Run the finished batch with pinned Flutter 3.38.5 and the unchanged lockfile:

```sh
flutter test --no-pub
./test/security/native_diagnostics_privacy_test.sh
ruby test/ci/blizzard_runtime_boundary_test.rb
ruby test/ci/ios_baseline_identity_inventory_test.rb
ruby test/ci/ios_baseline_signed_entitlements_test.rb
ruby test/ci/ios_baseline_release_test.rb
ruby test/ci/ios_baseline_workflow_test.rb
```

The runtime guard retains the original baseline and exact profile-privacy exceptions. Additional diagnostics files and edits require explicit reviewed fingerprints; extra bytes, unapproved runtime/native files, dependency/identity/pipeline changes remain rejected.

## Finished local checks

- Full Flutter suite: 453 passed.
- Runtime/native/dependency/identity boundary: 29 tests, 777 assertions passed.
- Native writer: hostile data, 2000 concurrent writes, byte caps, rollover/reset, bounded classification and contained I/O failure passed; all three changed Swift files passed syntax parsing.
- Release contracts: 112 tests completed without failures; one optional local signed-fixture reproduction was skipped. The actual signed IPA check remains mandatory in the release pipeline.
- Changed Dart files: no new analysis findings. The two findings in unchanged baseline statements (legacy unnecessary async and dead code) were verified against the baseline and left outside scope.
- Independent reviews found no remaining blockers in the journal/observer, native/output, UI/provider and runtime-boundary changes. Tests use synthetic data; physical iOS runtime acceptance is pending.

## Delivery acceptance

Publish one exact reviewed source revision through the existing protected controller using existing persistent signing materials. Query the free build number live, verify the signed artifact and upload once. Completion requires the intended marketing/build version, Apple `VALID`, assignment to existing group `Test`, and `READY_FOR_BETA_TESTING` or `IN_BETA_TESTING`. An uncertain upload resumes status/group verification without a second upload. The signing readiness flag is closed after use.

Physical iPhone acceptance remains separate: update manually in TestFlight, check preserved profiles, connect and open real sites, disconnect/reconnect, switch Wi-Fi/mobile data, lock/unlock and inspect/copy/clear the safe report. The report itself does not prove working VPN traffic. No automatic installation or production App Store submission is part of this batch.
