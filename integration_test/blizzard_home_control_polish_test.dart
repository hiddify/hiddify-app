import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/blizzard_visual_fixture.dart';
import '../test/visual/blizzard_native_home_refinement_test.dart' as refinement;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  setUpAll(() async {
    runApp(const MaterialApp(home: SizedBox.shrink()));
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(seconds: 1));
  });

  refinement.main();

  testWidgets('eligible iOS Home uses the approved Blizzard power control', (tester) async {
    expect(Platform.isIOS, isTrue, reason: 'Requires an actual iOS process; host overrides are not valid evidence');

    final fixture = await mountVisualFixture(tester);
    final button = find.byKey(const ValueKey('home_connection_button'));
    final action = find.byKey(const ValueKey('blizzard_home_action_label'));

    expect(BlizzardPresentation.isActive(tester.element(button)), isTrue);
    expect(tester.getSize(button), const Size.square(BlizzardMetrics.connectionButton));

    final power = tester.widget<Icon>(
      find.descendant(of: button, matching: find.byIcon(Icons.power_settings_new_rounded)),
    );
    expect(power.size, 48);
    expect(power.color, BlizzardPalette.accent);

    final actionText = tester.widget<Text>(action);
    expect(actionText.data, 'Disconnect');
    expect(actionText.style?.color, BlizzardPalette.accent);

    await tester.tap(button);
    await tester.pump();
    expect(fixture.events, ['toggle']);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
}
