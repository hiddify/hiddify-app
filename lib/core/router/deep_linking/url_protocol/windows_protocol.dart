import 'dart:ffi';
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

    final exe = executable ?? Platform.resolvedExecutable;
    // A handler pointing into the temp folder breaks once it is cleaned, and AV heuristics flag it as persistence
    if (_isInTempDir(exe)) return;

    final prefix = _regPrefix(scheme);
    final capitalized = scheme[0].toUpperCase() + scheme.substring(1);
    final args = getArguments(arguments).map((a) => _sanitize(a));
    final cmd = '$exe ${args.join(' ')}';

    if (_regGetString(_hive, '$prefix\\shell\\open\\command', '') == cmd) return;

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

  String? _regGetString(int hKey, String key, String valueName) {
    final txtKey = TEXT(key);
    final txtValue = TEXT(valueName);
    final size = calloc<Uint32>();
    try {
      if (RegGetValue(hKey, txtKey, txtValue, RRF_RT_REG_SZ, nullptr, nullptr, size) != ERROR_SUCCESS) return null;
      final data = calloc<Uint8>(size.value);
      try {
        if (RegGetValue(hKey, txtKey, txtValue, RRF_RT_REG_SZ, nullptr, data, size) != ERROR_SUCCESS) return null;
        return data.cast<Utf16>().toDartString();
      } finally {
        free(data);
      }
    } finally {
      free(txtKey);
      free(txtValue);
      free(size);
    }
  }

  bool _isInTempDir(String path) {
    final exe = path.toLowerCase();
    final env = Platform.environment;
    final temps = [Directory.systemTemp.path, env['TEMP'], env['TMP']]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .map((p) => '${p.toLowerCase().replaceAll(RegExp(r'[\\/]+$'), '')}\\');
    return temps.any(exe.startsWith) || exe.contains(r'\appdata\local\temp\');
  }

  String _sanitize(String value) {
    final sanitized = value.replaceAll('%s', '%1').replaceAll('"', '\\"');
    return '"$sanitized"';
  }
}
