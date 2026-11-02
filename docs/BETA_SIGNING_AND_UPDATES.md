# Beta signing and updates

The application ID stays `app.hiddify.com`. Beta 1.5 introduces a permanent RSA key;
only its public certificate SHA-256 is committed in `android/mit-signing-cert.sha256`.
An old Alpha signed with a different debug key cannot be upgraded in place.
The new key enables subsequent Beta upgrades to preserve Android application data.
Keep the private keystore and passwords backed up privately: losing them prevents
future compatible upgrades. Never commit them or upload them to release artifacts.

Configure these GitHub Actions repository secrets once:

| Secret | Value |
| --- | --- |
| `ANDROID_SIGNING_KEY` | Base64 of the permanent JKS file |
| `ANDROID_SIGNING_STORE_PASSWORD` | Keystore password |
| `ANDROID_SIGNING_KEY_PASSWORD` | Key password |
| `ANDROID_SIGNING_KEY_ALIAS` | `mits-vpn` |

The test job builds an explicitly unsigned release preview without signing secrets.
The publishing job downloads that same-run artifact, signs it, verifies the committed
certificate pin, package, version and non-debug mode, then creates an immutable GitHub
prerelease. Missing secrets fail publishing; no temporary debug signing fallback exists.
Version/tag/assets must be new for each release. Bump `MitRelease.buildName`,
`buildNumber`, label, workflow publishing branch/title and release notes together.

Release assets: `mits-vpn.apk`, `mits-vpn-update.json`, `SHA256SUMS`.
Updates are checked manually through the public GitHub releases API. HTTPS redirects
are restricted to explicit GitHub delivery hosts. Metadata and APK sizes are bounded;
only higher version codes for this package qualify. Android verifies SHA-256, size,
archive package/version and signing certificate match with the installed application
before both enabling installation and opening the system installer. The OS performs
its own APK signature verification. No silent installation or VPN auto-connect occurs.
Unknown-source permission is requested only after the user chooses installation.

The app cannot upgrade from an unsigned preview or another signing identity.
Keep GitHub account access and the four signing secrets protected; APK hash metadata
alone is not a substitute for a trusted signing certificate.
