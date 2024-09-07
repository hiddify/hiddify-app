import 'package:flutter/material.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(
    this.proxy, {
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ProxyItemEntity proxy;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        proxy.name,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: FontFamily.emoji),
      ),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: 6,
          height: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected ? theme.colorScheme.primary : Colors.transparent,
          ),
        ),
      ),
      subtitle: Text.rich(
        TextSpan(
          text: proxy.type.label,
          children: [
            if (proxy.selectedName != null)
              TextSpan(
                text: ' (${proxy.selectedName})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: proxy.urlTestDelay != 0
          ? Text(
              proxy.urlTestDelay > 65000 ? "×" : proxy.urlTestDelay.toString(),
              style: TextStyle(color: delayColor(context, proxy.urlTestDelay)),
            )
          : null,
      selected: selected,
      onTap: onSelect,
      onLongPress: () async {
        showDialog(
          context: context,
          builder: (context) => PlatformAlertDialog(
            content: SelectionArea(child: Text(proxy.name)),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              ),
            ],
          ),
        );
      },
      horizontalTitleGap: 4,
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) { < 800 => Colors.lightGreen, < 1500 => Colors.orange, _ => Colors.redAccent };
    }
    return switch (delay) { < 800 => Colors.green, < 1500 => Colors.deepOrangeAccent, _ => Colors.red };
  }
}
