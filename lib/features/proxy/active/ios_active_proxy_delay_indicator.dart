import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class IosActiveProxyDelayIndicator extends ConsumerStatefulWidget {
  const IosActiveProxyDelayIndicator({super.key});

  @override
  ConsumerState<IosActiveProxyDelayIndicator> createState() => _IosActiveProxyDelayIndicatorState();
}

class _IosActiveProxyDelayIndicatorState extends ConsumerState<IosActiveProxyDelayIndicator>
    with WidgetsBindingObserver {
  static const _resumeTimeout = Duration(seconds: 30);

  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  IosProxyMeasurementState? _snapshot;
  int? _retainedDelay;
  _PingSignature? _lastVerifiedSignature;
  _PingSignature? _resumeBaseline;
  Timer? _resumeTimer;
  var _serviceInitialized = false;
  var _serviceConfirmedRunning = false;
  var _requiresFreshOnReconnect = false;
  var _awaitingFreshAfterResume = false;
  var _sawCheckingSinceResume = false;
  var _allowChangedAvailable = false;
  var _refreshPending = false;
  var _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(serviceRunningProvider, _onServiceRunning, fireImmediately: true);
    ref.listenManual(iosActiveProxyMeasurementStateProvider, _onMeasurement, fireImmediately: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == _lifecycle) return;
    setState(() {
      final wasResumed = _lifecycle == AppLifecycleState.resumed;
      _lifecycle = state;
      if (state == AppLifecycleState.resumed) {
        if (!wasResumed && _serviceConfirmedRunning) {
          _beginWaitingForFreshMeasurement(allowChangedAvailable: _lastVerifiedSignature != null);
        }
      } else {
        _cancelResumeTimer();
        _awaitingFreshAfterResume = false;
        _sawCheckingSinceResume = false;
      }
    });
  }

  void _onServiceRunning(AsyncValue<bool>? previous, AsyncValue<bool> next) {
    if (next case AsyncData(value: final running)) {
      setState(() {
        final reconnecting = _serviceInitialized && !_serviceConfirmedRunning && running;
        _serviceInitialized = true;
        _serviceConfirmedRunning = running;
        if (!running) {
          _clearForDisconnect();
          _requiresFreshOnReconnect = true;
        } else if (reconnecting || _requiresFreshOnReconnect) {
          _requiresFreshOnReconnect = false;
          _beginWaitingForFreshMeasurement(allowChangedAvailable: false);
        }
      });
    } else if (next case AsyncError()) {
      setState(() {
        _serviceInitialized = true;
        _serviceConfirmedRunning = false;
        _clearForDisconnect();
        _requiresFreshOnReconnect = true;
      });
    }
  }

  void _onMeasurement(AsyncValue<IosProxyMeasurementState>? previous, AsyncValue<IosProxyMeasurementState> next) {
    final snapshot = next.asData?.value;
    if (!_serviceConfirmedRunning) return;
    if (snapshot == null) {
      if (next case AsyncError()) {
        setState(() {
          _snapshot = const IosProxyMeasurementState(IosProxyMeasurementPhase.idle);
          _clearFailedMeasurement();
        });
      }
      return;
    }

    setState(() {
      _snapshot = snapshot;
      switch (snapshot.phase) {
        case IosProxyMeasurementPhase.checking:
          if (_awaitingFreshAfterResume) _sawCheckingSinceResume = true;
        case IosProxyMeasurementPhase.available:
          final signature = _PingSignature.fromProxy(snapshot.proxy);
          if (signature == null) {
            _clearFailedMeasurement();
          } else if (!_awaitingFreshAfterResume ||
              _sawCheckingSinceResume ||
              (_allowChangedAvailable && signature != _resumeBaseline)) {
            _acceptAvailable(signature);
          }
        case IosProxyMeasurementPhase.failed ||
            IosProxyMeasurementPhase.unavailable ||
            IosProxyMeasurementPhase.timedOut:
          _clearFailedMeasurement();
        case IosProxyMeasurementPhase.idle:
          break;
      }
    });
  }

  void _beginWaitingForFreshMeasurement({required bool allowChangedAvailable}) {
    _cancelResumeTimer();
    _awaitingFreshAfterResume = true;
    _sawCheckingSinceResume = false;
    _allowChangedAvailable = allowChangedAvailable;
    _resumeBaseline = _lastVerifiedSignature;
    _refreshFailed = false;
    _resumeTimer = Timer(_resumeTimeout, () {
      if (!mounted || !_awaitingFreshAfterResume) return;
      setState(() {
        _snapshot = const IosProxyMeasurementState(IosProxyMeasurementPhase.idle);
        _clearFailedMeasurement();
      });
    });
  }

  void _acceptAvailable(_PingSignature signature) {
    _retainedDelay = signature.delay;
    _lastVerifiedSignature = signature;
    _awaitingFreshAfterResume = false;
    _sawCheckingSinceResume = false;
    _allowChangedAvailable = false;
    _resumeBaseline = null;
    _refreshFailed = false;
    _cancelResumeTimer();
  }

  void _clearFailedMeasurement() {
    _retainedDelay = null;
    _lastVerifiedSignature = null;
    _awaitingFreshAfterResume = false;
    _sawCheckingSinceResume = false;
    _allowChangedAvailable = false;
    _resumeBaseline = null;
    _cancelResumeTimer();
  }

  void _clearForDisconnect() {
    _snapshot = null;
    _refreshPending = false;
    _refreshFailed = false;
    _clearFailedMeasurement();
  }

  void _cancelResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }

  Future<void> _refresh() async {
    if (_refreshPending ||
        _awaitingFreshAfterResume ||
        _lifecycle != AppLifecycleState.resumed ||
        !_serviceConfirmedRunning) {
      return;
    }
    setState(() {
      _refreshPending = true;
      _refreshFailed = false;
    });
    try {
      await ref.read(activeProxyNotifierProvider.notifier).urlTest('');
    } on Object {
      if (!mounted) return;
      setState(() => _refreshFailed = true);
    } finally {
      if (mounted) setState(() => _refreshPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_serviceConfirmedRunning) return const SizedBox.shrink();

    final t = ref.watch(translationsProvider).requireValue;
    final blizzard =
        BlizzardPresentation.isActive(context) ||
        (Theme.of(context).extension<BlizzardEligibility>()?.applied ?? false);
    final phase = _snapshot?.phase ?? IosProxyMeasurementPhase.idle;
    final updating = _lifecycle == AppLifecycleState.resumed && _awaitingFreshAfterResume;
    final checking =
        !updating &&
        (_refreshPending || (_lifecycle == AppLifecycleState.resumed && phase == IosProxyMeasurementPhase.checking));
    final delay = _retainedDelay;
    final available =
        delay != null &&
        (_lifecycle != AppLifecycleState.resumed ||
            (!_awaitingFreshAfterResume && phase == IosProxyMeasurementPhase.available));
    final timedOut = phase == IosProxyMeasurementPhase.timedOut;
    final enabled = _lifecycle == AppLifecycleState.resumed && !updating && !checking;
    final label = updating
        ? t.pages.proxies.delay.updating
        : checking
        ? t.pages.proxies.delay.testing
        : available
        ? t.pages.proxies.delay.result(delay: delay)
        : _refreshFailed
        ? t.errors.unexpected
        : timedOut
        ? t.pages.proxies.delay.timeout
        : t.common.unknown;

    return Center(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        onTap: enabled ? _refresh : null,
        child: ExcludeSemantics(
          child: Tooltip(
            message: t.common.update,
            child: InkWell(
              onTap: enabled ? _refresh : null,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!blizzard) ...[const Icon(FluentIcons.wifi_1_24_regular), const Gap(8)],
                    if (checking)
                      const ShimmerSkeleton(width: 48, height: 18)
                    else
                      Text(
                        blizzard && available
                            ? t.pages.proxies.delay.result(delay: delay).replaceFirst(': ', ' ')
                            : updating
                            ? t.pages.proxies.delay.updating
                            : available
                            ? '$delay ms'
                            : _refreshFailed
                            ? t.errors.unexpected
                            : timedOut
                            ? t.common.timeout
                            : t.common.unknown,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (!blizzard && !checking && !updating) ...[const Gap(8), const Icon(Icons.refresh, size: 16)],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelResumeTimer();
    super.dispose();
  }
}

class _PingSignature {
  const _PingSignature({
    required this.delay,
    required this.tag,
    required this.selectedTag,
    required this.timestampSeconds,
    required this.timestampNanos,
  });

  static _PingSignature? fromProxy(OutboundInfo? proxy) {
    if (proxy == null || proxy.urlTestDelay <= 0 || proxy.urlTestDelay > 65000) return null;
    return _PingSignature(
      delay: proxy.urlTestDelay,
      tag: proxy.tag,
      selectedTag: proxy.groupSelectedTag,
      timestampSeconds: proxy.urlTestTime.seconds.toInt(),
      timestampNanos: proxy.urlTestTime.nanos,
    );
  }

  final int delay;
  final String tag;
  final String selectedTag;
  final int timestampSeconds;
  final int timestampNanos;

  @override
  bool operator ==(Object other) =>
      other is _PingSignature &&
      delay == other.delay &&
      tag == other.tag &&
      selectedTag == other.selectedTag &&
      timestampSeconds == other.timestampSeconds &&
      timestampNanos == other.timestampNanos;

  @override
  int get hashCode => Object.hash(delay, tag, selectedTag, timestampSeconds, timestampNanos);
}
