import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:uuid/uuid.dart';

/// Runs the real download → populate → parse flow for a remote profile from a
/// map of raw single-value response headers.
Either<ProfileFailure, ProfileEntity> parseRemoteWithHeaders(
  Map<String, String> rawHeaders, {
  String url = "https://example.com/",
  UserOverride? userOverride,
}) {
  return ProfileParser.populateHeaders(content: '', remoteHeaders: rawHeaders).flatMap(
    (headers) => ProfileParser.parse(
      tempFilePath: '',
      profile: ProfileEntity.remote(
        id: const Uuid().v4(),
        active: true,
        name: '',
        url: url,
        lastUpdate: DateTime.now(),
        userOverride: userOverride,
        populatedHeaders: headers,
      ),
    ),
  );
}

/// Assert [either] is a parsed remote profile and hand it to [check].
void expectRemote(Either<ProfileFailure, ProfileEntity> either, void Function(RemoteProfileEntity rp) check) {
  expect(either.isRight(), true);
  either.match((l) => fail('parse failed: $l'), (r) {
    expect(r is RemoteProfileEntity, true);
    check(r as RemoteProfileEntity);
  });
}

void main() {
  const validBaseUrl = "https://example.com/configurations/user1/filename.yaml";
  const validExtendedUrl = "https://example.com/configurations/user1/filename.yaml?test#b";
  const validSupportUrl = "https://example.com/support";

  group("parse", () {
    test("Should use filename in url with no headers and fragment", () {
      final profile = ProfileParser.parse(
        tempFilePath: '',
        profile: ProfileEntity.remote(
          id: const Uuid().v4(),
          active: true,
          name: '',
          url: validBaseUrl,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(profile.isRight(), true);
      profile.match((l) {}, (r) {
        expect(r is RemoteProfileEntity, true);
        r.map(
          remote: (rp) {
            expect(rp.name, equals("filename"));
            expect(rp.url, equals(validBaseUrl));
            expect(rp.options, isNull);
            expect(rp.subInfo, isNull);
          },
          local: (lp) {},
        );
      });
    });

    test("Should use fragment in url with no headers", () {
      final profile = ProfileParser.parse(
        tempFilePath: '',
        profile: ProfileEntity.remote(
          id: const Uuid().v4(),
          active: true,
          name: '',
          url: validExtendedUrl,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(profile.isRight(), true);
      profile.match((l) {}, (r) {
        expect(r is RemoteProfileEntity, true);
        r.map(
          remote: (rp) {
            expect(rp.name, equals("b"));
            expect(rp.url, equals(validExtendedUrl));
            expect(rp.options, isNull);
            expect(rp.subInfo, isNull);
          },
          local: (lp) {},
        );
      });
    });

    test("Should use base64 title in headers", () {
      final headers = <String, List<String>>{
        "profile-title": ["base64:ZXhhbXBsZVRpdGxl"],
        "profile-update-interval": ["1"],
        "connection-test-url": [validBaseUrl],
        "remote-dns-address": [validBaseUrl],
        "subscription-userinfo": ["upload=0;download=1024;total=10240.5;expire=1704054600.55"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      // This fix occurs in the _downloadProfile method within ProfileParser, and the fixed headers are passed to populateHeaders
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: ProfileEntity.remote(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validExtendedUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          expect(r is RemoteProfileEntity, true);
          r.map(
            remote: (rp) {
              expect(rp.name, equals("exampleTitle"));
              expect(rp.url, equals(validExtendedUrl));
              expect(rp.options, equals(const ProfileOptions(updateInterval: Duration(hours: 1))));
              expect(
                rp.subInfo,
                equals(
                  SubscriptionInfo(
                    upload: 0,
                    download: 1024,
                    total: 10240,
                    expire: DateTime.fromMillisecondsSinceEpoch(1704054600 * 1000),
                  ),
                ),
              );
              expect(rp.webPageUrl, equals(validBaseUrl));
              expect(rp.supportUrl, equals(validSupportUrl));
            },
            local: (lp) {},
          );
        });
      });
    });

    test("Should keep web page and support urls without subscription-userinfo", () {
      final headers = <String, List<String>>{
        "profile-title": ["title"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: ProfileEntity.remote(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validBaseUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          r.map(
            remote: (rp) {
              expect(rp.subInfo, isNull);
              expect(rp.webPageUrl, equals(validBaseUrl));
              expect(rp.supportUrl, equals(validSupportUrl));
            },
            local: (lp) {},
          );
        });
      });
    });

    test("Should use infinite when given 0 for subscription properties", () {
      final headers = <String, List<String>>{
        "profile-title": ["title"],
        "profile-update-interval": ["1"],
        "subscription-userinfo": ["upload=0;download=1024;total=0;expire=0"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      // This fix occurs in the _downloadProfile method within ProfileParser, and the fixed headers are passed to populateHeaders
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: RemoteProfileEntity(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validBaseUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          expect(r is RemoteProfileEntity, true);
          r.map(
            remote: (rp) {
              expect(rp.subInfo, isNotNull);
              expect(rp.subInfo!.total, equals(ProfileParser.infiniteTrafficThreshold + 1));
              expect(
                rp.subInfo!.expire,
                equals(DateTime.fromMillisecondsSinceEpoch(ProfileParser.infiniteTimeThreshold * 1000)),
              );
            },
            local: (lp) {},
          );
        });
      });
    });
  });

  group("subscription-userinfo robustness (#10)", () {
    test("parses a normal header", () {
      expectRemote(
        parseRemoteWithHeaders({
          "profile-title": "p",
          "subscription-userinfo": "upload=100;download=200;total=1000;expire=1704054600",
        }),
        (rp) {
          expect(rp.subInfo!.upload, equals(100));
          expect(rp.subInfo!.download, equals(200));
          expect(rp.subInfo!.total, equals(1000));
          expect(rp.subInfo!.expire, equals(DateTime.fromMillisecondsSinceEpoch(1704054600 * 1000)));
        },
      );
    });

    test("tolerates a trailing semicolon (previously threw)", () {
      expectRemote(
        parseRemoteWithHeaders({
          "profile-title": "p",
          "subscription-userinfo": "upload=100;download=200;total=1000;expire=1704054600;",
        }),
        (rp) => expect(rp.subInfo!.total, equals(1000)),
      );
    });

    test("skips a segment without '=' (previously threw)", () {
      expectRemote(
        parseRemoteWithHeaders({
          "profile-title": "p",
          "subscription-userinfo": "upload=100;garbage;download=200;total=1000;expire=1704054600",
        }),
        (rp) {
          expect(rp.subInfo!.upload, equals(100));
          expect(rp.subInfo!.download, equals(200));
        },
      );
    });

    test("tolerates spaces around separators", () {
      expectRemote(
        parseRemoteWithHeaders({
          "profile-title": "p",
          "subscription-userinfo": "upload=100; download=200; total=1000; expire=1704054600",
        }),
        (rp) => expect(rp.subInfo!.download, equals(200)),
      );
    });

    test("missing upload/download yields null subInfo but still parses", () {
      expectRemote(
        parseRemoteWithHeaders({"profile-title": "p", "subscription-userinfo": "total=1000;expire=1704054600"}),
        (rp) {
          expect(rp.subInfo, isNull);
          expect(rp.name, equals("p"));
        },
      );
    });

    test("empty header yields null subInfo but still parses", () {
      expectRemote(
        parseRemoteWithHeaders({"profile-title": "p", "subscription-userinfo": ";"}),
        (rp) => expect(rp.subInfo, isNull),
      );
    });

    test("decimals are truncated to int", () {
      expectRemote(
        parseRemoteWithHeaders({
          "profile-title": "p",
          "subscription-userinfo": "upload=0;download=1024;total=10240.5;expire=1704054600.55",
        }),
        (rp) {
          expect(rp.subInfo!.total, equals(10240));
          expect(rp.subInfo!.expire, equals(DateTime.fromMillisecondsSinceEpoch(1704054600 * 1000)));
        },
      );
    });
  });

  group("profile-update-interval robustness (#11)", () {
    test("valid integer sets the update interval", () {
      expectRemote(
        parseRemoteWithHeaders({"profile-title": "p", "profile-update-interval": "6"}),
        (rp) => expect(rp.options, equals(const ProfileOptions(updateInterval: Duration(hours: 6)))),
      );
    });

    test("non-integer is ignored and the profile still parses (previously threw)", () {
      expectRemote(parseRemoteWithHeaders({"profile-title": "p", "profile-update-interval": "abc"}), (rp) {
        expect(rp.options, isNull);
        expect(rp.name, equals("p"));
      });
    });

    test("decimal is ignored (integer-hours convention)", () {
      expectRemote(
        parseRemoteWithHeaders({"profile-title": "p", "profile-update-interval": "1.5"}),
        (rp) => expect(rp.options, isNull),
      );
    });

    test("zero or negative is ignored", () {
      expectRemote(
        parseRemoteWithHeaders({"profile-title": "p", "profile-update-interval": "0"}),
        (rp) => expect(rp.options, isNull),
      );
      expectRemote(
        parseRemoteWithHeaders({"profile-title": "p", "profile-update-interval": "-3"}),
        (rp) => expect(rp.options, isNull),
      );
    });
  });
}
