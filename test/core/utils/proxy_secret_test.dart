import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/utils/proxy_secret.dart';

void main() {
  test('a generated secret is in parts of four joined by dashes', () {
    expect(generateProxySecret(), matches(RegExp(r'^[A-Za-z2-9]{4}-[A-Za-z2-9]{4}$')));
    expect(generateProxySecret(length: 10), matches(RegExp(r'^[A-Za-z2-9]{4}-[A-Za-z2-9]{4}-[A-Za-z2-9]{2}$')));
  });

  test('a generated secret leaves out look-alike characters', () {
    final secrets = List.generate(200, (_) => generateProxySecret()).join();
    expect(secrets, isNot(matches(RegExp('[01OIl]'))));
  });
}
