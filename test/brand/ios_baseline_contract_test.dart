import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _baseBundleIdentifier = 'com.womaninred.baseline';
const _appGroupIdentifier = 'group.com.womaninred.baseline';
const _developmentTeam = 'M9D72QQJ79';
const _serviceIdentifier = 'com.hiddify.app';

final _root = Directory.current;

void main() {
  group('V1 iOS baseline identity', () {
    test('uses the isolated baseline bundle identity', () {
      final baseConfiguration = _parseXcconfig(_read('ios/Base.xcconfig'));

      expect(
        baseConfiguration['BASE_BUNDLE_IDENTIFIER'],
        _baseBundleIdentifier,
        reason: 'the baseline must install beside the existing app',
      );
      expect(baseConfiguration['DEVELOPMENT_TEAM'], _developmentTeam);
    });

    test('uses the Blizzard VPN display name', () async {
      final runnerInfo = await _readPlist('ios/Runner/Info.plist');
      expect(runnerInfo['CFBundleDisplayName'], 'Blizzard VPN');
    });

    test('keeps the real Dart and Swift service channel compatible', () {
      final baseConfiguration = _parseXcconfig(_read('ios/Base.xcconfig'));
      expect(baseConfiguration['SERVICE_IDENTIFIER'], _serviceIdentifier);
      final dartChannel = _read('lib/hiddifycore/core_interface/core_interface_mobile.dart');
      final swiftBundleProperties = _read('ios/Runner/Extensions/Bundle+Properties.swift');
      final swiftMethodHandler = _read('ios/Runner/Handlers/MethodHandler.swift');
      expect(dartChannel, contains('static const channelPrefix = "$_serviceIdentifier";'));
      expect(swiftBundleProperties, contains('infoDictionary?["SERVICE_IDENTIFIER"]'));
      expect(swiftMethodHandler, contains(r'"\(Bundle.main.serviceIdentifier)/method"'));
    });

    test('applies the chosen team to every target configuration', () {
      final project = _PbxProject.parse(_read('ios/Runner.xcodeproj/project.pbxproj'));

      for (final target in ['Runner', 'HiddifyPacketTunnel', 'RunnerTests']) {
        final configurations = project.configurationsForTarget(target);
        expect(
          configurations.keys,
          containsAll(<String>['Debug', 'Release', 'Profile']),
          reason: '$target must define all standard build configurations',
        );
        for (final entry in configurations.entries) {
          expect(
            entry.value['DEVELOPMENT_TEAM'],
            _developmentTeam,
            reason: '$target ${entry.key} overrides the selected team',
          );
        }
      }
    });

    test('derives isolated app, extension, and RunnerTests identities', () {
      final project = _PbxProject.parse(_read('ios/Runner.xcodeproj/project.pbxproj'));
      _expectSettingForEveryConfiguration(
        project,
        target: 'Runner',
        key: 'PRODUCT_BUNDLE_IDENTIFIER',
        value: r'$(BASE_BUNDLE_IDENTIFIER)',
      );
      _expectSettingForEveryConfiguration(
        project,
        target: 'HiddifyPacketTunnel',
        key: 'PRODUCT_BUNDLE_IDENTIFIER',
        value: r'$(BASE_BUNDLE_IDENTIFIER).HiddifyPacketTunnel',
      );
      _expectSettingForEveryConfiguration(
        project,
        target: 'RunnerTests',
        key: 'PRODUCT_BUNDLE_IDENTIFIER',
        value: r'$(BASE_BUNDLE_IDENTIFIER).RunnerTests',
      );

      final vpnManager = _read('ios/Runner/VPN/VPNManager.swift');
      expect(
        vpnManager,
        contains('Bundle.main.baseBundleIdentifier + ".HiddifyPacketTunnel"'),
        reason: 'runtime provider lookup must derive the actual extension ID',
      );
    });

    test('retains the complete upstream entitlement sets with a new App Group', () async {
      final runnerEntitlements = await _readPlist('ios/Runner/Runner.entitlements');
      final extensionEntitlements = await _readPlist('ios/HiddifyPacketTunnel/HiddifyPacketTunnel.entitlements');

      expect(runnerEntitlements, <String, Object?>{
        'aps-environment': 'development',
        'com.apple.developer.networking.networkextension': <Object?>[
          'app-proxy-provider',
          'dns-proxy',
          'packet-tunnel-provider',
        ],
        'com.apple.developer.networking.vpn.api': <Object?>['allow-vpn'],
        'com.apple.security.app-sandbox': true,
        'com.apple.security.application-groups': <Object?>[r'group.$(BASE_BUNDLE_IDENTIFIER)'],
        'com.apple.security.network.client': true,
        'com.apple.security.network.server': true,
      }, reason: 'Runner rights stay intact until a profile proves one incompatible');
      expect(
        (runnerEntitlements['com.apple.security.application-groups']! as List).single.toString().replaceAll(
          r'$(BASE_BUNDLE_IDENTIFIER)',
          _baseBundleIdentifier,
        ),
        _appGroupIdentifier,
      );
      expect(extensionEntitlements, <String, Object?>{
        'com.apple.developer.networking.networkextension': <Object?>[
          'app-proxy-provider',
          'dns-proxy',
          'packet-tunnel-provider',
          'content-filter-provider',
        ],
        'com.apple.developer.networking.vpn.api': <Object?>['allow-vpn'],
        'com.apple.security.app-sandbox': true,
        'com.apple.security.application-groups': <Object?>[r'group.$(BASE_BUNDLE_IDENTIFIER)'],
        'com.apple.security.network.client': true,
        'com.apple.security.network.server': true,
      }, reason: 'extension rights stay intact until a profile proves one incompatible');
      expect(
        (extensionEntitlements['com.apple.security.application-groups']! as List).single.toString().replaceAll(
          r'$(BASE_BUNDLE_IDENTIFIER)',
          _baseBundleIdentifier,
        ),
        _appGroupIdentifier,
      );
    });
  });

  group('V2 iOS baseline export', () {
    test('keeps the extension version and build aligned with Flutter inputs', () {
      final project = _PbxProject.parse(_read('ios/Runner.xcodeproj/project.pbxproj'));
      _expectSettingForEveryConfiguration(project, target: 'HiddifyPacketTunnel',
          key: 'CURRENT_PROJECT_VERSION', value: r'$(FLUTTER_BUILD_NUMBER)');
      _expectSettingForEveryConfiguration(project, target: 'HiddifyPacketTunnel',
          key: 'MARKETING_VERSION', value: r'$(FLUTTER_BUILD_NAME)');
      expect(_read('ios/Base.xcconfig'),
          contains('#include? "Flutter/Generated.xcconfig"'),
          reason: 'the extension must receive the same generated Flutter version inputs');
    });

    test('uses the selected team', () async {
      final exportOptions = await _readPlist('ios/exportOptions.plist');
      expect(exportOptions['teamID'], _developmentTeam);
    });

    test('does not let export rewrite version or build number', () async {
      final exportOptions = await _readPlist('ios/exportOptions.plist');
      expect(exportOptions['manageAppVersionAndBuildNumber'], isFalse);
    });

    test('exports with automatic target-specific provisioning', () async {
      final exportOptions = await _readPlist('ios/exportOptions.plist');
      expect(exportOptions['method'], 'app-store-connect');
      expect(exportOptions['signingStyle'], 'automatic');
      expect(exportOptions.containsKey('provisioningProfiles'), isFalse,
          reason: 'Xcode selects profiles for the actual isolated targets');
      expect(exportOptions.containsKey('signingCertificate'), isFalse,
          reason: 'export must not retain the upstream certificate fingerprint');
      final project = _PbxProject.parse(_read('ios/Runner.xcodeproj/project.pbxproj'));
      for (final target in ['Runner', 'HiddifyPacketTunnel', 'RunnerTests']) {
        _expectSettingForEveryConfiguration(project, target: target,
            key: 'CODE_SIGN_STYLE', value: 'Automatic');
      }
    });
  });
}

String _read(String relativePath) => File('${_root.path}/$relativePath').readAsStringSync();

Map<String, String> _parseXcconfig(String source) {
  final values = <String, String>{};
  for (final line in const LineSplitter().convert(source)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
    final separator = trimmed.indexOf('=');
    if (separator < 1) continue;
    values[trimmed.substring(0, separator).trim()] = trimmed.substring(separator + 1).trim();
  }
  return values;
}

Future<Map<String, Object?>> _readPlist(String relativePath) async {
  final result = await Process.run('/usr/bin/plutil', ['-convert', 'json', '-o', '-', '${_root.path}/$relativePath']);
  if (result.exitCode != 0) {
    throw TestFailure('Could not parse $relativePath: ${result.stderr}');
  }
  return Map<String, Object?>.from(jsonDecode(result.stdout as String) as Map);
}

void _expectSettingForEveryConfiguration(
  _PbxProject project, {
  required String target,
  required String key,
  required String value,
}) {
  for (final entry in project.configurationsForTarget(target).entries) {
    expect(entry.value[key], value, reason: '$target ${entry.key} must set $key');
  }
}

final class _PbxProject {
  _PbxProject._(this._targetConfigurationIds, this._configurations);

  factory _PbxProject.parse(String source) {
    final targetConfigurationIds = <String, List<String>>{};
    final listPattern = RegExp(r'([A-F0-9]{24}) /\* Build configuration list for PBXNativeTarget "([^"]+)" \*/ = \{');
    final idPattern = RegExp(r'([A-F0-9]{24}) /\* (Debug|Release|Profile) \*/');
    for (final match in listPattern.allMatches(source)) {
      final body = _balancedBody(source, match.end - 1);
      targetConfigurationIds[match.group(2)!] = <String>[
        for (final idMatch in idPattern.allMatches(body)) idMatch.group(1)!,
      ];
    }

    final configurations = <String, _BuildConfiguration>{};
    final settingPattern = RegExp(r'^\s*("?[A-Za-z0-9_\[\]=*.-]+"?)\s*=\s*(.+);\s*$');
    for (final ids in targetConfigurationIds.values) {
      for (final id in ids) {
        final configurationStart = RegExp('$id /\\* (Debug|Release|Profile) \\*/ = \\{').firstMatch(source);
        if (configurationStart == null) continue;
        final body = _balancedBody(source, configurationStart.end - 1);
        final settingsStart = RegExp(r'buildSettings = \{').firstMatch(body);
        final settingsBody = settingsStart == null ? '' : _balancedBody(body, settingsStart.end - 1);
        final settings = <String, String>{};
        for (final line in const LineSplitter().convert(settingsBody)) {
          final setting = settingPattern.firstMatch(line);
          if (setting == null) continue;
          settings[_unquote(setting.group(1)!)] = _unquote(setting.group(2)!.trim());
        }
        final name = RegExp(r'\n\s*name = (Debug|Release|Profile);').firstMatch(body)?.group(1);
        if (name != null) {
          configurations[id] = _BuildConfiguration(name, settings);
        }
      }
    }

    return _PbxProject._(targetConfigurationIds, configurations);
  }

  final Map<String, List<String>> _targetConfigurationIds;
  final Map<String, _BuildConfiguration> _configurations;

  Map<String, Map<String, String>> configurationsForTarget(String target) {
    final ids = _targetConfigurationIds[target];
    if (ids == null || ids.isEmpty) {
      throw TestFailure('PBXNativeTarget $target has no build configurations');
    }
    return <String, Map<String, String>>{
      for (final id in ids)
        if (_configurations[id] case final configuration?) configuration.name: configuration.settings,
    };
  }
}

final class _BuildConfiguration {
  const _BuildConfiguration(this.name, this.settings);

  final String name;
  final Map<String, String> settings;
}

String _unquote(String value) {
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

String _balancedBody(String source, int openingBrace) {
  var depth = 0;
  for (var index = openingBrace; index < source.length; index++) {
    final character = source[index];
    if (character == '{') depth++;
    if (character == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(openingBrace + 1, index);
      }
    }
  }
  throw const FormatException('Unbalanced PBX object');
}
