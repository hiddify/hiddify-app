/// Compile-time configuration for the Bedolaga Cabinet (Remnawave) backend.
///
/// These values must be provided at build time via `--dart-define`, e.g.:
/// ```
/// flutter run --dart-define=CABINET_URL=https://cabinet.example.com \
///              --dart-define=TELEGRAM_OIDC_CLIENT_ID=123456789
/// ```
///
/// Secrets/IDs are intentionally NOT hardcoded here.
class AppConfig {
  const AppConfig._();

  /// Base URL of the Cabinet API, e.g. `https://cabinet.example.com`.
  static const String cabinetUrl = String.fromEnvironment("CABINET_URL");

  /// Numeric Telegram bot ID used as OIDC client_id.
  static const String telegramOidcClientId = String.fromEnvironment("TELEGRAM_OIDC_CLIENT_ID");

  /// Path to the Telegram OIDC login endpoint.
  static const String telegramOidcLoginPath = "/cabinet/auth/telegram/oidc";

  /// Path to the refresh-token endpoint.
  ///
  /// If the backend exposes a different refresh path than the login endpoint,
  /// provide it via `--dart-define=TELEGRAM_OIDC_REFRESH_PATH=...`. Otherwise it
  /// falls back to the login endpoint (which per the documented protocol is used
  /// for exchanging tokens).
  static const String telegramOidcRefreshPath = String.fromEnvironment(
    "TELEGRAM_OIDC_REFRESH_PATH",
    defaultValue: "/cabinet/auth/telegram/oidc",
  );

  /// Convenience guard: whether the auth config is fully provided at build time.
  static bool get isConfigured => cabinetUrl.isNotEmpty && telegramOidcClientId.isNotEmpty;
}