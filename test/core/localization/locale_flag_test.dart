import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every language has a flag, and no two share one', () {
    final codes = AppLocale.values.map((e) => e.flagCountryCode).toList();
    for (final (i, locale) in AppLocale.values.indexed) {
      expect(codes[i], hasLength(2), reason: '${locale.name} has no flag');
    }
    expect(codes.toSet(), hasLength(codes.length));
  });

  test("every language's flag is bundled", () async {
    for (final locale in AppLocale.values) {
      // IPCountryFlag draws Iran with the lion and sun
      final code = locale.flagCountryCode == 'ir' ? 'ir-shir' : locale.flagCountryCode;
      final svg = await rootBundle.loadString('packages/circle_flags/assets/svg/$code.svg');
      expect(svg, contains('<svg'), reason: '${locale.name}: $code.svg');
    }
  });
}
