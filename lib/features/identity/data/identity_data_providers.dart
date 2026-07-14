import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/identity/data/identity_profile_store.dart';
import 'package:hiddify/features/identity/data/installation_identity_store.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final installationIdentityProvider = FutureProvider<String>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider).requireValue;
  return InstallationIdentityStore(preferences).getOrCreate();
});

final identityProfileProvider = StateNotifierProvider<IdentityProfileNotifier, IdentityProfileData>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider).requireValue;
  return IdentityProfileNotifier(IdentityProfileStore(preferences));
});

class IdentityProfileNotifier extends StateNotifier<IdentityProfileData> {
  IdentityProfileNotifier(this._store) : super(_store.read());

  final IdentityProfileStore _store;

  Future<void> saveEmail(String input) async {
    state = await _store.saveEmail(input);
  }

  Future<void> saveAvatarPath(String? path) async {
    state = await _store.saveAvatarPath(path);
  }
}
