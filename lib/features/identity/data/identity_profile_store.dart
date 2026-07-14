import 'package:hiddify/features/identity/model/email_address.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityProfileData {
  const IdentityProfileData({this.email, this.avatarPath});

  final String? email;
  final String? avatarPath;

  bool get emailVerified => false;

  @override
  bool operator ==(Object other) =>
      other is IdentityProfileData && other.email == email && other.avatarPath == avatarPath;

  @override
  int get hashCode => Object.hash(email, avatarPath);
}

class IdentityProfileStore {
  IdentityProfileStore(this._preferences);

  static const emailKey = 'woman_in_red_profile_email';
  static const avatarPathKey = 'woman_in_red_profile_avatar_path';

  final SharedPreferences _preferences;

  IdentityProfileData read() => IdentityProfileData(
    email: normalizeOptionalEmail(_preferences.getString(emailKey) ?? ''),
    avatarPath: switch (_preferences.getString(avatarPathKey)?.trim()) {
      final path? when path.isNotEmpty => path,
      _ => null,
    },
  );

  Future<IdentityProfileData> saveEmail(String input) {
    final normalized = normalizeOptionalEmail(input);
    if (normalized != null && !isValidEmail(normalized)) throw const FormatException('Invalid email address');
    return _saveEmail(normalized);
  }

  Future<IdentityProfileData> _saveEmail(String? email) async {
    final persisted = email == null
        ? await _preferences.remove(emailKey)
        : await _preferences.setString(emailKey, email);
    if (!persisted) throw StateError('Could not persist profile email');
    return read();
  }

  Future<IdentityProfileData> saveAvatarPath(String? path) async {
    final normalized = path?.trim();
    final persisted = normalized == null || normalized.isEmpty
        ? await _preferences.remove(avatarPathKey)
        : await _preferences.setString(avatarPathKey, normalized);
    if (!persisted) throw StateError('Could not persist profile avatar');
    return read();
  }
}
