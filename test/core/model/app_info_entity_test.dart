import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/model/app_info_entity.dart';
import 'package:hiddify/core/model/environment.dart';

AppInfoEntity appInfo({
  String version = '0.0.1',
  String buildNumber = '19',
  Environment environment = Environment.prod,
}) => AppInfoEntity(
  name: 'WIR',
  version: version,
  buildNumber: buildNumber,
  release: Release.general,
  operatingSystem: 'ios',
  operatingSystemVersion: '26',
  environment: environment,
);

void main() {
  group('presentVersionWithBuild', () {
    test('shows the actual production version and build', () {
      expect(appInfo().presentVersionWithBuild, '0.0.1 (19)');
      expect(appInfo(version: '0.0.2', buildNumber: '21').presentVersionWithBuild, '0.0.2 (21)');
    });

    test('puts the development suffix after the build', () {
      expect(appInfo(buildNumber: '20', environment: Environment.dev).presentVersionWithBuild, '0.0.1 (20) dev');
    });

    test('falls back to the existing version presentation for a blank build', () {
      for (final environment in Environment.values) {
        for (final buildNumber in ['', '   ']) {
          final info = appInfo(buildNumber: buildNumber, environment: environment);
          expect(info.presentVersionWithBuild, info.presentVersion);
        }
      }
    });

    test('does not add a build or environment suffix to a blank version', () {
      for (final environment in Environment.values) {
        for (final version in ['', '   ']) {
          expect(appInfo(version: version, environment: environment).presentVersionWithBuild, version);
        }
      }
    });

    test('preserves the existing version-only presentation', () {
      expect(appInfo().presentVersion, '0.0.1');
      expect(appInfo(environment: Environment.dev).presentVersion, '0.0.1 dev');
    });
  });
}
