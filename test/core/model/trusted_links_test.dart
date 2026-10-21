import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/model/trusted_links.dart';

void main() {
  // Seed under test: hiddify.com, github.com/hiddify, t.me/hiddify

  group("TrustedLinks.isTrusted - trusted (exact match, normalized)", () {
    test("exact telegram handle", () {
      expect(TrustedLinks.isTrusted("https://t.me/hiddify"), isTrue);
    });

    test("trailing slash is ignored", () {
      expect(TrustedLinks.isTrusted("https://t.me/hiddify/"), isTrue);
    });

    test("scheme is ignored (http)", () {
      expect(TrustedLinks.isTrusted("http://t.me/hiddify"), isTrue);
    });

    test("no scheme", () {
      expect(TrustedLinks.isTrusted("t.me/hiddify"), isTrue);
    });

    test("www prefix is stripped", () {
      expect(TrustedLinks.isTrusted("https://www.hiddify.com"), isTrue);
    });

    test("host is case-insensitive", () {
      expect(TrustedLinks.isTrusted("https://HIDDIFY.COM"), isTrue);
    });

    test("fragment is ignored", () {
      expect(TrustedLinks.isTrusted("https://t.me/hiddify#hiddify"), isTrue);
    });

    test("domain root with and without trailing slash", () {
      expect(TrustedLinks.isTrusted("https://hiddify.com"), isTrue);
      expect(TrustedLinks.isTrusted("https://hiddify.com/"), isTrue);
    });

    test("github org", () {
      expect(TrustedLinks.isTrusted("https://github.com/hiddify"), isTrue);
    });
  });

  group("TrustedLinks.isTrusted - untrusted (must warn)", () {
    test("look-alike handle (extra letter)", () {
      expect(TrustedLinks.isTrusted("https://t.me/Hiddiify"), isFalse);
    });

    test("missing letter", () {
      expect(TrustedLinks.isTrusted("https://t.me/hiddïfy"), isFalse);
    });

    test("sub-path is not covered by an exact handle entry", () {
      expect(TrustedLinks.isTrusted("https://t.me/hiddify/123"), isFalse);
    });

    test("extra query means not exact", () {
      expect(TrustedLinks.isTrusted("https://t.me/hiddify?x=1"), isFalse);
    });

    test("path is case-sensitive (exact match)", () {
      expect(TrustedLinks.isTrusted("https://t.me/Hiddify"), isFalse);
    });

    test("sub-path on a domain entry", () {
      expect(TrustedLinks.isTrusted("https://hiddify.com/donate"), isFalse);
    });

    test("telegram.me alias is not the same host", () {
      expect(TrustedLinks.isTrusted("https://telegram.me/hiddify"), isFalse);
    });

    test("look-alike domain", () {
      expect(TrustedLinks.isTrusted("https://evil-hiddify.com"), isFalse);
    });

    test("suffix-attack domain", () {
      expect(TrustedLinks.isTrusted("https://hiddify.com.evil.com"), isFalse);
    });

    test("different github org", () {
      expect(TrustedLinks.isTrusted("https://github.com/hiddiify"), isFalse);
    });

    test("empty and garbage input", () {
      expect(TrustedLinks.isTrusted(""), isFalse);
      expect(TrustedLinks.isTrusted("   "), isFalse);
      expect(TrustedLinks.isTrusted("not a url"), isFalse);
    });
  });
}
