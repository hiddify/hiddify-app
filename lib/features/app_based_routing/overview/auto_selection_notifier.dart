import 'package:hiddify/features/app_based_routing/data/auto_selection_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_selection_notifier.g.dart';

@Riverpod(keepAlive: true)
class AutoSelectionLoading extends _$AutoSelectionLoading {
  int _running = 0;

  @override
  bool build() => false;

  /// Loading lasts until the last run ends: a mode change can start one while another still loads.
  Future<void> doAsync(Future<void> Function() operation) async {
    _running++;
    state = true;
    try {
      await operation();
    } finally {
      if (--_running == 0) state = false;
    }
  }
}

/// Why the last auto selection did not give a list. Null when it worked or was not tried.
@Riverpod(keepAlive: true)
class AutoSelectionIssue extends _$AutoSelectionIssue {
  @override
  AutoSelectionResult? build() => null;

  void update(AutoSelectionResult? result) => state = result == AutoSelectionResult.success ? null : result;
}
