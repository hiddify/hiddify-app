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
queue and timers. A queued request is not evidence of server acceptance.

Free-tier limits per installation per UTC day are 256 KiB of attempted JSON log
bodies, including retries, and 50 Sentry events. Reservations persist before
sending; storage failure stops transmission. A clock rollback grants no extra
budget. Queue capacity is 100 events, each up to 2 KiB; batches contain at most 20.
Flushes run after 10 seconds or when the app backgrounds. Requests time out after
5 seconds; transient failures have at most three attempts. Repeated failed
operation/stage/code signatures are limited to one per minute. HTTP 401/402/403
stops this session's exporter. Only HTTPS Better Stack ingestion hosts are
accepted and redirects are not followed with the credential.

These device caps complement the account-wide free quota; they cannot guarantee
it for unlimited installations. Keep Better Stack on Free and watch aggregate
usage during the controlled beta. This change does not enable paid services.

## Device acceptance after the new build is installed

1. Open Safe Diagnostics and select **Send test event** (cloud upload icon).
2. The page reports that the event was queued, or that remote diagnostics are off.
3. Verify `test_event` in Better Stack Logs with the installed version/build.
4. Connect and disconnect; verify typed operation events with the same session.
5. Disable analytics and verify that subsequent local journal events are not sent.
6. Exercise startup and VPN use without network; telemetry must not block them.

The source CI has no service credentials or deployment environment. It runs all
Flutter tests, targeted analysis, existing release contracts and native privacy/
lifecycle checks. Signing/upload require separate protected jobs. MCP permits
reading ingested events from chat; scheduled AI analysis is not enabled here.
