import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hiddify/core/model/app_config.dart';
import 'package:hiddify/features/auth/widgets/telegram_login_webview_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A thin WebView that hosts a minimal in-app HTML page which drives the
/// Telegram Login JS SDK and streams the resulting `{ id_token, user, error }`
/// back to Dart via a `JavascriptChannel`.
///
/// Deliberately does NOT load the Bedolaga React cabinet; only a local data:
/// URL is used so no third-party UI is shown.
class TelegramLoginWebView extends StatefulWidget {
  const TelegramLoginWebView({super.key, required this.onResult, required this.onError});

  /// Called with the extracted `id_token` when Telegram login succeeds.
  final void Function(String idToken) onResult;

  /// Called with a user-friendly message when the Telegram login fails
  /// (e.g. the user closed the popup or an error was returned).
  final void Function(String message) onError;

  @override
  State<TelegramLoginWebView> createState() => _TelegramLoginWebViewState();
}

class _TelegramLoginWebViewState extends State<TelegramLoginWebView> {
  late final WebViewController _controller;
  bool _resultReported = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TelegramAuth',
        onMessageReceived: _onMessage,
      )
      ..loadRequest(Uri.dataFromString(
        telegramLoginHtml(clientId: AppConfig.telegramOidcClientId),
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ));
  }

  void _onMessage(JavaScriptMessage message) {
    if (_resultReported) return;
    final data = _tryDecode(message.message);
    if (data == null) {
      _reportError('invalid_response');
      return;
    }
    final idToken = data['id_token'];
    final error = data['error'];
    if (idToken is String && idToken.isNotEmpty) {
      _resultReported = true;
      widget.onResult(idToken);
    } else if (error != null) {
      _reportError('telegram_login_error');
    } else {
      _reportError('invalid_response');
    }
  }

  void _reportError(String key) {
    if (_resultReported) return;
    _resultReported = true;
    widget.onError(key);
  }

  Map<String, dynamic>? _tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}