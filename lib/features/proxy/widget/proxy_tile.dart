import 'package:flutter/material.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(this.proxy, {super.key, required this.selected, required this.onTap});

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = BlizzardPresentation.themeOf(context);
    final blizzard =
        BlizzardPresentation.isActive(context) || (theme.extension<BlizzardEligibility>()?.applied ?? false);

    return BlizzardPresentation(
      child: ListTile(
        minTileHeight: blizzard ? 74 : null,
        contentPadding: blizzard ? const EdgeInsets.symmetric(horizontal: 14) : null,
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          proxy.tagDisplay,
          overflow: TextOverflow.ellipsis,
          style: PlatformUtils.isWindows ? const TextStyle(fontFamily: FontFamily.emoji) : null,
        ),
        leading: IPCountryFlag(
          countryCode: proxy.ipinfo.countryCode,
          organization: proxy.ipinfo.org,
          size: blizzard ? 40 : 40,
          padding: blizzard ? EdgeInsets.zero : const EdgeInsetsDirectional.only(end: 8),
        ),
        subtitle: Text.rich(
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
        selectedTileColor: blizzard ? const Color(0x1272D1FF) : theme.colorScheme.primaryContainer,
        onTap: onTap,
        onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
        horizontalTitleGap: blizzard ? 8 : 4,
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
