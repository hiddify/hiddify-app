import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/utils/link_parsers.dart';

void main() {
  group("LinkParser.deep - hiddify scheme", () {
    test("path form uses the fragment as the name", () {
      final link = LinkParser.deep("hiddify://import/https://sub.com/x#MyProfile");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals("MyProfile"));
    });

    test("path form without a fragment has an empty name", () {
      final link = LinkParser.deep("hiddify://import/https://sub.com/x");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals(""));
    });

    test("path form keeps the inner query string", () {
      final link = LinkParser.deep("hiddify://import/https://sub.com/x?token=abc#Name");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x?token=abc"));
      expect(link.name, equals("Name"));
    });

    test("url-param form falls back to the fragment for the name (#8)", () {
      final link = LinkParser.deep("hiddify://install-config?url=https%3A%2F%2Fsub.com%2Fx#MyProfile");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals("MyProfile"));
    });

    test("url-param form prefers an explicit name= over the fragment", () {
      final link = LinkParser.deep("hiddify://install-config?url=https%3A%2F%2Fsub.com%2Fx&name=Explicit#Fragment");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals("Explicit"));
    });

    test("url-param form with neither name= nor fragment has an empty name", () {
      final link = LinkParser.deep("hiddify://install-config?url=https%3A%2F%2Fsub.com%2Fx");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals(""));
    });
  });

  group("LinkParser.deep - other panel schemes", () {
    test("v2ray with a url param", () {
      final link = LinkParser.deep("v2ray://install?url=https%3A%2F%2Fsub.com%2Fx&name=Sub");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals("Sub"));
    });

    test("v2ray without a url param returns null", () {
      expect(LinkParser.deep("v2ray://install"), isNull);
    });

    test("unknown scheme returns null", () {
      expect(LinkParser.deep("unknown://whatever?url=https%3A%2F%2Fx.com"), isNull);
    });
  });

  group("LinkParser.parse", () {
    test("plain https url is handled by simple()", () {
      final link = LinkParser.parse("https://example.com/sub?name=Foo");
      expect(link, isNotNull);
      expect(link!.url, equals("https://example.com/sub?name=Foo"));
      expect(link.name, equals("Foo"));
    });

    test("hiddify deep link is handled by deep()", () {
      final link = LinkParser.parse("hiddify://install-config?url=https%3A%2F%2Fsub.com%2Fx#Name");
      expect(link, isNotNull);
      expect(link!.url, equals("https://sub.com/x"));
      expect(link.name, equals("Name"));
    });
  });
}
