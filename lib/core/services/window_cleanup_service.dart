import 'dart:async';

import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Centralized window cleanup logic to be used before hiding/quitting the app.
class WindowCleanupService {
  static final WindowCleanupService _instance = WindowCleanupService._internal();
  factory WindowCleanupService() => _instance;
  WindowCleanupService._internal();

  ProviderContainer? _container;

  void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  /// Perform cleanup tasks safely, without throwing.
  Future<void> performSafeCleanup() async {
    try {
      if (_container == null) return;
      // Abort/Disconnect active connection gracefully
      await _container!
          .read(connectionNotifierProvider.notifier)
          .abortConnection()
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {
      // Best-effort cleanup only
    }
  }
}


