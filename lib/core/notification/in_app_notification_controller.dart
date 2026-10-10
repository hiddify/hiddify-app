import 'package:flutter/material.dart';
import 'package:hiddify/core/notification/toast_hover_pause.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';
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

/// A button at the end of a toast, such as Undo. Pressing it also closes the toast.
typedef ToastAction = ({String label, VoidCallback onPressed});

class InAppNotificationController with AppLogger {
  ToastificationItem? _show(String message, {NotificationType type = NotificationType.info, ToastAction? action}) {
    // Notifications raised during bootstrap (before runApp) have no overlay to
    // attach to, and toastification throws when it cannot find one. Swallow
    // that so a notification can never abort startup or crash the app.
    try {
      toastification.dismissAll();
      final text = Text(message, maxLines: 6, softWrap: true, overflow: TextOverflow.ellipsis);
      late final ToastificationItem item;
      return item = toastification.show(
        title: ToastHoverPause(
          item: () => item,
          child: action == null
              ? text
              : Row(
                  children: [
                    Expanded(child: text),
                    // in the color of the toast's icon
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: type._toastificationType.color),
                      onPressed: () {
                        toastification.dismiss(item);
                        action.onPressed();
                      },
                      child: Text(action.label),
                    ),
                  ],
                ),
        ),
        // the button's own padding stands in for the toast's at the end
        padding: action == null ? null : const EdgeInsetsDirectional.fromSTEB(20, 16, 4, 16),
        type: type._toastificationType,
        icon: CatFace(mood: type._catMood, size: 32),
        alignment: AlignmentDirectional.bottomCenter,
        margin: const EdgeInsets.only(bottom: 64 + 16, right: 16, left: 16),
        // 4 s, a Material 3 snackbar's time; 8 s with a button, to read it and reach the button
        autoCloseDuration: action == null ? const Duration(seconds: 4) : const Duration(seconds: 8),
        style: ToastificationStyle.flat,
        // see ToastHoverPause
        pauseOnHover: false,
        showProgressBar: false,
        dragToClose: true,
        closeOnClick: true,
        // a hidden close button takes no room, so an action reaches the end of the toast
        closeButton: ToastCloseButton(
          showType: action == null ? CloseButtonShowType.onHover : CloseButtonShowType.none,
        ),
      );
    } catch (e, stackTrace) {
      loggy.warning("failed to show notification, overlay may not be ready", e, stackTrace);
      return null;
    }
  }

  ToastificationItem? showErrorToast(String message) => _show(message, type: NotificationType.error);

  ToastificationItem? showSuccessToast(String message, {ToastAction? action}) =>
      _show(message, type: NotificationType.success, action: action);

  ToastificationItem? showInfoToast(String message, {ToastAction? action}) => _show(message, action: action);
}

extension NotificationTypeX on NotificationType {
  ToastificationType get _toastificationType => switch (this) {
    NotificationType.success => ToastificationType.success,
    NotificationType.error => ToastificationType.error,
    NotificationType.info => ToastificationType.info,
  };

  /// The little cat at the start of the toast.
  CatMood get _catMood => switch (this) {
    NotificationType.success => CatMood.purring,
    NotificationType.error => CatMood.hissing,
    NotificationType.info => CatMood.curious,
  };
}
