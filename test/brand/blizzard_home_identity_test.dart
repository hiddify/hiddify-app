import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/app_info_entity.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../support/home_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('application title uses Blizzard VPN', () {
    expect(Constants.appName, 'Blizzard VPN');
  });

  for (final width in [320.0, 393.0]) {
    testWidgets('Home shows Blizzard and follows installed version/build at width $width', (tester) async {
      final fixture = await mountHomeFixture(
        tester,
        width: width,
        scale: 1.3,
        extraOverrides: [appInfoProvider.overrideWith(_InstalledAppInfo.new)],
      );
      addTearDown(() => fixture.close(tester));
      expect(find.textContaining('Blizzard', findRichText: true), findsWidgets);
      expect(find.text('0.0.1 (19)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      fixture.container.read(appInfoProvider.notifier).state = AsyncData(_info('0.0.1', '20'));
      await tester.pump();
      expect(find.text('0.0.1 (20)'), findsOneWidget);
      expect(find.text('0.0.1 (19)'), findsNothing);

      fixture.container.read(appInfoProvider.notifier).state = AsyncData(_info('0.0.2', '21'));
      await tester.pump();
      expect(find.text('0.0.2 (21)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

AppInfoEntity _info(String version, String build) => AppInfoEntity(
  name: 'Blizzard VPN',
  version: version,
  buildNumber: build,
  release: Release.general,
  operatingSystem: 'ios',
  operatingSystemVersion: 'fixture',
  environment: Environment.prod,
);

class _InstalledAppInfo extends AppInfo {
  @override
  Future<AppInfoEntity> build() async => _info('0.0.1', '19');
}
