import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class InstallationIdentityStore {
  InstallationIdentityStore(this._preferences, {String Function()? generateId})
    : _generateId = generateId ?? const Uuid().v4;

  static const storageKey = 'woman_in_red_installation_id';

  final SharedPreferences _preferences;
  final String Function() _generateId;

  Future<String> getOrCreate() async {
    final existing = _preferences.getString(storageKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final created = _generateId();
    if (created.trim().isEmpty) throw StateError('Installation identity generator returned an empty value');
    final persisted = await _preferences.setString(storageKey, created);
    if (!persisted) throw StateError('Could not persist installation identity');
    return created;
  }
}
