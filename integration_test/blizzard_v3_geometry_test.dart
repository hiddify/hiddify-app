import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/support/home_fixture.dart';
import '../test/visual/blizzard_v3_home_geometry_test.dart' as geometry;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  geometry.main();
  if (const bool.fromEnvironment('BLIZZARD_NATIVE_CAPTURE')) {
    testWidgets('native compositor capture fixture', (tester) async {
      final fixture = await mountHomeFixture(tester);
      expect(find.byKey(const ValueKey('blizzard_bottom_dock')), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 12)));
      await fixture.close(tester);
    });
  }
}
