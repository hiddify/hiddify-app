import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/common/qr_code_dialog.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late Translations t;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(overrides: [translationsProvider.overrideWith((ref) => AppLocale.en.build())]);
    await container.read(sharedPreferencesProvider.future);
    t = await container.read(translationsProvider.future);
  });
  tearDown(() => container.dispose());

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: LocalProxyDialog())),
      ),
    );
    await tester.pumpAndSettle();
  }

  // #2597: a password set from the dialog could only be edited there, never taken off again
  testWidgets('a password set in the local proxy dialog can be removed there', (tester) async {
    await show(tester);
    final text = t.dialogs.localProxy;
    expect(container.read(ConfigOptions.localProxyAuth), isFalse);

    await tester.tap(find.text(text.setPassword));
    await tester.pumpAndSettle();
    expect(container.read(ConfigOptions.localProxyAuth), isTrue);
    expect(find.text(text.noPassword), findsNothing);
    // removing is offered only while the password is edited
    expect(find.text(text.removePassword), findsNothing);

    await tester.tap(find.byTooltip(text.edit).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text.removePassword));
    await tester.pumpAndSettle();

    expect(container.read(ConfigOptions.localProxyAuth), isFalse);
    expect(find.text(text.noPassword), findsOneWidget);
    // the local network's port keeps asking for the same secret
    expect(container.read(ConfigOptions.lanSharingPassword), isNotEmpty);
  });

  testWidgets('editing the port offers no remove', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip(t.dialogs.localProxy.edit).first);
    await tester.pumpAndSettle();
    expect(find.text(t.dialogs.localProxy.removePassword), findsNothing);
  });
}
