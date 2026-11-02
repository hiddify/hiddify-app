import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/one_tap/mit_resilience.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _primary = ProfileEntity.local(id: 'primary', active: true, name: 'VPN', lastUpdate: DateTime(2026));
final _backup = ProfileEntity.local(id: 'backup', active: false, name: 'VPN', lastUpdate: DateTime(2026));
class _Active extends ActiveProfile {
  @override
  Stream<ProfileEntity?> build() => Stream.value(_primary);
  void publish(ProfileEntity profile) => state = AsyncData(profile);
}
class _Haptic extends HapticService {
  @override
  bool build() => false;
  @override
  Future<void> lightImpact() async {}
  @override
  Future<void> mediumImpact() async {}
}
class _Dialogs extends DialogNotifier {
  int alerts = 0;
  @override
  void build() {}
  @override
  Future<void> showCustomAlertFromErr(({String type, String? message}) err) async { alerts++; }
}
class _Core extends ConnectionNotifier {
  DateTime now = DateTime(2026);
  @override
  bool get supportsAutomaticRecovery => true;
  @override
  DateTime get recoveryTime => now;
}
class _Platform extends MitVpnPlatform {
  MitVpnEnvironment value = const MitVpnEnvironment(networkAvailable: true, permissionGranted: true, stopEpoch: 2);
  @override
  Future<MitVpnEnvironment> environment() async => value;
}
class _Connections implements ConnectionRepository {
  final starts = <String>[];
  int stops = 0;
  Completer<void>? pausedStop;
  final enteredStop = Completer<void>();
  @override
  Stream<ConnectionStatus> watchConnectionStatus() => Stream.value(const Disconnected());
  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity profile, bool disableMemoryLimit) => TaskEither(() async {
    starts.add(profile.id);
    return left(const ConnectionFailure.unexpected('synthetic failure'));
  });
  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => TaskEither(() async {
    stops++; if (!enteredStop.isCompleted) enteredStop.complete();
    await pausedStop?.future; return right(unit);
  });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Profiles implements ProfileRepository {
  _Profiles(this.select);
  final void Function(ProfileEntity) select;
  int changes = 0;
  @override
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id) => TaskEither.right(id == 'backup' ? _backup : _primary);
  @override
  TaskEither<ProfileFailure, Unit> setAsActive(String id) => TaskEither(() async {
    changes++; select(id == 'backup' ? _backup : _primary); return right(unit);
  });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<({ProviderContainer container, _Core core, _Connections connections, _Platform platform, _Profiles profiles})>
      setup() async {
    SharedPreferences.setMockInitialValues({'mit_backup_profiles': 'backup'});
    final prefs = await SharedPreferences.getInstance();
    final connections = _Connections(), platform = _Platform();
    late ProviderContainer c;
    final profiles = _Profiles((p) => (c.read(activeProfileProvider.notifier) as _Active).publish(p));
    c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWith((ref) async => prefs),
      connectionNotifierProvider.overrideWith(_Core.new),
      connectionRepositoryProvider.overrideWithValue(connections),
      activeProfileProvider.overrideWith(_Active.new),
      profileRepositoryProvider.overrideWith((ref) async => profiles),
      hapticServiceProvider.overrideWith(_Haptic.new),
      dialogNotifierProvider.overrideWith(_Dialogs.new),
      translationsProvider.overrideWith((ref) => AppLocale.ru.build()),
      mitVpnPlatformProvider.overrideWithValue(platform),
    ]);
    addTearDown(c.dispose);
    await c.read(sharedPreferencesProvider.future);
    await c.read(translationsProvider.future);
    await c.read(activeProfileProvider.future);
    c.listen(connectionNotifierProvider, (_, __) {});
    await c.read(connectionNotifierProvider.future);
    return (container: c, core: c.read(connectionNotifierProvider.notifier) as _Core,
      connections: connections, platform: platform, profiles: profiles);
  }
  Future<void> tick(_Core core, int seconds) async {
    core.now = DateTime(2026).add(Duration(seconds: seconds));
    await core.pollRecoveryForTesting();
  }

  test('real notifier retries and selects a backup without opening new error dialogs', () async {
    final s = await setup();
    await s.core.toggleConnection();
    expect(s.connections.starts, ['primary']);
    await tick(s.core, 0);
    await tick(s.core, 3);
    await tick(s.core, 11);
    await tick(s.core, 31);
    expect(s.connections.starts, ['primary', 'primary', 'primary', 'backup']);
    expect(s.profiles.changes, 1);
    expect((s.container.read(dialogNotifierProvider.notifier) as _Dialogs).alerts, 1);
    expect(s.container.read(mitRecoveryViewProvider).attempt, 3);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('manual stop cancels a pending retry', () async {
    final s = await setup();
    await s.core.toggleConnection();
    await tick(s.core, 0);
    await s.core.toggleConnection();
    await tick(s.core, 100);
    expect(s.connections.starts, ['primary']);
    expect(s.container.read(mitRecoveryViewProvider).active, false);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('native user stop cancels recovery even if a network is available', () async {
    final s = await setup();
    await s.core.toggleConnection();
    s.platform.value = const MitVpnEnvironment(networkAvailable: true, permissionGranted: true, stopEpoch: 3);
    await tick(s.core, 0); await tick(s.core, 100);
    expect(s.connections.starts, ['primary']);
    expect(s.container.read(mitRecoveryViewProvider).active, false);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('disabling recovery cancels a backup decision suspended in disconnect', () async {
    final s = await setup();
    await s.core.toggleConnection();
    await tick(s.core, 0); await tick(s.core, 3); await tick(s.core, 11);
    s.connections.pausedStop = Completer<void>();
    final pending = tick(s.core, 31);
    await s.connections.enteredStop.future;
    await s.container.read(MitResiliencePreferences.autoRecovery.notifier).update(false);
    s.connections.pausedStop!.complete();
    await pending;
    expect(s.profiles.changes, 0);
    expect(s.connections.starts, ['primary', 'primary', 'primary']);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('manual profile action cancels a suspended automatic backup decision', () async {
    final s = await setup();
    await s.core.toggleConnection();
    await tick(s.core, 0); await tick(s.core, 3); await tick(s.core, 11);
    s.connections.pausedStop = Completer<void>();
    final pending = tick(s.core, 31);
    await s.connections.enteredStop.future;
    await s.core.reconnect(_backup);
    s.connections.pausedStop!.complete();
    await pending;
    expect(s.profiles.changes, 0);
    expect(s.connections.starts, ['primary', 'primary', 'primary']);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
