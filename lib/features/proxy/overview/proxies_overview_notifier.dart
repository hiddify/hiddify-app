import 'dart:async';

import 'package:dartx/dartx.dart';

import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'proxies_overview_notifier.g.dart';

enum ProxiesSort {
  unsorted,
  name,
  delay;

  String present(TranslationsEn t) => switch (this) {
        ProxiesSort.unsorted => t.proxies.sortOptions.unsorted,
        ProxiesSort.name => t.proxies.sortOptions.name,
        ProxiesSort.delay => t.proxies.sortOptions.delay,
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

@riverpod
class ProxiesOverviewNotifier extends _$ProxiesOverviewNotifier with AppLogger {
  @override
  Stream<List<ProxyGroupEntity>> build() async* {
    ref.disposeDelay(const Duration(seconds: 15));
    final serviceRunning = await ref.watch(serviceRunningProvider.future);
    if (!serviceRunning) {
      throw const ServiceNotRunning();
    }
    final sortBy = ref.watch(proxiesSortProvider);
    yield* ref
        .watch(proxyRepositoryProvider)
        .watchProxies()
        .throttleTime(
          const Duration(milliseconds: 100),
          leading: false,
          trailing: true,
        )
        .map(
          (event) => event.getOrElse(
            (err) {
              loggy.warning("error receiving proxies", err);
              throw err;
            },
          ),
        )
        .map((proxies) => _sortOutbounds(proxies, sortBy));
  }

  List<ProxyGroupEntity> _sortOutbounds(
    List<ProxyGroupEntity> proxies,
    ProxiesSort sortBy,
  ) {
    final groupWithSelected = {
      for (final o in proxies) o.tag: o.selected,
    };
    final sortedProxies = <ProxyGroupEntity>[];
    for (final group in proxies) {
      final sortedItems = switch (sortBy) {
        ProxiesSort.name => group.items.sortedWith((a, b) {
            if (a.type.isGroup && !b.type.isGroup) return -1;
            if (!a.type.isGroup && b.type.isGroup) return 1;
            return a.tag.compareTo(b.tag);
          }),
        ProxiesSort.delay => group.items.sortedWith((a, b) {
            if (a.type.isGroup && !b.type.isGroup) return -1;
            if (!a.type.isGroup && b.type.isGroup) return 1;

            final ai = a.urlTestDelay;
            final bi = b.urlTestDelay;
            if (ai == 0 && bi == 0) return -1;
            if (ai == 0 && bi > 0) return 1;
            if (ai > 0 && bi == 0) return -1;
            return ai.compareTo(bi);
          }),
        ProxiesSort.unsorted => group.items,
      };
      final items = <ProxyItemEntity>[];
      for (final item in sortedItems) {
        if (groupWithSelected.keys.contains(item.tag)) {
          items.add(item.copyWith(selectedTag: groupWithSelected[item.tag]));
        } else {
          items.add(item);
        }
      }
      sortedProxies.add(group.copyWith(items: items));
    }
    return sortedProxies;
  }

  Future<void> changeProxy(String groupTag, String outboundTag) async {
    loggy.debug(
      "changing proxy, group: [$groupTag] - outbound: [$outboundTag]",
    );
    if (state case AsyncData(value: final outbounds)) {
      await ref.read(hapticServiceProvider.notifier).lightImpact();
      await ref.read(proxyRepositoryProvider).selectProxy(groupTag, outboundTag).getOrElse((err) {
        loggy.warning("error selecting outbound", err);
        throw err;
      }).run();
      state = AsyncData(
        [
          ...outbounds.map(
            (e) => e.tag == groupTag ? e.copyWith(selected: outboundTag) : e,
          ),
        ],
      );
    }
  }

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
