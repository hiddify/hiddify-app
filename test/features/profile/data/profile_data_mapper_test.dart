import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/features/profile/data/profile_data_mapper.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';

void main() {
  ProfileEntry remote({String? url = 'https://example.com/sub', String? headers, String? userOverride}) => ProfileEntry(
    id: 'remote-id',
    type: ProfileType.remote,
    active: true,
    name: 'remote',
    url: url,
    lastUpdate: DateTime(2026),
    pinned: false,
    populatedHeaders: headers,
    userOverride: userOverride,
  );

  group("decodeProfileHeaders", () {
    test("reads saved headers", () {
      expect(decodeProfileHeaders('{"profile-title":"x"}'), {'profile-title': 'x'});
    });

    test("none saved, or saved as null", () {
      expect(decodeProfileHeaders(null), isNull);
      expect(decodeProfileHeaders('null'), isNull);
    });

    test("headers that can not be read are left out", () {
      expect(decodeProfileHeaders('{not json'), isNull);
      expect(decodeProfileHeaders('["a"]'), isNull);
    });
  });

  group("decodeUserOverride", () {
    test("none saved", () => expect(decodeUserOverride(null), isNull));

    test("choices that can not be read are left out", () {
      expect(decodeUserOverride('{not json'), isNull);
      expect(decodeUserOverride('"text"'), isNull);
      expect(decodeUserOverride('{"version":"two"}'), isNull);
    });
  });

  // hiddify-app#2422: one such profile failed the whole subscription list
  group("a remote profile still loads", () {
    test("with headers saved as null", () {
      final profile = remote(headers: 'null').toEntity() as RemoteProfileEntity;
      expect(profile.populatedHeaders, isNull);
    });

    test("with headers that can not be read", () {
      final profile = remote(headers: '{not json').toEntity() as RemoteProfileEntity;
      expect(profile.populatedHeaders, isNull);
      expect(profile.url, 'https://example.com/sub');
    });

    test("with choices that can not be read", () {
      final profile = remote(userOverride: '{not json').toEntity() as RemoteProfileEntity;
      expect(profile.userOverride, isNull);
    });

    test("without its URL", () {
      final profile = remote(url: null).toEntity() as RemoteProfileEntity;
      expect(profile.url, isEmpty);
    });
  });
}
