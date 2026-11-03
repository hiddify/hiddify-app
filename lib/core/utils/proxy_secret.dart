import 'dart:math';

/// Characters of the proxy secret. Visually ambiguous characters (`0`/`O`, `1`/`l`/`I`) are left out
/// so the secret stays readable when it is typed from a QR code by hand.
const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

/// A new secret for the local SOCKS/HTTP port (the user is "hiddify"): [length] characters, a dash
/// after every four (`Kp7x-Q2mZ`), so it reads in parts without a space that is not in it.
String generateProxySecret({int length = 8}) {
  final random = Random.secure();
  final chars = List.generate(length, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
  return RegExp('.{1,4}').allMatches(chars).map((m) => m[0]).join('-');
}
