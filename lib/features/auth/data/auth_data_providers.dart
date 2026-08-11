import 'package:dio/dio.dart';
import 'package:hiddify/core/model/app_config.dart';
import 'package:hiddify/features/auth/data/auth_api_client.dart';
import 'package:hiddify/features/auth/data/auth_interceptor.dart';
import 'package:hiddify/features/auth/data/token_storage.dart';
import 'package:hiddify/features/auth/domain/auth_tokens.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_data_providers.g.dart';

/// A dedicated plain [Dio] instance for the Cabinet API.
///
/// Kept separate from the proxy-aware [DioHttpClient] used for sing-box /
/// subscription traffic, since Cabinet requests must NOT go through the local
/// proxy and need their own auth interceptor.
@Riverpod(keepAlive: true)
Dio cabinetDio(Ref ref) {
  return Dio(BaseOptions(baseUrl: AppConfig.cabinetUrl));
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return TokenStorage();
}

@Riverpod(keepAlive: true)
AuthApiClient authApiClient(Ref ref) {
  return AuthApiClient(
    dio: ref.watch(cabinetDioProvider),
    baseUrl: AppConfig.cabinetUrl,
  );
}

/// Installs the auth interceptor on the Cabinet [Dio] instance so outgoing
/// requests automatically attach `Authorization: Bearer <access_token>` and
/// transparently refresh on 401.
@Riverpod(keepAlive: true)
void authInterceptorProvider(Ref ref) {
  final dio = ref.watch(cabinetDioProvider);
  final notifier = ref.watch(authNotifierProvider.notifier);
  dio.interceptors.add(
    AuthInterceptor(
      getAccessToken: () async => (await ref.read(tokenStorageProvider).read())?.tokens.accessToken,
      getRefreshToken: () async => (await ref.read(tokenStorageProvider).read())?.tokens.refreshToken,
      refreshTokens: (refreshToken) async {
        final tokens = await ref.read(authApiClientProvider).refreshTokens(refreshToken);
        final storage = ref.read(tokenStorageProvider);
        await storage.save(tokens: tokens, expiresAt: DateTime.now().add(Duration(seconds: tokens.expiresIn)));
        return tokens;
      },
      onSessionExpired: notifier.forceLogout,
    ),
  );
}

/// Convenience provider exposing the currently stored access token (if any),
/// so other parts of the app can check auth state without coupling to storage.
@Riverpod(keepAlive: true)
Future<String?> currentAccessToken(Ref ref) async {
  final session = await ref.read(tokenStorageProvider).read();
  return session?.tokens.accessToken;
}

/// Whether a persisted session currently exists (used by routing / bootstrap).
@Riverpod(keepAlive: true)
Future<AuthTokens?> storedSession(Ref ref) async {
  final session = await ref.read(tokenStorageProvider).read();
  return session?.tokens;
}