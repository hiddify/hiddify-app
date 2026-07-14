import 'package:flutter/material.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
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
    final nova = NovaThemeData.of(context);

    return ListTile(
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        proxy.tagDisplay,
        overflow: TextOverflow.ellipsis,
        style: PlatformUtils.isWindows ? const TextStyle(fontFamily: FontFamily.emoji) : null,
      ),
      leading: IPCountryFlag(
        countryCode: proxy.ipinfo.countryCode,
        organization: proxy.ipinfo.org,
        size: 40,
        padding: const EdgeInsetsDirectional.only(end: 8),
      ),
      subtitle: Text.rich(
        TextSpan(
          text: proxy.type,
          children: [
            if (proxy.isGroup)
              TextSpan(
                text: ' (${proxy.groupSelectedTagDisplay.trim()})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (proxy.urlTestDelay != 0)
                Text(
                  proxy.urlTestDelay > 65000 ? "×" : proxy.urlTestDelay.toString(),
                  style: TextStyle(color: delayColor(proxy.urlTestDelay)),
                ),

              if (proxy.download > 0) Text("⬩", style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, key: const ValueKey('proxy_selected_indicator'), size: 20, color: nova.accent),
          ],
        ],
      ),

      selected: selected,
      selectedColor: nova.accent,
      selectedTileColor: nova.accentFill,
      onTap: onTap,
      onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
      horizontalTitleGap: 4,
    );
  }

  Color delayColor(int delay) => switch (delay) {
    < 800 => NovaColors.signalGood,
    < 1500 => NovaColors.signalMid,
    _ => NovaColors.signalBad,
  };
}
