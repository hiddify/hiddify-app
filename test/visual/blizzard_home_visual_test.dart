import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';

import '../support/home_fixture.dart';

void main() => registerHomeVisualContracts();

void registerHomeVisualContracts() {
  for (final width in [320.0, 393.0, 430.0]) {
    for (final locale in [AppLocale.en, AppLocale.ru]) {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        testWidgets('full Home $width ${locale.name} $direction scale 1.3', (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final f = await mountHomeFixture(
            tester,
            width: width,
            scale: 1.3,
            locale: locale,
            direction: direction,
            profile: ProfileEntity.local(
              id: 'long-profile',
              active: true,
              name: 'Очень длинное название профиля — Synthetic long subscription name',
              lastUpdate: DateTime.utc(2026),
            ),
          );
          expect(find.byType(HomePage), findsOneWidget);
          expect(find.byType(AppVersionLabel), findsOneWidget);
          expect(find.byType(ProfileTile), findsOneWidget);
          expect(find.byType(ConnectionButton), findsOneWidget);
          expect(find.byType(ActiveProxyFooter), findsOneWidget);
          expect(find.byKey(const ValueKey('profile_quick_settings')), findsOneWidget);
          expect(find.byKey(const ValueKey('profile_add_button')), findsOneWidget);
          expect(tester.takeException(), isNull);
          final tile = tester.getRect(find.byType(ProfileTile));
          final footer = tester.getRect(find.byType(ActiveProxyFooter));
          expect(tile.width, lessThanOrEqualTo(width));
          expect(footer.bottom, lessThanOrEqualTo(852));
          final control = tester.widget<Material>(find.byKey(const ValueKey('home_connection_button')));
          expect(find.text('Synthetic Finland'), findsOneWidget);
          if (expectsBlizzard(AppThemeMode.dark, Brightness.dark, width)) {
            expect(f.innerTheme!.scaffoldBackgroundColor, const Color(0xFF06121D));
            expect(f.innerTheme!.colorScheme.primary, const Color(0xFF72D1FF));
            expect(control.shape, isA<RoundedRectangleBorder>());
            expect((control.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(44));
            expect(tester.getSize(find.byKey(const ValueKey('blizzard_bottom_dock'))), const Size(320, 64));
          } else {
            expect(control.shape, isA<CircleBorder>());
            expect(tester.getSize(find.byKey(const ValueKey('home_connection_button'))), const Size(148, 148));
          }
          await f.close(tester);
        });
      }
    }
  }
}
