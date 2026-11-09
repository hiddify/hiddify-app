import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/features/app_update/data/github_release_parser.dart';
import 'package:hiddify/features/app_update/model/install_kind.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';

Map<String, dynamic> _release(String tag, {bool draft = false, List<String> assets = const []}) => {
  'tag_name': tag,
  'draft': draft,
  // the release workflow marks every release a pre-release on GitHub
  'prerelease': true,
  'html_url': 'https://github.com/hiddify/hiddify-app/releases/tag/$tag',
  'published_at': '2026-11-01T22:42:47Z',
  'assets': [
    for (final name in assets)
      {
        'name': name,
        'browser_download_url': 'https://github.com/hiddify/hiddify-app/releases/download/$tag/$name',
        'size': 42,
      },
  ],
};

void main() {
  group('a release tag', () {
    test('names its version; the GitHub pre-release flag does not make it one', () {
      final release = GithubReleaseParser.parse(_release('v5.4.0', assets: ['Hiddify-MacOS.dmg']))!;
      expect(release.version, '5.4.0');
      expect(release.preRelease, isFalse);
      expect(release.flavor, Environment.prod);
      expect(release.asset('Hiddify-MacOS.dmg')!.size, 42);
    });

    test('with a suffix is a pre-release, .dev a dev build', () {
      expect(GithubReleaseParser.parse(_release('v5.5.0-beta.1'))!.preRelease, isTrue);
      final dev = GithubReleaseParser.parse(_release('v5.5.0.dev'))!;
      expect(dev.flavor, Environment.dev);
      expect(dev.version, '5.5.0');
      expect(GithubReleaseParser.parse(_release('v5.4.0+540'))!.buildNumber, '540');
    });

    test('that is no version, or a draft, is no release', () {
      expect(GithubReleaseParser.parse(_release('draft')), isNull);
      expect(GithubReleaseParser.parse(_release('v5.4.0', draft: true)), isNull);
    });
  });

  group('the file an install updates from', () {
    final release = GithubReleaseParser.parse(
      _release(
        'v5.4.0',
        assets: [
          'Hiddify-Android-arm64.apk',
          'Hiddify-Android-arm7.apk',
          'Hiddify-Android-x86_64.apk',
          'Hiddify-Android-universal.apk',
          'Hiddify-Windows-Setup-x64.exe',
          'Hiddify-Windows-Setup-x64.Msix',
          'Hiddify-Windows-Portable-x64.zip',
          'Hiddify-Linux-x64-AppImage.AppImage',
          'Hiddify-Debian-x64.deb',
          'Hiddify-MacOS.dmg',
          'Hiddify-MacOS-AppStore.dmg',
        ],
      ),
    )!;
    String? asset(InstallKind kind, {List<String> abis = const []}) => kind.assetIn(release, abis: abis)?.name;

    test('an APK is the one of the device ABI, else the universal one', () {
      expect(asset(InstallKind.androidApk, abis: ['arm64-v8a', 'armeabi-v7a']), 'Hiddify-Android-arm64.apk');
      expect(asset(InstallKind.androidApk, abis: ['armeabi-v7a']), 'Hiddify-Android-arm7.apk');
      expect(asset(InstallKind.androidApk, abis: ['x86_64']), 'Hiddify-Android-x86_64.apk');
      expect(asset(InstallKind.androidApk, abis: ['riscv64']), 'Hiddify-Android-universal.apk');
      expect(asset(InstallKind.androidApk), 'Hiddify-Android-universal.apk');
    });

    test('each desktop install takes its own format, never a store build', () {
      expect(asset(InstallKind.windowsSetup), 'Hiddify-Windows-Setup-x64.exe');
      expect(asset(InstallKind.linuxAppImage), 'Hiddify-Linux-x64-AppImage.AppImage');
      expect(asset(InstallKind.linuxDeb), 'Hiddify-Debian-x64.deb');
      expect(asset(InstallKind.macOS), 'Hiddify-MacOS.dmg');
    });

    test('on an arm64 Linux the update is the arm64 build, never the x64 one', () {
      final withArm = GithubReleaseParser.parse(
        _release(
          'v5.6.0',
          assets: [
            'Hiddify-Linux-x64-AppImage.AppImage',
            'Hiddify-Debian-x64.deb',
            'Hiddify-Linux-arm64-AppImage.AppImage',
            'Hiddify-Debian-arm64.deb',
          ],
        ),
      )!;
      String? arm(InstallKind kind, RemoteVersionEntity r) => kind.assetIn(r, arm64: true)?.name;
      expect(arm(InstallKind.linuxAppImage, withArm), 'Hiddify-Linux-arm64-AppImage.AppImage');
      expect(arm(InstallKind.linuxDeb, withArm), 'Hiddify-Debian-arm64.deb');
      // a release without arm64 Linux files opens the release page instead of installing x64
      expect(arm(InstallKind.linuxAppImage, release), isNull);
      expect(arm(InstallKind.linuxDeb, release), isNull);
    });

    test('a store install, the portable zip and other Linux installs download nothing', () {
      for (final kind in [InstallKind.store, InstallKind.windowsPortable, InstallKind.linuxOther]) {
        expect(asset(kind), isNull, reason: '$kind');
        expect(kind.installsItself, isFalse, reason: '$kind');
      }
    });

    test('a release without the file downloads nothing', () {
      final bare = GithubReleaseParser.parse(_release('v5.4.0'))!;
      expect(InstallKind.windowsSetup.assetIn(bare), isNull);
    });
  });

  test('a store release never updates itself', () {
    for (final release in [Release.googlePlay, Release.appStore, Release.microsoftStore]) {
      expect(release.allowCustomUpdateChecker, isFalse, reason: '$release');
      expect(InstallKind.detect(release), InstallKind.store, reason: '$release');
    }
    expect(Release.general.allowCustomUpdateChecker, isTrue);
  });

  test('an MSIX package runs from WindowsApps', () {
    expect(Release.isMsix(r'C:\Program Files\WindowsApps\Hiddify_5.4.0.0_x64__abc\hiddify.exe'), isTrue);
    expect(Release.isMsix(r'C:\Program Files\Hiddify\Hiddify.exe'), isFalse);
  });
}
