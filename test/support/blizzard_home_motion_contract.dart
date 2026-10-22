import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';

import 'blizzard_capture.dart';
import 'home_fixture.dart';

Future<Uint8List> _frame(WidgetTester tester, String label) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(blizzardFixtureCanvas));
  final image = await boundary.toImage(pixelRatio: 2);
  try {
    final data = await image.toByteData();
    if (const bool.fromEnvironment('BLIZZARD_CAPTURE')) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('${Directory.systemTemp.path}/blizzard-snowfall-captures');
      await directory.create(recursive: true);
      await File('${directory.path}/$label.png').writeAsBytes(png!.buffer.asUint8List());
    }
    return Uint8List.fromList(data!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

/// Native renderer proof uses real Home and routing; only external VPN/data
/// dependencies are synthetic, as in the existing preservation fixtures.
void registerBlizzardHomeMotionContracts() {
  for (final width in [393.0, 320.0]) {
    testWidgets('native snowfall Home $width retains actions and tab lifecycle', (tester) async {
      expect(Platform.isIOS, isTrue);
      final fixture = await mountHomeFixture(tester, width: width, scale: width == 320 ? 1.3 : 1, locale: AppLocale.ru);
      var closed = false;
      addTearDown(() async {
        if (!closed) await fixture.close(tester);
      });
      expect(find.byType(BlizzardScene), findsOneWidget);
      final button = find.byKey(const ValueKey('home_connection_button'));
      final bounds = tester.getRect(button);
      final sceneBounds = tester.getRect(find.byType(BlizzardScene));
      debugPrint('BLIZZARD_REFERENCE_GEOMETRY width=$width scene=$sceneBounds button=$bounds');
      expect(bounds.size, const Size(148, 148));
      final mark = find.descendant(of: button, matching: find.byType(SvgPicture));
      expect(mark, findsOneWidget, reason: 'The reference uses the existing Hiddify brand mark');
      expect((tester.widget<SvgPicture>(mark).bytesLoader as SvgAssetLoader).assetName, 'assets/images/logo.svg');
      expect(
        tester.widget<Material>(button).color!.a,
        lessThan(0.25),
        reason: 'The control must let the scene show through',
      );
      await tester.pump(const Duration(seconds: 1));
      final before = await _frame(tester, 'home-${width.toInt()}-before');
      // Fully-live native frames also provide a short reviewable video window.
      debugPrint('BLIZZARD_SNOWFALL_PREVIEW_READY width=$width');
      final timings = <ui.FrameTiming>[];
      void recordTimings(List<ui.FrameTiming> frames) => timings.addAll(frames);
      tester.binding.addTimingsCallback(recordTimings);
      try {
        await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 12)));
      } finally {
        tester.binding.removeTimingsCallback(recordTimings);
      }
      if (timings.isNotEmpty) {
        final builds = timings.map((frame) => frame.buildDuration.inMicroseconds).toList()..sort();
        final rasters = timings.map((frame) => frame.rasterDuration.inMicroseconds).toList()..sort();
        final p95 = ((timings.length - 1) * 0.95).round();
        debugPrint(
          'BLIZZARD_SNOWFALL_TIMING width=$width frames=${timings.length} '
          'build_p95_us=${builds[p95]} raster_p95_us=${rasters[p95]} mode=debug_simulator',
        );
      }
      await tester.pump();
      final after = await _frame(tester, 'home-${width.toInt()}-after');
      expect(listEquals(before, after), isFalse);
      final origin = tester.getRect(find.byKey(blizzardFixtureCanvas)).topLeft;
      final local = bounds.shift(-origin);
      var movingUnderGlass = 0;
      for (var y = (local.top + 18).round() * 2; y < (local.top + 32).round() * 2; y++) {
        for (var x = (local.left + 46).round() * 2; x < (local.left + 102).round() * 2; x++) {
          final pixel = (y * (width * 2).round() + x) * 4;
          if ((before[pixel + 2] - after[pixel + 2]).abs() > 4) movingUnderGlass++;
        }
      }
      expect(movingUnderGlass, greaterThan(120), reason: 'Moving light must remain visible through the button face');
      expect(tester.getRect(button), bounds);
      expect(find.text('Synthetic Finland'), findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      expect(fixture.events, ['toggle']);
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ConnectionButton), findsNothing);
      expect(find.text('settings'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'Offstage Home must release the ambient clock');
      await tester.tap(find.byKey(const ValueKey('blizzard_bottom_dock_tab_0')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ConnectionButton), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isTrue, reason: 'Returning to Home resumes its snowfall');
      expect(fixture.events, ['toggle']);
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
      closed = true;
      debugPrint('BLIZZARD_SNOWFALL width=$width renderer=ios data=synthetic actions=preserved result=PASS');
    });
  }
}
