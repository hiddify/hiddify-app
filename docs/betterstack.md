# WIR Baseline remote diagnostics

This source is based on the released Baseline branch `fix/baseline-vpn-reliability`,
not the different application on `main`. Release the exact tested source through
`main`'s protected `ios-baseline.yml` controller; do not replace Baseline with main.

The release-signing environment contains `BETTERSTACK_LOGS_URL`,
`BETTERSTACK_SOURCE_TOKEN` and `SENTRY_DSN`. The release controller validates them
and passes a private temporary Dart defines file, including `telemetry_beta=true`.
No management API credential belongs in a build or repository.

New typed SafeDiagnosticJournal events go to Logs source `2805644`; existing
sanitized Sentry error events go to Errors application `2805645` in team `620118`.
Logs contain only enum operation/stage/code, bounded counters and duration, safe
version/build metadata and a random per-session UUID. Historical journal records,
raw logs, profiles, addresses, configuration, home snapshots and ping reports are
never uploaded. Existing native/iOS Sentry transport sanitization is preserved.

Beta enables telemetry unless the user has already disabled analytics. Debug
builds do not send. Builds without `telemetry_beta` default analytics off.
Disabling analytics cancels the journal listener and disposes the HTTP client,
queue and timers. A queued request is not evidence of server acceptance. The
safe diagnostics page reads a local closed status snapshot: pending count and
age, attempted-byte usage and remainder, next permitted attempt, last HTTP
status code, and closed delivery/test outcomes. It never includes the request,
response, exception, token, endpoint, headers, profile, or visited resources.

Free-tier limits per installation per UTC day are 64 KiB of attempted JSON log
bodies, including retries, and 1 Sentry event per day / 10 per month. Reservations
persist before sending; storage failure stops transmission. A clock rollback or
application update grants no extra budget. A legacy same-day counter above the
new limit waits for the next UTC day rather than being reset. Queue capacity is
100 events and 64 KiB for at most 24 hours, each event is up to 2 KiB, and batches
contain at most 20. Near the daily cap the sender takes the largest serialized
FIFO prefix that fits; it never raises or bypasses the cap for a manual test.
Flushes run after 10 seconds or when the app backgrounds. Requests time out after
5 seconds; transient failures have at most three attempts before a persisted
cooldown. Budget exhaustion, corrupt budget state, budget storage failure, outbox
storage failure, retry wait, terminal rejection, expiry, and overflow remain
distinct local outcomes. Only budget exhaustion creates the persisted UTC-day
pause. Repeated failed operation/stage/code signatures are limited to one per
minute. HTTP 401/402/403 stops this session's exporter; other 4xx responses are
terminal rejections for that batch. Only an exact 2xx batch containing the tracked
manual event marks that test accepted. Only HTTPS Better Stack ingestion hosts
are accepted and redirects are not followed with the credential.

These device caps complement the account-wide free quota; they cannot guarantee
it for unlimited installations. Keep Better Stack on Free and watch aggregate
usage during the controlled beta. This change does not enable paid services.

## Device acceptance after the new build is installed

1. Open Safe Diagnostics and select **Send test event** (cloud upload icon).
2. Confirm the page advances from local persistence/waiting to server acceptance,
   or shows the specific closed reason it cannot proceed. "Accepted" requires a
   2xx acknowledgement for the batch containing that exact test event.
3. Separately verify `test_event` in Better Stack Logs with the installed
   version/build; local 2xx acceptance does not prove remote query visibility.
4. Connect and disconnect; verify typed operation events with the same session.
5. Disable analytics and verify that subsequent local journal events are not sent.
6. Exercise startup and VPN use without network; telemetry must not block them.

The source CI has no service credentials or deployment environment. It runs all
Flutter tests, targeted analysis, existing release contracts and native privacy/
lifecycle checks. Signing/upload require separate protected jobs. MCP permits
reading ingested events from chat; scheduled AI analysis is not enabled here.
