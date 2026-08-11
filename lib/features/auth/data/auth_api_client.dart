import 'package:dio/dio.dart';
import 'package:hiddify/core/model/app_config.dart';
import 'package:hiddify/features/auth/domain/auth_failure.dart';
import 'package:hiddify/features/auth/domain/auth_tokens.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// Typed exceptions raised by [AuthApiClient].
///
/// These are deliberately separate from the raw [DioException] so the UI layer
/// can map them to user-friendly messages without parsing HTTP status codes.
sealed class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => '$runtimeType($failure)';
}

class AuthNotConfiguredException extends AuthException {
  const AuthNotConfiguredException() : super(const AuthFailure.notConfigured());
}

class AuthInvalidTokenException extends AuthException {
  const AuthInvalidTokenException() : super(const AuthFailure.invalidToken());
}

class AuthAccountBlockedException extends AuthException {
  const AuthAccountBlockedException() : super(const AuthFailure.accountBlocked());
}

class AuthRateLimitedException extends AuthException {
  const AuthRateLimitedException() : super(const AuthFailure.rateLimited());
}

class AuthUnexpectedException extends AuthException {
  AuthUnexpectedException([Object? error, StackTrace? stackTrace])
      : super(AuthFailure.unexpected(error, stackTrace));
}

/// HTTP client for the Bedolaga Cabinet API (Remnawave).
///
/// Uses a dedicated plain [Dio] instance — NOT the proxy-aware
/// [DioHttpClient] used for sing-box / subscription traffic.
class AuthApiClient with InfraLogger {
  AuthApiClient({
    required Dio dio,
    required String baseUrl,
  }) : _dio = dio {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  final Dio _dio;

  /// Exchanges a Telegram OIDC `id_token` for a token pair.
  Future<AuthTokens> loginWithTelegram(String idToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.telegramOidcLoginPath,
        data: <String, dynamic>{
          'id_token': idToken,
          'campaign_slug': null,
          'referral_code': null,
        },
      );
      return _parseTokens(response.data);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Refreshes an expired `access_token` using the `refresh_token`.
  Future<AuthTokens> refreshTokens(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.telegramOidcRefreshPath,
        data: <String, dynamic>{
          'refresh_token': refreshToken,
        },
      );
      return _parseTokens(response.data);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AuthTokens _parseTokens(Map<String, dynamic>? data) {
    if (data == null) {
      throw const AuthUnexpectedException();
    }
    return AuthTokens.fromJson(data);
  }

  AuthException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    switch (statusCode) {
      case 400:
        // 400 == OIDC not configured on the backend (technical issue, not the user's).
        return const AuthNotConfiguredException();
      case 401:
        return const AuthInvalidTokenException();
      case 403:
        return const AuthAccountBlockedException();
      case 429:
        return const AuthRateLimitedException();
      default:
        return AuthUnexpectedException(e.error, e.stackTrace);
    }
  }
}