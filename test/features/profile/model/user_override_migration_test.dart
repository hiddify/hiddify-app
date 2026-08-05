import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';

void main() {
  /// Build a stored v1 record (the shape written before extraSecurity/fragment).
  String v1(Map<String, Object?> fields) => jsonEncode({'version': 1, ...fields});

  group("UserOverride v1 -> v2 migration", () {
    test("enableWarp becomes extraSecurity: warp", () {
      final o = UserOverride.fromStr(v1({'enableWarp': true}))!;
      expect(o.extraSecurity, equals('warp'));
      expect(o.version, equals(latestUserOverrideVersion));
    });

    test("enablePsiphon becomes extraSecurity: psiphon", () {
      expect(UserOverride.fromStr(v1({'enablePsiphon': true}))!.extraSecurity, equals('psiphon'));
    });

    test("both enabled: psiphon wins (matches v1 behaviour)", () {
      final o = UserOverride.fromStr(v1({'enableWarp': true, 'enablePsiphon': true}))!;
      expect(o.extraSecurity, equals('psiphon'));
    });

    test("enableFragment becomes an empty fragment (defaults)", () {
      final o = UserOverride.fromStr(v1({'enableFragment': true}))!;
      expect(o.fragment, equals(''));
    });

    test("false flags stay unset", () {
      final o = UserOverride.fromStr(
        v1({'enableWarp': false, 'enablePsiphon': false, 'enableFragment': false}),
      )!;
      expect(o.extraSecurity, isNull);
      expect(o.fragment, isNull);
    });

    test("other v1 fields survive", () {
      final o = UserOverride.fromStr(
        v1({'name': 'My Profile', 'updateInterval': 12, 'isAutoUpdateDisable': true, 'enableWarp': true}),
      )!;
      expect(o.name, equals('My Profile'));
      expect(o.updateInterval, equals(12));
      expect(o.isAutoUpdateDisable, isTrue);
      expect(o.extraSecurity, equals('warp'));
    });

    test("a record with no version is treated as v1", () {
      final o = UserOverride.fromStr(jsonEncode({'enableWarp': true}))!;
      expect(o.extraSecurity, equals('warp'));
      expect(o.version, equals(latestUserOverrideVersion));
    });

    test("empty v1 record migrates without error", () {
      final o = UserOverride.fromStr(v1({}))!;
      expect(o.extraSecurity, isNull);
      expect(o.fragment, isNull);
    });
  });

  group("UserOverride v2 round-trip", () {
    test("v2 values survive toStr -> fromStr", () {
      const original = UserOverride(
        name: 'p',
        updateInterval: 6,
        extraSecurity: 'warp',
        fragment: '2-4,10-20',
      );
      final restored = UserOverride.fromStr(original.toStr())!;
      expect(restored.extraSecurity, equals('warp'));
      expect(restored.fragment, equals('2-4,10-20'));
      expect(restored.name, equals('p'));
      expect(restored.updateInterval, equals(6));
    });

    test("a v2 record is not migrated again", () {
      const original = UserOverride(extraSecurity: 'psiphon');
      final restored = UserOverride.fromStr(original.toStr())!;
      expect(restored.extraSecurity, equals('psiphon'));
      expect(restored.version, equals(latestUserOverrideVersion));
    });

    test("null input returns null", () {
      expect(UserOverride.fromStr(null), isNull);
    });
  });
}
