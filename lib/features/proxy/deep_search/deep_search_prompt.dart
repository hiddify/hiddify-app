import 'package:fpdart/fpdart.dart' show unit;
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_search_prompt.g.dart';

/// The proxy whose search for a way through (WARP endpoint, Psiphon route) gave up and that is
/// worth a deep search, from the core's main list; null when there is none.
///
/// It is worth one when it is the unblocker hop, which every connection goes through, or when
/// nothing else works: no proxy the main list holds (each group's pick, lowest's among them, so the
/// best one) answers its ping.
OutboundInfo? deepSearchCandidate(OutboundGroupList list, ChainStatus chain) {
  if (chain.isUnblocker() && list.hasChainHop() && list.chainHop.deepSearchAvailable) return list.chainHop;
  final items = [for (final group in list.items) ...group.items, if (list.hasChainHop()) list.chainHop];
  if (items.any((item) => ConnectionConst.isValidDelay(item.urlTestDelay))) return null;
  return items.where((item) => item.deepSearchAvailable).firstOrNull;
}

/// Offers a deep search when a proxy's search for a way through found nothing in its time (see
/// [deepSearchCandidate]). It asks once for each proxy in a connection: after "Not now" it asks
/// again only once the service has stopped and started again.
@Riverpod(keepAlive: true)
class DeepSearchPrompt extends _$DeepSearchPrompt with AppLogger {
  final _asked = <String>{};
  bool _showing = false;

  @override
  void build() {
    ref.listen(serviceRunningProvider, (previous, next) {
      if (previous != next) _asked.clear();
    });
    ref.listen(mainOutboundsNotifierProvider, (_, next) {
      final list = next.valueOrNull;
      if (list == null || !ref.read(serviceRunningProvider)) return;
      final candidate = deepSearchCandidate(list, ref.read(ConfigOptions.chainStatus));
      if (candidate != null) _offer(candidate);
    });
  }

  Future<void> _offer(OutboundInfo proxy) async {
    if (_showing || _asked.contains(proxy.tag)) return;
    _asked.add(proxy.tag);
    _showing = true;
    final bool accepted;
    try {
      loggy.info("search of [${proxy.tag}] found nothing, offering a deep search");
      accepted = await ref.read(dialogNotifierProvider.notifier).showDeepSearch(name: proxy.name);
    } finally {
      _showing = false;
    }
    if (!accepted || !ref.read(serviceRunningProvider)) return;
    await ref.read(proxyRepositoryProvider).startDeepSearch(proxy.tag).getOrElse((err) {
      loggy.warning("error starting deep search", err);
      final t = ref.read(translationsProvider).requireValue;
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.pages.proxies.deepSearch.failed);
      return unit;
    }).run();
  }
}
