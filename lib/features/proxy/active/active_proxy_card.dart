import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ios_active_proxy_measurement_providers.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyFooter extends ConsumerWidget with InfraLogger {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );

    final legacyProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final ios = Theme.of(context).platform == TargetPlatform.iOS && ref.watch(iosActiveProxyMeasurementEnabledProvider);
    final activeProxy = ios ? ref.watch(iosActiveProxyMeasurementStateProvider).asData?.value.proxy : legacyProxy;
    final t = ref.watch(translationsProvider).requireValue;

    if (connectionState != const Connected()) {
      return const SizedBox.shrink();
    }
    if (activeProxy == null) {
      if (!ios) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: () => context.goNamed('proxies'),
          icon: const Icon(Icons.public),
          label: Text(t.pages.proxies.title),
        ),
      );
    }

    final theme = Theme.of(context);
    final blizzard = BlizzardPresentation.isActive(context);
    final materials = BlizzardMaterials(highContrast: MediaQuery.highContrastOf(context));

    // Handle URL test in a way that won't trigger during build
    Future<void> handleUrlTest() async {
      try {
        if (!context.mounted) return;
        await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
      } catch (e) {
        // Handle error here
        loggy.error("Error during URL test: $e");
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: blizzard ? materials.content : theme.colorScheme.background.withOpacity(1),
        border: blizzard ? Border.all(color: materials.edge) : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.secondary.withOpacity(.21), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.goNamed('proxies');
        },
        child: Row(
          children: [
            InkWell(
              onTap: () async {
                await handleUrlTest();
                await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: activeProxy);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IPCountryFlag(
                  countryCode: activeProxy.ipinfo.countryCode,
                  organization: activeProxy.ipinfo.org,
                  size: 48,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: t.pages.proxies.activeProxy,
                    child: Text(
                      // getRealOutboundTag(activeProxy),
                      activeProxy.tagDisplay,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        flex: blizzard ? 3 : 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (activeProxy.ipinfo.ip.isNotEmpty)
                              Flexible(
                                flex: blizzard ? 1 : 0,
                                child: IPText(ip: activeProxy.ipinfo.ip, onLongPress: handleUrlTest, constrained: true),
                              )
                            else
                              Flexible(
                                flex: blizzard ? 1 : 0,
                                child: UnknownIPText(text: t.pages.proxies.unknownIp, onTap: handleUrlTest),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        flex: blizzard ? 1 : 0,
                        child: Text(
                          // getRealOutboundTag(activeProxy),
                          activeProxy.type,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(blizzard ? 8 : 16.0),
              child: Icon(
                Icons.arrow_forward_ios,
                size: blizzard ? 16 : null,
                color: blizzard ? theme.colorScheme.primary : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getRealOutboundTag(OutboundInfo group) {
  var tag = group.tagDisplay;
  if (group.groupSelectedTagDisplay != "" && group.groupSelectedTagDisplay != tag) {
    tag = "$tag → ${group.groupSelectedTagDisplay}";
  }
  return tag;
}

// class _StatsColumn extends HookConsumerWidget {
//   const _StatsColumn();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;
//     final stats = ref.watch(statsNotifierProvider).value;

//     return Directionality(
//       textDirection: TextDirection.values[(Directionality.of(context).index + 1) % TextDirection.values.length],
//       child: Flexible(
//         child: Column(
//           children: [
//             _InfoProp(
//               icon: FluentIcons.arrow_bidirectional_up_down_20_regular,
//               text: (stats?.downlinkTotal ?? 0).size(),
//               semanticLabel: t.stats.totalTransferred,
//             ),
//             const Gap(8),
//             _InfoProp(
//               icon: FluentIcons.arrow_download_20_regular,
//               text: (stats?.downlink ?? 0).speed(),
//               semanticLabel: t.stats.speed,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _InfoProp extends StatelessWidget {
//   const _InfoProp({
//     required this.icon,
//     required this.text,
//     this.semanticLabel,
//   });

//   final IconData icon;
//   final String text;
//   final String? semanticLabel;

//   @override
//   Widget build(BuildContext context) {
//     return Semantics(
//       label: semanticLabel,
//       child: Row(
//         children: [
//           Icon(icon),
//           const Gap(8),
//           Flexible(
//             child: Text(
//               text,
//               style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: FontFamily.emoji),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
