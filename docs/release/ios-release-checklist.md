# Woman in Red iOS release checklist

Updated: 2026-07-14 (Europe/Moscow)

## Locally verified

- [x] Main bundle id derives from `BASE_BUNDLE_IDENTIFIER=com.womaninred.app`.
- [x] Packet Tunnel bundle id derives from `$(BASE_BUNDLE_IDENTIFIER).HiddifyPacketTunnel`.
- [x] Both targets use `group.$(BASE_BUNDLE_IDENTIFIER)` for the App Group.
- [x] Internal `SERVICE_IDENTIFIER=com.hiddify.app` remains unchanged for Flutter/Swift channel compatibility.
- [x] No upstream Apple development team is embedded; `DEVELOPMENT_TEAM` is intentionally empty.
- [x] Only the `packet-tunnel-provider` Network Extension subtype is requested.
- [x] Unused push, app-proxy, DNS-proxy, and content-filter entitlements are absent.
- [x] The main and extension privacy manifests parse successfully.
- [x] Analytics and crash reporting are opt-in on fresh installations.
- [x] The privacy manifest declares no tracking and non-linked crash diagnostics.
- [x] Private subscription URLs and provider values are excluded from app diagnostics.
- [x] Test/free subscription endpoints are absent from Release behavior and source.
- [x] Camera and photo usage descriptions match QR import behavior.
- [x] Display name, app icon, launch assets, and dark Woman in Red shell are present.
- [x] Existing Hiddify license attribution and fork modification notice are retained.
- [x] Unsigned iOS Release compilation succeeds.

## Owner-controlled release gates

- [ ] Assign the authorized Apple Developer Team to both targets.
- [ ] Register the main App ID, Packet Tunnel App ID, and App Group with the exact identifiers above.
- [ ] Obtain and attach the production Network Extension entitlement/provisioning profiles.
- [ ] Install a signed Release build on a physical iPhone.
- [ ] Import a private non-production subscription without exposing it to logs or screenshots.
- [ ] Verify VPN permission, first connect, protected state, disconnect, reconnect, failure recovery, and state restoration.
- [ ] Verify the archived app's signed entitlements with `codesign -d --entitlements :-`.
- [ ] Complete App Store Connect privacy answers and provide the externally hosted privacy-policy URL.
- [ ] Provide truthful review notes explaining that users receive access from the service administrator and that the app has no purchases.
- [ ] Run TestFlight validation before any App Store submission.

Do not submit, upload, or call the product App Store-ready until every owner-controlled gate is evidenced.
