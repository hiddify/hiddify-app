import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:hiddify/core/logger/logger_setup.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _log = appLogger('Diagnostics');

/// The core keeps the request under its 4 MB receive limit: the app's logs and the background
/// core's zip together stay below this.
const _maxExtraFileSize = 1 << 20;
const _maxBackgroundZipSize = 2 << 20;

final diagnosticsExporterProvider = Provider<DiagnosticsExporter>((ref) {
  return DiagnosticsExporter(ref.read(hiddifyCoreServiceProvider));
});

/// Builds the zip the user sends after a crash: the app's own core gathers its crash, OOM and
/// power reports, stderr and core log files, the previous run's goroutine snapshots and the
/// sanitized config, and the app adds its in-memory logs and, when the background core runs in
/// another process with its own working directory, that core's own zip.
class DiagnosticsExporter {
  DiagnosticsExporter(this._service);

  final HiddifyCoreService _service;

  Future<File> export() async {
    final core = _service.core;
    final extraFiles = <String, List<int>>{};

    final appLogs = utf8.encode(logRing.records.map(formatRecord).join('\n'));
    extraFiles['app-logs.txt'] = appLogs.length > _maxExtraFileSize
        ? appLogs.sublist(appLogs.length - _maxExtraFileSize)
        : appLogs;

    if (!core.isSingleChannel()) {
      // the background core may not run at all: a few seconds, then go on without it
      final options = CallOptions(timeout: const Duration(seconds: 5));
      try {
        final response = await core.bgClient.exportDiagnostics(
          ExportDiagnosticsRequest(inline: true),
          options: options,
        );
        if (response.content.length <= _maxBackgroundZipSize) {
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
}
