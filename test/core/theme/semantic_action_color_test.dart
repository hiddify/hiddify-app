import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/widgets/chain_license_dialog.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  const primary = Color(0xFFCC1234);
  const hover = Color(0xFFEE4567);
  late Translations translations;

  setUpAll(() async {
    translations = await AppLocale.en.build();
  });

  Widget app(Widget child) => ProviderScope(
    overrides: [translationsProvider.overrideWith((ref) => translations)],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(primary: primary),
        extensions: const [NovaThemeData.dark],
      ).copyWith(extensions: <ThemeExtension<dynamic>>{NovaThemeData.dark.copyWith(accentHover: hover)}),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('license links use inherited primary instead of blue or green', (tester) async {
    await tester.pumpWidget(app(const ChainLicenseDialog(mode: ChainMode.warp)));
    await tester.pumpAndSettle();

    final richText = tester.widget<Text>(find.byWidgetPredicate((widget) => widget is Text && widget.textSpan != null));
    final coloredSpans = (richText.textSpan! as TextSpan).children!.whereType<TextSpan>().where(
      (span) => span.style?.color != null,
    );
    expect(coloredSpans, isNotEmpty);
    expect(coloredSpans.every((span) => span.style?.color == primary), isTrue);
  });

  testWidgets('profile-site action uses inherited primary and interaction colors', (tester) async {
    final info = SubscriptionInfo(
      upload: 0,
      download: 0,
      total: 1,
      expire: DateTime(2099),
      webPageUrl: 'https://example.com/account',
    );
    await tester.pumpWidget(app(NewSiteSubscriptionInfo(info)));

    final icon = tester.widget<Icon>(find.byKey(const ValueKey('profile_site_icon')));
    expect(icon.color, primary);
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.hoverColor, NovaThemeData.dark.accentFill);
    expect(inkWell.focusColor, hover.withValues(alpha: 0.24));
  });
}
