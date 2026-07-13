# Woman in Red rebrand isolation map

The Woman in Red identity is deliberately isolated from the Hiddify application internals so upstream changes can be rebased with a small conflict surface.

## Platform identity

- `ios/Base.xcconfig` — iOS bundle id, internal service-channel id, and signing team. `SERVICE_IDENTIFIER=com.hiddify.app` is retained because Dart and Swift use it for private method channels; `DEVELOPMENT_TEAM` stays empty until the Woman in Red Apple Developer Team ID is available.
- `ios/Runner/Info.plist` — iOS display name.
- `android/app/build.gradle` — Android application id. The Kotlin namespace remains `com.hiddify.hiddify` to avoid internal package churn.
- `android/app/src/main/AndroidManifest.xml` — Android display name.

## Visual identity

- `lib/core/theme/app_theme.dart` — brand seed color `#FF2D3E`.
- `test/core/theme/app_theme_test.dart` — regression check for the brand seed in light and dark themes.
- `design/assets/woman-in-red-app-icon-master.png` — source app-icon master.
- `ios/Runner/AppIcon.icon/` — iOS Icon Composer asset.
- `android/app/src/main/res/mipmap-*` and `android/app/src/main/res/drawable*` — Android launcher and adaptive-icon assets.

## Attribution

- `README.md` — visible upstream credit and fork change list.
- `docs/gpl-compliance.md` — license gate and release constraints.

Do not rename the Dart package, native service-channel id, Kotlin namespace, Xcode Network Extension target, or compatibility URL schemes as part of the visual rebrand. Those are internal compatibility surfaces rather than user-facing brand identity.
