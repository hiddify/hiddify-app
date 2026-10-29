import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/gen/translations.g.dart';

void main() {
  test('macOS extension approval is an expected permission prompt with readable instructions', () {
    const message = 'Allow Hiddify in System Settings, then connect again.';
    final failure = ConnectionFailure.fromError(
      PlatformException(code: 'MACOS_VPN_APPROVAL_REQUIRED', message: message),
    );

    expect(failure, isA<ExpectedMeasuredFailure>());
    expect(failure, isA<MissingVpnPermission>());
    expect(failure.present(TranslationsEn()).type, 'Missing VPN permission');
    expect(failure.present(TranslationsEn()).message, message);
  });

  test('unclassified native failures remain errors without the platform wrapper', () {
    final failure = ConnectionFailure.fromError(
      PlatformException(code: 'MACOS_VPN', message: 'The packet tunnel failed to start.'),
    );

    expect(failure, isA<UnexpectedConnectionFailure>());
    expect(failure.present(TranslationsEn()).message, 'The packet tunnel failed to start.');
  });
}
