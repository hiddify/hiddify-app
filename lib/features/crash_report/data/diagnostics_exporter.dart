import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/logger/logger_setup.dart';
import 'package:hiddify/features/crash_report/data/app_diagnostics.dart';
import 'package:hiddify/features/crash_report/data/crash_excerpt.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('Diagnostics');

/// The core keeps the request under its 4 MB receive limit: the app's logs, its log file on
/// desktop, the background core's zip and the rest together stay below [_maxRequestSize].
const _maxRequestSize = 3584 * 1024;
const _maxExtraFileSize = 1 << 20;
const _maxAppLogFileSize = 256 * 1024;
const _maxBackgroundZipSize = 2 << 20;
const _maxDescriptionLength = 4000;
const _maxAppCrashes = 5;
const _maxAppCrashSize = 128 * 1024;

final diagnosticsExporterProvider = Provider<DiagnosticsExporter>(DiagnosticsExporter.new);

/// Builds the zip the user sends after a crash or to report a problem: the app's own core gathers
/// its crash, OOM and power reports, stderr and core log files, the previous run's goroutine
/// snapshots and the sanitized config, and the app adds what the user wrote, what only the app
/// knows ([collectAppDiagnostics]), its in-memory logs, its log file, its own crashes and, when the
/// background core runs in another process with its own working directory, that core's own zip.
class DiagnosticsExporter {
  DiagnosticsExporter(this._ref);

  final Ref _ref;

  Future<File> export({String? description}) async {
    final core = _ref.read(hiddifyCoreServiceProvider).core;
    final extraFiles = <String, List<int>>{};

    final text = description?.trim() ?? '';
    if (text.isNotEmpty) {
      extraFiles['description.txt'] = utf8.encode(
        text.length > _maxDescriptionLength ? text.substring(0, _maxDescriptionLength) : text,
      );
    }

    try {
      final info = await collectAppDiagnostics(_ref);
      extraFiles['app-info.json'] = utf8.encode(const JsonEncoder.withIndent('  ').convert(info));
    } catch (e, stack) {
      _log.warning('collecting the app diagnostics failed: $e', e, stack);
    }

    extraFiles['app-logs.txt'] = _tail(utf8.encode(logRing.records.map(formatRecord).join('\n')), _maxExtraFileSize);

    // the app's errors across runs, the one that crashed among them; the ring above holds this
    // run only
    final file = _ref.read(logPathResolverProvider).appFile();
    try {
      if (file.existsSync()) extraFiles['app.log'] = _tail(await file.readAsBytes(), _maxAppLogFileSize);
    } catch (e) {
      _log.info('the app log file could not be read: $e');
    }

    // the app's own crashes, newest first: a Dart error with its stack, and on Android a Java or
    // Kotlin crash, a native one or an ANR (crash_excerpt.dart)
    final crashes = appCrashFiles(_ref.read(appDirectoriesProvider).requireValue.workingDir).reversed;
    for (final crash in crashes.take(_maxAppCrashes)) {
      try {
        extraFiles['app-crash-${crash.uri.pathSegments.last}'] = _tail(await crash.readAsBytes(), _maxAppCrashSize);
      } catch (e) {
        _log.info('the app crash ${crash.path} could not be read: $e');
      }
    }

    if (!core.isSingleChannel()) {
      // the background core may not run at all: a few seconds, then go on without it
      final options = CallOptions(timeout: const Duration(seconds: 5));
      try {
        final response = await core.bgClient.exportDiagnostics(
          ExportDiagnosticsRequest(inline: true),
          options: options,
        );
        final room = _maxRequestSize - extraFiles.values.fold(0, (sum, content) => sum + content.length);
        if (response.content.length <= _maxBackgroundZipSize && response.content.length <= room) {
          extraFiles['background-core.zip'] = response.content;
        } else {
          _log.info('the background core zip is too large to include: ${response.content.length} bytes');
        }
      } catch (e) {
        _log.info('no diagnostics from the background core: $e');
      }
    }

    final response = await core.fgClient.exportDiagnostics(ExportDiagnosticsRequest(extraFiles: extraFiles));
    _log.info('diagnostics written to ${response.path}');
    return File(response.path);
  }

  /// The newest [max] bytes: the end of a log is what led up to the problem.
  static List<int> _tail(List<int> content, int max) =>
      content.length > max ? content.sublist(content.length - max) : content;
}
