# Woman in Red iOS MVP verification matrix

Updated: 2026-07-14 (Europe/Moscow)

| Procedure | Environment | Expected | Actual evidence | Status |
|---|---|---|---|---|
| Baseline `flutter test` | macOS, Flutter 3.38.5, Dart 3.10.4 | Existing tests pass before edits | 30 tests passed | Pass |
| Baseline `flutter analyze` | Same | Record pre-existing debt | 248 existing issues; command exits non-zero | Fail (pre-existing) |
| Baseline `flutter build ios --release --no-codesign` | Xcode 26.6, iOS device Release target | Compile without signing | `Runner.app` built, 158.9 MB, exit 0 | Pass |
| Identity/access focused tests | Flutter test VM | New domain behavior passes after verified red failures | Email, installation identity, local profile, and access-state tests pass | Pass |
| Final full `flutter test` | Same | All old and new tests pass | 60 tests passed, exit 0 | Pass |
| Final scoped analyze | Changed Dart files | No errors introduced | 0 issues, exit 0 | Pass |
| Final full analyze | Whole repo | No regression beyond baseline | 243 existing issues versus baseline 248; command remains non-zero on legacy debt | Pass (no regression) |
| Final iOS Release no-codesign build | Xcode 26.6 | Compile changed app | Clean `Runner.app` build, 159.6 MB, exit 0 | Pass |
| Privacy manifests in product | Clean iOS Release bundle | App and Packet Tunnel each contain their own valid manifest | Both `Runner.app/PrivacyInfo.xcprivacy` and embedded `HiddifyPacketTunnel.appex/PrivacyInfo.xcprivacy` present after clean build | Pass |
| Release privacy/security regression | Flutter test VM plus source/config audit | Opt-in analytics, no URL/provider-value logging, no raw core error in Sentry, no test subscription endpoint, manifests copied into both targets | 14 focused privacy/security tests pass after observed red phases | Pass |
| Clean simulator launch and onboarding smoke test | iPhone 17 Pro, iOS 26.5 | Install, launch, render localized branded onboarding without clipping | Clean uninstall/install/launch succeeded; dark Russian onboarding inspected in `build/qa/woman-in-red-onboarding.png` | Pass |
| No-access and local-profile behavior | Flutter test VM plus simulator | No fake connect state; validate/save/remove profile; stable installation identity | Domain/widget behavior covered by focused tests; no-access UI inspected during simulator iteration | Pass |
| Auto Mode policy | Flutter test VM | Rank active-core candidates by valid latency, exclude invalid entries, and fall back deterministically | 5 focused tests pass after an observed red phase; production action reuses core `urlTest` and existing `selectProxy` | Pass (policy/integration) |
| Auto Mode with private subscription | Signed physical iPhone | Measure authorized subscription servers, select one, and feed the real tunnel | Cannot obtain authorized candidates without a private test subscription and signed tunnel environment | Blocked |
| Signed real-device tunnel test | Physical iPhone + approved App ID/Network Extension entitlement + signing team + private test subscription | Import, connect, permission, protected, disconnect, reconnect | Private test subscription has been supplied; environment reports 0 physical iOS devices and 0 valid code-signing identities | Blocked |

## External owner actions

The product owner must provide an authorized Apple Developer Team/signing setup with the Network Extension entitlement and a physical iPhone. A non-production private test subscription has now been supplied and is handled as a secret. If identity-based Remnawave retrieval is required instead of private URL/QR import, the backend owner must also provide the documented authenticated verification and entitlement API contract; an email address alone is explicitly insufficient.
