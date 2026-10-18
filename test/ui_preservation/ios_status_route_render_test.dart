import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/home_presentation_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../support/connection_fixtures.dart';
import '../support/home_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS Home keeps its current status text while its route ticker is muted', (tester) async {
    final fixture = await mountHomeFixture(
      tester,
      width: 800,
      locale: AppLocale.ru,
      extraOverrides: [
        homePresentationDiagnosticsEnabledProvider.overrideWithValue(true),
        homePresentationRuntimeIosProvider.overrideWithValue(true),
      ],
      child: Theme(data: ThemeData(platform: TargetPlatform.iOS), child: const HomePage()),
    );
    var closed = false;
    addTearDown(() async {
      if (!closed) await fixture.close(tester);
    });

    final translations = fixture.container.read(translationsProvider).requireValue;
    final notifier = fixture.container.read(connectionNotifierProvider.notifier) as ButtonConnectionSpy;
    notifier.state = const AsyncData(Connecting());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final initialText = tester.widgetList<RichText>(
      find.descendant(of: find.byType(ConnectionButton), matching: find.byType(RichText)),
    ).map((text) => text.text.toPlainText()).toList();
    expect(initialText, [translations.connection.connecting]);

    fixture.router.go('/settings');
    await tester.pumpAndSettle();
    notifier.state = const AsyncData(Connected());
    await tester.pump();

    final offstageButton = find.byType(ConnectionButton, skipOffstage: false);
    final offstageText = tester
        .widgetList<RichText>(
          find.descendant(
            of: offstageButton,
            matching: find.byType(RichText, skipOffstage: false),
          ),
        )
        .map((text) => text.text.toPlainText())
        .toList();
    expect(offstageText, [translations.connection.connected]);
    expect(find.byType(AnimatedText, skipOffstage: false), findsNothing);

    final hiddenSnapshot = fixture.container.read(homePresentationSnapshotProvider)!;
    expect(hiddenSnapshot.asyncVariant, HomeAsyncVariant.data);
    expect(hiddenSnapshot.connectionValue, HomeConnectionValue.connected);
    expect(hiddenSnapshot.labelChoice, HomeLabelChoice.connected);
    expect(hiddenSnapshot.tickersEnabled, false);

    fixture.router.go('/home');
    await tester.pump();

    final visibleText = tester
        .widgetList<RichText>(
          find.descendant(
            of: find.byType(ConnectionButton),
            matching: find.byType(RichText),
          ),
        )
        .map((text) => text.text.toPlainText())
        .toList();
    expect(visibleText, [translations.connection.connected]);
    expect(fixture.container.read(homePresentationSnapshotProvider)!.tickersEnabled, true);
    expect(tester.takeException(), isNull);

    await fixture.close(tester);
    closed = true;
  });
}
