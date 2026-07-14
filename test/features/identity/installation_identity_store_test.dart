import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/identity/data/installation_identity_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates an installation id once and returns it after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var generations = 0;
    final store = InstallationIdentityStore(preferences, generateId: () => 'installation-${++generations}');

    expect(await store.getOrCreate(), 'installation-1');
    expect(await store.getOrCreate(), 'installation-1');
    expect(generations, 1);
  });

  test('keeps an existing non-empty installation id', () async {
    SharedPreferences.setMockInitialValues({InstallationIdentityStore.storageKey: 'existing-id'});
    final preferences = await SharedPreferences.getInstance();
    final store = InstallationIdentityStore(preferences, generateId: () => 'replacement-id');

    expect(await store.getOrCreate(), 'existing-id');
  });
}
