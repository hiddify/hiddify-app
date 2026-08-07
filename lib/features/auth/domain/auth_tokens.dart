import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/auth/domain/auth_user.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

/// Token pair and (optionally) the authenticated user returned by the
/// Bedolaga Cabinet API.
@freezed
class AuthTokens with _$AuthTokens {
  const AuthTokens._();

  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    AuthUser? user,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}