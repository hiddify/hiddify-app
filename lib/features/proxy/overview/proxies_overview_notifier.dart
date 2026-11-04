import 'dart:async';
import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:fpdart/fpdart.dart' show unit;
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'proxies_overview_notifier.g.dart';

enum ProxiesSort {
  unsorted,
  name,
  delay,
  usage,
  upload,
  download;

  String present(TranslationsEn t) => switch (this) {
    ProxiesSort.unsorted => t.pages.proxies.sortOptions.unsorted,
    ProxiesSort.name => t.pages.proxies.sortOptions.name,
    ProxiesSort.delay => t.pages.proxies.sortOptions.delay,
    ProxiesSort.usage => t.pages.proxies.sortOptions.usage,
    ProxiesSort.upload => t.pages.proxies.sortOptions.upload,
    ProxiesSort.download => t.pages.proxies.sortOptions.download,
  };
}

@Riverpod(keepAlive: true)
class ProxiesSortNotifier extends _$ProxiesSortNotifier with AppLogger {
  late final _pref = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "proxies_sort_mode",
    defaultValue: ProxiesSort.delay,
    mapFrom: ProxiesSort.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  ProxiesSort build() {
    final sortBy = _pref.read();
    loggy.info("sort proxies by: [${sortBy.name}]");
    return sortBy;
  }

  Future<void> update(ProxiesSort value) {
    state = value;
    return _pref.write(value);
  }
}

/// How a proxy row shows its ping: the bare number, or the signal (the logo, lit by the ping).
enum ProxyPingStyle { number, signal }

@Riverpod(keepAlive: true)
class ProxyPingStyleNotifier extends _$ProxyPingStyleNotifier {
  late final _pref = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "proxies_ping_style",
    defaultValue: ProxyPingStyle.number,
    mapFrom: ProxyPingStyle.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  ProxyPingStyle build() => _pref.read();

  Future<void> update(ProxyPingStyle value) {
    state = value;
    return _pref.write(value);
  }

  /// The "Signal style" menu item: number ↔ signal.
  Future<void> toggle() => update(state == ProxyPingStyle.number ? ProxyPingStyle.signal : ProxyPingStyle.number);
}

@riverpod
class ProxiesOverviewNotifier extends _$ProxiesOverviewNotifier with AppLogger {
  @override
  Stream<OutboundGroup?> build() {
    ref.disposeDelay(const Duration(seconds: 15));
    final serviceRunning = ref.watch(serviceRunningProvider);
    // Set up again when the app comes back from the background, on a new gRPC
    // channel; the stream below lives on the old one.
    ref.watch(coreRestartSignalProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    // Reopening the stream also runs build, and that must not drop the pin.
    if (serviceRunning != _lastServiceRunning || sortBy != _lastSortBy) {
      _lastServiceRunning = serviceRunning;
      _lastSortBy = sortBy;
      _pinned = null;
      _resubscribeDelay = _minResubscribeDelay;
    }
    if (!serviceRunning) {
      // Empty data (not Stream.error / not loading): the page shows "Connect to see proxies".
      return Stream.value(null);
    }
    Timer? resubscribe;
    ref.onDispose(() => resubscribe?.cancel());
    return ref
        .watch(proxyRepositoryProvider)
        .watchProxies()
        // Log failures but still emit null so the page leaves the spinner. Filtering them
        // out left AsyncLoading forever when gRPC never delivered a good event.
        .map(
          (event) => event.fold((err) {
            loggy.warning("error receiving proxies", err);
            return null;
          }, (group) => group),
        )
        .startWith(null)
        .doOnData((_) => _resubscribeDelay = _minResubscribeDelay)
        .doOnDone(() {
          // gRPC ends the stream when its connection drops, e.g. once iOS suspends the app.
          // While reopening keeps failing the wait doubles, as for the active proxy.
          loggy.debug("proxies stream ended, resubscribing in $_resubscribeDelay");
          resubscribe = Timer(_resubscribeDelay, ref.invalidateSelf);
          final doubled = _resubscribeDelay * 2;
          _resubscribeDelay = doubled < _maxResubscribeDelay ? doubled : _maxResubscribeDelay;
        })
        .asyncMap((proxies) async => await _sortOutbounds(proxies, sortBy));
  }

  bool? _lastServiceRunning;
  ProxiesSort? _lastSortBy;

  static const _minResubscribeDelay = Duration(seconds: 2);
  static const _maxResubscribeDelay = Duration(seconds: 30);
  Duration _resubscribeDelay = _minResubscribeDelay;

  // Future<List<OutboundGroup>> _sortOutbounds(
  //   List<OutboundGroup> proxies,
  //   ProxiesSort sortBy,
  // ) async {
  //   final groupWithSelected = {
  //     for (final o in proxies) o.tag: o.selected,
  //   };
  //   final sortedProxies = <OutboundGroup>[];
  //   for (final group in proxies) {
  //     final sortedItems = switch (sortBy) {
  //       ProxiesSort.name => group.items.sortedWith((a, b) {
  //           if (a.isGroup && !b.isGroup) return -1;
  //           if (!a.isGroup && b.isGroup) return 1;
  //           return a.tag.compareTo(b.tag);
  //         }),
  //       ProxiesSort.delay => group.items.sortedWith((a, b) {
  //           if (a.isGroup && !b.isGroup) return -1;
  //           if (!a.isGroup && b.isGroup) return 1;

  //           final ai = a.urlTestDelay;
  //           final bi = b.urlTestDelay;
  //           if (ai == 0 && bi == 0) return -1;
  //           if (ai == 0 && bi > 0) return 1;
  //           if (ai > 0 && bi == 0) return -1;
  //           return ai.compareTo(bi);
  //         }),
  //       ProxiesSort.unsorted => group.items,
  //     };
  //     final items = <OutboundInfo>[];
  //     for (final item in sortedItems) {
  //       // if (groupWithSelected.keys.contains(item.tag)) {
  //       //   items.add(item.copyWith(selectedTag: groupWithSelected[item.tag]));
  //       // } else {
  //       items.add(item);
  //       // }
  //     }
  //     group.items.clear();
  //     group.items.addAll(items);
  //     sortedProxies.add(group);
  //   }
  //   return sortedProxies;
  // }

  /// The proxy picked on this page and the row it was in. Cleared by a new connection or sort.
  ({String tag, int index})? _pinned;

  Future<OutboundGroup?> _sortOutbounds(OutboundGroup? proxies, ProxiesSort sortBy) async {
    if (proxies == null) return null;

    final sortedItems = switch (sortBy) {
      ProxiesSort.name => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;
        return a.tag.compareTo(b.tag);
      }),
      // by sortDelay: the real ping, or the one cached from the previous run, which is not shown
      // and orders the untested ones until their real ping arrives; untested last
      ProxiesSort.delay => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;

        final ai = a.sortDelay;
        final bi = b.sortDelay;
        if (ai == 0 && bi == 0) return 0;
        if (ai == 0) return 1;
        if (bi == 0) return -1;
        return ai.compareTo(bi);
      }),
      ProxiesSort.unsorted => proxies.items,
      ProxiesSort.usage => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;
        return (b.upload + b.download).compareTo(a.upload + a.download);
      }),
      // the fastest first; untested and failed ones at the end
      ProxiesSort.upload => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;
        return compareBySpeeds(a, b, uploadFirst: true);
      }),
      ProxiesSort.download => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;
        return compareBySpeeds(a, b, uploadFirst: false);
      }),
    };
    // a copy: sortedItems reads proxies.items, which is cleared below
    final items = sortedItems.toList();
    // The proxy the user picked stays in the row they tapped, and the rest sorts around it. A new
    // ping used to move it, often to the end of the list, right after the tap.
    if (_pinned case (:final tag, :final index) when proxies.selected == tag) {
      final picked = items.indexWhere((item) => item.tag == tag);
      if (picked != -1) items.insert(min(index, items.length - 1), items.removeAt(picked));
    }
    proxies.items.clear();
    proxies.items.addAll(items);
    return proxies;
  }

  // Future<void> changeProxy(String groupTag, String outboundTag) async {
  //   loggy.debug(
  //     "changing proxy, group: [$groupTag] - outbound: [$outboundTag]",
  //   );
  //   if (state case AsyncData(value: final outbounds)) {
  //     await ref.read(hapticServiceProvider.notifier).lightImpact();
  //     await ref.read(proxyRepositoryProvider).selectProxy(groupTag, outboundTag).getOrElse((err) {
  //       loggy.warning("error selecting outbound", err);
  //       throw err;
  //     }).run();
  //     final outboundg = outbounds.where((e) => e.tag == groupTag).firstOrNull;
  //     if (outboundg != null) {
  //       final newselected = outboundg.items.where((e) => e.tag == outboundTag).firstOrNull;
  //       if (newselected != null) {
  //         newselected.isSelected = true;
  //         outboundg.selected = newselected;
  //       }
  //     }
  //     state = AsyncData(
  //       [...outbounds],
  //     ).copyWithPrevious(state);
  //   }
  // }

  Future<void> changeProxy(String groupTag, String outboundTag) async {
    loggy.debug("changing proxy, group: [$groupTag] - outbound: [$outboundTag]");
    if (!state.hasValue) return;
    final outbounds = state.value!;
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    final selected = await ref
        .read(proxyRepositoryProvider)
        .selectProxy(groupTag, outboundTag)
        .map((_) => true)
        .getOrElse((err) {
          loggy.warning("error selecting outbound", err);
          // thrown from a tap, the error reached no one and the tap seemed ignored
          final t = ref.read(translationsProvider).requireValue;
          ref.read(inAppNotificationControllerProvider).showErrorToast(t.pages.proxies.switchFailed);
          return false;
        })
        .run();
    if (!selected) return;
    final row = outbounds.items.indexWhere((e) => e.tag == outboundTag);
    if (row != -1) _pinned = (tag: outboundTag, index: row);
    final newselected = outbounds.items.where((e) => e.tag == outboundTag).firstOrNull;
    if (newselected != null) {
      newselected.isSelected = true;
      outbounds.selected = newselected.tag;
      state = AsyncValue.data(outbounds);
    }
  }

  /// Tests the upload speed of [tag], a proxy, or each proxy of a group, sending the megabytes the
  /// settings name through each.
  Future<void> uploadTest(String tag) async {
    final bytes = uploadTestBytes(ref);
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    await ref.read(proxyRepositoryProvider).uploadTest(tag, bytes).getOrElse((err) {
      loggy.warning("error testing upload", err);
      final t = ref.read(translationsProvider).requireValue;
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.pages.proxies.upload.failed);
      return unit;
    }).run();
  }

  /// Tests the download speed of [tag], a proxy, or each proxy of a group, receiving the megabytes
  /// the settings name through each.
  Future<void> downloadTest(String tag) async {
    final bytes = uploadTestBytes(ref);
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    await ref.read(proxyRepositoryProvider).downloadTest(tag, bytes).getOrElse((err) {
      loggy.warning("error testing download", err);
      final t = ref.read(translationsProvider).requireValue;
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.pages.proxies.upload.failed);
      return unit;
    }).run();
  }

  /// Forgets every speed test result, of this run and the earlier ones kept.
  Future<void> clearSpeedTests() async {
    await ref.read(proxyRepositoryProvider).clearSpeedTests().getOrElse((err) {
      loggy.warning("error clearing the speed tests", err);
      return unit;
    }).run();
  }

  /// Tests the speed of [tag], a proxy, or each proxy of a group, as the speed test is set:
  /// download, upload, or both; the core tests one proxy's two in turn, never at once.
  Future<void> speedTest(String tag) async {
    switch (ref.read(ConfigOptions.speedTestDirection)) {
      case SpeedTestDirection.download:
        await downloadTest(tag);
      case SpeedTestDirection.upload:
        await uploadTest(tag);
      case SpeedTestDirection.both:
        await downloadTest(tag);
        await uploadTest(tag);
    }
  }

  /// Tests the speed of the proxies in the list as the speed test is set: all of them, or the
  /// fastest by their ping up to its limit, one after the other.
  Future<void> speedTestAll() async {
    final group = state.valueOrNull;
    if (group == null) return;
    final proxies = group.items.where((e) => !e.isGroup).toList();
    final limit = ref.read(ConfigOptions.uploadTestLimit);
    if (limit <= 0 || proxies.length <= limit) return speedTest(group.tag);
    for (final tag in fastestProxies(proxies, limit)) {
      await speedTest(tag);
    }
  }

  /// Tests [groupTag]'s proxies, or only the one proxy when given a proxy's tag (a tap on its ping).
  Future<void> urlTest(String groupTag) async {
    loggy.debug("testing group: [$groupTag]");
    if (state case AsyncData()) {
      await ref.read(hapticServiceProvider.notifier).lightImpact();
      await ref.read(proxyRepositoryProvider).urlTest(groupTag).getOrElse((err) {
        loggy.error("error testing group", err);
        throw err;
      }).run();
    }
  }
}

/// Orders proxies by one speed, then by the other speed, then by ping: upload first when
/// [uploadFirst], else download. For each speed, this run's results go first, the faster first, then
/// the ones from an earlier run (cached), the faster first, then none (0) or a failure (-1); a ping
/// that answered goes before one that did not, the lower first.
int compareBySpeeds(OutboundInfo a, OutboundInfo b, {required bool uploadFirst}) {
  // 0: measured in this run, 1: measured in an earlier run, 2: none or failed
  int tier(int speed, bool cached) => speed <= 0 ? 2 : (cached ? 1 : 0);
  int bySpeed(int x, bool xCached, int y, bool yCached) {
    final byTier = tier(x, xCached).compareTo(tier(y, yCached));
    return byTier != 0 ? byTier : (x > 0 ? y.compareTo(x) : 0);
  }

  final up = bySpeed(a.uploadSpeed.toInt(), a.uploadSpeedCached, b.uploadSpeed.toInt(), b.uploadSpeedCached);
  final down = bySpeed(a.downloadSpeed.toInt(), a.downloadSpeedCached, b.downloadSpeed.toInt(), b.downloadSpeedCached);
  final (first, second) = uploadFirst ? (up, down) : (down, up);
  if (first != 0) return first;
  if (second != 0) return second;
  bool answers(int delay) => delay > 0 && delay < 65000;
  final (x, y) = (a.urlTestDelay, b.urlTestDelay);
  if (answers(x) != answers(y)) return answers(x) ? -1 : 1;
  return answers(x) ? x.compareTo(y) : 0;
}

/// The tags of the [count] proxies with the lowest ping that answered.
List<String> fastestProxies(List<OutboundInfo> proxies, int count) {
  final answered = proxies.where((e) => e.urlTestDelay > 0 && e.urlTestDelay < 65000).toList()
    ..sort((a, b) => a.urlTestDelay.compareTo(b.urlTestDelay));
  return answered.take(count).map((e) => e.tag).toList();
}
