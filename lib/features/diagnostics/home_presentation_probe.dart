import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/diagnostics/home_presentation_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePresentationProbe extends ConsumerStatefulWidget {
  const HomePresentationProbe({
    required this.connectionStatus,
    required this.label,
    required this.translations,
    required this.requiresReconnect,
    required this.delay,
    required this.themePlatform,
    required this.tickersEnabled,
    required this.child,
    super.key,
  });

  final AsyncValue<ConnectionStatus> connectionStatus;
  final String label;
  final TranslationsEn translations;
  final bool? requiresReconnect;
  final int delay;
  final TargetPlatform themePlatform;
  final bool tickersEnabled;
  final Widget child;

  @override
  ConsumerState<HomePresentationProbe> createState() => _HomePresentationProbeState();
}

class _HomePresentationProbeState extends ConsumerState<HomePresentationProbe> {
  HomePresentationSnapshot? _scheduledOrPublished;
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(homePresentationDiagnosticsEnabledProvider);
    if (enabled) {
      try {
        final runtimeIos = ref.watch(homePresentationRuntimeIosProvider);
        final snapshot = HomePresentationSnapshot(
          asyncVariant: switch (widget.connectionStatus) {
            AsyncData() => HomeAsyncVariant.data,
            AsyncLoading() => HomeAsyncVariant.loading,
            AsyncError() => HomeAsyncVariant.error,
            _ => HomeAsyncVariant.data,
          },
          connectionValue: switch (widget.connectionStatus.valueOrNull) {
            Connected() => HomeConnectionValue.connected,
            Connecting() => HomeConnectionValue.connecting,
            Disconnected() => HomeConnectionValue.disconnected,
            Disconnecting() => HomeConnectionValue.disconnecting,
            null => HomeConnectionValue.none,
          },
          labelChoice: _labelChoice(widget.label, widget.translations),
          themePlatform: _themePlatform(widget.themePlatform),
          runtimeIos: runtimeIos,
          reconnect: HomeReconnectValue.fromNullable(widget.requiresReconnect),
          latencyBand: HomeLatencyBand.fromDelay(widget.delay),
          tickersEnabled: widget.tickersEnabled,
          lifecycleState: _lifecycleState(WidgetsBinding.instance.lifecycleState),
        );
        if (snapshot != _scheduledOrPublished) {
          _scheduledOrPublished = snapshot;
          final generation = ++_generation;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || generation != _generation) return;
            try {
              if (ref.read(homePresentationSnapshotProvider) != snapshot) {
                ref.read(homePresentationSnapshotProvider.notifier).state = snapshot;
              }
            } on Object {
              // Diagnostics must never affect the Home screen.
            }
          });
        }
      } on Object {
        // Diagnostics must never affect the Home screen.
      }
    }
    return widget.child;
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

HomeLabelChoice _labelChoice(String label, TranslationsEn t) {
  if (label.isEmpty) return HomeLabelChoice.empty;
  if (label == t.connection.connected) return HomeLabelChoice.connected;
  if (label == t.connection.connecting) return HomeLabelChoice.connecting;
  if (label == t.connection.tapToConnect) return HomeLabelChoice.disconnected;
  if (label == t.connection.disconnecting) return HomeLabelChoice.disconnecting;
  if (label == t.connection.reconnect) return HomeLabelChoice.reconnect;
  return HomeLabelChoice.unknown;
}

HomeThemePlatform _themePlatform(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => HomeThemePlatform.android,
  TargetPlatform.fuchsia => HomeThemePlatform.fuchsia,
  TargetPlatform.iOS => HomeThemePlatform.iOS,
  TargetPlatform.linux => HomeThemePlatform.linux,
  TargetPlatform.macOS => HomeThemePlatform.macOS,
  TargetPlatform.windows => HomeThemePlatform.windows,
};

HomeLifecycleState _lifecycleState(AppLifecycleState? state) => switch (state) {
  AppLifecycleState.resumed => HomeLifecycleState.resumed,
  AppLifecycleState.inactive => HomeLifecycleState.inactive,
  AppLifecycleState.paused => HomeLifecycleState.paused,
  AppLifecycleState.hidden => HomeLifecycleState.hidden,
  AppLifecycleState.detached => HomeLifecycleState.detached,
  null => HomeLifecycleState.unknown,
};
