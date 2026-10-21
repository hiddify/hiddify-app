# iOS foreground recovery after prolonged lock

## Device evidence

Build 15 (`17c94f1bfc6344c5a0417a20feab7122d1a0e282`) showed numeric ping before lock, then Unknown after a longer lock; tapping did not visibly recover it. The supplied safe trace shows three setup failures before FrontReady (7/22/20 ms), resumeCompleted despite setup failure, and four refreshCoreNotReady rejections. A preceding short successful run does not establish stability.

This locates the failed foreground setup and blocked manual path. The report does not identify the exact first-Hello/native/second-Hello exception. Its home snapshot still contains a valid latency band, so it is not treated as a fresh measurement result.

## Confirmed source defect

Runner parses the requested setup mode but replaced it with 4. Dart requests mode 3 and pause closes modes 3/1. In official core commit `c9d6f0f00b2eda34e4fb71863e4e0a62b3e931a0` (the project's gitlink and v4.1.0), Setup returns immediately for an existing map entry of that mode; Close only stops/deletes the requested mode. Therefore the Runner server was outside its intended cleanup path. A stale listener/map entry after prolonged suspension is a concrete hypothesis for the device failure, not a proven exception trace.

Runner now forwards the requested mode. Packet Tunnel's separate process and mode 4 remain unchanged. This corrects local foreground setup/cleanup ownership without adding a tunnel start, stop or reconnect.

References: official core `platform/mobile/mobile.go:23`, `v2/hcore/grpc_server.go:40,293`, `v2/hcore/pause.go:11` at the pinned commit above.

## Recovery behavior

The service owns a single-flight foreground-readiness operation serialized with pause. Pause invalidates the current generation immediately. Failed/stale recovery records resumeFailed and resolves false; only a current successful setup emits restart. Lifecycle callbacks handle failure without an uncaught asynchronous exception; existing default/strict initialization and non-iOS behavior remain.

A connected, resumed manual refresh with a suspended measurement requests this operation. After success it reacquires the measurement through a stable provider reader, rechecks foreground/connection/disposal, and lets the rebuilt provider start its one automatic measurement. Concurrent requests share setup; an obsolete notifier Ref is not read after await.

The indicator shows pending feedback during manual recovery, a localized closed error on failure, and permits retry. Current checking/available measurement state has priority; unmounted indicators cannot update hook state.

The safe trace distinguishes first Hello, native setup and second Hello failures, known VPN-preferences failure and bounded timeout categories. No platform messages, private details, addresses or credentials are added. refreshRecoveryCompleted means readiness recovered; measurementAvailable establishes a measured result.

## Verification and limits

Behavioral RED preceded native mode forwarding, manual retry and failure classification. The native harness executes the real Swift setup case with synthetic boundaries. Service/real-pipeline tests cover failure, successful recovery, single-flight, repeated taps, invalidation by pause, disconnection, stale completion and one measurement. Widget tests cover loading, sanitized failure, retry, newer available data and disposal during a pending refresh. Existing pending-native-setup ownership and setup deadlines remain covered.

Independent source review found no substantiated P1/P2 issues. Synthetic tests do not establish the physical failure cause or actual tunnel traffic. Existing unbounded foreground Close RPC behavior is retained; the diagnostic stalled-close scenario remains distinguishable and is not claimed fixed by this change. Three historical standalone runtime-guard failures remain separate (VPNManager baseline fingerprint, unavailable baseline framework and aggregate protected diff); exact current-source negative controls remain strict.

After the next exact TestFlight build, repeat the prolonged-lock duration that reproduced the bug several times, verify fresh numeric ping and manual retry, and capture the safe trace on any failure. Do not close the device defect after one short successful run.

## Build 16 — preliminary physical feedback

In response to the build 16 prolonged-lock acceptance request, the user reported “Пока вроде все работает”. No exact duration, repeat count or fresh safe report accompanied that response. This is preliminary improvement, not completed long-lock or network acceptance.

The current iOS network protocol and results ledger are maintained in [2026-10-20-2214-ios-build16-network-acceptance-plan](../../plans/2026-10-20-2214-ios-build16-network-acceptance-plan.md).

## Build 16 — failure reported 2026-10-21

The user subsequently reported “Непредвиденная ошибка” in the ping indicator during connection and no internet. The safe report confirms build 16. Foreground setup operations 114/119/124 fail at second Hello (`coreSetupSecondHelloFailed`, `coreSetupHelloFailed`, `coreSetupFailed`), followed by `coreResumeFailed`. Native setup therefore returned before the failed second probe; the exact gRPC status is absent. All displayed elapsed_ms are saturated at 3600000 and provide no duration measurement. Home connected/valid-latency and final tunnel started are not traffic proof. The relation between foreground recovery failure and reported internet loss remains unproven. Network scenario N02 is blocked by this P1 investigation; the prior short OFF result remains scoped to its original run.

System OFF restored internet, but a cold WIR restart and new connection did not clear the error. The user also reported missing country selection and clarified that Russian destinations remain accessible. This is partial connectivity evidence, not proof that every destination fails or that subscription data was deleted.

The next patch rejects foreground settings UNAVAILABLE on iOS instead of misclassifying it as acceptable background absence. A real RPC RED test reproduced the false Right; background-before-start and non-iOS tolerance controls remain green. It also records canonical gRPC statuses as closed events and a bounded TCP reachability observation only after second-Hello failure. No private gRPC messages or metadata are included. The true refused-socket-to-native-start regression passes without changing channel reuse, so that hypothesis is not presented as the cause. Full Flutter regression: 663 passed; native setup-mode, manual policy and diagnostic privacy scripts passed. Physical recovery and traffic remain unverified.
