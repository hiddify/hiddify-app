import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTileMain extends HookConsumerWidget {
  const ProfileTileMain({super.key, required this.profile, this.isMain = false});

  final ProfileEntity profile;
  final bool isMain;
  static const verifiedDomains = [
    'hiddify.com',
    // 't.me',
    // 'telegram.me',
    // 'instagram.com',
    // 'x.com',
    // 'facebook.com',
  ];
  static const verifiedLinks = [
    'https://t.me/hiddify',
    'https://t.me/hiddify_board',
    'https://instagram.com/hiddify_com',
    'https://x.com/hiddify_com',
    'https://facebook.com/hiddify',
  ];
  Future<void> _launchUrlWithCheck(BuildContext context, WidgetRef ref, String url) async {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (verifiedDomains.any((p) => host == p || host.endsWith(".$p")) || verifiedLinks.any((p) => url == p)) {
      await launchUrl(uri);
      return;
    }

    // Show warning dialog for unknown domains
    final shouldLaunch = await ref.read(dialogNotifierProvider.notifier).showUnknownDomainsWarning(url: url);
    if (shouldLaunch == true) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    if (!isMain) return const Card();

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => ref
                  .read(updateProfileNotifierProvider(profile.id).notifier)
                  .updateProfile(profile as RemoteProfileEntity),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(FluentIcons.arrow_sync_24_filled, color: theme.colorScheme.primary, size: 20),
                  ),
                  const Gap(6),
                  Text(
                    profile.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (subInfo != null)
            Container(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicHeight(
                    // Add this to ensure equal height
                    child: Row(
                      children: [
                        if (subInfo.total > 0) _BandwithUsageRow(subInfo),

                        // if (subInfo.total > 0 && subInfo.remaining.inDays > 0)
                        //   const VerticalDivider(
                        //     // Add divider between items
                        //     width: 1,
                        //     thickness: 1,
                        //     indent: 12,
                        //     endIndent: 12,
                        //   ),
                        if (subInfo.remaining.inDays > 0)
                          // Add Expanded
                          _UsageRow(
                            icon: null, //FluentIcons.timer_24_regular,
                            title: subInfo.remaining.inDays > 365
                                ? "∞ days remaining"
                                : "${subInfo.remaining.inDays}/30 days remaining",
                            progress: subInfo.remaining.inDays > 365 ? 0 : subInfo.remaining.inDays / 30,
                            color: _getProgressColor(1 - (subInfo.remaining.inDays / 30)),
                          ),
                      ],
                    ),
                  ),
                  if ((subInfo.webPageUrl != null || subInfo.supportUrl != null))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          if (subInfo.webPageUrl != null)
                            Expanded(
                              child: InkWell(
                                onTap: () => _launchUrlWithCheck(context, ref, subInfo.webPageUrl!),
                                borderRadius: BorderRadius.circular(8),
                                child: _InfoItem(
                                  icon: _getLinkIcon(subInfo.webPageUrl!, FluentIcons.building_shop_24_regular),
                                  label: t.components.subscriptionInfo.profileSite,
                                  value: _formatSupportLink(subInfo.webPageUrl!),
                                ),
                              ),
                            ),
                          if (subInfo.supportUrl != null) ...[
                            const Gap(12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _launchUrlWithCheck(context, ref, subInfo.supportUrl!),
                                borderRadius: BorderRadius.circular(8),
                                child: _InfoItem(
                                  icon: _getLinkIcon(subInfo.supportUrl!, FontAwesomeIcons.headset),
                                  label: t.components.subscriptionInfo.profileSupport,
                                  value: _formatSupportLink(subInfo.supportUrl!),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getLinkIcon(String url, [IconData? icon]) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (host.endsWith('telegram.me') || host.endsWith('t.me')) {
      return FontAwesomeIcons.telegram;
    }
    if (host.endsWith('instagram.com')) {
      return FontAwesomeIcons.instagram;
    }
    if (host.endsWith('twitter.com')) {
      return FontAwesomeIcons.xTwitter;
    }
    if (host.endsWith('facebook.com')) {
      return FontAwesomeIcons.facebook;
    }
    if (host.endsWith('hiddify.com')) {
      // return IconData();
    }
    return icon ?? FluentIcons.link_24_regular;
  }

  String _formatSupportLink(String url) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (host.endsWith('telegram.me') || host.endsWith('t.me')) {
      return "@${uri.pathSegments.last}";
    }
    if (host.endsWith('instagram.com')) {
      return "@${uri.pathSegments.first}";
    }
    if (host.endsWith('twitter.com')) {
      return "@${uri.pathSegments.first}";
    }
    if (host.endsWith('facebook.com')) {
      return uri.pathSegments.lastWhere((e) => e.isNotEmpty, orElse: () => '');
    }
    if (host.endsWith('hiddify.com')) {
      return "Hiddify";
    }
    return uri.host;
  }

  Color _getProgressColor(double ratio) {
    if (ratio < 0.25) return Colors.red;
    if (ratio < 0.45) return Colors.orange;
    return Colors.green;
  }

  Widget _BandwithUsageRow(SubscriptionInfo subInfo) {
    return _UsageRow(
      icon: FluentIcons.data_usage_24_filled,
      title: subInfo.total.isInfinitSize() ? "∞ GB remaining" : "${subInfo.remainingBWratio * 100}% remaining",
      progress: subInfo.total.isInfinitSize() ? 1 : subInfo.remainingBWratio,
      color: _getProgressColor(subInfo.remainingBWratio),
    );
  }
}

// Rest of the widget classes remain the same...

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.icon, required this.title, required this.progress, required this.color});

  final IconData? icon;
  final String title;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: color), const Gap(12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const Gap(4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      // decoration: BoxDecoration(
      //   color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
