import 'dart:async';

import 'package:hiddify/core/observability/better_stack_log_printer.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';

/// Follows new typed events only. Restored local history is never uploaded.
final class RemoteDiagnosticSubscription {
  RemoteDiagnosticSubscription(SafeDiagnosticJournal journal, BetterStackLogPrinter remote) {
    var lastSequence = journal.events.isEmpty ? 0 : journal.events.last.sequence;
    _subscription = journal.changes.listen((snapshot) {
      for (final event in snapshot) {
        if (event.sequence <= lastSequence) continue;
        lastSequence = event.sequence;
        remote.addDiagnostic(event);
      }
    });
  }

  late final StreamSubscription<Object?> _subscription;

  void dispose() => unawaited(_subscription.cancel());
}
