import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';

void main() {
  const validBaseUrl = "https://example.com/configurations/user1/filename.yaml";
  const validExtendedUrl = "https://example.com/configurations/user1/filename.yaml?test#b";
  const validSupportUrl = "https://example.com/support";

  group(
    "parse",
    () {
      test(
        "Should use filename in url with no headers and fragment",
        () {
          final profile = ProfileParser.parse(validBaseUrl, {});

          expect(profile.name, equals("filename"));
          expect(profile.url, equals(validBaseUrl));
          expect(profile.options, isNull);
          expect(profile.subInfo, isNull);
        },
      );

      test(
        "Should use fragment in url with no headers",
        () {
          final profile = ProfileParser.parse(validExtendedUrl, {});

          expect(profile.name, equals("b"));
          expect(profile.url, equals(validExtendedUrl));
          expect(profile.options, isNull);
          expect(profile.subInfo, isNull);
        },
      );

      test(
        "Should use base64 title in headers",
        () {
          final headers = <String, List<String>>{
            "profile-title": ["base64:ZXhhbXBsZVRpdGxl"],
            "profile-update-interval": ["1"],
            "test-url": [validBaseUrl],
            "subscription-userinfo": [
              "upload=0;download=1024;total=10240.5;expire=1704054600.55",
            ],
            "profile-web-page-url": [validBaseUrl],
            "support-url": [validSupportUrl],
          };
          final profile = ProfileParser.parse(validExtendedUrl, headers);

          expect(profile.name, equals("exampleTitle"));
          expect(profile.url, equals(validExtendedUrl));
          expect(profile.testUrl, equals(validBaseUrl));
          expect(
            profile.options,
            equals(const ProfileOptions(updateInterval: Duration(hours: 1))),
          );
          expect(
            profile.subInfo,
            equals(
              SubscriptionInfo(
                upload: 0,
                download: 1024,
                total: 10240,
                expire: DateTime.fromMillisecondsSinceEpoch(1704054600 * 1000),
                webPageUrl: validBaseUrl,
                supportUrl: validSupportUrl,
              ),
            ),
          );
        },
      );

      test(
        "Should use infinite when given 0 for subscription properties",
        () {
          final headers = <String, List<String>>{
            "profile-title": ["title"],
            "profile-update-interval": ["1"],
            "subscription-userinfo": [
              "upload=0;download=1024;total=0;expire=0",
            ],
            "profile-web-page-url": [validBaseUrl],
            "support-url": [validSupportUrl],
          };
          final profile = ProfileParser.parse(validExtendedUrl, headers);

          expect(profile.subInfo, isNotNull);
          expect(
            profile.subInfo!.total,
            equals(ProfileParser.infiniteTrafficThreshold),
          );
          expect(
            profile.subInfo!.expire,
            equals(
              DateTime.fromMillisecondsSinceEpoch(
                ProfileParser.infiniteTimeThreshold * 1000,
              ),
            ),
          );
        },
      );
    },
  );
}
