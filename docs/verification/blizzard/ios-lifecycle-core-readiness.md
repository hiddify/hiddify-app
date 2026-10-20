# iOS lifecycle and startup diagnosis

## Device evidence

The user confirmed TestFlight 0.0.1 (13): Connected remained visible, ping was Unknown, and the server footer was absent. The app subsequently remained on the Hiddify launch logo after force quit and relaunch, including with system VPN disabled. The actual blocked startup stage on the iPhone has not been observed.

## Reproduced defects

An inactive/resumed pair delivered before a Flutter frame stops the iOS measurement but is coalesced by the previous lifecycle hook. The resume callback and core restart signal are then absent. The new iOS observer forwards both events directly; other platforms retain the existing hook.

Accepted but unanswered foreground Hello RPCs and native setup callbacks previously retained startup indefinitely. iOS setup now uses five-second gRPC and native-wait deadlines, coalesces concurrent setup attempts, and retains an unfinished native callback across retries. A late native completion cannot publish clients for the timed-out attempt. No setup timeout starts, stops or resets the tunnel.

## Startup behavior

iOS mounts an independent startup shell before awaiting application dependencies. Each stage has a 15-second watchdog. Failure or timeout exposes a copyable report containing a fixed schema, stage/state/code enums, a pending flag and bounded elapsed time. Error messages, stack traces, paths, URLs, IP addresses and profile contents cannot enter the report.

The watchdog changes the screen while retaining ownership of the original pending operation. Late completion cannot advance bootstrap or mount the normal app. There is no automatic retry, replay or second container. The successful path passes the same container to the app. A failed iOS preferences migration no longer clears all preferences; the existing migration itself is not transactional. Strict core initialization propagates failure to the gate instead of treating a completed Future as readiness. Default initialization and the bootstrap of other platforms retain their earlier behavior.

## Verification

- Full Flutter suite: 611 passed on pinned Flutter 3.38.5.
- Behavioral regressions: frame-coalesced lifecycle, stalled first/second Hello and native setup, overlapping setup, late callbacks, all startup-stage watchdogs, terminal state, disposal and closed report privacy.
- Actual bootstrap wiring: shell before a stalled directory initialization, splash removal after its frame, single container and no normal app after late completion. A failed migration preserves the existing test preferences.
- Strict initialization: setup failure throws a closed exception without restart; success emits restart; default failure retains existing side effects. A compiling no-op strict flag reproduces the missing exception.
- Independent review: no blocking P1/P2 findings. A fully successful bootstrap through all real dependencies is not covered by the bootstrap integration test.
- New startup source and tests: analyzer clean. Existing touched sources retain earlier lint findings.
- Manual system VPN policy, native diagnostic privacy, baseline identity/release/workflow and entitlement contracts passed; the existing signed-artifact fixture remains skipped locally.
- Exact path and byte fingerprints cover the startup changes, with modified-byte and wrong-path rejection tests. The broad historical runtime guard retains its three preexisting failures: earlier protected-file drift, the older VPNManager diagnostic fingerprint, and the unhydrated local core framework. Their allowances were not broadened.

## Device acceptance still required

Cold launch with system VPN off, then with an already connected tunnel. If startup fails, copy the startup report after the bounded wait; its stage identifies the next investigation target. If the home screen opens, connect, lock for 60 seconds, unlock without pressing VPN, and record ping and server/IP separately. Synthetic tests and Apple delivery do not prove physical startup recovery, numeric ping, tunnel routing or leak absence.
