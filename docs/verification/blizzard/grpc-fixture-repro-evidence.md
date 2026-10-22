# Blizzard gRPC fixture reproduction

Date: 2026-10-22
Scope: synthetic localhost gRPC only.

## Evidence

- Deferred unary Start without streams: GREEN.
- Status stream cancellation and replacement followed by deferred Start: GREEN.
- Persistent broadcast LogListener plus status replacement followed by deferred Start: GREEN.
- Persistent replacement status subscription racing with Start before server acceptance: GREEN.
- Immediately empty LogListener, then replacement log/status subscriptions and immediate Start: RED.

The RED unary result was gRPC code 2 (UNKNOWN): `HTTP/2 error: Connection error: Connection is being forcefully terminated. (errorCode: 1)`.

Conclusion: the canonical test fixture's `LogListener => const Stream.empty()` can emit late HTTP/2 completion headers or trailers after cancellation. grpc/http2 treats the frame for the removed stream as a connection-level protocol error, terminating the shared channel and failing the concurrent Start. A persistent broadcast log stream matches the real core lifecycle and removes the fixture-induced transport failure.

The executable reproduction is preserved in `grpc-fixture-repro.dart.txt` (evidence artifact; intentionally excluded from the runnable release suite).
