import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/settings/overview/sections/routing_options_page.dart';

void main() {
  testWidgets('routing controls keep at least 44 logical pixel hit regions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RoutingTapTarget(key: ValueKey('general_target'), child: Text('General')),
              RoutingTapTarget(key: ValueKey('fab_target'), width: 48, child: Icon(Icons.add)),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('general_target'))).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byKey(const ValueKey('fab_target'))).height, greaterThanOrEqualTo(44));
  });
}
