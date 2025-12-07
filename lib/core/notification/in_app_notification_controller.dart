import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toastification/toastification.dart';

part 'in_app_notification_controller.g.dart';

@Riverpod(keepAlive: true)
InAppNotificationController inAppNotificationController(Ref ref) {
  return InAppNotificationController();
}

enum NotificationType { info, error, success }

class InAppNotificationController with AppLogger {
  ToastificationItem? showToast(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Desktop workaround: toastification overlays with hover/drag interactions
    // can trigger RenderViewport/MouseTracker hitTest crashes on Windows.
    // Use ScaffoldMessenger as a fallback.
    if (PlatformUtils.isDesktop) {
      final context = RootScaffold.stateKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            width: 400,
            backgroundColor: type == NotificationType.error ? Colors.red : null,
          ),
        );
      }
      return null;
    }

    return toastification.show(
      context: context,
      title: Text(message),
      type: type._toastificationType,
      alignment: Alignment.bottomLeft,
      autoCloseDuration: duration,
      style: ToastificationStyle.fillColored,
      pauseOnHover: true,
      showProgressBar: false,
      dragToClose: true,
      closeOnClick: true,
      closeButton: const ToastCloseButton(
        showType: CloseButtonShowType.onHover,
      ),
    );
  }

  ToastificationItem? showErrorToast(String message) {
    final context = RootScaffold.stateKey.currentContext;
    if (context == null) {
      loggy.warning("context is null");
      return null;
    }
    return showToast(
      context,
      message,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
    );
  }

  ToastificationItem? showSuccessToast(String message) {
    final context = RootScaffold.stateKey.currentContext;
    if (context == null) {
      loggy.warning("context is null");
      return null;
    }
    return showToast(context, message, type: NotificationType.success);
  }

  ToastificationItem? showInfoToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = RootScaffold.stateKey.currentContext;
    if (context == null) {
      loggy.warning("context is null");
      return null;
    }
    return showToast(context, message, duration: duration);
  }

  Future<void> showErrorDialog(PresentableError error) async {
    final context = RootScaffold.stateKey.currentContext;
    if (context == null) {
      loggy.warning("context is null");
      return;
    }
    CustomAlertDialog.fromErr(error).show(context);
  }

  void showActionToast(
    String message, {
    required String actionText,
    required VoidCallback callback,
    Duration duration = const Duration(seconds: 5),
  }) {
    final context = RootScaffold.stateKey.currentContext;
    if (context == null) return;

    // Desktop workaround: avoid interactive toast overlays entirely.
    if (PlatformUtils.isDesktop) {
      loggy.debug("skip action toast on desktop: $message");
      return;
    }
    toastification.dismissAll();

    toastification.showCustom(
      context: context,
      autoCloseDuration: duration,
      alignment: Alignment.bottomLeft,
      builder: (context, holder) {
        return GestureDetector(
          onTap: () => toastification.dismiss(holder),
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(message)),
                  const Gap(8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          toastification.dismiss(holder);
                          callback();
                        },
                        child: Text(actionText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension NotificationTypeX on NotificationType {
  ToastificationType get _toastificationType => switch (this) {
    NotificationType.success => ToastificationType.success,
    NotificationType.error => ToastificationType.error,
    NotificationType.info => ToastificationType.info,
  };
}
