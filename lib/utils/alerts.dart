import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/notification/toast_hover_pause.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';
import 'package:toastification/toastification.dart';

enum AlertType {
  info,
  error,
  success;

  ToastificationType get _toastificationType => switch (this) {
    success => ToastificationType.success,
    error => ToastificationType.error,
    info => ToastificationType.info,
  };

  /// The little cat at the start of the toast.
  CatMood get _catMood => switch (this) {
    success => CatMood.purring,
    error => CatMood.hissing,
    info => CatMood.curious,
  };
}

class CustomToast extends StatelessWidget {
  const CustomToast(this.message, {this.type = AlertType.info, this.icon});

  const CustomToast.error(this.message) : type = AlertType.error, icon = FluentIcons.error_circle_24_regular;

  const CustomToast.success(this.message) : type = AlertType.success, icon = FluentIcons.checkmark_24_regular;

  final String message;
  final AlertType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (type) {
      AlertType.info => null,
      AlertType.error => scheme.error,
      AlertType.success => scheme.tertiary,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color), const SizedBox(width: 8)],
          Flexible(child: Text(message)),
        ],
      ),
    );
  }

  void show(BuildContext context) {
    late final ToastificationItem item;
    item = toastification.show(
      context: context,
      title: ToastHoverPause(item: () => item, child: Text(message)),
      type: type._toastificationType,
      icon: CatFace(mood: type._catMood, size: 32),
      alignment: AlignmentDirectional.bottomStart,
      // a Material 3 snackbar's time
      autoCloseDuration: const Duration(seconds: 4),
      style: ToastificationStyle.flat,
      // see ToastHoverPause
      pauseOnHover: false,
      showProgressBar: false,
      dragToClose: true,
      closeOnClick: true,
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.onHover),
    );
  }
}
