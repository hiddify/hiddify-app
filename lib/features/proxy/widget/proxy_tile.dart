import 'package:flutter/material.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/widget/country_iso_badge.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(
    this.proxy, {
    super.key,
    required this.selected,
    required this.onTap,
    this.grouped = false,
    this.firstInGroup = false,
    this.lastInGroup = false,
  });

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;
  final bool grouped;
  final bool firstInGroup;
  final bool lastInGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = BlizzardPresentation.themeOf(context);
    final blizzard =
        BlizzardPresentation.isActive(context) || (theme.extension<BlizzardEligibility>()?.applied ?? false);

    final tile = ListTile(
      minTileHeight: blizzard ? 74 : null,
      contentPadding: blizzard ? const EdgeInsets.symmetric(horizontal: 14) : null,
      title: Text(
        proxyDisplayName(proxy),
        overflow: TextOverflow.ellipsis,
        style: PlatformUtils.isWindows ? const TextStyle(fontFamily: FontFamily.emoji) : null,
      ),
      leading: blizzard
          ? CountryIsoBadge(key: ValueKey('country_iso_badge_${proxy.tag}'), countryCode: proxy.ipinfo.countryCode)
          : IPCountryFlag(
              countryCode: proxy.ipinfo.countryCode,
              organization: proxy.ipinfo.org,
              size: 40,
              padding: const EdgeInsetsDirectional.only(end: 8),
            ),
      subtitle: blizzard
          ? Text(proxyServerSubtitle(proxy), maxLines: 1, overflow: TextOverflow.ellipsis)
          : Text.rich(
              TextSpan(
                text: proxy.type,
                children: [
                  if (proxy.isGroup)
                    TextSpan(
                      text: ' (${proxy.groupSelectedTagDisplay.trim()})',
                      style: BlizzardPresentation.themeOf(context).textTheme.bodySmall,
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: blizzard && selected
          ? const Icon(Icons.check_rounded, size: 20, color: BlizzardPalette.accent)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (proxy.urlTestDelay != 0)
                  Text(
                    proxy.urlTestDelay > 65000 ? "×" : proxy.urlTestDelay.toString(),
                    style: TextStyle(color: delayColor(context, proxy.urlTestDelay)),
                  )
                else if (blizzard)
                  const Text('—', style: TextStyle(color: BlizzardPalette.muted)),

                if (proxy.download > 0) Text("⬩", style: BlizzardPresentation.themeOf(context).textTheme.bodySmall),
              ],
            ),

      selected: selected,
      tileColor: blizzard && grouped ? Colors.transparent : null,
      selectedTileColor: blizzard && grouped
          ? Colors.transparent
          : blizzard
          ? const Color(0x1272D1FF)
          : theme.colorScheme.primaryContainer,
      onTap: onTap,
      onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
      horizontalTitleGap: blizzard ? 8 : 4,
      shape: blizzard && grouped ? const RoundedRectangleBorder() : null,
    );

    if (!blizzard || !grouped) return BlizzardPresentation(child: tile);

    final materials = BlizzardMaterials(highContrast: MediaQuery.highContrastOf(context));
    final radius = BorderRadius.vertical(
      top: firstInGroup ? const Radius.circular(BlizzardRadii.card) : Radius.zero,
      bottom: lastInGroup ? const Radius.circular(BlizzardRadii.card) : Radius.zero,
    );
    return BlizzardPresentation(
      child: Material(
        color: selected ? BlizzardPalette.selected : materials.content,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: tile),
            if (!lastInGroup)
              const PositionedDirectional(
                start: 64,
                end: 0,
                bottom: 0,
                child: Divider(height: 1, thickness: 1, color: BlizzardPalette.separator),
              ),
          ],
        ),
      ),
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) {
        < 800 => Colors.lightGreen,
        < 1500 => Colors.orange,
        _ => Colors.redAccent,
      };
    }
    return switch (delay) {
      < 800 => Colors.green,
      < 1500 => Colors.deepOrangeAccent,
      _ => Colors.red,
    };
  }
}
