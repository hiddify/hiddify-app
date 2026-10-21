import 'dart:async';
import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_notification_controller.g.dart';

/// The app's [ScaffoldMessenger], so a notification can be shown without a [BuildContext].
final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@Riverpod(keepAlive: true)
InAppNotificationController inAppNotificationController(Ref ref) {
  return InAppNotificationController();
}

enum NotificationType { info, error, success }

/// A button at the end of a toast, such as Undo. Pressing it also closes the toast.
typedef ToastAction = ({String label, VoidCallback onPressed});

class InAppNotificationController with AppLogger {
  void _show(String message, {NotificationType type = NotificationType.info, ToastAction? action}) {
    // Notifications raised during bootstrap (before runApp) have no messenger to show them yet.
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) {
      loggy.warning("failed to show notification, the app is not ready yet");
      return;
    }
    showAppSnackBar(messenger, message, type: type, action: action);
  }

  void showErrorToast(String message) => _show(message, type: NotificationType.error);

  void showSuccessToast(String message, {ToastAction? action}) =>
      _show(message, type: NotificationType.success, action: action);

  void showInfoToast(String message, {ToastAction? action}) => _show(message, action: action);
}

/// Shows [message] as the app's SnackBar, replacing the one on screen.
///
/// Its close timer starts only when it is first drawn, so one raised while the app draws no frames
/// (in the background) still shows, then closes. The pointer on it stops the timer; leaving starts
/// it again with the full time.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  NotificationType type = NotificationType.info,
  ToastAction? action,
}) {
  final side = math.max(16.0, (MediaQuery.sizeOf(messenger.context).width - 480) / 2);
  // 4 s, a Material 3 snackbar's time; 8 s with a button, to read it and reach the button
  final duration = Duration(seconds: action == null ? 4 : 8);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        // a close button on hover when there is no action
        content: HookBuilder(
          builder: (context) {
            final hovered = useState(false);
            useEffect(() {
              if (hovered.value) return null;
              final timer = Timer(duration, () => messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.timeout));
              return timer.cancel;
            }, [hovered.value]);
            return MouseRegion(
              onEnter: (_) => hovered.value = true,
              onExit: (_) => hovered.value = false,
              // a min height of 40: 36 here plus the SnackBar's 2 above and below
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Row(
                  children: [
                    Icon(type._icon, color: type._color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      // room above and below a text of several lines; one line still fits in 36
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          message,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    if (action == null)
                      // hidden, it keeps its room but can't be pressed or reached by a screen reader
                      Visibility(
                        visible: hovered.value,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: IconButton(
                          iconSize: 18,
                          // small enough to keep a one-line SnackBar at 40
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(),
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          onPressed: messenger.hideCurrentSnackBar,
                          icon: Icon(Icons.close, semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // a padding of its own replaces the SnackBar's 14 above and below the content
        padding: EdgeInsetsDirectional.fromSTEB(16, 2, action == null ? 8 : 4, 2),
        // at most 480 wide, 16 from the sides on a narrow screen. A margin instead of a width: SnackBar
        // takes only one of them. On a phone it clears the 80 high bottom bar by 12.
        margin: EdgeInsets.fromLTRB(side, 0, side, Breakpoint(messenger.context).isMobile() ? 92 : 16),
        action: action == null ? null : SnackBarAction(label: action.label, onPressed: action.onPressed),
        // the timer above closes it: SnackBar's own can't stop while the pointer is on it
        persist: true,
      ),
    );
}

/// Shows the app's SnackBars above every route, so a dialog or a bottom sheet can't cover them.
///
/// It is a Scaffold around the Navigator. The pages' Scaffolds sit inside it, and a
/// ScaffoldMessenger shows a SnackBar only on the outermost of its Scaffolds: this one.
class SnackBarHost extends StatelessWidget {
  const SnackBarHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // no top padding: on iOS a Scaffold puts a status bar tap target there, over the pages' own
    final hostMediaQuery = mediaQuery.removePadding(removeTop: true);
    return MediaQuery(
      // the keyboard as bottom padding: a floating SnackBar stays above both
      data: hostMediaQuery.copyWith(
        viewPadding: hostMediaQuery.viewPadding.copyWith(
          bottom: math.max(mediaQuery.viewPadding.bottom, mediaQuery.viewInsets.bottom),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // the pages keep their full height and handle the keyboard themselves
        resizeToAvoidBottomInset: false,
        // the pages get the app's MediaQuery as it was
        body: MediaQuery(data: mediaQuery, child: child),
      ),
    );
  }
}

extension NotificationTypeX on NotificationType {
  IconData get _icon => switch (this) {
    NotificationType.success => FluentIcons.checkmark_circle_24_regular,
    NotificationType.error => FluentIcons.dismiss_circle_24_regular,
    NotificationType.info => FluentIcons.info_24_regular,
  };

  Color get _color => switch (this) {
    NotificationType.success => const Color(0xFF32BC32),
    NotificationType.error => const Color(0xFFFF3A30),
    NotificationType.info => const Color(0xFF47AFFF),
  };
}
