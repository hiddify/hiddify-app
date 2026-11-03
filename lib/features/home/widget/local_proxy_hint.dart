import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// In proxy mode, a "Manual" tab beside the quick settings one, a size smaller and tinted in the
/// theme's error color: the mode routes nothing by itself, each app is pointed at the local proxy
/// by hand. It opens how.
class LocalProxyHint extends ConsumerWidget {
  const LocalProxyHint({super.key});

  static const _radius = BorderRadius.only(topLeft: Radius.circular(13), topRight: Radius.circular(13));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(ConfigOptions.serviceMode) != ServiceMode.proxy) return const SizedBox.shrink();
    final t = ref.watch(translationsProvider).requireValue;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      // apart from the quick settings tab beside it
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Tooltip(
        message: t.dialogs.localProxy.hint,
        child: Material(
          color: Color.alphaBlend(colors.error.withValues(alpha: .16), colors.surface),
          borderRadius: _radius,
          child: InkWell(
            borderRadius: _radius,
            onTap: () => ref.read(dialogNotifierProvider.notifier).showLocalProxy(),
            child: Container(
              height: 26,
              padding: const EdgeInsetsDirectional.only(start: 9, end: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.back_hand_outlined, size: 13, color: colors.error),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      t.dialogs.localProxy.manual,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
