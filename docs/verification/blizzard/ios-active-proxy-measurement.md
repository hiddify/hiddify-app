# iOS active proxy measurement after unlock

## Device evidence

Build 0.0.1 (12) fixes the Connected text after lock/unlock. The user still reports an unbounded ping skeleton. The screenshot also shows an empty server name/type and Unknown IP while subscription information remains populated. Physical ping/IP recovery remains unverified until the next exact TestFlight build is tested.

## Cause established in source

The active-groups stream starts with an empty cached list. The old notifier converted both missing groups and failures into a protobuf-default outbound, and the delay widget interpreted every nonpositive delay as an active test without a deadline. URL test dispatch used an async callback inside a void throttler, so its caller could not await the operation. Core resume reopened streams without requesting a fresh measurement.

## iOS correction

An iOS-only coordinator waits for both the existing URL-test RPC and a fresh nonempty outbound snapshot. A 15-second deadline ends unanswered attempts; a matching gRPC transport deadline bounds the native request. The UI offers retry after failure/timeout, and renders a footer only when a genuine outbound exists. Ping and IP remain independent: a valid delay can coexist with Unknown IP, and later metadata can update without changing the verified delay.

Backgrounding, disconnection, core restart and disposal invalidate the old attempt. A readiness latch blocks manual/haptic continuations until core setup has completed. Late stream/RPC responses cannot overwrite a newer session. Other platforms retain the legacy path; no native tunnel configuration or RPC interface changed.

## Verification

Behavioral RED evidence preceded the implementation: unbounded UI loading; actual iOS RPC without a deadline; session/freshness/identity/error regressions; inactive-to-resumed manual and haptic races; passive empty snapshots and later IP enrichment. Synthetic fixtures contain only documentation IP addresses.

- Full Flutter suite: 577 passed.
- Coordinator: 30 cases; provider/lifecycle: 9; iOS latency/footer: 9.
- Real localhost gRPC: 15-second iOS timeout and unchanged non-iOS pending request control.
- Presentation guard: 49 files, 651 preserved shipped bindings, exactly three approved new watches plus negative controls, including unused nested closures/functions.
- Runtime allowance: exact five source paths/fingerprints, 22 assertions including modified-byte and wrong-path controls.
- Manual VPN policy, baseline identity/release/workflow/entitlement contracts, native diagnostic privacy: passed (one existing signed-artifact fixture skip).
- The older broad runtime-boundary suite still has its three preexisting failures: historical protected-file drift, an older VPNManager diagnostic fingerprint and an unhydrated core framework. This change does not broaden their allowances.
- Static analysis: no issues in the new production files. Existing touched files retain their earlier lint warnings; no lint cleanup is included.

## Physical acceptance for the new build

With VPN connected, lock the iPhone for 60 seconds and unlock without pressing VPN. Connected should remain stable. Ping should either appear or finish with a retryable timeout within 15 seconds; no perpetual skeleton. A genuine server can display Unknown IP when IP metadata is unavailable. Repeat a manual retry and background/resume. Successful code tests and TestFlight processing alone do not prove real tunnel traffic, IP retrieval or device recovery.
