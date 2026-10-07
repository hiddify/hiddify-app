import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/features/settings/widget/preference_tile.dart';

void main() {
  group('Region labels across locales', () {
    // The flag shown next to a region is parsed out of the translated label, so
    // every locale must survive that parse. A label that does not end in a
    // parenthesised country code simply has no flag; it must never take the
    // whole picker down with it.
    for (final locale in AppLocale.values) {
      test('${locale.name} labels resolve without throwing', () async {
        final t = await locale.build();
        for (final region in Region.values) {
          final label = region.present(t);
          expect(label, isNotEmpty, reason: '${locale.name}/${region.name} is empty');
          expect(
            () => ChoicePreferenceWidget.flagByTitle(label),
            returnsNormally,
            reason: '${locale.name}/${region.name} = "$label"',
          );
        }
      });
    }
  });

  group('flagByTitle', () {
    test('reads the country code out of the tail parentheses', () async {
      final t = await AppLocale.en.build();
      final label = Region.cn.present(t);
      expect(label, 'China (cn)');
      expect(ChoicePreferenceWidget.flagByTitle(label), isNotNull);
    });

    test('has no flag when the label carries no country code', () async {
      final t = await AppLocale.en.build();
      // English "Other" is five characters: short enough to have overflowed the
      // old positional slice, long enough to have produced a bogus code.
      final label = Region.other.present(t);
      expect(ChoicePreferenceWidget.flagByTitle(label), isNull);
    });

    // "其他" is two characters, which is what made the picker unusable under the
    // Chinese locales.
    test('has no flag for the two-character Chinese label', () async {
      final t = await AppLocale.zhCn.build();
      final label = Region.other.present(t);
      expect(label, '其他');
      expect(ChoicePreferenceWidget.flagByTitle(label), isNull);
    });

    test('has no flag for an empty label', () {
      expect(ChoicePreferenceWidget.flagByTitle(''), isNull);
    });

    test('ignores parentheses that are not at the tail', () {
      expect(ChoicePreferenceWidget.flagByTitle('China (cn) region'), isNull);
    });
  });
}
