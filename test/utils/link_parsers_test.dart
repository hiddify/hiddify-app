import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/utils/link_parsers.dart';

void main() {
  group("LinkParser.deep", () {
    test("parses spritenet://import?url= links from the Telegram bot", () {
      const sub = "https://panel.example.com:2096/sub/abc123";
      final link = LinkParser.deep("spritenet://import?url=${Uri.encodeComponent(sub)}&name=SpriteNet");
      expect(link, isNotNull);
      expect(link!.url, sub);
      expect(link.name, "SpriteNet");
    });

    test("keeps understanding legacy hiddify:// links", () {
      final link = LinkParser.deep("hiddify://import/https://example.com/sub#Name");
      expect(link?.url, "https://example.com/sub");
      expect(link?.name, "Name");
    });

    test("registers the spritenet scheme", () {
      expect(LinkParser.protocols, contains("spritenet"));
      expect(LinkParser.protocols, isNot(contains("hiddify")));
    });
  });
}
