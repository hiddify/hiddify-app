import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:hiddify/core/router/deep_linking/url_protocol/protocol.dart';
import 'package:win32/win32.dart';

const _hive = HKEY_CURRENT_USER;

class WindowsProtocolHandler extends ProtocolHandler {
  @override
  void register(String scheme, {String? executable, List<String>? arguments}) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    final prefix = _regPrefix(scheme);
    final capitalized = scheme[0].toUpperCase() + scheme.substring(1);
    final args = getArguments(arguments).map((a) => _sanitize(a));
    final cmd = '${executable ?? Platform.resolvedExecutable} ${args.join(' ')}';

    _regCreateStringKey(_hive, prefix, '', 'URL:$capitalized');
    _regCreateStringKey(_hive, prefix, 'URL Protocol', '');
    _regCreateStringKey(_hive, '$prefix\\shell\\open\\command', '', cmd);
  }

  @override
  void unregister(String scheme) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    final txtKey = TEXT(_regPrefix(scheme));
    try {
      RegDeleteTree(HKEY_CURRENT_USER, txtKey);
    } finally {
      free(txtKey);
    }
  }

  String _regPrefix(String scheme) => 'SOFTWARE\\Classes\\$scheme';

  int _regCreateStringKey(int hKey, String key, String valueName, String data) {
    final txtKey = TEXT(key);
    final txtValue = TEXT(valueName);
    final txtData = TEXT(data);
    try {
      return RegSetKeyValue(hKey, txtKey, txtValue, REG_SZ, txtData, txtData.length * 2 + 2);
    } finally {
      free(txtKey);
      free(txtValue);
      free(txtData);
    }
  }

  String _sanitize(String value) {
    value = value.replaceAll(r'%s', '%1').replaceAll(r'"', '\\"');
    return '"$value"';
  }
}
