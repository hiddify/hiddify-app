# Woman in Red privacy data inventory

| Data | Purpose | Storage | Transmission | Retention and deletion | Logging rule |
|---|---|---|---|---|---|
| Anonymous installation ID | Stable local continuity before any verified account exists | App SharedPreferences | Not transmitted by the MVP | Until app data is erased | Never log |
| Optional email | Local profile and future recovery hint | App SharedPreferences | Not transmitted; no verified backend contract exists | User can replace or clear it; app-data deletion removes it | Never log |
| Local avatar | User-selected local profile image | App support directory; only its path is referenced in preferences | Not transmitted | Replacement deletes the prior managed file; removal deletes the managed file | Never log the path or image |
| Private subscription URL | Retrieve already-assigned VPN access | Existing Hiddify profile persistence/cache | Sent only to the subscription origin selected by the user | Existing profile delete/replace lifecycle | Secret: never log, expose to analytics, screenshots, or crash reports |
| Subscription metadata | Show expiration and traffic information | Existing Drift/profile cache | Refreshed from the subscription origin | Existing profile lifecycle | May log state names only, never URL/header values |
| VPN configuration and credentials | Build the authorized tunnel | Existing Hiddify profile/core storage and minimum Network Extension App Group data | VPN server and subscription origin as required | Existing profile lifecycle | Secret: never log or attach to crash reports |
| Selected server and latency | Auto/manual routing and connection status | Existing core state/preferences | Existing core connection path | Existing profile lifecycle | Tags may contain sensitive labels; do not add new logging |
| Operational logs and crashes | Diagnose app failures | No persistent iOS app log in Release; Sentry only after explicit opt-in | Crash diagnostics may be sent to Sentry after opt-in | Until the user disables analytics, then collection stops; server retention follows the published policy | Provider values and profile URLs are never logged; raw core errors are never attached to Sentry |

## Identity boundary

The repository contains no confirmed account, Remnawave authentication, OTP, or magic-link API. Therefore email is always displayed as unverified and knowledge of an email address cannot retrieve or activate VPN access. The authoritative MVP access mechanism is the existing private URL, QR/deep-link, or local profile import path.

## Network Extension boundary

Only the existing configuration required by `HiddifyPacketTunnel` is shared through the existing App Group. The Woman in Red profile email, avatar, and anonymous installation ID are not shared with the extension.

## Apple declarations

The app declares no tracking. Its privacy manifest lists non-linked crash diagnostics for app functionality and the required-reason APIs used by the app. Analytics and crash reporting default to off on a fresh installation and preserve only an explicit user opt-in. The iOS targets request only the packet-tunnel Network Extension subtype plus the existing VPN and App Group capabilities.
