import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/widget/proxy_type_label.dart';

void main() {
  Future<void> pump(WidgetTester tester, String type) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: ProxyTypeLabel(type))));

  String shown(WidgetTester tester) => tester.widget<RichText>(find.byType(RichText).first).text.toPlainText();

  testWidgets("hides the scanner's endpoint until the magnifier is tapped", (tester) async {
    await pump(tester, "WARP · MASQUE · 🔍 162.159.198.2:4443");
    expect(shown(tester), isNot(contains("162.159.198.2")));

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    expect(shown(tester), contains("162.159.198.2:4443"));

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    expect(shown(tester), isNot(contains("162.159.198.2")));
  });

  testWidgets("shows other types as they are", (tester) async {
    await pump(tester, "WARP · WG · 🔍 Not found");
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(shown(tester), "WARP · WG · 🔍 Not found");
  });
}
