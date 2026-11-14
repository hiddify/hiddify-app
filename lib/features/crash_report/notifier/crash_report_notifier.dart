import 'dart:async';

import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/crash_report/data/crash_excerpt.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('CrashReport');

final crashReportNotifierProvider = NotifierProvider<CrashReportNotifier, CrashReport?>(CrashReportNotifier.new);

/// After a crash, the next run offers to send a report: the core archives what the crashed
/// process wrote to stderr, the app keeps its own crashes in app_crashes/ (crash_excerpt.dart),
/// and this shows the dialog once for the newest of them all. The name of the newest report the
/// user has seen is kept, so a crash is offered once, whether the user sent it or not.
/// On desktop the app starts the core's process again when it crashes, so a crash there is also
/// offered as soon as the core has come back, without waiting for the next run.
class CrashReportNotifier extends Notifier<CrashReport?> {
  @override
  CrashReport? build() {
    final crashes = ref.read(hiddifyCoreServiceProvider).core.coreCrashes.listen((_) => unawaited(_checkAfterCrash()));
    ref.onDispose(crashes.cancel);
    return null;
  }

  bool _checked = false;
  bool _offering = false;

  Future<void> _checkAfterCrash() async {
    if (!ref.read(Preferences.introCompleted)) return;
    try {
      final reports = await ref.read(hiddifyCoreServiceProvider).core.fgClient.listCrashReports(Empty());
      await _offer(reports.reports);
    } catch (e) {
      _log.debug('crash reports not available after the crash: $e');
    }
  }

  /// Called once the first frame is up. The core may still be setting up, so the list is asked
  /// for a few times before giving up for this run.
  Future<void> checkOnStart() async {
    if (_checked) return;
    _checked = true;
    if (!ref.read(Preferences.introCompleted)) return;
    final app = appCrashReports(ref.read(appDirectoriesProvider).requireValue.workingDir);
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final reports = await ref.read(hiddifyCoreServiceProvider).core.fgClient.listCrashReports(Empty());
        await _offer([...reports.reports, ...app]);
        return;
      } catch (e) {
        _log.debug('crash reports not available yet: $e');
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
    // the core never answered: the app's own crashes are still worth offering
    await _offer(app);
  }

  Future<void> _offer(List<CrashReport> reports) async {
    // one dialog at a time: a crash while it is open is offered after it, by the next check
    if (_offering) return;
    final crashes = reports.where((report) => report.isCrash).toList()
      ..sort((a, b) => a.crashedAt.compareTo(b.crashedAt));
    if (crashes.isEmpty) return;
    final newest = crashes.last;
    final key = _seenKey(newest);
    if (key == ref.read(Preferences.lastSeenCrashReport)) return;
    _log.info('new crash report ${newest.name} (${newest.source}), asking to send it');
    _offering = true;
    try {
      state = newest;
      await ref.read(dialogNotifierProvider.notifier).showCrashReport();
      await ref.read(Preferences.lastSeenCrashReport.notifier).update(key);
    } finally {
      state = null;
      _offering = false;
    }
  }

  /// An archived report is named by its time, but a live stderr file (an engine that crashed and
  /// has not started again) keeps its name from one crash to the next, so its time tells them apart.
  static String _seenKey(CrashReport report) =>
      report.source == report.name ? '${report.name}@${report.crashedAt}' : report.name;
}
