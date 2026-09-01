import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger_setup.dart';
import 'package:hiddify/core/logger/ring/log_ring.dart';
import 'package:hiddify/core/logger/sinks/file_sink.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/log/data/log_path_resolver.dart';
import 'package:hiddify/features/log/overview/logs_overview_notifier.dart';
import 'package:hiddify/features/log/overview/logs_page.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

/// These are top level functions, so there is no instance for a mixin to take
/// a name from — the factory is how the project names a logger without building
/// one directly.
final _log = appLogger('LogsShare');

/// Step one: what to share at all.
///
/// The in-memory history is offered everywhere and can be filtered. A file is
/// listed only when it exists and has something in it — the app keeps one on
/// desktop only, and the core writes its own two beside it.
class LogsShareModal extends ConsumerWidget {
  const LogsShareModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final paths = ref.watch(logPathResolverProvider);
    final notifications = ref.watch(inAppNotificationControllerProvider);

    final crash = paths.coreCrashFile();

    final files = <(String, String, File)>[
      if (PlatformUtils.isDesktop)
        (t.pages.logs.errorLog, t.pages.logs.errorLogMsg, paths.appFile()),
      (t.pages.logs.coreLog, t.pages.logs.coreLogMsg, paths.coreFile()),
      // Absent until the core actually crashes, which is the point of it.
      if (crash != null)
        (t.pages.logs.coreCrash, t.pages.logs.coreCrashMsg, crash),
    ].where(_worthOffering).toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(FluentIcons.history_20_regular),
            title: Text(t.pages.logs.recentLogs),
            subtitle: Text(t.pages.logs.recentLogsMsg),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(bottomSheetsNotifierProvider.notifier).showLogsRecent();
            },
          ),
          for (final (title, subtitle, file) in files)
            ListTile(
              leading: const Icon(FluentIcons.document_20_regular),
              title: Text(title),
              subtitle: Text(subtitle),
              onTap: () async {
                Navigator.of(context).pop();
                await _saveFileAs(file, t: t, notifications: notifications);
              },
            ),
        ],
      ),
    );
  }
}

/// A file nobody has written to is not worth a row: sharing it would hand over
/// an empty file and read as if the log were lost.
bool _worthOffering((String, String, File) entry) {
  final file = entry.$3;
  return file.existsSync() && file.lengthSync() > 0;
}

/// Step two, in-memory branch: adjust the filters, then copy or export.
///
/// It opens on whatever the page is already filtered by, so the common case —
/// "share what I am looking at" — needs no adjusting at all. The search text
/// comes along silently rather than as a fourth control: it is already visible
/// on the page behind the sheet.
class LogsRecentModal extends ConsumerStatefulWidget {
  const LogsRecentModal({super.key});

  @override
  ConsumerState<LogsRecentModal> createState() => _LogsRecentModalState();
}

class _LogsRecentModalState extends ConsumerState<LogsRecentModal> {
  LogCategory? _category;
  late Level _minLevel;
  late final String _text;

  @override
  void initState() {
    super.initState();
    final pageState = ref.read(logsOverviewNotifierProvider);
    _category = pageState.category;
    _minLevel = pageState.minLevel;
    _text = pageState.text;
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final paths = ref.watch(logPathResolverProvider);
    final notifications = ref.watch(inAppNotificationControllerProvider);
    final matches = logRing.view(
      minLevel: _minLevel,
      category: _category,
      text: _text,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.pages.logs.recentLogs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            LogFilterBar(
              category: _category,
              minLevel: _minLevel,
              onCategory: (value) => setState(() => _category = value),
              onLevel: (value) => setState(() => _minLevel = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.pages.logs.linesMatch(count: matches.length),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _copyLines(
                            matches,
                            t: t,
                            notifications: notifications,
                          );
                        },
                        icon: const Icon(FluentIcons.copy_20_regular, size: 18),
                        label: Text(t.common.addToClipboard),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _exportLines(
                            matches,
                            t: t,
                            notifications: notifications,
                            paths: paths,
                          );
                        },
                        icon: const Icon(
                          FluentIcons.arrow_download_20_regular,
                          size: 18,
                        ),
                        label: Text(t.pages.logs.exportToFile),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A long history can exceed what the platform clipboard accepts — Android
/// throws rather than truncating — so the failure points at the export button
/// instead of leaving the user with nothing.
Future<void> _copyLines(
  List<LogRecord> records, {
  required Translations t,
  required InAppNotificationController notifications,
}) async {
  final text = records.map(formatRecord).join('\n');

  try {
    await Clipboard.setData(ClipboardData(text: text));
    notifications.showSuccessToast(t.common.msg.export.clipboard.success);
  } catch (e, stack) {
    _log.error('copying logs failed', e, stack);
    notifications.showErrorToast(
      t.common.msg.export.clipboard.contentTooLarge,
    );
  }
}

Future<void> _exportLines(
  List<LogRecord> records, {
  required Translations t,
  required InAppNotificationController notifications,
  required LogPathResolver paths,
}) async {
  final target = paths.appExportFile();

  await writeLinesToFile(target.path, records.map(formatRecord));
  await _saveFileAs(target, t: t, notifications: notifications);
}

/// Desktop gets a save dialog; a phone gets the share sheet, which is what
/// "save this somewhere" means there.
Future<void> _saveFileAs(
  File file, {
  required Translations t,
  required InAppNotificationController notifications,
}) async {
  if (!PlatformUtils.isDesktop) {
    await UriUtils.tryShareOrLaunchFile(Uri.parse(file.path));
    return;
  }

  // saveFile only asks where to put it. On desktop it writes nothing and
  // ignores `bytes` — on macOS it throws when they are passed — so copying the
  // file over is ours to do. Reporting success without it was a lie.
  final saveTo = await FilePicker.platform.saveFile(
    fileName: file.uri.pathSegments.last,
  );
  if (saveTo == null) return;

  try {
    await file.copy(saveTo);
    notifications.showSuccessToast(t.pages.logs.fileSaved);
  } catch (e, stack) {
    _log.error('saving logs to $saveTo failed', e, stack);
    notifications.showErrorToast(t.pages.logs.fileSaveFailed);
  }
}
