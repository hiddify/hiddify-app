import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/crash_report/data/diagnostics_exporter.dart';
import 'package:hiddify/features/crash_report/data/diagnostics_sender.dart';
import 'package:hiddify/features/crash_report/notifier/crash_report_notifier.dart';
import 'package:hiddify/features/log/overview/logs_modals.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('CrashReportDialog');

/// How a report reaches the developers.
enum ReportChannel {
  /// uploaded by the app, to Sentry
  hiddify,

  /// by the user's mail app, to [Constants.bugReportEmail]
  email,

  /// by the user's Telegram, to [Constants.bugReportTelegramUrl]
  telegram,
}

/// Shown on the first run after a crash: send the diagnostics zip one of three ways, or not
/// now. Either way it is not shown again for the same crash.
class CrashReportDialog extends HookConsumerWidget {
  const CrashReportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final crash = ref.read(crashReportNotifierProvider);

    Widget option(ReportChannel channel, IconData icon, String title, String subtitle) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () async {
        context.pop();
        await sendDiagnostics(ref, channel, crashName: crash?.name);
      },
    );

    return AlertDialog(
      icon: const Icon(Icons.bug_report_outlined),
      title: Text(t.dialogs.crashReport.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.dialogs.crashReport.msg),
              const SizedBox(height: 8),
              if (DiagnosticsSender.available)
                option(
                  ReportChannel.hiddify,
                  FluentIcons.cloud_arrow_up_20_regular,
                  t.dialogs.crashReport.sendHiddify,
                  t.dialogs.crashReport.sendHiddifyMsg,
                ),
              option(
                ReportChannel.email,
                FluentIcons.mail_20_regular,
                t.dialogs.crashReport.sendEmail,
                Constants.bugReportEmail,
              ),
              option(
                ReportChannel.telegram,
                FluentIcons.send_20_regular,
                t.dialogs.crashReport.sendTelegram,
                Constants.bugReportTelegramUrl.replaceFirst('https://', ''),
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => context.pop(), child: Text(t.common.later))],
    );
  }
}

/// Builds the diagnostics zip and hands it to the share sheet, or to a save dialog on desktop.
Future<void> shareDiagnostics(WidgetRef ref) async {
  final t = ref.read(translationsProvider).requireValue;
  final notifications = ref.read(inAppNotificationControllerProvider);
  try {
    final file = await ref.read(diagnosticsExporterProvider).export();
    await saveFileAs(file, t: t, notifications: notifications);
  } catch (e, stack) {
    _log.error('exporting the diagnostics failed: $e', e, stack);
    notifications.showErrorToast(t.pages.logs.fileSaveFailed);
  }
}

/// Builds the diagnostics zip and sends it by [channel].
///
/// Only the upload to Hiddify needs nothing more from the user. Neither a mailto: link nor a
/// Telegram link can carry a file, so for those two the user attaches it: a phone opens the
/// share sheet with the destination in the text (and the mail address in the clipboard, for the
/// recipient field); a desktop saves the zip, then opens the mail app or the Telegram group.
Future<void> sendDiagnostics(WidgetRef ref, ReportChannel channel, {String? crashName}) async {
  final t = ref.read(translationsProvider).requireValue;
  final notifications = ref.read(inAppNotificationControllerProvider);
  final File file;
  try {
    file = await ref.read(diagnosticsExporterProvider).export();
  } catch (e, stack) {
    _log.error('exporting the diagnostics failed: $e', e, stack);
    notifications.showErrorToast(t.pages.logs.fileSaveFailed);
    return;
  }

  if (channel == ReportChannel.hiddify) {
    final sent = await ref.read(diagnosticsSenderProvider).send(file, crashName: crashName);
    if (sent) {
      notifications.showSuccessToast(t.dialogs.crashReport.sent);
    } else {
      notifications.showErrorToast(t.dialogs.crashReport.sendFailed);
    }
    return;
  }

  final subject = t.dialogs.crashReport.subject;
  final destination = channel == ReportChannel.email ? Constants.bugReportEmail : Constants.bugReportTelegramUrl;

  if (!PlatformUtils.isDesktop) {
    if (channel == ReportChannel.email) {
      await Clipboard.setData(const ClipboardData(text: Constants.bugReportEmail));
      notifications.showInfoToast(t.dialogs.crashReport.addressCopied(address: Constants.bugReportEmail));
    }
    await UriUtils.tryShareFile(
      Uri.file(file.path),
      mimeType: 'application/zip',
      subject: subject,
      text: t.dialogs.crashReport.shareText(to: destination),
    );
    return;
  }

  await saveFileAs(file, t: t, notifications: notifications);
  final attach = t.dialogs.crashReport.attachHint(file: file.uri.pathSegments.last);
  await UriUtils.tryLaunch(
    channel == ReportChannel.email
        ? Uri(
            scheme: 'mailto',
            path: Constants.bugReportEmail,
            query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(attach)}',
          )
        : Uri.parse(Constants.bugReportTelegramUrl),
  );
  notifications.showInfoToast(attach);
}
