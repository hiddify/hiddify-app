import 'package:flutter/widgets.dart';

/// The few labels the glass home needs, in Persian and English.
/// Kept separate from Hiddify's slang translations on purpose so the redesign
/// does not touch the generated translation files; fold them in later if wanted.
class OrcaStrings {
  const OrcaStrings._(this._fa);

  final bool _fa;

  factory OrcaStrings.of(BuildContext context) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode;
    return OrcaStrings._(code == 'fa');
  }

  String _p(String fa, String en) => _fa ? fa : en;

  String get readyToConnect => _p('آماده اتصال', 'Ready to connect');
  String get connecting => _p('در حال اتصال…', 'Connecting…');
  String get connected => _p('متصل', 'Connected');
  String get youAreConnected => _p('متصل هستید', 'You are connected');
  String get secureConnect => _p('اتصال امن', 'Secure connect');
  String get disconnect => _p('قطع اتصال', 'Disconnect');
  String get ping => _p('پینگ', 'Ping');
  String get status => _p('وضعیت', 'Status');
  String get selectedServer => _p('سرور انتخاب‌شده', 'Selected server');
  String get noServer => _p('هنوز سروری انتخاب نشده', 'No server selected yet');
  String get navHome => _p('خانه', 'Home');
  String get navServers => _p('سرورها', 'Servers');
  String get navStats => _p('آمار', 'Stats');
  String get navSettings => _p('تنظیمات', 'Settings');
  String get download => _p('دانلود', 'Download');
  String get upload => _p('آپلود', 'Upload');
  String get statsTitle => _p('آمار لحظه‌ای', 'Live stats');
  String get notConnected => _p('اتصالی برقرار نیست', 'Not connected');
}
