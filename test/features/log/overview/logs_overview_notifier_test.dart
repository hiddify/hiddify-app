import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/log/data/log_repository.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_failure.dart';
import 'package:hiddify/features/log/overview/logs_overview_notifier.dart';
import 'package:hiddify/features/log/overview/logs_overview_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test("an empty initial log snapshot resolves the loading state", () async {
    final repository = _EmptyLogRepository();
    final container = ProviderContainer(overrides: [logRepositoryProvider.overrideWith((ref) => repository)]);
    addTearDown(container.dispose);
    await container.read(logRepositoryProvider.future);

    final dataState = Completer<LogsOverviewState>();
    final subscription = container.listen(logsOverviewNotifierProvider, (previous, next) {
      if (next.logs.hasValue && !dataState.isCompleted) {
        dataState.complete(next);
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);

    final state = await dataState.future.timeout(const Duration(seconds: 2));

    expect(state.logs.requireValue, isEmpty);
  });
}

class _EmptyLogRepository implements LogRepository {
  @override
  TaskEither<LogFailure, Unit> init() => TaskEither.of(unit);

  @override
  Stream<Either<LogFailure, List<LogEntity>>> watchLogs() => Stream.value(right([]));

  @override
  TaskEither<LogFailure, Unit> clearLogs() => TaskEither.of(unit);
}
