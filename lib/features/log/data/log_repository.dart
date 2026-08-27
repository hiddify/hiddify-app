import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/log/data/log_parser.dart';
import 'package:hiddify/features/log/data/log_path_resolver.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_failure.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';

abstract interface class LogRepository {
  TaskEither<LogFailure, Unit> init();
  Stream<Either<LogFailure, List<LogEntity>>> watchLogs();
  TaskEither<LogFailure, Unit> clearLogs();
}

class LogRepositoryImpl with ExceptionHandler, InfraLogger implements LogRepository {
  LogRepositoryImpl({required this.singbox, required this.logPathResolver});

  final HiddifyCoreService singbox;
  final LogPathResolver logPathResolver;

  @override
  TaskEither<LogFailure, Unit> init() {
    return exceptionHandler(() async {
      if (!kIsWeb) {
        if (!await logPathResolver.directory.exists()) {
          await logPathResolver.directory.create(recursive: true);
        }
        // The files are no longer emptied at startup. A crash leaves its
        // evidence in the previous run's lines, and wiping on launch threw
        // exactly that away. Growth is bounded by the size cap in the sink
        // instead. The engine creates and manages its own file.
        if (!await logPathResolver.appFile().exists()) {
          await logPathResolver.appFile().create(recursive: true);
        }
      }
      return right(unit);
    }, LogUnexpectedFailure.new);
  }

  @override
  Stream<Either<LogFailure, List<LogEntity>>> watchLogs() {
    return singbox
        .watchLogs(logPathResolver.coreFile().path)
        .map((event) => event.map(LogParser.parseLogProto).toList())
        .handleExceptions((error, stackTrace) {
          loggy.warning("error watching logs", error, stackTrace);
          return LogFailure.unexpected(error, stackTrace);
        });
  }

  @override
  TaskEither<LogFailure, Unit> clearLogs() {
    return exceptionHandler(() => singbox.clearLogs().mapLeft(LogFailure.unexpected).run(), LogFailure.unexpected);
  }
}
