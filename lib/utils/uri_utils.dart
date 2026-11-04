import 'dart:io';
import 'dart:ui';

import 'package:hiddify/utils/custom_loggers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class UriUtils {
  static final loggy = infraLogger('UriUtils');

  static Future<bool> tryShareOrLaunchFile(Uri uri, {Uri? fileOrDir}) {
    if (Platform.isWindows || Platform.isLinux) {
      return tryLaunch(fileOrDir ?? uri);
    }
    return tryShareFile(uri);
  }

  static Future<bool> tryLaunch(Uri uri) async {
    try {
      loggy.debug("launching [$uri]");
      if (!await canLaunchUrl(uri)) {
        loggy.warning("can't launch [$uri]");
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, stackTrace) {
      loggy.warning("error launching [$uri]", e, stackTrace);
      return false;
    }
  }

  static Future<bool> tryShareFile(Uri uri, {String? mimeType}) async {
    try {
      loggy.debug("sharing [$uri]");
      // the file's own path: uri.path keeps the percent-encoding, so a name with a space or a
      // non-ASCII letter pointed at a file that does not exist
      final path = uri.scheme.isEmpty || uri.isScheme('file') ? uri.toFilePath() : uri.path;
      final file = XFile(path, mimeType: mimeType);
      final result = await Share.shareXFiles([file], sharePositionOrigin: _shareOrigin());
      loggy.debug("share result: ${result.raw}");
      return result.status == ShareResultStatus.success;
    } catch (e, stackTrace) {
      // the error is in the message: the logs page shows only the message
      loggy.warning("error sharing file [$uri]: $e", e, stackTrace);
      return false;
    }
  }

  /// Where the share sheet is anchored: the middle of the screen. iOS refuses to present the
  /// sheet without an anchor inside the view when it presents it as a popover (iPad, and
  /// iPhone on recent iOS), and the sheet is not opened from a widget here.
  static Rect? _shareOrigin() {
    if (!Platform.isIOS && !Platform.isMacOS) return null;
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return null;
    final size = view.physicalSize / view.devicePixelRatio;
    return Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 2, height: 2);
  }
}
