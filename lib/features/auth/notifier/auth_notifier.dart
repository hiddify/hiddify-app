import 'package:hiddify/core/model/app_config.dart';
import 'package:hiddify/features/auth/data/auth_api_client.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/data/token_storage.dart';
import 'package:hiddify/features/auth/domain/auth_failure.dart';
import 'package:hiddify/features/auth/domain/auth_user.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// Authentication state exposed to the UI / router.
sealed class AuthState {
  const AuthState();
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthLoggedIn extends AuthState {
  const AuthLoggedIn(this.user);
  final AuthUser user;
}

class AuthError extends AuthState {
  const AuthError(this.failure);
  final AuthFailure failure;
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier with AppLogger {
  AuthApiClient get _apiClient => ref.read(authApiClientProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  @override
  AuthState build() {
    return const AuthLoggedOut();
  }

  /// Restores a persisted session at app startup.
  ///
  /// If a valid access token exists (or at least a refresh token), the user is
  /// considered logged in without going through the login UI.
  Future<void> restoreSession() async {
    if (state is AuthLoggedIn || state is AuthLoading) return;
    state = const AuthLoading();

    final session = await _tokenStorage.read();
    if (session == null) {
      state = const AuthLoggedOut();
      return;
    }

    // Prefer a still-valid access token; otherwise attempt a refresh if the
    // access token is expired but a refresh token exists.
    if (session.hasNotExpiredAccess || !session.hasValidRefreshToken) {
      final user = session.tokens.user;
      if (user != null) {
        state = AuthLoggedIn(user);
      } else {
        state = const AuthLoggedOut();
      }
      return;
    }

    // Access token expired but refresh token is present — try to refresh.
    try {
      final tokens = await _apiClient.refreshTokens(session.tokens.refreshToken);
      await _tokenStorage.save(tokens: tokens, expiresAt: DateTime.now().add(Duration(seconds: tokens.expiresIn)));
      final user = tokens.user ?? session.tokens.user;
      if (user != null) {
        state = AuthLoggedIn(user);
      } else {
        state = const AuthLoggedOut();
      }
    } on AuthException catch (e) {
      loggy.warning('failed to restore session', e);
      await _tokenStorage.clear();
      state = const AuthLoggedOut();
    } catch (e) {
      loggy.warning('unexpected error restoring session', e);
      await _tokenStorage.clear();
      state = const AuthLoggedOut();
    }
  }

  /// Performs a Telegram OIDC login using the given [idToken].
  Future<void> loginWithTelegram(String idToken) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      final tokens = await _apiClient.loginWithTelegram(idToken);
      await _tokenStorage.save(tokens: tokens, expiresAt: DateTime.now().add(Duration(seconds: tokens.expiresIn)));
      final user = tokens.user;
      if (user != null) {
        state = AuthLoggedIn(user);
      } else {
        state = const AuthError(const AuthFailure.sessionExpired());
      }
    } on AuthException catch (e) {
      state = AuthError(e.failure);
    } catch (e) {
      loggy.warning('unexpected login error', e);
      state = const AuthError(AuthFailure.unexpected());
    }
  }

  /// Clears tokens and transitions to the logged-out state.
  Future<void> logout() async {
    await _tokenStorage.clear();
    state = const AuthLoggedOut();
  }

  /// Immediate logout triggered by a failed token refresh inside the
  /// interceptor (does not perform async network calls).
  Future<void> forceLogout() async {
    await _tokenStorage.clear();
    state = const AuthLoggedOut();
  }

  /// Whether the auth feature is usable at all given the build-time config.
  bool get isConfigured => AppConfig.isConfigured;
}