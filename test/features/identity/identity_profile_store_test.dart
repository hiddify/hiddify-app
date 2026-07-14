import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/identity/data/identity_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists normalized optional email without implying verification', () async {
    SharedPreferences.setMockInitialValues({});
    final store = IdentityProfileStore(await SharedPreferences.getInstance());

    final saved = await store.saveEmail('  User@Example.COM ');
    final restored = store.read();

    expect(saved.email, 'user@example.com');
    expect(saved.emailVerified, isFalse);
    expect(restored, saved);
  });

  test('rejects invalid email and preserves the previous value', () async {
    SharedPreferences.setMockInitialValues({IdentityProfileStore.emailKey: 'valid@example.com'});
    final store = IdentityProfileStore(await SharedPreferences.getInstance());

    expect(() => store.saveEmail('invalid'), throwsFormatException);
    expect(store.read().email, 'valid@example.com');
  });

  test('supports avatar replacement and removal', () async {
    SharedPreferences.setMockInitialValues({});
    final store = IdentityProfileStore(await SharedPreferences.getInstance());

    await store.saveAvatarPath('/Private/Avatar.PNG');
    expect(store.read().avatarPath, '/Private/Avatar.PNG');
    await store.saveAvatarPath(null);
    expect(store.read().avatarPath, isNull);
  });
}
