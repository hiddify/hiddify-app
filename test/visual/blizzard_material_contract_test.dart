import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/features/profile/details/json_editor.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';
import 'package:hiddify/utils/platform_utils.dart';

import '../support/home_fixture.dart';

class _ResetTunnelSpy extends ResetTunnelNotifier {
  int calls = 0;
  @override
  Future<void> build() async {}
  @override
  Future<void> run() async {
    calls++;
  }
}

void main() => registerBlizzardMaterialContracts();

void registerBlizzardMaterialContracts() {
  for (final highContrast in [false, true]) {
    for (final type in [MaterialType.canvas, MaterialType.card]) {
      testWidgets('local uncolored $type paints opaque content highContrast=$highContrast', (tester) async {
        final base = AppTheme(AppThemeMode.dark, 'BlizzardFixture').darkTheme(null);
        final scoped = BlizzardTheme.from(base, highContrast: highContrast);
        await tester.pumpWidget(
          MaterialApp(
            theme: scoped,
            home: Center(
              child: Material(
                key: const ValueKey('uncolored-material'),
                type: type,
                child: const SizedBox(width: 100, height: 60),
              ),
            ),
          ),
        );
        final physical = find.descendant(
          of: find.byKey(const ValueKey('uncolored-material')),
          matching: find.byWidgetPredicate((widget) => widget is PhysicalModel || widget is PhysicalShape),
        );
        expect(physical, findsOneWidget);
        final paint = tester.widget(physical);
        final color = switch (paint) {
          PhysicalModel(:final color) => color,
          PhysicalShape(:final color) => color,
          _ => throw StateError('Material did not resolve to a physical painted surface'),
        };
        expect(color, BlizzardMaterials(highContrast: highContrast).content);
        expect(color.a, 1);
        expect(base.canvasColor, isNot(scoped.canvasColor), reason: 'Global legacy theme remains separate');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('actual JSON search strip uses opaque control highContrast=$highContrast', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scoped = BlizzardTheme.from(
        AppTheme(AppThemeMode.dark, 'BlizzardFixture').darkTheme(null),
        highContrast: highContrast,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: scoped,
          home: Scaffold(
            body: JsonEditor(json: '{"name":"synthetic"}', onChanged: (_) {}),
          ),
        ),
      );
      final search = find.byIcon(Icons.search);
      expect(search, findsOneWidget);
      final strip = find.ancestor(of: search, matching: find.byType(ColoredBox)).first;
      expect(tester.widget<ColoredBox>(strip).color, BlizzardMaterials(highContrast: highContrast).control);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('actual JSON outline uses local accent highContrast=$highContrast', (tester) async {
      final scoped = BlizzardTheme.from(
        AppTheme(AppThemeMode.dark, 'BlizzardFixture').darkTheme(null),
        highContrast: highContrast,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: scoped,
          home: Scaffold(
            body: JsonEditor(json: '{"name":"synthetic"}', editors: const [Editors.text], onChanged: (_) {}),
          ),
        ),
      );
      final outlined = find.descendant(
        of: find.byType(JsonEditor),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) return false;
          final border = (widget.decoration as BoxDecoration).border;
          return border is Border && border.top == border.bottom && border.top.width == 1;
        }),
      );
      expect(outlined, findsOneWidget);
      final border = (tester.widget<DecoratedBox>(outlined).decoration as BoxDecoration).border! as Border;
      expect(border.top.color, BlizzardPalette.accent);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    for (final active in [false, true]) {
      for (final mode in [AppThemeMode.dark, AppThemeMode.light, AppThemeMode.black]) {
        testWidgets('actual profile card and ink share radius $direction active=$active ${mode.name}', (tester) async {
          final profile = ProfileEntity.local(
            id: 'material-profile',
            active: active,
            name: 'Material profile',
            lastUpdate: DateTime.utc(2026),
          );
          final fixture = await mountHomeFixture(
            tester,
            mode: mode,
            direction: direction,
            child: ProfileTile(profile: profile),
          );
          final radius = Radius.circular(expectsBlizzard(mode, Brightness.dark, 393) ? 20 : 16);
          final card = tester.widget<Card>(find.descendant(of: find.byType(ProfileTile), matching: find.byType(Card)));
          expect((card.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.all(radius));
          final content = tester.widget<InkWell>(
            find.ancestor(of: find.text('Material profile'), matching: find.byType(InkWell)).first,
          );
          final action = tester.widget<InkWell>(
            find.descendant(of: find.byType(ProfileActionButton), matching: find.byType(InkWell)),
          );
          final start = direction == TextDirection.ltr
              ? BorderRadius.horizontal(left: radius)
              : BorderRadius.horizontal(right: radius);
          final end = direction == TextDirection.ltr
              ? BorderRadius.horizontal(right: radius)
              : BorderRadius.horizontal(left: radius);
          expect(content.borderRadius, end);
          expect(action.borderRadius, start);
          expect(tester.getSize(find.byType(ProfileActionButton)).width, 48);
          expect(fixture.events, isEmpty);
          expect(tester.takeException(), isNull);
          await fixture.close(tester);
        });
      }
    }
  }
  for (final mode in [AppThemeMode.dark, AppThemeMode.light, AppThemeMode.black]) {
    testWidgets('actual Settings reset backing radius and one spy call ${mode.name}', (tester) async {
      final spy = _ResetTunnelSpy();
      final fixture = await mountHomeFixture(
        tester,
        mode: mode,
        child: SettingsPage(),
        extraOverrides: [resetTunnelNotifierProvider.overrideWith(() => spy)],
      );
      final resetIcon = find.byIcon(Icons.autorenew_rounded);
      if (expectsBlizzard(mode, Brightness.dark, 393)) {
        final resetAction = find.byKey(const ValueKey('settings-reset-tunnel'));
        expect(resetAction, findsOneWidget);
        expect(resetIcon, findsNothing);
        final backing = tester.widget<Material>(resetAction);
        expect(backing.borderRadius, BorderRadius.circular(16));
        expect(backing.clipBehavior, Clip.antiAlias);
        final tile = find.descendant(of: resetAction, matching: find.byType(ListTile));
        final resetTile = tester.widget<ListTile>(tile);
        expect(resetTile.leading, isNull);
        expect(resetTile.onTap, isNotNull);
        expect(tester.getSize(resetAction).height, greaterThanOrEqualTo(48));
        await tester.tap(find.descendant(of: resetAction, matching: find.byType(Text)));
        await tester.pump();
        expect(spy.calls, 1);
      } else if (PlatformUtils.isIOS) {
        expect(resetIcon, findsOneWidget);
        final tile = find.ancestor(of: resetIcon, matching: find.byType(ListTile)).first;
        final backing = tester.widget<Material>(find.ancestor(of: tile, matching: find.byType(Material)).first);
        if (expectsBlizzard(mode, Brightness.dark, 393)) {
          final shape = backing.shape;
          final radius = backing.borderRadius ?? (shape is RoundedRectangleBorder ? shape.borderRadius : null);
          expect(radius, BorderRadius.circular(12));
          expect(backing.clipBehavior, isNot(Clip.none));
          final theme = Theme.of(tester.element(tile));
          expect(backing.color ?? theme.canvasColor, theme.colorScheme.surface);
        } else {
          expect(backing.shape, isNull);
          expect(backing.borderRadius, isNull);
          expect(backing.clipBehavior, Clip.none);
        }
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pump();
        expect(spy.calls, 1);
      } else {
        expect(resetIcon, findsNothing, reason: 'Source reset control is iOS-only; host cannot prove native styling');
        expect(spy.calls, 0);
      }
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    for (final remote in [false, true]) {
      testWidgets('actual main profile ink geometry $direction remote=$remote', (tester) async {
        final ProfileEntity profile = remote
            ? ProfileEntity.remote(
                id: 'main-material',
                active: true,
                name: 'Main material',
                url: 'https://example.invalid/sub',
                lastUpdate: DateTime.utc(2026),
              )
            : ProfileEntity.local(
                id: 'main-material',
                active: true,
                name: 'Main material',
                lastUpdate: DateTime.utc(2026),
              );
        final spy = TileUpdateSpy();
        final fixture = await mountHomeFixture(
          tester,
          direction: direction,
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: ProfileTile(profile: profile, isMain: true),
          ),
          extraOverrides: [updateProfileNotifierProvider('main-material').overrideWith(() => spy)],
        );
        final radius = Radius.circular(expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393) ? 20 : 16);
        final content = tester.widget<InkWell>(
          find.ancestor(of: find.text('Main material'), matching: find.byType(InkWell)).first,
        );
        expect(
          content.borderRadius,
          remote
              ? (direction == TextDirection.ltr
                    ? BorderRadius.horizontal(right: radius)
                    : BorderRadius.horizontal(left: radius))
              : BorderRadius.all(radius),
        );
        if (remote) {
          final action = tester.widget<InkWell>(
            find.descendant(of: find.byType(ProfileActionButton), matching: find.byType(InkWell)),
          );
          expect(
            action.borderRadius,
            direction == TextDirection.ltr
                ? BorderRadius.horizontal(left: radius)
                : BorderRadius.horizontal(right: radius),
          );
          await tester.tap(find.byIcon(Icons.update_rounded));
          await tester.pump();
          expect(spy.calls, ['update:main-material']);
        } else {
          expect(find.byType(ProfileActionButton), findsNothing);
          expect(spy.calls, isEmpty);
        }
        expect(tester.takeException(), isNull);
        await fixture.close(tester);
      });
    }
  }
}
