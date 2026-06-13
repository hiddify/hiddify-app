import 'package:flutter/material.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toastification/toastification.dart';

part 'in_app_notification_controller.g.dart';

@Riverpod(keepAlive: true)
InAppNotificationController inAppNotificationController(Ref ref) {
  return InAppNotificationController();
}

enum NotificationType { info, error, success }

class InAppNotificationController with AppLogger {
  ToastificationItem? _show(
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Notifications raised during bootstrap (before runApp) have no overlay to
    // attach to, and toastification throws when it cannot find one. Swallow
    // that so a notification can never abort startup or crash the app.
    try {
      toastification.dismissAll();
      return toastification.show(
        title: Text(message),
        type: type._toastificationType,
        alignment: AlignmentDirectional.bottomCenter,
        margin: const EdgeInsets.only(bottom: 64 + 16, right: 16, left: 16),
        autoCloseDuration: duration,
        style: ToastificationStyle.fillColored,
        pauseOnHover: true,
        showProgressBar: false,
        dragToClose: true,
        closeOnClick: true,
        closeButtonShowType: CloseButtonShowType.onHover,
      );
    } catch (e, stackTrace) {
      loggy.warning("failed to show notification, overlay may not be ready", e, stackTrace);
      return null;
    }
  }

  ToastificationItem? showErrorToast(String message) =>
      _show(message, type: NotificationType.error, duration: const Duration(seconds: 5));

  ToastificationItem? showSuccessToast(String message) => _show(message, type: NotificationType.success);

  ToastificationItem? showInfoToast(String message, {Duration duration = const Duration(seconds: 3)}) =>
      _show(message, duration: duration);
}

extension NotificationTypeX on NotificationType {
  ToastificationType get _toastificationType => switch (this) {
    NotificationType.success => ToastificationType.success,
    NotificationType.error => ToastificationType.error,
    NotificationType.info => ToastificationType.info,
  };
}
