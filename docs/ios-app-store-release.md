# iOS App Store release runbook

The repository can validate iOS without signing on pull requests and can build
and upload a signed IPA to TestFlight from a release tag. A signed release still
requires access to the Apple Developer organization that owns the app record,
identifiers, and Network Extension capability.

Contributors do not need Apple credentials. Forks should run only the unsigned
pull-request checks. Signing secrets, release tags, TestFlight uploads, and App
Store submission belong exclusively to maintainers of the upstream repository
who have access to the owning Apple Developer organization.

## Ownership prerequisites

- The Apple Developer Program membership must be an **organization**. Apple does
  not accept VPN apps from individual memberships.
- The submitting team must own App Store app `6596777532` and the bundle ID
  `apple.hiddify.com`, or the fork must use a new app name, bundle IDs, signing
  settings, store listing, support site, and privacy policy that the submitter
  owns.
- The submitter must have the right to distribute the Hiddify name, icon, and
  store metadata. The source-code license alone does not grant trademark rights.
- Apple must approve the Packet Tunnel Network Extension capability for both
  the containing app and `apple.hiddify.com.HiddifyPacketTunnel`.

Do not create a release tag until these points are confirmed. The checked-in
configuration intentionally targets the existing Hiddify App Store record.

## GitHub Actions secrets

Upstream maintainers configure these Actions secrets on the release repository.
Do not copy signing material or App Store Connect credentials into contributor
forks:

| Secret | Purpose |
| --- | --- |
| `APPLE_CERTIFICATE_P12` | Base64-encoded Apple Distribution certificate and private key |
| `APPLE_CERTIFICATE_P12_PASSWORD` | Password for the P12 archive |
| `APPLE_MOBILE_PROVISIONING_PROFILES_TARGZ_BASE64` | Base64-encoded tar.gz containing App Store profiles for the app and packet-tunnel extension |
| `APPSTORE_ISSUER_ID` | App Store Connect API issuer ID |
| `APPSTORE_API_KEY_ID` | App Store Connect API key ID |
| `APPSTORE_API_PRIVATE_KEY` | Full contents of the API private key |
| `SENTRY_DSN` | Optional; leave empty to disable crash delivery even after a user opts in |
| `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT` | Optional debug-symbol upload settings |

The App Store Connect API key needs permission to upload builds for the app.
Keep the key and signing material only in Actions secrets; never commit them.

## App Store Connect checklist

1. Accept all pending agreements and complete banking/tax information if shown.
2. Confirm app name, subtitle, description, support URL, privacy-policy URL,
   categories, copyright, and screenshots are final and accurate.
3. Update App Privacy answers. With a non-empty `SENTRY_DSN`, the opt-in Sentry
   integration can send crash data, performance data, product interaction, and
   other diagnostics. These categories are not linked to the user and are not
   used for tracking.
4. Answer the current age-rating questionnaire.
5. Complete export-compliance questions. `ITSAppUsesNonExemptEncryption` is
   `false`; confirm that this remains correct for the submitted binary and its
   use of standard encryption.
6. Select only territories where the VPN app complies with local law. Put any
   required VPN licence details in App Review Notes.
7. Provide App Review with a working sample profile/QR code and precise steps to
   exercise connection, routing, analytics opt-in/opt-out, and profile import.
8. State that Hiddify is a client and does not provide VPN servers. Explain that
   traffic is sent to the server selected by the user.
9. Test the TestFlight build on physical iPhone and iPad hardware, including an
   IPv6-only network, before submitting it for review.

## Release flow

1. A contributor opens a pull request from a fork and requires CI to pass. The
   iOS job compiles the app and packet-tunnel extension with `--no-codesign` on
   `macos-26` / Xcode 26, builds the production entry point for Simulator in
   Flutter's supported debug mode, installs it, and verifies that the app remains
   running after launch. The separate unsigned device build validates release
   mode. Fork CI must not contain Apple signing secrets.
2. Upstream maintainers review and merge the change to `main`.
3. An upstream maintainer runs `.github/change_version.sh` with the intended
   semantic version and confirms the generated commit and tag before pushing.
4. A `vX.Y.Z` tag in the upstream repository triggers the Release workflow. The
   iOS matrix job creates the signed IPA; `upload-to-testflight` uploads that
   unchanged artifact using the upstream App Store Connect API key.
5. Upstream maintainers wait for processing, resolve any compliance warnings,
   invite the contributor as an external TestFlight tester, test the VPN on
   physical iPhone and iPad hardware, attach the build to the version, complete
   Review Notes, and submit for review.

The release workflow deliberately fails when iOS fails; it must never publish a
successful-looking release while silently omitting the IPA.
