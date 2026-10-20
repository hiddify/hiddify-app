# iOS post-unlock ping trace

## Physical evidence

The user confirmed 0.0.1 (14) opens the home screen and displays a numeric ping before locking the phone. After unlock it remains Connected, displays Unknown ping, and tapping ping has no visible effect. The device's failing recovery stage remains unknown.

The app-side measurement is suspended on inactive/paused and reopens after a successful core restart. Connected status is independent of that readiness. Several different recovery failures therefore produce the same visible result.

## Reproduction and scope

Tests run the real service queue, setup/init, repository, measurement provider and manual refresh notifier. External core/status boundaries and ephemeral localhost RPC responses are controlled. Every scenario first obtains numeric ping, then exercises inactive/paused/resumed:

- An accepted but unanswered foreground Close keeps resume behind pause.
- Setup failure completes the default resume without a restart signal.
- A pending system-status response holds setup after the foreground core is ready.
- A successful control completes setup, publishes restart and obtains numeric ping again.

These are distinct possible causes, not a diagnosis of the iPhone. The tests do not mount the full App, and substitute the independent Connected status boundary. Existing tests that manually emit restart remain useful unit coverage but do not establish service recovery.

This change adds observation only. It adds no recovery retries or deadlines and changes no tunnel decisions. It retains the existing non-iOS queue path.

## Closed report

The existing safe diagnostic report includes optional `ios_ping` with schema `wir-ios-ping-trace/v1`. Entries contain only a sequence, fixed event enum, operation ID and bounded elapsed milliseconds. The session ring defaults to 96 entries, with maximum 128. It never accepts error objects/text, profiles, tags, URLs, IP addresses or paths. The trace is in memory and does not write additional preferences.

Automatic and manual attempts receive distinct IDs. Late RPC completion retains its originating ID. Repeated stream markers are deduplicated per attempt so they do not crowd out recovery milestones. Diagnostic observer failures cannot interrupt the observed operation.

Viewing/copying the report does not initialize the core or measurement. The preview follows the trace asynchronously. The existing clear action clears both journal and trace, preserving counters so unfinished operations cannot reuse an ID. Restore validates all optional trace keys and bounds; unknown/raw fields invalidate the document.

| Last relevant evidence | Interpretation |
| --- | --- |
| Resume queued but not started | Earlier lifecycle operation still owns the queue |
| Setup failed without restart | Core readiness was not restored |
| System status requested without ready | Setup is waiting for its native status response |
| Refresh core-not-ready | Tap reached the handler and was rejected by readiness |
| Haptic requested without completed | Refresh has not passed the haptic boundary |
| Request completed without fresh snapshot | RPC completion alone did not supply a usable measurement |

## Validation and device protocol

Behavioral RED preceded instrumentation and report wiring. Tests cover all four service paths, guard rejection, accepted refresh, automatic IDs, late RPC attribution, stream deduplication, strict parser/privacy, immutable bounds, asynchronous preview/copy and clear. Independent review found no remaining P1/P2 issues after automatic-ID and provider-identity test corrections.

After installing the next exact TestFlight build: connect and confirm numeric ping; lock for 60 seconds; unlock and open WIR; tap ping once if Unknown; open the existing safe diagnostics page and copy its report. The `ios_ping` trail should identify the actual failing stage. Physical recovery and tunnel traffic remain unaccepted until independently observed.
