import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/fallback_localizations.dart';

void main() {
  testWidgets('Material widgets build in a language Flutter has no texts for', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tk'),
        supportedLocales: [Locale('tk')],
        localizationsDelegates: appLocalizationsDelegates,
        home: Scaffold(body: TextField()),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
