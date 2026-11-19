import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show Bidi;

class CustomAlertDialog extends HookConsumerWidget {
  const CustomAlertDialog({super.key, this.title, required this.message});

  final String? title;
  final String message;

  factory CustomAlertDialog.fromErr(({String type, String? message}) err) =>
      CustomAlertDialog(title: err.message == null ? null : err.type, message: err.message ?? err.type);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: SingleChildScrollView(
        child: SizedBox(
          width: 468,
          // left to right for technical text; a message that starts in Persian or Arabic is a hint to
          // read, right to left
          child: SelectableText(
            message,
            textDirection: Bidi.startsWithRtl(message) ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ),
      actions: [
        // the title and the message together, so a report carries both
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: title == null ? message : '$title\n\n$message'));
            ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(t.common.addToClipboard),
        ),
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: Text(t.common.ok),
        ),
      ],
    );
  }
}
