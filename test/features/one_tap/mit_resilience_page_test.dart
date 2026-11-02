import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/one_tap/mit_resilience.dart';
import 'package:hiddify/features/one_tap/mit_resilience_page.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Core extends ConnectionNotifier {
  _Core(this.current);
  final ConnectionStatus current;
  @override
  Stream<ConnectionStatus> build() => Stream.value(current);
}
class _Profiles extends ProfilesNotifier {
  @override
  Stream<List<ProfileEntity>> build() => Stream.value([
    ProfileEntity.local(id: 'primary-private-id', active: true, name: 'Primary private name', lastUpdate: DateTime(2026)),
    ProfileEntity.local(id: 'backup-private-id', active: false, name: 'Backup private name', lastUpdate: DateTime(2026)),
  ]);
}
class _Platform extends MitVpnPlatform {
  MitVpnEnvironment value = const MitVpnEnvironment(protectionSupported: true);
  int opens = 0, reads = 0;
  bool fail = false;
  @override
  Future<MitVpnEnvironment> environment() async {
    reads++;
    if (fail) throw const FormatException('vpn://private-key server.example');
    return value;
  }
  @override
  Future<void> openProtectionSettings() async { opens++; }
}

void main() {
  Future<ProviderContainer> open(WidgetTester tester, _Platform platform, {ConnectionStatus status = const Disconnected()}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWith((ref) async => prefs),
      connectionNotifierProvider.overrideWith(() => _Core(status)),
      profilesNotifierProvider.overrideWith(_Profiles.new),
      mitVpnPlatformProvider.overrideWithValue(platform),
    ]);
    addTearDown(container.dispose);
    await container.read(sharedPreferencesProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(container: container,
      child: const MaterialApp(home: MitResiliencePage())));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('backup selection persists and is disabled while a tunnel is running', (tester) async {
    final container = await open(tester, _Platform());
    await tester.scrollUntilVisible(find.text('Backup private name'), 200);
    await tester.tap(find.text('Backup private name'));
    await tester.pumpAndSettle();
    expect(container.read(MitResiliencePreferences.backupProfiles), ['backup-private-id']);
    expect(container.read(sharedPreferencesProvider).requireValue.getString('mit_backup_profiles'), 'backup-private-id');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await open(tester, _Platform(), status: const Connected());
    for (final tile in tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))) {
      expect(tile.onChanged, isNull);
    }
  });

  testWidgets('strict protection is not claimed until Android reports both settings enabled', (tester) async {
    final platform = _Platform();
    await open(tester, platform);
    await tester.scrollUntilVisible(find.text('Защита пока не подтверждена.'), 250);
    expect(find.text('Защита пока не подтверждена.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Настройки VPN в Android'), 200);
    await tester.tap(find.text('Настройки VPN в Android'));
    await tester.pumpAndSettle(); expect(platform.opens, 1);
    platform.value = const MitVpnEnvironment(protectionSupported: true, alwaysOn: true, lockdown: true);
    await tester.scrollUntilVisible(find.text('Обновить статус'), 150);
    await tester.tap(find.text('Обновить статус'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Обе системные настройки включены.'), -150);
    expect(find.text('Обе системные настройки включены.'), findsOneWidget);
  });

  testWidgets('diagnostic is previewed before explicit copy and never includes profile data', (tester) async {
    final platform = _Platform();
    var copies = 0; String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') { copies++; copied = (call.arguments as Map)['text'] as String; }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester, platform);
    await tester.scrollUntilVisible(find.text('Просмотреть безопасный отчёт'), 250);
    await tester.tap(find.text('Просмотреть безопасный отчёт'));
    await tester.pumpAndSettle();
    expect(copies, 0);
    final preview = tester.widget<SelectableText>(find.byType(SelectableText)).data!;
    expect(jsonDecode(preview)['connection'], 'disconnected');
    for (final token in ['private-id', 'private name', 'vpn://', 'server.example']) {
      expect(preview, isNot(contains(token)));
    }
    await tester.tap(find.text('Копировать'));
    await tester.pumpAndSettle(); expect(copies, 1); expect(copied, preview);
  });

  testWidgets('platform errors show fixed text and leave protection unknown', (tester) async {
    await open(tester, _Platform()..fail = true);
    await tester.scrollUntilVisible(find.text('Не удалось прочитать состояние Android.'), 250);
    expect(find.textContaining('vpn://private-key'), findsNothing);
    expect(find.textContaining('server.example'), findsNothing);
    expect(find.text('Не удалось прочитать состояние Android.'), findsOneWidget);
  });
}
