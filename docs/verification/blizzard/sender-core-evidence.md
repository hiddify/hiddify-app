# Sender-core delivery evidence

Scope: U2/U3 sender core only, based on `9e8e342102666769a8293f7defb2725b9efd4664`.

## TDD evidence

- Baseline: `/tmp/blizzard-sender-core-baseline.log` — 32 existing focused tests passed.
- RED: `/tmp/blizzard-sender-core-red.log` — exit 1 because the new typed budget result,
  read-only snapshot, and delivery-status API did not exist.
- First behavior run: `/tmp/blizzard-sender-core-green-attempt1.log` — 42 tests passed
  and two waiting-state assertions failed; no transport/storage/cap behavior was hidden.
- GREEN: `/tmp/blizzard-sender-core-green.log` — 47 focused tests passed.

All Flutter tests used the serialized runner:

```text
python3 /private/tmp/blizzard-flutter-locked.py test --no-pub test/core/observability
```

## Verified sender behavior

- The local snapshot and stream expose only closed states, bounded counters, UTC
  timestamps, and an HTTP status code. Strict report parsing rejects unknown fields.
- Manual test acceptance is tied to its existing `event_id` and only a 2xx batch that
  contains that ID can accept it. A 2xx for an older in-flight batch leaves it waiting.
- Budget cap, corrupt budget state, budget read/write failure, and outbox write failure
  have distinct outcomes. Only cap exhaustion persists a same-day pause.
- The daily 64 KiB log budget includes every attempted serialized body, including
  retries. A legacy same-day overage remains blocked and a new UTC day resets usage.
- When a full batch does not fit the remaining budget, the largest exact serialized
  UTF-8 FIFO prefix is reserved and sent. If the first event does not fit, no HTTP call
  occurs and the queue remains intact.
- Queue bounds remain 100 events / 64 KiB / 24 hours. Tracked tests end with explicit
  expiry or overflow outcomes. Retry cooldown survives restart; explicit foreground
  resume reuses the existing queue and does not bypass the budget.
- 401/402/403 disable and clear the exporter; another 4xx terminally rejects its batch.
  Transport exceptions remain private and appear only as a closed retry state.

## Remaining runtime boundary

These tests prove local state transitions and controlled transport responses. They do
not prove that Better Stack indexed a device event, that an installed build resumed in
the background, or that VPN traffic worked. Those remain exact-build device checks.
