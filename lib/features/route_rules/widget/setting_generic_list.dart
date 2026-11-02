import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
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
    this.expandable = false,
  });

  final String title;
  final List<T> values;
  final GestureTapCallback? onTap;
  final bool useEllipsis;

  /// Offer a dialog with every value in full, opened from the count or, when there is no [onTap], from the row.
  final bool expandable;
  final bool isPackageName;
  final bool showPlatformWarning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final canExpand = expandable && values.isNotEmpty;
    void showAll() => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: values.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: isPackageName
                  ? AndroidAppInfo(packageName: '${values[index]}')
                  : SelectableText(
                      '${values[index]}',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyMedium,
                    ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: values.join('\n')));
              ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(t.pages.settings.routing.routeRule.copyAll),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.close)),
        ],
      ),
    );
    final trailing = canExpand
        ? InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: showAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${values.length}'),
                  const Gap(2),
                  Icon(Icons.open_in_full_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          )
        : Text('${values.length}');
    return Material(
      child: InkWell(
        onTap: onTap ?? (canExpand ? showAll : null),
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
                              t.pages.settings.routing.routeRule.rule.notAvailableInThisPlatform,
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
              trailing: trailing,
            ),
            if (values.isNotEmpty)
              SettingDetailChips<T>(values: values, useEllipsis: useEllipsis, isPackageName: isPackageName),
          ],
        ),
      ),
    );
  }
}
