import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/log/data/log_parser.dart';
import 'package:hiddify/features/log/data/log_path_resolver.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_failure.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:watcher/watcher.dart';

abstract interface class LogRepository {
  TaskEither<LogFailure, Unit> init();
  Stream<Either<LogFailure, List<LogEntity>>> watchLogs();
  TaskEither<LogFailure, Unit> clearLogs();
}

class LogRepositoryImpl
    with ExceptionHandler, InfraLogger
    implements LogRepository {
  LogRepositoryImpl({
    required this.singbox,
    required this.logPathResolver,
  });

  final SingboxService singbox;
  final LogPathResolver logPathResolver;

  // local app.log watcher (separate state per repository instance)
  final _appLogBuffer = <String>[];
  int _appLogFilePosition = 0;

  Stream<List<LogEntity>> _watchAppLogs() async* {
    final file = logPathResolver.appFile();
    yield await _readAppLogFile(file).then((_) => _appLogBuffer.map(LogParser.parseApp).toList());
    yield* Watcher(file.path, pollingDelay: const Duration(seconds: 1)).events.asyncMap((event) async {
      if (event.type == ChangeType.MODIFY) {
        await _readAppLogFile(file);
      }
      return _appLogBuffer.map(LogParser.parseApp).toList();
    });
  }

  Future<List<String>> _readAppLogFile(File file) async {
    if (_appLogFilePosition == 0 && file.lengthSync() == 0) return _appLogBuffer;
    final content = await file.openRead(_appLogFilePosition).transform(utf8.decoder).join();
    _appLogFilePosition = file.lengthSync();
    final lines = const LineSplitter().convert(content);
    if (lines.length > 300) {
      lines.removeRange(0, lines.length - 300);
    }
    for (final line in lines) {
      _appLogBuffer.add(line);
      if (_appLogBuffer.length > 300) {
        _appLogBuffer.removeAt(0);
      }
    }
    return _appLogBuffer;
  }

  @override
  TaskEither<LogFailure, Unit> init() {
    return exceptionHandler(
      () async {
        if (!await logPathResolver.directory.exists()) {
          await logPathResolver.directory.create(recursive: true);
        }
        if (await logPathResolver.coreFile().exists()) {
          await logPathResolver.coreFile().writeAsString("");
        } else {
          await logPathResolver.coreFile().create(recursive: true);
        }
        if (await logPathResolver.appFile().exists()) {
          await logPathResolver.appFile().writeAsString("");
        } else {
          await logPathResolver.appFile().create(recursive: true);
        }
        return right(unit);
      },
      LogUnexpectedFailure.new,
    );
  }

  @override
  Stream<Either<LogFailure, List<LogEntity>>> watchLogs() {
    final core$ = singbox
        .watchLogs(logPathResolver.coreFile().path)
        .map((event) => event.map(LogParser.parseSingbox).toList())
        .handleExceptions(
      (error, stackTrace) {
        loggy.warning("error watching core logs", error, stackTrace);
        return LogFailure.unexpected(error, stackTrace);
      },
    );

    final app$ = _watchAppLogs().handleExceptions(
      (error, stackTrace) {
        loggy.warning("error watching app logs", error, stackTrace);
        return LogFailure.unexpected(error, stackTrace);
      },
    );

    return Rx.combineLatest2(
      core$,
      app$,
      (Either<LogFailure, List<LogEntity>> a, Either<LogFailure, List<LogEntity>> b) {
        return a.fold(
          (l) => left(l),
          (coreLogs) => b.fold(
            (l) => left(l),
            (appLogs) => right(<LogEntity>[...appLogs, ...coreLogs]),
          ),
        );
      },
    );
  }

  @override
  TaskEither<LogFailure, Unit> clearLogs() {
    return exceptionHandler(
      () => singbox.clearLogs().mapLeft(LogFailure.unexpected).run(),
      LogFailure.unexpected,
    );
  }
}
