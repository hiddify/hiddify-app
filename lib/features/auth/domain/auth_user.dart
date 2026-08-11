import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// A user authenticated via the Bedolaga Cabinet API.
@freezed
class AuthUser with _$AuthUser {
  const AuthUser._();

  const factory AuthUser({
    required int id,
    required int telegramId,
    required String username,
    String? firstName,
    String? email,
    @Default(0) int balanceKopeks,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);
}