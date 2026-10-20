import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Closed vocabulary: startup reports never accept exception text or metadata.
enum IosStartupStage {
  preparing,
  directories,
  logger,
  appInfo,
  preferences,
  analyticsPreferences,
  analytics,
  preferencesMigration,
  logsRepository,
  loggerController,
  profileRepository,
  translations,
  activeProfile,
  core,
}

enum IosStartupState { loading, ready, failed, timedOut }

enum IosStartupCode { none, unexpected, deadlineExceeded }

class IosStartupAborted implements Exception {
  const IosStartupAborted();
}

/// A watchdog changes presentation, never ownership of an unfinished operation.
class IosStartupGate extends ChangeNotifier {
  IosStartupGate({this.deadline = const Duration(seconds: 15)}) {
    if (deadline <= Duration.zero) throw ArgumentError.value(deadline, 'deadline');
  }

  final Duration deadline;
  IosStartupStage _stage = IosStartupStage.preparing;
  IosStartupState _state = IosStartupState.loading;
  IosStartupCode _code = IosStartupCode.none;
  bool _pending = false;
  bool _disposed = false;
  int _elapsedMs = 0;
  Timer? _watchdog;

  IosStartupStage get stage => _stage;
  IosStartupState get state => _state;
  bool get pending => _pending;

  String get report => jsonEncode({
    'schema': 'wir-ios-startup/v1',
    'stage': _stage.name,
    'state': _state.name,
    'code': _code.name,
    'pending': _pending,
    'elapsed_ms': _elapsedMs,
  });

  Future<T> runStage<T>(IosStartupStage stage, Future<T> Function() initializer) async {
    if (_disposed || _pending || _state != IosStartupState.loading) {
      throw const IosStartupAborted();
    }
    _stage = stage;
    _pending = true;
    _elapsedMs = 0;
    final stopwatch = Stopwatch()..start();
    _watchdog = Timer(deadline, () {
      if (_disposed || !_pending || _state != IosStartupState.loading) return;
      _elapsedMs = deadline.inMilliseconds.clamp(0, 3600000);
      _state = IosStartupState.timedOut;
      _code = IosStartupCode.deadlineExceeded;
      notifyListeners();
    });
    notifyListeners();
    try {
      final value = await initializer();
      if (_disposed || _state != IosStartupState.loading) throw const IosStartupAborted();
      return value;
    } on Object {
      if (!_disposed && _state == IosStartupState.loading) {
        _state = IosStartupState.failed;
        _code = IosStartupCode.unexpected;
      }
      throw const IosStartupAborted();
    } finally {
      _watchdog?.cancel();
      _watchdog = null;
      stopwatch.stop();
      if (_state != IosStartupState.timedOut) {
        _elapsedMs = stopwatch.elapsedMilliseconds.clamp(0, 3600000);
      }
      _pending = false;
      if (!_disposed) notifyListeners();
    }
  }

  void complete() {
    if (_disposed || _pending || _state != IosStartupState.loading) return;
    _state = IosStartupState.ready;
    notifyListeners();
  }

  /// Covers bootstrap failures outside a stage without storing their payload.
  void fail() {
    if (_disposed || _state != IosStartupState.loading) return;
    _state = IosStartupState.failed;
    _code = IosStartupCode.unexpected;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    // The native operation remains owned and awaited by runStage.
    super.dispose();
  }
}

/// Intentionally independent of providers, preferences, routing and analytics.
class IosStartupShell extends StatelessWidget {
  const IosStartupShell({super.key, required this.gate, required this.locale, this.copyReport});

  final IosStartupGate gate;
  final Locale locale;
  final Future<void> Function(String)? copyReport;

  @override
  Widget build(BuildContext context) {
    final russian = locale.languageCode == 'ru';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: gate,
                builder: (context, _) {
                  final failed = gate.state == IosStartupState.failed || gate.state == IosStartupState.timedOut;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!failed) const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        failed
                            ? (russian ? 'Не удалось запустить приложение' : 'Unable to start the app')
                            : (russian ? 'Запускаем приложение…' : 'Starting the app…'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (failed) ...[
                        const SizedBox(height: 16),
                        Text(
                          russian
                              ? 'Скопируйте отчёт, затем полностью закройте приложение и откройте его снова.'
                              : 'Copy the report, then fully close the app and open it again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('ios-startup-copy'),
                          onPressed: () async {
                            try {
                              final report = gate.report;
                              if (copyReport case final copy?) {
                                await copy(report);
                              } else {
                                await Clipboard.setData(ClipboardData(text: report));
                              }
                            } on Object {
                              // Clipboard failure must not replace the recovery screen.
                            }
                          },
                          child: Text(russian ? 'Скопировать отчёт' : 'Copy report'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
