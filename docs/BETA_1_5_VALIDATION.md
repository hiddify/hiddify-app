# Beta 1.5 verification

Code: `92e2a7bd653eb7ece187407781a9a8d3d7637ee2`.

- Local full Flutter suite: **417 passed, 0 failed, 0 skipped**. Native AWG import
  ran with `MIT_REQUIRE_AWG_NATIVE_TESTS=true` and passed.
- Flutter analysis: exit 0 with `--no-fatal-infos --no-fatal-warnings`;
  no errors, 128 existing/new lint notices in total.
- Android identity/resources and upstream iOS configuration checks passed.
- Permanent key signing was exercised on a synthetic APK using Android build tools
  36.0.0. `apksigner verify` accepted the signature and expected package/version;
  the publishing script rejected an intentionally incorrect certificate pin.
- Update tests cover downgrade/identity rejection, redirect host restrictions,
  bounded downloads, short/oversized responses, cancellation and removal of partial
  files. UI tests require separate check/download/install actions, block installation
  after verification failure and require explicit action for Android install permission.
- QR tests use synthetic profiles and an injected scanner result: no automatic
  camera access or profile addition. Physical camera recognition and a real Android
  upgrade still require device verification.
- Alias tests cover persistence, invalid storage, clearing, UI editing and preventing
  edits while connected; backup ordering tests preserve profile IDs and list bounds.

Local Android release compilation could not download Flutter's Maven artifacts:
the managed network returned HTTP 403 for `storage.googleapis.com`. The authoritative
GitHub Actions build is [run 41549183590](https://github.com/Mit-ping/Mit-s/actions/runs/41549183590).
Publishing additionally requires the four repository signing secrets documented in
[BETA_SIGNING_AND_UPDATES.md](BETA_SIGNING_AND_UPDATES.md).

Release notes for Telegram: [BETA_1_5_RU.md](releases/BETA_1_5_RU.md).
