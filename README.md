# SpriteNet VPN (Android)

SpriteNet is an Android VPN client for VLESS Reality subscriptions served by a 3X-UI panel.
Keys, billing and support are handled by the Telegram bot [@DsitWork](https://t.me/DsitWork);
the app only imports the subscription, keeps it up to date and holds the tunnel.

## Based on Hiddify

SpriteNet is a fork of [Hiddify](https://github.com/hiddify/hiddify-app) (upstream `main` after `v4.1.2`) and is distributed
under the same [Hiddify Extended GNU General Public License v3](LICENSE.md). All credit for the core client,
the sing-box integration and the original UI goes to the Hiddify team.

### Changes from upstream

- Application ID and Android namespace `com.spritenet.vpn`, minimum Android 8.0 (API 26).
- SpriteNet branding: name, adaptive and monochrome launcher icon, notification icon, splash screen, TV banner
  and in-app logo, all generated from [`branding/spritenet_icon.svg`](branding/spritenet_icon.svg) by
  [`branding/generate_icons.py`](branding/generate_icons.py).
- Dark-only "Deep Matte" theme: canvas `#0F0F11`, cards `#18181C`, lime accent `#8DFF19`, alert `#EF4444`.
  The theme mode picker is removed.
- New power button with idle, connecting, connected and error states; latency and live download/upload
  speed on the home screen; fixed Support button that opens the Telegram bot.
- Deep links `spritenet://import?url=<subscription>&name=<name>` (legacy `hiddify://` links are still parsed
  when pasted).
- Subscriptions refresh every 12 hours unless the panel sends `profile-update-interval`.
- Hidden for end users: WARP options and quick toggle, TLS tricks, inbound options, the logs page and the
  list of free public configs.
- The upstream in-app updater (which checks Hiddify releases) is disabled.

## Building

The build is the same as upstream Hiddify (Flutter `3.38.5`):

```bash
make android-prepare          # downloads hiddify-core libraries, runs code generation
make android-apk-release      # split APKs for arm64-v8a, armeabi-v7a, x86_64 + universal
```

Release signing reads `android/key.properties` (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`).

To change the logo or palette of the generated icons, edit `branding/generate_icons.py` and run
`python3 branding/generate_icons.py` (needs `pip install cairosvg pillow`).
