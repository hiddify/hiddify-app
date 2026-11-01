import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('CrashReport');

final crashReportNotifierProvider = NotifierProvider<CrashReportNotifier, CrashReport?>(CrashReportNotifier.new);

/// After a crash, the next run offers to send a report: the core archives what the crashed
/// process wrote to stderr, and this asks it for the list and shows the dialog once for every
/// new crash. The name of the newest report the user has seen is kept, so a crash is offered
/// once, whether the user sent it or not.
class CrashReportNotifier extends Notifier<CrashReport?> {
  @override
  CrashReport? build() => null;

  bool _checked = false;

  /// Called once the first frame is up. The core may still be setting up, so the list is asked
  /// for a few times before giving up for this run.
  Future<void> checkOnStart() async {
    if (_checked) return;
    _checked = true;
    if (!ref.read(Preferences.introCompleted)) return;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final reports = await ref.read(hiddifyCoreServiceProvider).core.fgClient.listCrashReports(Empty());
        await _offer(reports.reports);
        return;
      } catch (e) {
        _log.debug('crash reports not available yet: $e');
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }

  Future<void> _offer(List<CrashReport> reports) async {
    final crashes = reports.where((report) => report.isCrash).toList();
    if (crashes.isEmpty) return;
    final newest = crashes.last;
    final seen = ref.read(Preferences.lastSeenCrashReport);
    if (newest.name == seen) return;
    _log.info('new crash report ${newest.name} (${newest.source}), asking to send it');
    state = newest;
    await ref.read(dialogNotifierProvider.notifier).showCrashReport();
    await ref.read(Preferences.lastSeenCrashReport.notifier).update(newest.name);
    state = null;
  }
}
