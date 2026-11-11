import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ships the texts of its own widgets (dialog buttons, date pickers, copy and paste, ...) for
/// a fixed list of languages. The app has languages outside it, such as Turkmen, and for those the
/// delegates say "not supported" and every Material widget fails to build. This asks the delegate for
/// the language and, when it is not there, gives it English instead, so only those few texts are English.
class _FallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _FallbackDelegate(this._inner);

  final LocalizationsDelegate<T> _inner;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => _inner.load(_inner.isSupported(locale) ? locale : const Locale('en'));

  @override
  bool shouldReload(_FallbackDelegate<T> old) => false;
}

const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  _FallbackDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
  _FallbackDelegate<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
  _FallbackDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
];
