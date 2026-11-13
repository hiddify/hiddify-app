import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:path/path.dart' as p;

/// The longest start parameter Telegram passes to a bot.
const _maxPayload = 64;

/// The issues bot's link with this device's details as its start parameter: `;`-separated
/// `key=value` pairs, base64url without padding. Each key has one name and each value one code;
/// the bot has no aliases.
///
/// - `os`: `android` `ios` `win` `mac` `tv`, a Linux distro's code ([linuxDistro]) or `linux`
/// - `ov`: the OS or distro version, short (`14`, `11`, `24.04`)
/// - `v`: the build number, the part after `+` in pubspec's version
/// - `pm`: how the app was installed ([_packageMode])
/// - `t`: `c` crash, `b` bug
/// - `l`: the app's language; `a`: the CPU architecture
///
/// What does not fit Telegram's 64 characters is left out: `a`, then `l`, then `ov` is shortened.
@visibleForTesting
Uri telegramReportLink({
  required String os,
  required String ov,
  required String v,
  required String t,
  String? pm,
  String? l,
  String? a,
}) {
  String encode(Map<String, String?> fields) => base64Url
      .encode(
        utf8.encode(
          [
            for (final MapEntry(:key, :value) in fields.entries)
              if (value != null && _clean(value).isNotEmpty) '$key=${_clean(value)}',
          ].join(';'),
        ),
      )
      .replaceAll('=', '');

  var version = ov;
  Map<String, String?> fields({bool language = true, bool arch = true}) => {
    'os': os,
    'ov': version,
    'v': v,
    'pm': pm,
    't': t,
    if (language) 'l': l,
    if (arch) 'a': a,
  };
  var payload = encode(fields());
  if (payload.length > _maxPayload) payload = encode(fields(arch: false));
  if (payload.length > _maxPayload) payload = encode(fields(arch: false, language: false));
  while (payload.length > _maxPayload && version.isNotEmpty) {
    version = version.substring(0, version.length - 1);
    payload = encode(fields(arch: false, language: false));
  }
  return Uri.https('t.me', '/${Constants.bugReportTelegramBot}', {'start': payload});
}

/// The link for this device: [crash] after a crash, else a bug; [build] is the app's build
/// number, [language] its UI language, [release] what it was built as.
Future<Uri> telegramReportLinkFor({
  required bool crash,
  required String build,
  required String language,
  required bool tv,
  required Release release,
}) async {
  final (os, ov) = await _system(tv: tv);
  return telegramReportLink(
    os: os,
    ov: ov,
    v: build,
    pm: await _packageMode(release),
    t: crash ? 'c' : 'b',
    l: language,
    a: _arch(),
  );
}

/// The `os` code and its version: the release a person knows, not the build string.
Future<(String, String)> _system({required bool tv}) async {
  final full = Platform.operatingSystemVersion;
  String number() => RegExp(r'\d+(\.\d+){0,2}').firstMatch(full)?.group(0) ?? '';
  if (Platform.isAndroid) {
    var release = '';
    try {
      release = await const MethodChannel('com.hiddify.app/platform').invokeMethod<String>('os_version') ?? '';
    } on PlatformException {
      // the bot asks for it
    }
    return (tv ? 'tv' : 'android', release);
  }
  if (Platform.isIOS) return ('ios', number());
  if (Platform.isMacOS) return ('mac', number());
  if (Platform.isWindows) return ('win', windowsVersion(full));
  if (Platform.isLinux) {
    // inside a Flatpak, /etc is the runtime's: the host's own file is under /run/host
    for (final path in const ['/run/host/os-release', '/etc/os-release', '/usr/lib/os-release']) {
      try {
        final (os, ov) = linuxDistro(File(path).readAsStringSync());
        // a distro without a version (a rolling one) leaves the kernel's
        return (os, ov.isEmpty ? number() : ov);
      } on FileSystemException {
        continue;
      }
    }
    return ('linux', number());
  }
  return (Platform.operatingSystem, number());
}

/// `11` or `10`, from Windows's `"Windows 10 Pro" 10.0 (Build 22631)`: Windows 11 still says 10.0,
/// only its build tells.
@visibleForTesting
String windowsVersion(String operatingSystemVersion) {
  final build = int.tryParse(RegExp(r'Build (\d+)').firstMatch(operatingSystemVersion)?.group(1) ?? '');
  if (build == null) return '';
  return build >= 22000 ? '11' : '10';
}

/// The bot's code for the distro an os-release file names, with its version; `linux` for one the
/// bot does not know.
@visibleForTesting
(String, String) linuxDistro(String osRelease) {
  final values = {
    for (final line in const LineSplitter().convert(osRelease))
      if (line.indexOf('=') case final at when at > 0)
        line.substring(0, at).trim(): line.substring(at + 1).trim().replaceAll(RegExp(r'''^["']|["']$'''), ''),
  };
  final id = (values['ID'] ?? '').toLowerCase();
  final code = switch (id) {
    'ubuntu' => 'ubu',
    'debian' => 'deb',
    'fedora' => 'fed',
    'linuxmint' => 'mint',
    'arch' => 'arch',
    'manjaro' => 'manj',
    'endeavouros' => 'eos',
    'cachyos' => 'cachy',
    'garuda' => 'garu',
    'pop' => 'pop',
    'elementary' => 'elem',
    'zorin' => 'zorin',
    'mx' => 'mx',
    'neon' => 'neon',
    'kali' => 'kali',
    'almalinux' => 'alma',
    'rocky' => 'rocky',
    'centos' => 'cent',
    'rhel' => 'rhel',
    'nixos' => 'nix',
    'gentoo' => 'gen',
    'void' => 'void',
    'alpine' => 'alp',
    'deepin' => 'deep',
    'kylin' || 'ubuntukylin' => 'kylin',
    'astra' => 'astra',
    'solus' => 'sol',
    'slackware' => 'slack',
    'steamos' => 'steam',
    'bazzite' => 'bazz',
    _ when id.startsWith('opensuse') || id == 'sles' => 'sus',
    _ => 'linux',
  };
  return (code, values['VERSION_ID'] ?? '');
}

/// How this copy was installed, as the bot names it: the store's own build, or else what the
/// files around the app say; null when nothing tells.
Future<String?> _packageMode(Release release) async {
  bool exists(String path) => FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  if (Platform.isAndroid) return release == Release.googlePlay ? 'play' : 'apk';
  if (Platform.isIOS) return 'appstore';
  if (Platform.isMacOS) {
    if (release == Release.appStore) return 'appstore';
    // a Homebrew cask keeps its record in the Caskroom, on Apple silicon and on Intel
    if (exists('/opt/homebrew/Caskroom/hiddify') || exists('/usr/local/Caskroom/hiddify')) return 'brew';
    return 'dmg';
  }
  if (Platform.isWindows) {
    if (release == Release.microsoftStore) return 'msix';
    if (Platform.resolvedExecutable.toLowerCase().contains(r'\scoop\apps\')) return 'scoop';
    final programData = Platform.environment['ProgramData'] ?? r'C:\ProgramData';
    if (exists(p.join(programData, 'chocolatey', 'lib', 'hiddify'))) return 'choco';
    return Environment.isPortable ? 'portable' : 'exe';
  }
  if (Platform.isLinux) {
    final environment = Platform.environment;
    if ((environment['APPIMAGE'] ?? '').isNotEmpty) return 'appimage';
    if ((environment['FLATPAK_ID'] ?? '').isNotEmpty) return 'flatpak';
    if ((environment['SNAP'] ?? '').isNotEmpty) return 'snap';
    // each package manager's record of what it installed
    if (exists('/var/lib/dpkg/info/hiddify.list')) return 'deb';
    try {
      final pacman = Directory('/var/lib/pacman/local');
      if (pacman.existsSync() && pacman.listSync().any((e) => p.basename(e.path).startsWith('hiddify'))) {
        return 'aur';
      }
    } on FileSystemException {
      // not readable: not this one
    }
    try {
      final rpm = await Process.run('rpm', ['-q', '--quiet', 'hiddify']);
      if (rpm.exitCode == 0) return 'rpm';
    } on ProcessException {
      // no rpm on this system
    }
    return null;
  }
  return null;
}

/// `arm64`, `x64`, `arm`, `ia32` or `riscv64`.
String _arch() => Abi.current().toString().split('_').last;

/// What a value may hold: a `;` or `=` would split the payload in the wrong place.
String _clean(String value) => value.replaceAll(RegExp('[^A-Za-z0-9._-]'), '');
