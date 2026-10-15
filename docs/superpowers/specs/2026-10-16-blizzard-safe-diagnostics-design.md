# Blizzard iOS safe diagnostics

## Authorized outcome

The user approved a single safe-diagnostics batch and explicitly requested goal-mode completion through private TestFlight publication. Base application source is `da5d55860171df26b92950d0658439248c8e0293`, working Blizzard 0.0.1 (5). Preserve that source branch and IPA. This batch fixes logging; it does not repair unrelated connection/import behavior.

## Evidence and decisions

The current source lacks the safe-diagnostics implementation from the older observability fork. Loggy forwards raw message/error/stack fields to console, optional files and Sentry. The iOS extension persists raw messages without a size cap. Logs UI reads raw core messages and can export entire files in debug mode. Prior research is evidence for test cases, not permission to copy unrelated runtime changes.

Use a closed local journal and explicit copy action. Regex-redacting arbitrary text cannot reliably exclude unfamiliar secrets; adding a remote diagnostics service would add credentials and data-transfer decisions. Neither is necessary for this batch. Existing iOS telemetry sinks must receive only rebuilt closed data, including direct SDK exception capture; unfiltered automatic tracing/native crash payloads are disabled on iOS. Other platforms retain their existing logging behavior.

## Data flow

Wrap the existing ConnectionRepository in an observation-only decorator on iOS. Delegated calls, arguments, results, thrown objects, stream ordering and business logic stay unchanged. The decorator records setup/connect/reconnect/disconnect request and command completion/failure. A successful command is **accepted**, not evidence that the tunnel or traffic works. Separately observed tunnel starting/started/stopping/stopped events always carry `reachability=not_checked` and no inferred traffic result.

SafeDiagnosticJournal stores at most 128 immutable events, bounded to 64 KiB. Operation numbers and sequence numbers are local numeric correlation counters, never user/profile/device identifiers. Durations use a monotonic clock and clamp at one hour. Fixed enums determine operation/stage/code. Failure classification inspects ConnectionFailure variants without reading payloads or calling toString. No URLs, IPs, UUIDs, user data, configs, raw errors, stacks or arbitrary metadata are accepted into event fields.

Persist only the closed journal to one dedicated SharedPreferences key. Existing preferences are untouched. Validate restored data strictly and reject oversized, malformed, unexpected-field or unknown-code data. Serialize persistence operations and contain storage failures; diagnostic recording must not interrupt VPN actions. A storage failure leaves an in-memory report and is reported without raw exception text.

On iOS the existing Logs entry opens the safe report, with bounded live events, an empty state, clear, selectable JSON preview and explicit copy. Raw log repositories/files are not read by that page or copied. The report includes only validated package version/build metadata and fixed platform/schema. Use the current UI/theme and existing localization conventions; provide Russian and English copy. Keep other platforms' Logs page unchanged.

Native Packet Tunnel logging uses fixed codes, per-entry 256-byte and file 64-KiB caps, synchronized writes, atomic rollover and lifecycle reset. File-write failure is contained. Preserve VPN configuration, identities, entitlements, start/stop/reload ordering, NSError domain/code and existing error propagation semantics. Runner console statements emit fixed stage/error codes rather than localized errors.

## Verification and delivery

Tests precede production changes: hostile synthetic canaries/poison objects, exact JSON allowlist, strict restoration, caps and persistence ordering/failure; real Swift writer concurrency/reset/caps; real repository-decorator lazy execution/result/error/stream preservation; UI preview/copy/clear/failure; actual console/file/Sentry outgoing-record privacy. Extend the original runtime boundary only for explicitly reviewed diagnostic files and retain untouched VPN/dependency/identity/framework checks.

Run focused tests during implementation, then one complete Flutter/regression/analyzer/native verification pass on the finished batch. Independently review the exact diff. Publish the reviewed application SHA through the existing protected iOS-only release controller and persistent signing identity. Query the next free build live; upload once, and use status-only recovery after an uncertain upload. Completion requires Apple VALID, assignment to existing group Test and READY_FOR_BETA_TESTING/IN_BETA_TESTING. Physical iPhone traffic and report usability remain separately reported user acceptance; do not install automatically.

## Explicit deferred findings

ConnectionRepository.applyConfigOption currently ignores a changeOptions Left, and VPNManager.connect swallows native start errors. Fixing those would alter VPN behavior and is outside this logging batch. Diagnostics must distinguish command acceptance from tunnel/traffic proof instead of masking these boundaries.
