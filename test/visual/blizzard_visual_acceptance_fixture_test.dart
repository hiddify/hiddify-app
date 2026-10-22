import 'package:flutter_test/flutter_test.dart';

import '../support/blizzard_visual_acceptance_fixture.dart';

void main() {
  test('server capture fixture keeps the reference hosts unmeasured', () {
    final group = blizzardVisualAcceptanceServerGroup;

    expect(group.selected, 'finland-vless');
    expect(
      group.items
          .map((proxy) => '${proxy.tagDisplay}|${proxy.groupSelectedTagDisplay}|${proxy.ipinfo.countryCode}')
          .toList(),
      [
        'Финляндия|Вьюга 1G|FI',
        'Германия|Хёллентэлер|DE',
        'Нидерланды|Хармоник|NL',
        'Эстония|Рао|EE',
        'США|Виливав|US',
        'Япония|Ямасэ|JP',
        'Турция|Лодос|TR',
        'Нидерланды|Фавоний|NL',
        'Польша|Хальны|PL',
        'Швейцария|Тивано|CH',
      ],
    );
    expect(group.items.singleWhere((proxy) => proxy.tag == group.selected).urlTestDelay, 84);
    expect(
      group.items.where((proxy) => proxy.tag != group.selected).map((proxy) => proxy.urlTestDelay),
      everyElement(0),
      reason: 'The reference capture shows an em dash for every unmeasured host.',
    );
  });
}
