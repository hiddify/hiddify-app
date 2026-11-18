import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/crash_report/data/crash_excerpt.dart';
import 'package:hiddify/features/crash_report/data/diagnostics_exporter.dart';
import 'package:hiddify/features/crash_report/data/diagnostics_sender.dart';
import 'package:hiddify/features/crash_report/data/telegram_report_link.dart';
import 'package:hiddify/features/crash_report/notifier/crash_report_notifier.dart';
import 'package:hiddify/features/crash_report/notifier/trace_session_notifier.dart';
import 'package:hiddify/features/crash_report/widget/trace_session_view.dart';
import 'package:hiddify/features/log/overview/logs_modals.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('ReportDialog');

/// Where a report goes. Telegram, email and GitHub go the same way up to the last steps: the zip is saved,
/// then the place it goes to opens and the user attaches it there.
enum ReportChannel {
  /// by the user's Telegram, to the issues bot, started with this device's details
  /// ([telegramReportLinkFor]): the recommended way, the team can answer there
  telegram,

  /// uploaded by the app, to Sentry
  hiddify,

  /// by the user's mail app, to [Constants.bugReportEmail]
  email,

  /// as a public issue on [Constants.bugReportGithubIssueUrl]
  github,

  /// kept on this device: encrypted, or in the clear for the user to look at. The only way the
  /// sensitive part leaves the app unencrypted.
  local,
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
/// crash, with what they write about it. It first offers detailed logging for a few minutes, so the
/// problem is caught in the act; a crash report has its crash already and skips that.
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
      offerTrace: true,
    );
  }
}

enum _Upload { sending, sent, failed }

/// The dialog's width on a screen with room for it.
const _dialogWidth = 480.0;

/// How long the dialog takes to move between its states: pages, destinations, a step done.
const _motion = Duration(milliseconds: 280);

/// Two pages: what happened, then the report and where it goes. The zip is built once, on
/// Continue. Every destination shares the card and the save; picking another only changes the
/// steps under them, and a save already done stays done.
class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({
    required this.icon,
    required this.title,
    required this.msg,
    required this.dismiss,
    this.crashName,
    this.crash,
    this.offerTrace = false,
  });

  final IconData icon;
  final String title;
  final String msg;
  final String dismiss;
  final String? crashName;
  final CrashExcerpt? crash;

  /// Opens on the detailed logging offer, unless it is already on: then the user came back to send.
  final bool offerTrace;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  final _description = TextEditingController();

  /// On the first page: detailed logging, offered or counting down.
  late var _offer = widget.offerTrace && ref.read(traceSessionProvider) == null;

  /// Kept for dispose, where ref can no longer be read: read in initState, since a late field is
  /// only read at its first use, which was dispose.
  late final TraceSessionNotifier _trace;

  /// On the second page: the report is being made, or is made.
  var _sending = false;
  var _channel = ReportChannel.telegram;

  /// What leaves the device, as the core made it: the generic metadata to read, the sensitive part
  /// encrypted to the build's key (in the clear in a build without one).
  DiagnosticsReport? _report;
  Object? _error;
  _Upload? _upload;

  /// The zip is kept where the user can attach it: the first step of every manual destination.
  var _saved = false;

  /// The destinations whose bot, mail app or issue page the user opened.
  final _opened = <ReportChannel>{};

  /// Each Continue builds its own zip: one built before Back may lack an edited description.
  int _generation = 0;

  /// The issues bot's link, started with this device's details; a platform call is behind it.
  late final Future<Uri> _telegramLink = _makeTelegramLink();

  Future<Uri> _makeTelegramLink() async {
    // every ref read before the first await: the dialog can be closed while it waits
    final infoFuture = ref.read(appInfoProvider.future);
    final tvFuture = ref.read(isAndroidTvProvider.future);
    final language = ref.read(localePreferencesProvider).languageCode;
    final crash = widget.crashName != null;
    final info = await infoFuture;
    return telegramReportLinkFor(
      crash: crash,
      build: info.buildNumber,
      language: language,
      tv: await tvFuture,
      release: info.release,
    );
  }

  @override
  void initState() {
    super.initState();
    _trace = ref.read(traceSessionProvider.notifier);
  }

  @override
  void dispose() {
    // the detailed logs are in the report now: no reason to keep the core on trace
    if (_report != null && _trace.active) unawaited(_trace.stop());
    _description.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final generation = ++_generation;
    setState(() {
      _sending = true;
      _report = null;
      _error = null;
      _upload = null;
      _saved = false;
      _opened.clear();
    });
    try {
      // the core encrypts the sensitive part to its own key; one whose key is not an age key
      // throws here, and nothing is sent in the clear
      final export = ref.read(diagnosticsExporterProvider).export(description: _description.text);
      // the scrubbing steps play out before the file appears, however fast the core is
      await Future.wait([export, Future<void>.delayed(_ScrubChecklist.minDuration)]);
      final report = await export;
      if (mounted && generation == _generation) setState(() => _report = report);
    } catch (e, stack) {
      _log.error('preparing the diagnostics failed: $e', e, stack);
      if (mounted && generation == _generation) setState(() => _error = e);
    }
  }

  void _back() => setState(() {
    _generation++;
    _sending = false;
  });

  Future<void> _uploadToHiddify() async {
    final report = _report;
    if (report == null) return;
    final generation = _generation;
    setState(() => _upload = _Upload.sending);
    final sent = await ref
        .read(diagnosticsSenderProvider)
        .send(report, crashName: widget.crashName, description: _description.text, crashText: widget.crash?.text);
    if (mounted && generation == _generation) setState(() => _upload = sent ? _Upload.sent : _Upload.failed);
  }

  Future<void> _save(Translations t) async {
    final report = _report;
    if (report == null) return;
    final saved = await saveFileAs(report.file, t: t, notifications: ref.read(inAppNotificationControllerProvider));
    if (saved && mounted) setState(() => _saved = true);
  }

  /// The same report with the sensitive part in the clear, made only when asked for: to look
  /// inside it. It never leaves the device by the app.
  Future<void> _saveUnencrypted(Translations t) async {
    // read before the export: the dialog can be closed while it runs
    final notifications = ref.read(inAppNotificationControllerProvider);
    try {
      final copy = await ref
          .read(diagnosticsExporterProvider)
          .export(description: _description.text, unencrypted: true);
      await saveFileAs(copy.file, t: t, notifications: notifications);
    } catch (e, stack) {
      _log.error('preparing the unencrypted copy failed: $e', e, stack);
    }
  }

  Future<void> _open(ReportChannel channel, Translations t) async {
    final uri = switch (channel) {
      ReportChannel.telegram => await _telegramLink,
      ReportChannel.email => Uri(
        scheme: 'mailto',
        path: Constants.bugReportEmail,
        query:
            'subject=${Uri.encodeComponent(widget.crashName != null ? t.dialogs.crashReport.subject : t.dialogs.crashReport.problemSubject)}'
            '&body=${Uri.encodeComponent(_mailBody())}',
      ),
      _ => _githubIssue(),
    };
    if (await UriUtils.tryLaunch(uri) && mounted) setState(() => _opened.add(channel));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final sent = _upload == _Upload.sent;
    final traceUntil = ref.watch(traceSessionProvider);
    return AlertDialog(
      icon: Icon(widget.icon),
      title: Text(widget.title),
      // one width for both pages and every destination: sized by its content, the dialog grew
      // with the file name and jumped between pages. A narrow screen still narrows it.
      content: SizedBox(
        width: _dialogWidth,
        child: SingleChildScrollView(
          child: AnimatedSize(
            duration: _motion,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _motion,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: _topStack,
              transitionBuilder: _fadeSlide,
              child: _offer
                  ? KeyedSubtree(key: const ValueKey('trace'), child: _tracePage(t, traceUntil))
                  : _sending
                  ? KeyedSubtree(key: const ValueKey('send'), child: _sendPage(t))
                  : KeyedSubtree(key: const ValueKey('write'), child: _writePage(t, traceUntil)),
            ),
          ),
        ),
      ),
      actions: _offer
          ? traceUntil == null
                ? [
                    TextButton(
                      onPressed: () => setState(() => _offer = false),
                      child: Text(t.dialogs.crashReport.trace.skip),
                    ),
                    FilledButton.icon(
                      onPressed: () => ref.read(traceSessionProvider.notifier).start(),
                      icon: const Icon(FluentIcons.record_20_filled, size: 18),
                      label: Text(t.dialogs.crashReport.trace.start),
                    ),
                  ]
                : [FilledButton(onPressed: () => context.pop(), child: Text(t.dialogs.crashReport.trace.gotIt))]
          : !_sending
          ? [
              TextButton(onPressed: () => context.pop(), child: Text(widget.dismiss)),
              FilledButton.icon(
                onPressed: _prepare,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(t.common.kContinue),
              ),
            ]
          : [
              if (!sent) TextButton(onPressed: _back, child: Text(t.dialogs.crashReport.back)),
              FilledButton(onPressed: () => context.pop(), child: Text(t.common.done)),
            ],
    );
  }

  Widget _tracePage(Translations t, DateTime? until) {
    final status = ref.watch(connectionNotifierProvider).valueOrNull;
    return TraceSessionView(
      t: t,
      until: until,
      disconnected: status?.isDisconnected ?? true,
      onConnect: () {
        // the dialog steps aside so the user sees the connection come up and can make the problem happen
        unawaited(ref.read(connectionNotifierProvider.notifier).toggleConnection());
        context.pop();
      },
    );
  }

  Widget _writePage(Translations t, DateTime? traceUntil) {
    final r = t.dialogs.crashReport;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.offerTrace && traceUntil != null) ...[
          TraceSessionBanner(t: t, until: traceUntil, onStop: () => ref.read(traceSessionProvider.notifier).stop()),
          const SizedBox(height: 14),
        ],
        Text(
          widget.msg,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (widget.crash case final crash?) ...[const SizedBox(height: 12), _CrashBox(crash)],
        const SizedBox(height: 16),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            labelText: r.description,
            hintText: r.descriptionHint,
            alignLabelWithHint: true,
            // the limit is far: a counter from the first letter is noise
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _sendPage(Translations t) {
    final r = t.dialogs.crashReport;
    final uploading = _upload == _Upload.sending || _upload == _Upload.sent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _reportCard(t),
        const SizedBox(height: 20),
        Text(r.chooseHow, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 18),
        _DestinationPicker(
          selected: _channel,
          recommended: ReportChannel.telegram,
          recommendedLabel: r.recommended,
          // a report on its way to Hiddify stays there
          onChanged: uploading ? null : (channel) => setState(() => _channel = channel),
          options: [
            (channel: ReportChannel.telegram, icon: FluentIcons.send_24_regular, label: 'Telegram'),
            if (DiagnosticsSender.available)
              (channel: ReportChannel.hiddify, icon: FluentIcons.cloud_arrow_up_24_regular, label: 'Hiddify'),
            (channel: ReportChannel.email, icon: FluentIcons.mail_24_regular, label: r.email),
            (channel: ReportChannel.github, icon: FluentIcons.code_24_regular, label: 'GitHub'),
            (channel: ReportChannel.local, icon: FluentIcons.phone_laptop_24_regular, label: r.localOnly),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: _motion,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: _topStack,
          transitionBuilder: _fadeSlide,
          child: KeyedSubtree(
            key: ValueKey(_channel),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_privacy(t) case final privacy?) ...[privacy, const SizedBox(height: 8)],
                ...switch (_channel) {
                  ReportChannel.hiddify => [_hiddifySteps(t)],
                  ReportChannel.local => [_localSteps(t)],
                  _ => _manualSteps(t),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The report itself: being made, made with its name, or failed. It is the same for every
  /// destination, so it stands above them.
  Widget _reportCard(Translations t) {
    final r = t.dialogs.crashReport;
    final s = r.steps;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final report = _report;
    final failed = _error != null;

    final Widget badge = failed
        ? CircleAvatar(
            radius: 22,
            backgroundColor: colors.errorContainer,
            child: Icon(FluentIcons.error_circle_24_regular, color: colors.onErrorContainer),
          )
        : report == null
        ? SizedBox.square(
            dimension: 44,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.primary),
            ),
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: colors.primary,
            child: Icon(FluentIcons.folder_zip_24_regular, color: colors.onPrimary),
          );

    return AnimatedContainer(
      duration: _motion,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (failed ? colors.error : colors.outlineVariant).withValues(alpha: .6)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: failed
              ? [colors.errorContainer.withValues(alpha: .35), colors.surfaceContainerHigh]
              : [colors.primaryContainer.withValues(alpha: report == null ? .25 : .55), colors.surfaceContainerHigh],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: _motion,
            child: KeyedSubtree(key: ValueKey((failed, report == null)), child: badge),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failed
                        ? s.prepareFailed
                        : report == null
                        ? s.preparing
                        : s.ready,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: failed ? colors.error : null,
                    ),
                  ),
                  if (report != null) ...[
                    const SizedBox(height: 8),
                    _FileChip(name: report.file.uri.pathSegments.last),
                  ],
                  if (!failed)
                    _ScrubChecklist(
                      key: ValueKey(_generation),
                      done: report != null,
                      encrypted: report?.encrypted ?? true,
                      steps: [r.scrubSecrets, r.encryptingLogs],
                      notEncrypted: r.notEncrypted,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Who sees the report this way, in a quiet line.
  Widget? _privacy(Translations t) {
    final r = t.dialogs.crashReport;
    final s = r.steps;
    return switch (_channel) {
      ReportChannel.telegram => _Hint(icon: FluentIcons.lock_closed_16_regular, text: s.telegramPrivate),
      ReportChannel.hiddify => _Hint(icon: FluentIcons.lock_closed_16_regular, text: r.sendHiddifyMsg),
      ReportChannel.email => _Hint(icon: FluentIcons.lock_closed_16_regular, text: s.emailPrivate),
      ReportChannel.local => _Hint(icon: FluentIcons.shield_checkmark_16_regular, text: r.localOnlyMsg),
      ReportChannel.github => null,
    };
  }

  /// Kept on this device: the report as it would be sent, and, when that one is encrypted, a copy
  /// in the clear to look inside.
  Widget _localSteps(Translations t) {
    final s = t.dialogs.crashReport.steps;
    final desktop = PlatformUtils.isDesktop;
    final report = _report;
    final encrypted = report?.encrypted ?? false;
    return _StepTile(
      number: 1,
      title: s.save,
      detail: desktop ? s.saveDesktopMsg : s.saveMobileMsg,
      state: _saved
          ? _StepState.done
          : report != null
          ? _StepState.active
          : _StepState.waiting,
      actions: [
        (
          label: desktop ? t.common.save : t.common.share,
          icon: encrypted
              ? FluentIcons.lock_closed_20_regular
              : desktop
              ? FluentIcons.arrow_download_20_regular
              : FluentIcons.share_20_regular,
          primary: report != null && !_saved,
          run: report == null ? null : () => _save(t),
        ),
        if (encrypted)
          (
            label: s.saveUnencryptedCopy,
            icon: FluentIcons.lock_open_20_regular,
            primary: false,
            run: () => _saveUnencrypted(t),
          ),
      ],
    );
  }

  /// One button, and the app does the rest.
  Widget _hiddifySteps(Translations t) {
    final r = t.dialogs.crashReport;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_upload == _Upload.sent) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .4, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Icon(FluentIcons.checkmark_circle_48_filled, size: 48, color: colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              r.sent,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      );
    }

    final uploading = _upload == _Upload.sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_upload == _Upload.failed) ...[
          const SizedBox(height: 4),
          _Notice(icon: FluentIcons.warning_16_regular, text: r.sendFailed, warning: true),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _report == null || uploading ? null : _uploadToHiddify,
          icon: uploading
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(FluentIcons.cloud_arrow_up_24_regular, size: 20),
          label: Text(uploading ? r.steps.uploading : r.sendHiddify),
        ),
      ],
    );
  }

  /// Save, open, attach: the same three steps for Telegram, email and GitHub, and only the last
  /// two say where. A phone has no save dialog: its share sheet saves the file.
  List<Widget> _manualSteps(Translations t) {
    final s = t.dialogs.crashReport.steps;
    final desktop = PlatformUtils.isDesktop;
    final ready = _report != null;
    final channel = _channel;
    final opened = _opened.contains(channel);

    final (openTitle, openDetail, openLabel, openIcon, attachTitle, attachHow) = switch (channel) {
      ReportChannel.telegram => (
        s.openBot,
        _ltr(Constants.bugReportTelegramName),
        s.openBotButton,
        FluentIcons.send_20_regular,
        s.attachInChat,
        s.attachHow,
      ),
      ReportChannel.email => (
        s.openMail,
        s.openMailMsg(address: _ltr(Constants.bugReportEmail)),
        s.openMailButton,
        FluentIcons.mail_20_regular,
        s.attachSend,
        s.attachHow,
      ),
      _ => (
        s.openGithub,
        s.openGithubMsg,
        s.openGithubButton,
        FluentIcons.open_20_regular,
        s.dropInIssue,
        s.dropInIssueHow,
      ),
    };

    _StepState state({required bool done, required bool reachable}) => done
        ? _StepState.done
        : reachable
        ? _StepState.active
        : _StepState.waiting;

    return [
      _StepTile(
        number: 1,
        title: s.save,
        detail: desktop ? s.saveDesktopMsg : s.saveMobileMsg,
        state: state(done: _saved, reachable: ready),
        actions: [
          (
            label: desktop ? t.common.save : t.common.share,
            icon: desktop ? FluentIcons.arrow_download_20_regular : FluentIcons.share_20_regular,
            primary: ready && !_saved,
            run: ready ? () => _save(t) : null,
          ),
        ],
      ),
      _StepTile(
        number: 2,
        title: openTitle,
        detail: openDetail,
        state: state(done: opened, reachable: _saved),
        actions: [
          (label: openLabel, icon: openIcon, primary: _saved && !opened, run: _saved ? () => _open(channel, t) : null),
        ],
      ),
      _StepTile(
        number: 3,
        title: attachTitle,
        detail: attachHow,
        file: _report?.file.uri.pathSegments.last,
        state: _saved && opened ? _StepState.active : _StepState.waiting,
      ),
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

/// The old page under the new one, both from the top: the dialog grows or shrinks from there.
Widget _topStack(Widget? current, List<Widget> previous) =>
    Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]);

Widget _fadeSlide(Widget child, Animation<double> animation) => FadeTransition(
  opacity: animation,
  child: SlideTransition(
    position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(animation),
    child: child,
  ),
);

/// Where the report goes, as tiles: one row when there is room, three a row on a phone. The recommended
/// one wears a pill across its top edge.
class _DestinationPicker extends StatelessWidget {
  const _DestinationPicker({
    required this.options,
    required this.selected,
    required this.recommended,
    required this.recommendedLabel,
    this.onChanged,
  });

  final List<({ReportChannel channel, IconData icon, String label})> options;
  final ReportChannel selected;
  final ReportChannel recommended;
  final String recommendedLabel;
  final ValueChanged<ReportChannel>? onChanged;

  @override
  Widget build(BuildContext context) {
    // the dialog sizes its content by its intrinsic width, which a LayoutBuilder cannot give:
    // the screen decides instead
    final perRow = MediaQuery.sizeOf(context).width >= 600 ? options.length : 3;
    const gap = 10.0;
    final rows = [for (var i = 0; i < options.length; i += perRow) options.sublist(i, min(i + perRow, options.length))];
    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const SizedBox(height: gap + 8),
          Row(
            children: [
              for (final (i, option) in row.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: _DestinationTile(
                    icon: option.icon,
                    label: option.label,
                    selected: option.channel == selected,
                    badge: option.channel == recommended ? recommendedLabel : null,
                    onTap: onChanged == null ? null : () => onChanged!(option.channel),
                  ),
                ),
              ],
              // a short last row keeps the tiles the size of the others
              for (var i = row.length; i < perRow; i++) ...[const SizedBox(width: gap), const Spacer()],
            ],
          ),
        ],
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.icon, required this.label, required this.selected, this.badge, this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(18);
    final enabled = onTap != null || selected;

    return Semantics(
      selected: selected,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: _motion,
              curve: Curves.easeOutCubic,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
                border: Border.all(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 2 : 1),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: .22),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.12 : 1,
                          duration: _motion,
                          curve: Curves.easeOutBack,
                          child: Icon(icon, size: 26, color: selected ? colors.primary : colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: selected ? colors.onPrimaryContainer : colors.onSurface,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (badge case final badge?)
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: colors.primary,
                    // a ring of the dialog's own color lifts the pill off the tile's border
                    border: Border.all(color: colors.surfaceContainerHigh, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 11, color: colors.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What the core does to the report before it leaves the device, shown while it does it: each
/// step ticks off in turn, the last one waits for the file, and they stay checked once it is made.
class _ScrubChecklist extends StatefulWidget {
  const _ScrubChecklist({
    super.key,
    required this.done,
    required this.encrypted,
    required this.steps,
    required this.notEncrypted,
  });

  static const _step = Duration(milliseconds: 800);

  /// How long the report is held back so the first step can tick off before the last.
  static Duration get minDuration => _step + const Duration(milliseconds: 120);

  final bool done;

  /// Whether the sensitive part was encrypted: a build without a key only removes.
  final bool encrypted;

  /// The last one is the encryption: a warning instead once a build without a key made the file.
  final List<String> steps;

  /// The last step's label when the file came out unencrypted.
  final String notEncrypted;

  @override
  State<_ScrubChecklist> createState() => _ScrubChecklistState();
}

class _ScrubChecklistState extends State<_ScrubChecklist> {
  /// How many steps are done: the one at this index is in progress.
  var _ticked = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_ScrubChecklist._step, (_) => _tick());
  }

  void _tick() {
    final last = widget.steps.length - 1;
    if (_ticked < last) {
      setState(() => _ticked++);
    } else if (widget.done) {
      _timer?.cancel();
      setState(() => _ticked = widget.steps.length);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.steps.length - 1;
    return AnimatedSize(
      duration: _motion,
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, label) in widget.steps.indexed)
              _ScrubStep(
                label: i == last && i < _ticked && !widget.encrypted ? widget.notEncrypted : label,
                state: i == last && i < _ticked && !widget.encrypted
                    ? _StepState.failed
                    : i < _ticked
                    ? _StepState.done
                    : i == _ticked
                    ? _StepState.working
                    : _StepState.waiting,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScrubStep extends StatelessWidget {
  const _ScrubStep({required this.label, required this.state});

  /// The theme has no warning color: amber, darker on a light background to stay readable.
  static Color _warning(ThemeData theme) =>
      theme.brightness == Brightness.dark ? Colors.amber.shade300 : Colors.orange.shade800;

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final Widget mark = switch (state) {
      _StepState.done => Icon(
        FluentIcons.checkmark_circle_16_filled,
        key: const ValueKey('done'),
        size: 16,
        color: colors.tertiary,
      ),
      _StepState.working => SizedBox.square(
        key: const ValueKey('working'),
        dimension: 16,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 1.8, color: colors.tertiary),
        ),
      ),
      _StepState.failed => Icon(
        FluentIcons.warning_16_filled,
        key: const ValueKey('warning'),
        size: 16,
        color: _warning(theme),
      ),
      _ => Icon(FluentIcons.circle_16_regular, key: const ValueKey('waiting'), size: 16, color: colors.outline),
    };
    return AnimatedOpacity(
      duration: _motion,
      opacity: state == _StepState.waiting ? .45 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                // drive, not CurvedAnimation: that one listens to the parent until it is disposed,
                // and a transition builder makes one on every rebuild
                scale: animation.drive(CurveTween(curve: Curves.easeOutBack)),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: mark,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: _motion,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: switch (state) {
                    _StepState.failed => _warning(theme),
                    _StepState.working => colors.onSurface,
                    _ => colors.onSurfaceVariant,
                  },
                  fontWeight: state == _StepState.working || state == _StepState.failed
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet line of what the user should know: who sees the report, what is encrypted.
class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}

enum _StepState { waiting, active, working, done, failed }

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.state,
    this.detail,
    this.file,
    this.actions = const [],
  });

  final int number;
  final String title;
  final String? detail;
  final String? file;
  final _StepState state;

  /// [run] is null while an earlier step is still to do: the button shows, disabled.
  final List<({String label, IconData icon, bool primary, Future<void> Function()? run})> actions;

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
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in actions)
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.folder_zip_16_regular, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              // a file name reads left to right in a right-to-left language too
              textDirection: TextDirection.ltr,
              // small: a monospace name is wide, and it should fit the card whole
              style: _mono(
                theme.textTheme.labelSmall,
              )?.copyWith(fontSize: 10, letterSpacing: -.2, height: 1.2, color: colors.onSurfaceVariant),
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
