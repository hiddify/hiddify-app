import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/go_router/refresh_listenable.dart';

void main() {
  tearDown(() => newUrlFromAppLink = '');

  test('consumes a pending mobile app link while the router stays on its current route', () {
    newUrlFromAppLink = 'hiddify://import?url=https%3A%2F%2Fexample.com%2Fsubscription';

    final result = takeIncomingAppLink(Uri.parse('/settings'));

    expect(result, 'hiddify://import?url=https%3A%2F%2Fexample.com%2Fsubscription');
    expect(newUrlFromAppLink, isEmpty);
  });

  test('prefers a deep link already delivered as the router URI', () {
    newUrlFromAppLink = 'hiddify://import?url=https%3A%2F%2Fstale.example';
    final routeUri = Uri.parse('hiddify://import?url=https%3A%2F%2Fcurrent.example');

    final result = takeIncomingAppLink(routeUri);

    expect(result, routeUri.toString());
    expect(newUrlFromAppLink, isEmpty);
  });
}
