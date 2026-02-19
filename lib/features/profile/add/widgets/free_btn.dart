import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/custom_text_scroll.dart';
import 'package:hiddify/features/profile/add/model/free_profiles_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FreeBtn extends ConsumerWidget {
  const FreeBtn({super.key, required this.freeProfile, required this.onTap});

  final FreeProfile freeProfile;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final locale = ref.watch(localePreferencesProvider);
    final isFa = locale.name == AppLocale.fa.name;
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(18);

    return Material(
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isFa ? freeProfile.title.fa : freeProfile.title.en,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    if (freeProfile.neededFeatures != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (freeProfile.neededFeatures!.contains('warp_over_proxies'))
                            Feature(title: t.common.warp, icon: Icons.add_moderator),
                          if (freeProfile.neededFeatures!.contains('fragment'))
                            Feature(title: t.common.fragment, icon: Icons.content_cut),
                        ],
                      ),
                  ],
                ),
              ),
              CustomTextScroll(
                isFa ? freeProfile.tags.fa.join(' · ') : freeProfile.tags.en.join(' · '),
                style: theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Feature extends ConsumerWidget {
  const Feature({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.primary),
        const Gap(4),
        Text(title, style: theme.textTheme.labelSmall!.copyWith(color: color)),
      ],
    );
  }
}
