import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/crash_report/data/telegram_report_link.dart';

/// The fields the bot will read back from [link].
Map<String, String> _fields(Uri link) {
  final plain = utf8.decode(base64Url.decode(base64Url.normalize(link.queryParameters['start']!)));
  return {for (final pair in plain.split(';')) pair.split('=')[0]: pair.split('=')[1]};
}

String _payload(Uri link) => link.queryParameters['start']!;

void main() {
  test("encodes as the bot's own examples do", () {
    expect(
      _payload(telegramReportLink(os: 'android', ov: '14', v: '50901', pm: 'play', t: 'c')),
      'b3M9YW5kcm9pZDtvdj0xNDt2PTUwOTAxO3BtPXBsYXk7dD1j',
    );
    expect(
      _payload(telegramReportLink(os: 'win', ov: '11', v: '50901', pm: 'msix', t: 'c')),
      'b3M9d2luO292PTExO3Y9NTA5MDE7cG09bXNpeDt0PWM',
    );
    expect(
      _payload(telegramReportLink(os: 'ubu', ov: '24.04', v: '50901', pm: 'deb', t: 'c')),
      'b3M9dWJ1O292PTI0LjA0O3Y9NTA5MDE7cG09ZGViO3Q9Yw',
    );
    expect(
      _payload(telegramReportLink(os: 'fed', ov: '41', v: '50901', pm: 'rpm', t: 'b', l: 'fa')),
      'b3M9ZmVkO292PTQxO3Y9NTA5MDE7cG09cnBtO3Q9YjtsPWZh',
    );
    expect(
      telegramReportLink(os: 'win', ov: '11', v: '50901', pm: 'msix', t: 'c').toString(),
      'https://t.me/hiddify_issues_bot?start=b3M9d2luO292PTExO3Y9NTA5MDE7cG09bXNpeDt0PWM',
    );
  });

  test('sends every field when it fits, within what Telegram takes', () {
    final link = telegramReportLink(os: 'android', ov: '16', v: '50901', pm: 'apk', t: 'c', l: 'fa', a: 'arm64');
    expect(_fields(link), {'os': 'android', 'ov': '16', 'v': '50901', 'pm': 'apk', 't': 'c', 'l': 'fa', 'a': 'arm64'});
    expect(_payload(link).length, lessThanOrEqualTo(64));
    expect(_payload(link), matches(RegExp(r'^[A-Za-z0-9_-]+$')));
  });

  test('leaves out the architecture, then the language, when it would not fit', () {
    final noArch = telegramReportLink(os: 'linux', ov: '6.8', v: '50901', pm: 'appimage', t: 'b', l: 'fa', a: 'x64');
    expect(_fields(noArch).keys, ['os', 'ov', 'v', 'pm', 't', 'l']);
    final neither = telegramReportLink(
      os: 'linux',
      ov: '6.8.12-300',
      v: '50901',
      pm: 'appimage',
      t: 'b',
      l: 'fa',
      a: 'x64',
    );
    expect(_fields(neither).keys, ['os', 'ov', 'v', 'pm', 't']);
    expect(_payload(neither).length, lessThanOrEqualTo(64));
  });

  test('a value cannot break the payload apart, and a missing one is left out', () {
    final link = telegramReportLink(os: 'linux', ov: '6.8;x=1', v: '50901', t: 'b');
    expect(_fields(link), {'os': 'linux', 'ov': '6.8x1', 'v': '50901', 't': 'b'});
  });

  test("Windows 11 is told from 10 by its build, as both say 10.0", () {
    expect(windowsVersion('"Windows 10 Pro" 10.0 (Build 22631)'), '11');
    expect(windowsVersion('"Windows 10 Pro" 10.0 (Build 19045)'), '10');
    expect(windowsVersion('something else'), '');
  });

  test('names the distro by its code and keeps its version', () {
    expect(linuxDistro('NAME="Ubuntu"\nID=ubuntu\nID_LIKE=debian\nVERSION_ID="24.04"\n'), ('ubu', '24.04'));
    expect(linuxDistro('ID=fedora\nVERSION_ID=41\n'), ('fed', '41'));
    expect(linuxDistro('ID="opensuse-tumbleweed"\nVERSION_ID="20261101"\n'), ('sus', '20261101'));
    expect(linuxDistro('ID=linuxmint\nVERSION_ID="22"\n'), ('mint', '22'));
    expect(linuxDistro('ID=debian\nVERSION_ID="13"\n'), ('deb', '13'));
    expect(linuxDistro('ID=arch\n'), ('arch', ''));
    expect(linuxDistro("ID='someos'\nVERSION_ID='3'\n"), ('linux', '3'));
  });
}
