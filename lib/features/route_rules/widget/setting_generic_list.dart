import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/route_rules/widget/setting_detail_chips.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingGenericList<T extends Object> extends ConsumerWidget {
  const SettingGenericList({
    super.key,
    required this.title,
    required this.values,
    required this.onTap,
    this.useEllipsis = false,
    this.isPackageName = false,
    this.showPlatformWarning = false,
  });

  final String title;
  final List<T> values;
  final GestureTapCallback? onTap;
  final bool useEllipsis;
  final bool isPackageName;
  final bool showPlatformWarning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: showPlatformWarning
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(size: 16, Icons.warning_rounded, color: Colors.amber),
                            const Gap(2),
                            Text(
                              t.pages.settings.routing.routeRule.rule.notAvailabeInThisPlatform,
                              style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        Text(title),
                      ],
                    )
                  : Text(title),
              trailing: Text('${values.length}'),
            ),
            if (values.isNotEmpty)
              SettingDetailChips<T>(values: values, useEllipsis: useEllipsis, isPackageName: isPackageName),
          ],
        ),
      ),
    );
  }
}
