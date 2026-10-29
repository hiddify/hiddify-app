import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/utils/throttler.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart' hide IpInfo;
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'active_proxy_notifier.g.dart';

String? _ipinfoUrlFromHeaders(Map<String, dynamic>? headers) {
  final value = headers?['ipinfo-url'];
  if (value is! String) return null;
  final url = value.trim();
  return isUrl(url) ? url : null;
}

@riverpod
class IpInfoNotifier extends _$IpInfoNotifier with AppLogger {
  @override
  Future<IpInfo> build() async {
    ref.disposeDelay(const Duration(seconds: 20));
    final cancelToken = CancelToken();
    Timer? timer;
    ref.onDispose(() {
      loggy.debug("disposing");
      cancelToken.cancel();
      timer?.cancel();
    });

    ref.listen(serviceRunningProvider, (_, next) => _idle = false);

    final autoCheck = ref.watch(Preferences.autoCheckIp);
    final serviceRunning = ref.watch(serviceRunningProvider);
    // loggy.debug(
    //   "idle? [$_idle], forced? [$_forceCheck], connected? [$serviceRunning]",
    // );
    if (!_forceCheck && !serviceRunning) {
      throw const ServiceNotRunning();
    } else if ((_idle && !_forceCheck) || (!_forceCheck && serviceRunning && !autoCheck)) {
      throw const UnknownIp();
    }

    _forceCheck = false;
    final customIpInfoUrl = _ipinfoUrlFromHeaders(
      ref.watch(activeProfileProvider).valueOrNull?.populatedHeaders,
    );
    final info = await ref
        .watch(proxyRepositoryProvider)
        .getCurrentIpInfo(cancelToken, customIpInfoUrl: customIpInfoUrl)
        .getOrElse((err) {
          loggy.warning("error getting proxy ip info", err, StackTrace.current);
          // throw err; //hiddify: remove exception to be logged
          throw const UnknownIp();
        })
        .run();

    timer = Timer(const Duration(seconds: 10), () {
      loggy.debug("entering idle mode");
      _idle = true;
      ref.invalidateSelf();
    });

    return info;
  }

  bool _idle = false;
  bool _forceCheck = false;

  Future<void> refresh() async {
    if (state.isLoading) return;
    loggy.debug("refreshing");
    state = const AsyncLoading();
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    _forceCheck = true;
    ref.invalidateSelf();
  }
}

/// The core's main proxy list: each group with only the item it selected, and the active chain
/// hop. The active proxy and the home proxy card share this one stream.
@Riverpod(keepAlive: true)
class MainOutboundsNotifier extends _$MainOutboundsNotifier with AppLogger {
  @override
  Stream<OutboundGroupList> build() {
    // ref.disposeDelay(const Duration(seconds: 20));
    final serviceRunning = ref.watch(serviceRunningProvider);
    // The core is set up again when the app comes back from the background, on
    // a new gRPC channel. The stream below lives on the old one, so it has to be
    // opened again; serviceRunning stays true throughout and would not do it.
    ref.watch(coreRestartSignalProvider);
    if (serviceRunning != _lastServiceRunning) {
      _lastServiceRunning = serviceRunning;
      _wasConnectionValid = false;
      _resubscribeDelay = _minResubscribeDelay;
    }
    if (!serviceRunning) {
      // Emit an empty list, so the active proxy becomes an empty outbound (delay 0) and
      // disconnect clears the last ping. Stream.error alone kept the previous AsyncData via
      // copyWithPrevious, so the tray/dock stayed green and the UI still showed the old ms value.
      return Stream.value(OutboundGroupList());
    }
    Timer? resubscribe;
    ref.onDispose(() => resubscribe?.cancel());
    var received = 0;
    return _proxyRepo
        .watchActiveProxies()
        // A failed stream used to become an empty outbound with no delay, which the
        // connection button shows as a yellow "connecting" that never clears. The
        // tunnel itself is fine, so the last known outbound stays and the stream is
        // opened again below.
        .where((event) => event.isRight())
        .map((event) => event.getOrElse((l) => OutboundGroupList()))
        .doOnData((list) {
          // The first event is the core service's cached list, sent even when
          // the call fails; only a later one shows the stream really works.
          if (++received > 1) _resubscribeDelay = _minResubscribeDelay;
          _handleConnectionHaptic(_activeOf(list, ref.read(ConfigOptions.chainStatus)).urlTestDelay);
        })
        .doOnDone(() {
          // gRPC ends the stream when its connection drops, e.g. once iOS suspends
          // the app or the Mac sleeps. Nothing else would ever open it again.
          // While it keeps failing the wait doubles, so a core that stays
          // unreachable is not retried, and logged as an error, every 2 seconds.
          loggy.debug("active proxy stream ended, resubscribing in $_resubscribeDelay");
          resubscribe = Timer(_resubscribeDelay, ref.invalidateSelf);
          final doubled = _resubscribeDelay * 2;
          _resubscribeDelay = doubled < _maxResubscribeDelay ? doubled : _maxResubscribeDelay;
        });
  }

  ProxyRepository get _proxyRepo => ref.read(proxyRepositoryProvider);

  /// Whether the tunnel currently has a valid ping. Tracked so haptics fire only
  /// on real transitions (connect / timeout / recover), not on every ping update.
  bool _wasConnectionValid = false;
  bool? _lastServiceRunning;

  static const _minResubscribeDelay = Duration(seconds: 2);
  static const _maxResubscribeDelay = Duration(seconds: 30);
  Duration _resubscribeDelay = _minResubscribeDelay;

  void _handleConnectionHaptic(int urlTestDelay) {
    final isValid = ConnectionConst.isValidDelay(urlTestDelay);
    if (isValid == _wasConnectionValid) return;
    _wasConnectionValid = isValid;
    final haptic = ref.read(hapticServiceProvider.notifier);
    if (isValid) {
      // connected successfully, or recovered after a timeout
      haptic.heavyImpact();
    } else {
      // still connected but the ping timed out → medium then heavy
      haptic.mediumImpact();
      Future.delayed(const Duration(milliseconds: 150), haptic.heavyImpact);
    }
  }
}

/// The outbound the traffic leaves through, whose ping tells whether the whole path works: with
/// extra security the hop (it dials through the user's pick), else the pick, the main group's only item.
OutboundInfo _activeOf(OutboundGroupList list, ChainStatus chain) => chain.isExtraSecurity() && list.hasChainHop()
    ? list.chainHop
    : list.items.firstOrNull?.items.firstOrNull ?? OutboundInfo();

@Riverpod(keepAlive: true)
class ActiveProxyNotifier extends _$ActiveProxyNotifier with AppLogger {
  // Follows the shared list state for state, loading and error alike, so readers see what
  // they saw when this notifier owned the stream.
  @override
  AsyncValue<OutboundInfo> build() {
    final chain = ref.watch(ConfigOptions.chainStatus);
    return ref.watch(mainOutboundsNotifierProvider).whenData((list) => _activeOf(list, chain));
  }

  final _urlTestThrottler = Throttler(const Duration(seconds: 1));

  Future<void> urlTest(String? groupTag_) async {
    final groupTag = groupTag_ ?? "";
    _urlTestThrottler(() async {
      if (state case AsyncData()) {
        await ref.read(hapticServiceProvider.notifier).lightImpact();
        await ref.read(proxyRepositoryProvider).urlTest(groupTag).getOrElse((err) {
          loggy.warning("error testing group", err);
          throw err;
        }).run();
      }
    });
  }
}

/// What the home proxy card shows; null until the core has sent a message.
@Riverpod(keepAlive: true)
ActiveProxyCardData? activeProxyCard(Ref ref) {
  final list = ref.watch(mainOutboundsNotifierProvider).valueOrNull;
  if (list == null) return null;
  final chain = ref.watch(ConfigOptions.chainStatus);
  return ActiveProxyCardData.from(
    list,
    chain: chain,
    hopMode: ref.watch(chain.isUnblocker() ? ConfigOptions.unblockerMode : ConfigOptions.extraSecurityMode),
  );
}
