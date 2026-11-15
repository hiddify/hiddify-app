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

  /// Android and iOS open [uri] without asking first: Android answers "can launch" only for apps
  /// in the manifest's queries, so a browser, Telegram or a mail app looked absent and nothing
  /// opened; iOS answers it only for schemes in Info.plist (`mailto` is not). Opening just fails
  /// when no app takes it. Desktops check first, as in [tryLaunchAppOrWeb].
  static Future<bool> tryLaunch(Uri uri) async {
    try {
      loggy.debug("launching [$uri]");
      if (!Platform.isAndroid && !Platform.isIOS && !await canLaunchUrl(uri)) {
        loggy.warning("can't launch [$uri]");
        return false;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) loggy.warning("no app opened [$uri]");
      return launched;
    } catch (e, stackTrace) {
      loggy.warning("error launching [$uri]", e, stackTrace);
      return false;
    }
  }

  /// Opens [appUri] (such as `tg://`) in its app, and [webUri] when no app takes it.
  /// Android and iOS are asked to open the app link directly: iOS answers "can launch" only
  /// for schemes listed in Info.plist, and Android only for apps in the manifest's queries,
  /// while opening it just fails when no app is there. Desktops check first: Windows opens
  /// a "find an app" prompt for a scheme nothing handles instead of failing.
  static Future<bool> tryLaunchAppOrWeb(Uri appUri, Uri webUri) async {
    try {
      if (Platform.isAndroid || Platform.isIOS || await canLaunchUrl(appUri)) {
        loggy.debug("launching [$appUri]");
        if (await launchUrl(appUri, mode: LaunchMode.externalNonBrowserApplication)) return true;
      }
    } catch (e, stackTrace) {
      loggy.debug("no app for [$appUri], opening [$webUri]", e, stackTrace);
    }
    return tryLaunch(webUri);
  }

  /// [subject] and [text] go with the file to the app the user picks: a mail app makes them
  /// the message's subject and body.
  static Future<bool> tryShareFile(Uri uri, {String? mimeType, String? subject, String? text}) async {
    try {
      loggy.debug("sharing [$uri]");
      // the file's own path: uri.path keeps the percent-encoding, so a name with a space or a
      // non-ASCII letter pointed at a file that does not exist
      final path = uri.scheme.isEmpty || uri.isScheme('file') ? uri.toFilePath() : uri.path;
      final file = XFile(path, mimeType: mimeType);
      final result = await Share.shareXFiles([file], subject: subject, text: text, sharePositionOrigin: _shareOrigin());
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
