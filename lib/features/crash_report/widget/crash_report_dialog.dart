import 'dart:async';
import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/crash_report/data/crash_excerpt.dart';
import 'package:hiddify/features/crash_report/data/diagnostics_exporter.dart';
import 'package:hiddify/features/crash_report/data/diagnostics_sender.dart';
import 'package:hiddify/features/crash_report/data/telegram_report_link.dart';
import 'package:hiddify/features/crash_report/notifier/crash_report_notifier.dart';
import 'package:hiddify/features/log/overview/logs_modals.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('ReportDialog');

/// How a report reaches the developers.
enum ReportChannel {
  /// uploaded by the app, to Sentry
  hiddify,

  /// by the user's Telegram, to the issues bot, started with this device's details
  /// ([telegramReportLinkFor])
  telegram,

  /// by the user's mail app, to [Constants.bugReportEmail]
  email,

  /// as a public issue on [Constants.bugReportGithubIssueUrl]
  github,

  /// saved on desktop, or handed to the share sheet on a phone, for the user to send anywhere
  file,
}

/// Shown on the first run after a crash: send the diagnostics zip, or not now. Either way it is
/// not shown again for the same crash.
class CrashReportDialog extends ConsumerWidget {
  const CrashReportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final crash = ref.read(crashReportNotifierProvider);
    return _ReportDialog(
      icon: Icons.bug_report_outlined,
      title: t.dialogs.crashReport.title,
      msg: t.dialogs.crashReport.msg,
      crashName: crash?.name,
      // the exception itself, for the user to see and for every way that can carry text
      crash: crash == null ? null : readCrashExcerpt(ref.read(appDirectoriesProvider).requireValue.workingDir, crash),
      dismiss: t.common.later,
    );
  }
}

/// Opened by the user from About or Logs when something does not work: the same report as after a
/// crash, with what they write about it.
class ReportProblemDialog extends ConsumerWidget {
  const ReportProblemDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return _ReportDialog(
      icon: FluentIcons.chat_warning_24_regular,
      title: t.dialogs.crashReport.problemTitle,
      msg: t.dialogs.crashReport.problemMsg,
      dismiss: t.common.cancel,
    );
  }
}

/// One thing the user does to send the report. A step with an [action] gets a button and a check
/// once its action reports it done; one without is the instruction that finishes the way.
class _Step {
  const _Step(this.title, {this.detail, this.file, this.action, this.actionLabel, this.actionIcon});

  final String title;
  final String? detail;

  /// The zip's name, shown on a line of its own: it is long and would break a sentence apart.
  final String? file;

  /// Whether it got done: a save dialog closed without saving leaves the step to do again.
  final Future<bool> Function()? action;
  final String? actionLabel;
  final IconData? actionIcon;
}

enum _Upload { sending, sent, failed }

/// Two pages: what happened and which way to send it, then the numbered steps of that way. The
/// zip is built as soon as a way is picked, so it is ready by the time the user reaches a step
/// that needs it; the upload to Hiddify needs no step from the user at all.
class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({
    required this.icon,
    required this.title,
    required this.msg,
    required this.dismiss,
    this.crashName,
    this.crash,
  });

  final IconData icon;
  final String title;
  final String msg;
  final String dismiss;
  final String? crashName;
  final CrashExcerpt? crash;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  final _description = TextEditingController();
  ReportChannel? _channel;
  File? _file;
  Object? _error;
  _Upload? _upload;
  final _done = <int>{};

  /// Each pick builds its own zip: one built for an earlier pick may lack an edited description.
  int _generation = 0;

  /// The issues bot's link, started with this device's details; a platform call is behind it.
  late final Future<Uri> _telegramLink = _makeTelegramLink();

  Future<Uri> _makeTelegramLink() async {
    final info = await ref.read(appInfoProvider.future);
    return telegramReportLinkFor(
      crash: widget.crashName != null,
      build: info.buildNumber,
      language: ref.read(localePreferencesProvider).languageCode,
      tv: await ref.read(isAndroidTvProvider.future),
      release: info.release,
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _choose(ReportChannel channel) async {
    final generation = ++_generation;
    setState(() {
      _channel = channel;
      _file = null;
      _error = null;
      _upload = null;
      _done.clear();
    });
    final File file;
    try {
      file = await ref.read(diagnosticsExporterProvider).export(description: _description.text);
    } catch (e, stack) {
      _log.error('exporting the diagnostics failed: $e', e, stack);
      if (mounted && generation == _generation) setState(() => _error = e);
      return;
    }
    if (!mounted || generation != _generation) return;
    setState(() => _file = file);

    if (channel == ReportChannel.hiddify) {
      setState(() => _upload = _Upload.sending);
      final sent = await ref
          .read(diagnosticsSenderProvider)
          .send(file, crashName: widget.crashName, description: _description.text, crashText: widget.crash?.text);
      if (mounted && generation == _generation) setState(() => _upload = sent ? _Upload.sent : _Upload.failed);
    }
  }

  void _back() => setState(() {
    _generation++;
    _channel = null;
  });

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final channel = _channel;
    return AlertDialog(
      icon: Icon(widget.icon),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(child: channel == null ? _chooser(t) : _stepsView(t, channel)),
      ),
      actions: channel == null
          ? [TextButton(onPressed: () => context.pop(), child: Text(widget.dismiss))]
          : [
              if (_upload != _Upload.sent) TextButton(onPressed: _back, child: Text(t.dialogs.crashReport.back)),
              FilledButton(onPressed: () => context.pop(), child: Text(t.common.done)),
            ],
    );
  }

  Widget _chooser(Translations t) {
    Widget option(ReportChannel channel, IconData icon, String title, String subtitle) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(FluentIcons.chevron_right_20_regular),
      onTap: () => _choose(channel),
    );

    final r = t.dialogs.crashReport;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.msg),
        if (widget.crash case final crash?) ...[const SizedBox(height: 12), _CrashBox(crash)],
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: r.description,
            hintText: r.descriptionHint,
          ),
        ),
        Text(r.chooseHow, style: Theme.of(context).textTheme.titleSmall),
        if (DiagnosticsSender.available)
          option(
            ReportChannel.hiddify,
            FluentIcons.cloud_arrow_up_20_regular,
            r.sendHiddify,
            DiagnosticsSender.encrypted ? r.sendHiddifyEncryptedMsg : r.sendHiddifyMsg,
          ),
        option(
          ReportChannel.telegram,
          FluentIcons.send_20_regular,
          r.sendTelegram,
          _ltr(Constants.bugReportTelegramName),
        ),
        option(ReportChannel.email, FluentIcons.mail_20_regular, r.sendEmail, _ltr(Constants.bugReportEmail)),
        option(ReportChannel.github, FluentIcons.code_20_regular, r.sendGithub, r.sendGithubMsg),
        option(ReportChannel.file, FluentIcons.folder_zip_20_regular, r.saveFile, r.saveFileMsg),
      ],
    );
  }

  Widget _stepsView(Translations t, ReportChannel channel) {
    final r = t.dialogs.crashReport;
    final theme = Theme.of(context);
    final steps = _steps(t, channel);
    // the first step with a button that is not done yet; the zip comes first of all. Steps go in
    // order: a later button waits for this one, a done one can be run again.
    final active = _file == null
        ? -1
        : steps.indexed.where((e) => e.$2.action != null && !_done.contains(e.$1)).firstOrNull?.$1 ?? -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(switch (channel) {
          ReportChannel.hiddify => r.sendHiddify,
          ReportChannel.telegram => r.sendTelegram,
          ReportChannel.email => r.sendEmail,
          ReportChannel.github => r.sendGithub,
          ReportChannel.file => r.saveFile,
        }, style: theme.textTheme.titleMedium),
        if (switch (channel) {
              ReportChannel.github => (FluentIcons.warning_20_regular, r.steps.githubPublic, true),
              ReportChannel.hiddify when DiagnosticsSender.encrypted => (
                FluentIcons.lock_closed_20_regular,
                r.steps.hiddifyEncrypted,
                false,
              ),
              ReportChannel.telegram => (FluentIcons.lock_closed_20_regular, r.steps.telegramPrivate, false),
              ReportChannel.email => (FluentIcons.lock_closed_20_regular, r.steps.emailPrivate, false),
              _ => null,
            }
            case (final icon, final text, final warning)) ...[
          const SizedBox(height: 8),
          _Notice(icon: icon, text: text, warning: warning),
        ],
        const SizedBox(height: 12),
        _StepTile(
          number: 1,
          title: r.steps.prepare,
          detail: _error != null
              ? r.steps.prepareFailed
              : _file == null
              ? r.steps.preparing
              : null,
          file: _file?.uri.pathSegments.last,
          state: _error != null
              ? _StepState.failed
              : _file == null
              ? _StepState.working
              : _StepState.done,
        ),
        if (channel == ReportChannel.hiddify && _file != null)
          _StepTile(
            number: 2,
            title: r.steps.upload,
            detail: switch (_upload) {
              _Upload.sent => r.sent,
              _Upload.failed => r.sendFailed,
              _ => r.steps.uploading,
            },
            state: switch (_upload) {
              _Upload.sent => _StepState.done,
              _Upload.failed => _StepState.failed,
              _ => _StepState.working,
            },
          ),
        for (final (index, step) in steps.indexed)
          _StepTile(
            number: index + 2,
            title: step.title,
            detail: step.detail,
            file: step.file,
            state: _done.contains(index)
                ? _StepState.done
                : index == active || (step.action == null && active == -1 && _file != null)
                ? _StepState.active
                : _StepState.waiting,
            action: step.action == null || _file == null
                ? null
                : (
                    label: step.actionLabel!,
                    icon: step.actionIcon!,
                    primary: index == active,
                    run: index == active || _done.contains(index)
                        ? () async {
                            final done = await step.action!();
                            if (done && mounted) setState(() => _done.add(index));
                          }
                        : null,
                  ),
          ),
      ],
    );
  }

  /// The steps after the zip is ready, for [channel] on this kind of device. A phone has no save
  /// dialog: its share sheet saves the file, or hands it to the mail app or Telegram.
  List<_Step> _steps(Translations t, ReportChannel channel) {
    final s = t.dialogs.crashReport.steps;
    final notifications = ref.read(inAppNotificationControllerProvider);
    final desktop = PlatformUtils.isDesktop;
    final file = _file;
    final name = file?.uri.pathSegments.last ?? '';
    final crash = widget.crashName != null;
    final subject = crash ? t.dialogs.crashReport.subject : t.dialogs.crashReport.problemSubject;

    Future<bool> save() async => file != null && await saveFileAs(file, t: t, notifications: notifications);

    // every way goes the same: the zip is kept somewhere, the place it goes to opens, and the
    // user attaches it there. Neither a mailto: nor a Telegram or GitHub link can carry a file.
    _Step open(String title, String detail, String label, IconData icon, FutureOr<Uri> uri) => _Step(
      title,
      detail: detail,
      action: () async => UriUtils.tryLaunch(await uri),
      actionLabel: label,
      actionIcon: icon,
    );

    return [
      if (channel != ReportChannel.hiddify)
        _Step(
          s.save,
          detail: desktop ? s.saveDesktopMsg : s.saveMobileMsg,
          action: save,
          actionLabel: desktop ? t.common.save : t.common.share,
          actionIcon: desktop ? FluentIcons.arrow_download_20_regular : FluentIcons.share_20_regular,
        ),
      ...switch (channel) {
        ReportChannel.hiddify || ReportChannel.file => const <_Step>[],
        ReportChannel.telegram => [
          open(
            s.openBot,
            _ltr(Constants.bugReportTelegramName),
            s.openBotButton,
            FluentIcons.send_20_regular,
            _telegramLink,
          ),
          _Step(s.attachInChat, detail: s.attachHow, file: name),
        ],
        ReportChannel.email => [
          open(
            s.openMail,
            s.openMailMsg(address: _ltr(Constants.bugReportEmail)),
            s.openMailButton,
            FluentIcons.mail_20_regular,
            Uri(
              scheme: 'mailto',
              path: Constants.bugReportEmail,
              query:
                  'subject=${Uri.encodeComponent(subject)}'
                  '&body=${Uri.encodeComponent(_mailBody())}',
            ),
          ),
          _Step(s.attachSend, detail: s.attachHow, file: name),
        ],
        ReportChannel.github => [
          open(s.openGithub, s.openGithubMsg, s.openGithubButton, FluentIcons.open_20_regular, _githubIssue()),
          _Step(s.dropInIssue, detail: s.dropInIssueHow, file: name),
        ],
      },
    ];
  }

  /// This system as the bug report template's Platform/OS dropdown names it.
  static String? get _githubPlatform => switch (Platform.operatingSystem) {
    'android' => 'Android',
    'ios' => 'iOS',
    'macos' => 'macOS',
    'windows' => 'Windows',
    'linux' => 'Linux',
    _ => null,
  };

  /// What the user wrote, then the exception after a crash.
  String _mailBody() => [
    _description.text.trim(),
    if (widget.crash case final crash?) crash.text,
  ].where((part) => part.isNotEmpty).join('\n\n---\n\n');

  Uri _githubIssue() => githubIssueUrl(
    description: _description.text,
    crash: widget.crash,
    version: switch (ref.read(appInfoProvider).valueOrNull) {
      final info? => '${info.version} (${info.buildNumber}) ${info.release.key}',
      null => null,
    },
    platform: _githubPlatform,
    os: Platform.operatingSystemVersion,
  );
}

enum _StepState { waiting, active, working, done, failed }

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.state,
    this.detail,
    this.file,
    this.action,
  });

  final int number;
  final String title;
  final String? detail;
  final String? file;
  final _StepState state;

  /// [run] is null while an earlier step is still to do: the button shows, disabled.
  final ({String label, IconData icon, bool primary, Future<void> Function()? run})? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = state == _StepState.waiting;

    final badge = switch (state) {
      _StepState.working => const SizedBox(
        width: 28,
        height: 28,
        child: Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      _StepState.done => CircleAvatar(
        radius: 14,
        backgroundColor: colors.primary,
        child: Icon(Icons.check, size: 16, color: colors.onPrimary),
      ),
      _StepState.failed => CircleAvatar(
        radius: 14,
        backgroundColor: colors.error,
        child: Icon(Icons.close, size: 16, color: colors.onError),
      ),
      _ => CircleAvatar(
        radius: 14,
        backgroundColor: state == _StepState.active ? colors.primaryContainer : colors.surfaceContainerHighest,
        child: Text(
          '$number',
          style: theme.textTheme.labelLarge?.copyWith(
            color: state == _StepState.active ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          ),
        ),
      ),
    };

    final action = this.action;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: muted ? colors.onSurfaceVariant : null,
                      fontWeight: state == _StepState.active ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: state == _StepState.failed ? colors.error : colors.onSurfaceVariant,
                    ),
                  ),
                if (file case final file?) ...[const SizedBox(height: 6), _FileChip(name: file)],
                if (action != null) ...[
                  const SizedBox(height: 8),
                  if (action.primary)
                    FilledButton.icon(
                      onPressed: action.run,
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: action.run,
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the user should know about the way before taking it: a warning in the error colors, or
/// a plain note.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.warning = false});

  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = warning ? colors.errorContainer : colors.secondaryContainer;
    final foreground = warning ? colors.onErrorContainer : colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

/// The report's file name on one line, the way a file looks in a chat: the user looks for this
/// name in the save dialog, in Downloads and in the attach menu.
class _FileChip extends StatelessWidget {
  const _FileChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.folder_zip_16_regular, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              // a file name reads left to right in a right-to-left language too
              textDirection: TextDirection.ltr,
              style: _mono(theme.textTheme.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}

/// The exception the crash ended with: its headline, and the lines after it on a tap.
class _CrashBox extends StatefulWidget {
  const _CrashBox(this.crash);

  final CrashExcerpt crash;

  @override
  State<_CrashBox> createState() => _CrashBoxState();
}

class _CrashBoxState extends State<_CrashBox> {
  var _open = false;

  /// The lines under the headline, which is already shown above them.
  String get _details {
    final crash = widget.crash;
    final text = crash.text.trimLeft();
    return text.startsWith(crash.headline) ? text.substring(crash.headline.length).trimLeft() : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mono = _mono(theme.textTheme.bodySmall);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.crash.headline,
            maxLines: _open ? null : 2,
            overflow: _open ? null : TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: mono?.copyWith(color: colors.error, fontWeight: FontWeight.w600),
          ),
          if (_open)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 6, right: 6),
                // a stack line reads whole: the box scrolls sideways rather than wrapping it
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(_details, textDirection: TextDirection.ltr, style: mono),
                ),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => setState(() => _open = !_open),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Consumer(
                builder: (context, ref, _) {
                  final t = ref.watch(translationsProvider).requireValue;
                  return Text(_open ? t.common.showLess : t.common.showMore);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [text] kept left to right inside a right-to-left sentence: an address or a bot name otherwise
/// shows its `@` at the wrong end in Persian.
String _ltr(String text) => '\u2066$text\u2069';

/// Monospace, for file names and stack traces: the app's Persian font draws every digit as a
/// Persian one, and a name must read as the file is called.
TextStyle? _mono(TextStyle? style) =>
    style?.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New']);

/// A new issue from the bug report template, with what the app knows already filled in: after a
/// crash, the exception is the title's and the log field's.
@visibleForTesting
Uri githubIssueUrl({
  required String description,
  required CrashExcerpt? crash,
  required String? version,
  required String? platform,
  required String os,
}) {
  final text = description.trim();
  final headline = text.isNotEmpty ? text.split('\n').first : crash?.headline ?? '';
  return Uri.parse(Constants.bugReportGithubIssueUrl).replace(
    queryParameters: {
      'template': 'bug_report.yaml',
      'title':
          '${crash == null ? '[Bug]' : '[Crash]'}: '
          '${headline.length > 80 ? '${headline.substring(0, 80)}…' : headline}',
      if (platform != null) 'platform': platform,
      'os': os,
      if (version != null) 'version': version,
      if (text.isNotEmpty)
        'problem': text.length > 1500 ? '${text.substring(0, 1500)}…' : text
      else if (crash != null)
        'problem': 'Hiddify crashed: ${crash.headline}',
      if (crash != null) 'logs': crash.text,
      'additional': 'Diagnostics report:\n',
    },
  );
}
