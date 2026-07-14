import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/gen/translations.g.dart';

void main() {
  test('unexpected core details are not exposed in the user-facing error', () {
    final translations = TranslationsEn();
    const rawCoreMessage = 'startService - starting background core...';

    final presented = const ConnectionFailure.unexpected(rawCoreMessage).present(translations);

    expect(presented.type, translations.errors.connectivity.unexpected);
    expect(presented.message, isNull);
  });
}
