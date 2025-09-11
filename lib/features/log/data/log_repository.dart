import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/log/data/log_parser.dart';
import 'package:hiddify/features/log/data/log_path_resolver.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_failure.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';

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
    return singbox
        .watchLogs(logPathResolver.coreFile().path)
        .map((event) => event.map(LogParser.parseSingbox).toList())
        .handleExceptions(
      (error, stackTrace) {
        loggy.warning("error watching logs", error, stackTrace);
        return LogFailure.unexpected(error, stackTrace);
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
