import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hiddify/features/auth/domain/auth_tokens.dart';
import 'package:hiddify/features/auth/domain/auth_user.dart';
import 'package:hiddify/utils/custom_loggers.dart';

/// A small typed wrapper around [FlutterSecureStorage] for persisting tokens.
///
/// Centralizes all secure-storage access so call sites never touch the
/// underlying plugin directly. Access/refresh tokens are persisted in the
/// platform's secure storage (Keychain / Keystore / encrypted file), NOT in
/// plain text on disk.
class TokenStorage with InfraLogger {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_expires_at';
  static const _userKey = 'auth_user';

  /// Persists the given tokens. [expiresAt] is a concrete timestamp after
  /// which [accessToken] is considered stale.
  Future<void> save({required AuthTokens tokens, required DateTime expiresAt}) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String());
    final user = tokens.user;
    if (user != null) {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    }
  }

  /// Reads the persisted session, if any. Returns `null` when no session exists
  /// or the stored data is corrupt.
  Future<StoredSession?> read() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty) {
        return null;
      }
      final expiresAtRaw = await _storage.read(key: _expiresAtKey);
      final userRaw = await _storage.read(key: _userKey);
      return StoredSession(
        tokens: AuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: 0,
          user: userRaw == null ? null : AuthUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>),
        ),
        expiresAt: expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw),
      );
    } catch (e) {
      loggy.warning('failed to read stored session', e);
      return null;
    }
  }

  /// Clears the persisted session.
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _userKey);
  }
}

/// A persisted session: the token pair plus the moment the access token expires.
class StoredSession {
  const StoredSession({required this.tokens, required this.expiresAt});

  final AuthTokens tokens;
  final DateTime? expiresAt;

  bool get hasNotExpiredAccess => expiresAt != null && DateTime.now().isBefore(expiresAt!);
  bool get hasValidRefreshToken => tokens.refreshToken.isNotEmpty;
}