import 'package:dio/dio.dart';
import 'package:hiddify/features/auth/domain/auth_tokens.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// Adds `Authorization: Bearer <access_token>` to outgoing Cabinet requests and
/// transparently refreshes the access token once when the backend returns 401.
///
/// Refresh is attempted at most **once** per request to avoid infinite loops.
/// If refresh fails, [onSessionExpired] is invoked so the app can log the user
/// out and redirect to the login screen.
class AuthInterceptor extends Interceptor with InfraLogger {
  AuthInterceptor({
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.refreshTokens,
    required this.onSessionExpired,
  });

  /// Reads the current access token (from secure storage).
  final Future<String?> Function() getAccessToken;

  /// Reads the stored refresh token (from secure storage).
  final Future<String?> Function() getRefreshToken;

  /// Refreshes the token pair using [refreshToken]. Implementations should
  /// persist the new tokens before returning.
  final Future<AuthTokens> Function(String refreshToken) refreshTokens;

  /// Called when the refresh fails (invalid/expired refresh token) so the app
  /// can force-logout the user.
  final void Function() onSessionExpired;

  static const _refreshAttemptHeader = 'X-Auth-Retry-Attempt';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // A request retried after a refresh already carries a fresh token.
    if (options.extra[_refreshAttemptHeader] == true) {
      return handler.next(options);
    }
    final accessToken = await getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthRequest = err.requestOptions.uri.path.contains('/auth/');
    final alreadyRetried = err.requestOptions.extra[_refreshAttemptHeader] == true;

    if (err.response?.statusCode == 401 && !isAuthRequest && !alreadyRetried) {
      try {
        final refreshToken = await getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          onSessionExpired();
          return handler.reject(err);
        }
        final newTokens = await refreshTokens(refreshToken);
        if (!newTokens.isValid) {
          onSessionExpired();
          return handler.reject(err);
        }

        // Retry the original request once with the new access token.
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
        opts.extra[_refreshAttemptHeader] = true;
        final response = await _retry(opts);
        return handler.resolve(response);
      } catch (e) {
        loggy.warning('token refresh failed, logging out', e);
        onSessionExpired();
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }

  /// Re-issues the request on a fresh [Dio] without the interceptor to avoid
  /// recursion. The extra header prevents this path from re-triggering refresh.
  Future<Response<dynamic>> _retry(RequestOptions opts) async {
    final dio = Dio();
    return dio.request<dynamic>(
      opts.path,
      data: opts.data,
      queryParameters: opts.queryParameters,
      options: Options(
        method: opts.method,
        headers: opts.headers,
        extra: opts.extra,
        responseType: opts.responseType,
        contentType: opts.contentType,
        validateStatus: (_) => true,
      )..baseUrl = opts.baseUrl,
    );
  }
}