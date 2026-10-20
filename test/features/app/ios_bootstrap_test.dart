import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/features/app/startup/ios_startup_gate.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('iOS bootstrap shows shell before initialization settles and removes splash after shell frame', (
    tester,
  ) async {
    final gate = IosStartupGate(deadline: const Duration(milliseconds: 20));
    final directories = Completer<Directories>();
    var containers = 0;
    var removals = 0;
    var shellAtRemoval = false;
    ProviderContainer? container;
    final bootstrap = bootstrapIos(
      tester.binding,
      Environment.prod,
      startupGate: gate,
      initializeDirectories: () => directories.future,
      containerFactory: () {
        containers++;
        return container = ProviderContainer();
      },
      removeSplash: () {
        removals++;
        shellAtRemoval = find.byType(IosStartupShell).evaluate().isNotEmpty;
      },
    );
    expect(removals, 0);
    await tester.pump();
    expect(find.byType(IosStartupShell), findsOneWidget);
    expect(removals, 1);
    expect(shellAtRemoval, isTrue);
    expect(containers, 1);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(gate.state, IosStartupState.timedOut);
    expect(find.byKey(const Key('ios-startup-copy')), findsOneWidget);
    expect(find.byType(App), findsNothing);
    directories.complete((
      baseDir: Directory('/unused'),
      workingDir: Directory('/unused'),
      tempDir: Directory('/unused'),
    ));
    await bootstrap;
    await tester.pump();
    expect(find.byType(App), findsNothing);
    expect(gate.stage, IosStartupStage.directories);
    expect(containers, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    container?.dispose();
    gate.dispose();
  });

  test('iOS production migration error preserves preferences', () async {
    SharedPreferences.setMockInitialValues({'profile': 'keep-profile', 'settings': 'keep-settings'});
    final preferences = await SharedPreferences.getInstance();
    await expectLater(
      migrateIosBootstrapPreferences(
        preferences,
        migrate: () {
          throw StateError('CANARY_SECRET');
        },
      ),
      throwsA(isA<StateError>()),
    );
    expect(preferences.getString('profile'), 'keep-profile');
    expect(preferences.getString('settings'), 'keep-settings');
  });
}
