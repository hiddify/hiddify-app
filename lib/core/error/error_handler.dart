import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/log_bus.dart';
import 'package:hiddify/core/logger/logger.dart';

class ErrorHandler {
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    Logger.ui.error(
      'Flutter Error: $message',
      details.exception,
      details.stack,
    );
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  static void _handlePlatformError(Object error, StackTrace stack) {
    Logger.system.error('Platform Error: $error', error, stack);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: Text(title ?? 'Error'),
          content: SingleChildScrollView(child: SelectableText(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String formatErrorMessage(Object error) {
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    if (msg.startsWith('UnsupportedError: ')) {
      return msg.substring(18);
    }
    if (msg.startsWith('FormatException: ')) {
      return msg.substring(17);
    }

    return msg;
  }

  static bool isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('host lookup') ||
        msg.contains('timeout');
  }

  static bool isAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('unauthorized') ||
        msg.contains('authentication') ||
        msg.contains('401') ||
        msg.contains('403');
  }

  static String getUserFriendlyMessage(Object error) {
    if (isNetworkError(error)) {
      return 'Network error. Please check your internet connection.';
    }
    if (isAuthError(error)) {
      return 'Authentication failed. Please check your credentials.';
    }
    return formatErrorMessage(error);
  }

  static ConnectionErrorPresentation presentConnectionError({
    required TranslationsEn t,
    required String rawError,
    String? coreMode,
  }) {
    final isFa = t.$meta.locale == AppLocale.fa;
    String l10n(String en, String fa) => isFa ? fa : en;

    final raw = rawError.trim();
    final safeRaw = LogBus.redact(raw);
    final lower = raw.toLowerCase();

    var title = t.failure.unexpected;
    var message = formatErrorMessage(raw);
    final hints = <String>[];

    final isTunError = lower.startsWith('tun:') || lower.contains('tun2socks');
    final isHysteriaError =
        lower.startsWith('hysteria:') || lower.contains('hysteria');
    final isDownloadError =
        lower.contains('download') || lower.contains('statuscode');

    final isAdminError =
        lower.contains('administrator') ||
        lower.contains('access is denied') ||
        lower.contains('permission denied') ||
        lower.contains('missing privilege');

    if (isAdminError) {
      title = t.failure.singbox.missingPrivilege;
      message = t.failure.singbox.missingPrivilegeMsg;
      hints.addAll([
        l10n(
          'Restart the app as Administrator.',
          'برنامه را با دسترسی Administrator اجرا کنید.',
        ),
        l10n(
          'Or switch Core Mode to Proxy.',
          'یا Core Mode را روی Proxy قرار دهید.',
        ),
      ]);
    } else if (lower.contains('tun only supported on windows') ||
        (lower.contains('tun') &&
            lower.contains('only supported') &&
            !Platform.isWindows)) {
      title = l10n('VPN mode is not supported', 'حالت VPN پشتیبانی نمی‌شود');
      message = l10n(
        'VPN mode is only available on Windows in this build.',
        'در این نسخه، حالت VPN فقط روی ویندوز در دسترس است.',
      );
      hints.add(
        l10n('Switch Core Mode to Proxy.', 'Core Mode را روی Proxy بگذارید.'),
      );
    } else if (lower.contains('tun assets') ||
        lower.contains('assets not found') ||
        lower.contains('wintun') ||
        lower.contains('tun2socks.exe not found')) {
      title = l10n('Missing VPN components', 'فایل‌های VPN موجود نیست');
      message = l10n(
        'VPN mode needs extra components (wintun.dll + tun2socks.exe).',
        'حالت VPN نیاز به فایل‌های اضافی (wintun.dll و tun2socks.exe) دارد.',
      );
      hints.addAll([
        l10n(
          'Download TUN assets from Settings.',
          'از تنظیمات، فایل‌های TUN را دانلود کنید.',
        ),
        l10n(
          'If download is blocked (Iran), try a different network/DNS or manual install.',
          'اگر دانلود در ایران مسدود است، شبکه/DNS را تغییر دهید یا دستی نصب کنید.',
        ),
      ]);
    } else if (isDownloadError && (isTunError || isHysteriaError)) {
      title = l10n('Download failed', 'دانلود ناموفق');
      message = l10n(
        'Failed to download required components. This can be blocked by network/firewall.',
        'دانلود فایل‌های مورد نیاز انجام نشد. ممکن است توسط شبکه/فایروال مسدود شده باشد.',
      );
      hints.addAll([
        l10n(
          'Try another network (mobile hotspot).',
          'با یک اینترنت دیگر (مثلاً هات‌اسپات) امتحان کنید.',
        ),
        l10n(
          'Change DNS to DoH in settings.',
          'DNS را روی DoH در تنظیمات قرار دهید.',
        ),
      ]);
    } else if (lower.contains('sha256 mismatch') ||
        lower.contains('hash mismatch') ||
        lower.contains('mismatch')) {
      title = l10n('File verification failed', 'اعتبارسنجی فایل ناموفق');
      message = l10n(
        'Downloaded file verification failed (hash mismatch).',
        'اعتبارسنجی فایل دانلودشده ناموفق بود (عدم تطابق هش).',
      );
      hints.addAll([
        l10n(
          'Retry download on a stable network.',
          'دانلود را روی یک شبکه پایدار دوباره انجام دهید.',
        ),
        l10n(
          'Disable antivirus for the download folder and retry.',
          'در صورت نیاز آنتی‌ویروس را موقتاً برای پوشه دانلود غیرفعال کنید.',
        ),
      ]);
    } else if (lower.contains('address already in use') ||
        lower.contains('only one usage of each socket') ||
        (lower.contains('bind') && lower.contains('in use'))) {
      title = l10n('Port is already in use', 'پورت در حال استفاده است');
      message = l10n(
        'A required port (SOCKS/HTTP) is already used by another app.',
        'یکی از پورت‌های مورد نیاز (SOCKS/HTTP) توسط برنامه دیگری در حال استفاده است.',
      );
      hints.addAll([
        l10n(
          'Change SOCKS/HTTP ports in Settings.',
          'پورت‌های SOCKS/HTTP را در تنظیمات تغییر دهید.',
        ),
        l10n(
          'Close other proxy/VPN apps and retry.',
          'برنامه‌های پروکسی/VPN دیگر را ببندید و دوباره امتحان کنید.',
        ),
      ]);
    } else if (lower.contains('x509') ||
        lower.contains('certificate') ||
        lower.contains('bad certificate') ||
        lower.contains('cert_verify_failed') ||
        lower.contains('certificate_verify_failed')) {
      title = t.failure.connection.badCertificate;
      message = l10n(
        'TLS certificate verification failed.',
        'اعتبارسنجی گواهی TLS ناموفق بود.',
      );
      hints.addAll([
        l10n(
          'Check your device date/time.',
          'تاریخ/ساعت دستگاه را بررسی کنید.',
        ),
        l10n(
          'Enable "Allow Insecure" (if you trust the server).',
          'در صورت اطمینان، گزینه Allow Insecure را فعال کنید.',
        ),
      ]);
    } else if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded') ||
        lower.contains('context deadline exceeded')) {
      title = t.failure.connection.timeout;
      message = l10n(
        'Connection timed out. The server may be blocked or the network is unstable.',
        'اتصال تایم‌اوت شد. ممکن است سرور مسدود باشد یا شبکه ناپایدار است.',
      );
      hints.addAll([
        l10n(
          'Try another network or another server.',
          'با اینترنت دیگر یا سرور دیگر امتحان کنید.',
        ),
        l10n(
          'Change DNS (DoH) and try again.',
          'DNS را (DoH) تغییر دهید و دوباره امتحان کنید.',
        ),
      ]);
    } else if (lower.contains('host lookup') ||
        lower.contains('no such host') ||
        (lower.contains('dns') && lower.contains('fail'))) {
      title = t.failure.connection.connectionError;
      message = l10n(
        'DNS resolution failed.',
        'حل نام دامنه (DNS) ناموفق بود.',
      );
      hints.addAll([
        l10n(
          'Set DNS to DoH in settings.',
          'DNS را در تنظیمات روی DoH قرار دهید.',
        ),
        l10n(
          'Try a different ISP / mobile data.',
          'با اینترنت/اپراتور دیگر امتحان کنید.',
        ),
      ]);
    } else if (lower.contains('invalid config') ||
        lower.contains('invalid configuration') ||
        lower.contains('format exception') ||
        lower.contains('unknown field') ||
        lower.contains('unexpected character') ||
        lower.contains('json')) {
      title = t.failure.singbox.invalidConfig;
      message = l10n(
        'The configuration looks invalid.',
        'به نظر می‌رسد کانفیگ نامعتبر است.',
      );
      hints.addAll([
        l10n(
          'Re-import/update the subscription.',
          'اشتراک را دوباره اضافه/آپدیت کنید.',
        ),
        l10n(
          'Open Core Configuration viewer for details.',
          'برای جزئیات، Core Configuration را مشاهده کنید.',
        ),
      ]);
    } else if (lower.contains('wireguard') ||
        lower.contains('uapi') ||
        lower.contains('device key')) {
      title = l10n('WireGuard Config Error', 'خطای کانفیگ WireGuard');

      if (lower.contains('endpoint')) {
        message = l10n(
          'WireGuard endpoint is invalid or missing.',
          'endpoint کانفیگ WireGuard نامعتبر یا ناقص است.',
        );
        hints.addAll([
          l10n(
            'Check that server address:port is correct.',
            'آدرس و پورت سرور را بررسی کنید.',
          ),
          l10n(
            'Re-import the config or try another WireGuard config.',
            'کانفیگ را دوباره وارد کنید یا یک کانفیگ WireGuard دیگر امتحان کنید.',
          ),
        ]);
      } else if (lower.contains('public') ||
          lower.contains('private') ||
          lower.contains('key')) {
        message = l10n(
          'WireGuard keys are invalid or missing.',
          'کلیدهای WireGuard نامعتبر یا ناقص هستند.',
        );
        hints.addAll([
          l10n(
            'Ensure publicKey and privateKey are provided.',
            'از وجود publicKey و privateKey اطمینان حاصل کنید.',
          ),
          l10n(
            'Keys should be valid Base64 strings.',
            'کلیدها باید رشته‌های Base64 معتبر باشند.',
          ),
        ]);
      } else {
        message = l10n(
          'WireGuard configuration is invalid.',
          'کانفیگ WireGuard نامعتبر است.',
        );
        hints.addAll([
          l10n(
            'Check config format: wg://privateKey@server:port?publicKey=xxx',
            'فرمت کانفیگ را بررسی کنید: wg://privateKey@server:port?publicKey=xxx',
          ),
          l10n(
            'Try another WireGuard config.',
            'یک کانفیگ WireGuard دیگر امتحان کنید.',
          ),
        ]);
      }
    } else if (lower.contains('core') &&
        (lower.contains('failed') || lower.contains('error'))) {
      title = t.failure.connectivity.core;
      message = l10n('Core failed to start.', 'هسته اجرا نشد.');
      hints.addAll([
        l10n(
          'Check logs for the exact reason.',
          'برای علت دقیق، لاگ‌ها را بررسی کنید.',
        ),
        l10n(
          'Try switching transport/protocol.',
          'نوع اتصال/پروتکل را تغییر دهید.',
        ),
      ]);
    }

    final mode = coreMode?.toLowerCase();
    if (mode == 'vpn' &&
        hints.every((h) => !h.toLowerCase().contains('proxy'))) {
      hints.add(
        l10n(
          'As a workaround, switch Core Mode to Proxy.',
          'به عنوان راه‌حل موقت، Core Mode را روی Proxy بگذارید.',
        ),
      );
    }

    if (hints.isEmpty) {
      hints.add(
        l10n(
          'Open Logs for more details.',
          'برای جزئیات بیشتر لاگ‌ها را باز کنید.',
        ),
      );
    }

    return (title: title, message: message, hints: hints, technical: safeRaw);
  }

  static String toSnackBarMessage(
    ConnectionErrorPresentation p,
    TranslationsEn t,
  ) {
    final isFa = t.$meta.locale == AppLocale.fa;
    final tipLabel = isFa ? 'راهکار: ' : 'Tip: ';
    final firstHint = p.hints.isEmpty ? '' : '\n$tipLabel${p.hints.first}';
    return '${p.title}\n${p.message}$firstHint';
  }
}

typedef ConnectionErrorPresentation = ({
  String title,
  String message,
  List<String> hints,
  String technical,
});

extension SafeAsync<T> on Future<T> {
  Future<T?> safeExecute({
    void Function(T result)? onSuccess,
    void Function(Object error)? onError,
    void Function()? onComplete,
  }) async {
    try {
      final result = await this;
      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      Logger.system.error('SafeExecute error: $e', e, stack);
      onError?.call(e);
      return null;
    } finally {
      onComplete?.call();
    }
  }
}
