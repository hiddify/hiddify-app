import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

class ProfileTile extends HookConsumerWidget {
  const ProfileTile({super.key, required this.profile, this.isMain = false, this.margin = EdgeInsets.zero, this.color});

  final ProfileEntity profile;

  /// home screen active profile card
  final bool isMain;
  final EdgeInsets margin;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final selectActiveMutation = useMutation(
      initialOnFailure: (err) {
        CustomToast.error(t.presentShortError(err)).show(context);
      },
      initialOnSuccess: () {
        if (context.mounted && context.canPop()) context.pop();
      },
    );

    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    final showActionButton = profile is RemoteProfileEntity || !isMain;

    // final effectiveMargin = isMain ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.only(left: 12, right: 12, bottom: 12);
    // final double effectiveElevation = profile.active ? 12 : 4;
    // final effectiveOutlineColor = profile.active ? theme.colorScheme.outline : Colors.transparent;
    return Card(
      // margin: effectiveMargin,
      // elevation: effectiveElevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        side: profile.active ? BorderSide(color: theme.colorScheme.outline) : BorderSide.none,
        borderRadius: ProfileTileConst.cardBorderRadius,
      ),
      // color: color ?? theme.colorScheme.secondaryContainer,
      elevation: profile.active ? 0 : 1,

      // shadowColor: Colors.transparent,
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showActionButton) ...[
                SizedBox(
                  width: 48,
                  child: Semantics(sortKey: const OrdinalSortKey(1), child: ProfileActionButton(profile, !isMain)),
                ),
                if (profile.active) VerticalDivider(width: 1, color: theme.colorScheme.outline) else const Gap(1),
              ],
              Expanded(
                child: Semantics(
                  button: true,
                  sortKey: isMain ? const OrdinalSortKey(0) : null,
                  focused: isMain,
                  liveRegion: isMain,
                  namesRoute: isMain,
                  label: isMain ? t.pages.profiles.viewAllProfiles : null,
                  child: InkWell(
                    borderRadius: showActionButton
                        ? ProfileTileConst.endBorderRadius(Directionality.of(context))
                        : ProfileTileConst.cardBorderRadius,
                    onTap: () {
                      if (isMain) {
                        if (Breakpoint(context).isMobile()) {
                          ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
                        } else {
                          context.goNamed('profiles');
                        }
                      } else {
                        if (selectActiveMutation.state.isInProgress) return;
                        // if (profile.active) return;
                        selectActiveMutation.setFuture(
                          ref.read(profilesNotifierProvider.notifier).selectActiveProfile(profile.id),
                        );
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed('home');
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(
                        // mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMain)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Material(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
                                        ),
                                        semanticsLabel: t.pages.profiles.activeProfileName(name: profile.name),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down_rounded),
                                  ],
                                ),
                              ),
                            )
                          else
                            Text(
                              profile.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
                              ),
                              semanticsLabel: profile.active
                                  ? t.pages.profiles.activeProfileName(name: profile.name)
                                  : t.pages.profiles.nonActiveProfileName(name: profile.name),
                            ),
                          if (subInfo != null) ...[
                            const Gap(4),
                            RemainingTrafficIndicator(subInfo.ratio),
                            const Gap(4),
                            ProfileSubscriptionInfo(subInfo),
                            const Gap(4),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileActionButton extends HookConsumerWidget {
  const ProfileActionButton(this.profile, this.showAllActions, {super.key});

  final ProfileEntity profile;
  final bool showAllActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    if (profile case RemoteProfileEntity() when !showAllActions) {
      return Semantics(
        button: true,
        enabled: !ref.watch(updateProfileNotifierProvider(profile.id)).isLoading,
        child: Tooltip(
          message: t.pages.profiles.update,
          child: InkWell(
            borderRadius: ProfileTileConst.startBorderRadius(Directionality.of(context)),
            onTap: () {
              if (ref.read(updateProfileNotifierProvider(profile.id)).isLoading) {
                return;
              }
              ref
                  .read(updateProfileNotifierProvider(profile.id).notifier)
                  .updateProfile(profile as RemoteProfileEntity);
            },
            child: const Icon(Icons.update_rounded),
          ),
        ),
      );
    }
    return ProfileActionsMenu(profile, (context, toggleVisibility, _) {
      return Semantics(
        button: true,
        child: Tooltip(
          message: MaterialLocalizations.of(context).showMenuTooltip,
          child: InkWell(
            borderRadius: ProfileTileConst.startBorderRadius(Directionality.of(context)),
            onTap: toggleVisibility,
            child: Icon(AdaptiveIcon(context).more),
          ),
        ),
      );
    });
  }
}

class ProfileActionsMenu extends HookConsumerWidget {
  const ProfileActionsMenu(this.profile, this.builder, {super.key, this.child});

  final ProfileEntity profile;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final menuItems = [
      if (profile case RemoteProfileEntity())
        AdaptiveMenuItem(
          title: t.common.update,
          icon: Icons.update_rounded,
          onTap: () {
            if (ref.read(updateProfileNotifierProvider(profile.id)).isLoading) {
              return;
            }
            ref.read(updateProfileNotifierProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
          },
        ),
      AdaptiveMenuItem(
        title: t.common.share,
        icon: AdaptiveIcon(context).share,
        subItems: [
          if (profile case RemoteProfileEntity(:final url, :final name)) ...[
            AdaptiveMenuItem(
              title: t.pages.profiles.share.urlToClipboard,
              onTap: () async {
                final link = LinkParser.generateSubShareLink(url, name);
                if (link.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ref
                        .read(inAppNotificationControllerProvider)
                        .showSuccessToast(t.common.msg.export.clipboard.success);
                  }
                }
              },
            ),
            AdaptiveMenuItem(
              title: t.pages.profiles.share.showUrlQr,
              onTap: () async {
                final link = LinkParser.generateSubShareLink(url, name);
                if (link.isNotEmpty) {
                  await ref.read(dialogNotifierProvider.notifier).showQrCode(link, message: name);
                }
              },
            ),
          ],
          AdaptiveMenuItem(
            title: t.pages.profiles.share.jsonToClipboard,
            onTap: () async => await ref.read(profilesNotifierProvider.notifier).exportConfigToClipboard(profile),
          ),
        ],
      ),
      AdaptiveMenuItem(
        icon: Icons.edit_rounded,
        title: t.common.edit,
        onTap: () {
          if (Breakpoint(context).isMobile()) context.pop();
          context.goNamed('profileDetails', pathParameters: {'id': profile.id});
        },
      ),
      // if (!profile.active)
      AdaptiveMenuItem(
        icon: Icons.delete_outline_rounded,
        title: t.common.delete,
        onTap: () async => await ref
            .read(dialogNotifierProvider.notifier)
            .showConfirmation(
              title: t.dialogs.confirmation.profile.delete.title,
              message: t.dialogs.confirmation.profile.delete.msg,
            )
            .then((deleteConfirmed) async {
              if (!deleteConfirmed) return;
              await ref.read(profilesNotifierProvider.notifier).deleteProfile(profile);
            }),
      ),
    ];

    return AdaptiveMenu(builder: builder, items: menuItems, child: child);
  }
}

// TODO add support url
class ProfileSubscriptionInfo extends HookConsumerWidget {
  const ProfileSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.components.subscriptionInfo.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.components.subscriptionInfo.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.components.subscriptionInfo.remainingDuration(duration: "∞"), null);
    } else {
      return (t.components.subscriptionInfo.remainingDuration(duration: subInfo.remaining.inDays), null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Flexible(
            child: Text(
              subInfo.total >
                      10 *
                          1099511627776 //10TB
                  ? "∞ GiB"
                  : subInfo.consumption.sizeOf(subInfo.total),
              semanticsLabel: t.components.subscriptionInfo.remainingTrafficSemanticLabel(
                consumed: subInfo.consumption.sizeGB(),
                total: subInfo.total.sizeGB(),
              ),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Flexible(
          child: Text(
            remaining.$1,
            style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// TODO add support url
class NewTrafficSubscriptionInfo extends HookConsumerWidget {
  const NewTrafficSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Column(
      children: [
        const Icon(Icons.assessment_rounded, color: Colors.blue),
        Text(t.components.subscriptionInfo.remainingTraffic),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                subInfo.total >
                        10 *
                            1099511627776 //10TB
                    ? "∞ GiB"
                    : subInfo.consumption.sizeOf(subInfo.total),
                semanticsLabel: t.components.subscriptionInfo.remainingTrafficSemanticLabel(
                  consumed: subInfo.consumption.sizeGB(),
                  total: subInfo.total.sizeGB(),
                ),
                // style: theme.textTheme.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// TODO add support url
class NewDaySubscriptionInfo extends HookConsumerWidget {
  const NewDaySubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.components.subscriptionInfo.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.components.subscriptionInfo.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.components.subscriptionInfo.remainingDurationNew(duration: "∞"), null);
    } else {
      return (t.components.subscriptionInfo.remainingDurationNew(duration: subInfo.remaining.inDays), null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Column(
      children: [
        const Icon(Icons.timer, color: Colors.blue),
        Text(t.components.subscriptionInfo.remainingTime),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                remaining.$1,
                // style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// TODO add support url
class NewDayTrafficSubscriptionInfo extends HookConsumerWidget {
  const NewDayTrafficSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.components.subscriptionInfo.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.components.subscriptionInfo.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.components.subscriptionInfo.remainingDurationNew(duration: "∞"), null);
    } else {
      return (t.components.subscriptionInfo.remainingDurationNew(duration: subInfo.remaining.inDays), null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.assessment_rounded, color: Colors.blue),
        Text(t.components.subscriptionInfo.remainingUsage),
        const SizedBox(height: 4),
        Text(
          remaining.$1,
          // style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
          overflow: TextOverflow.ellipsis,
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            subInfo.total >
                    10 *
                        1099511627776 //10TB
                ? "∞ GiB"
                : subInfo.consumption.sizeOf(subInfo.total),
            semanticsLabel: t.components.subscriptionInfo.remainingTrafficSemanticLabel(
              consumed: subInfo.consumption.sizeGB(),
              total: subInfo.total.sizeGB(),
            ),
            // style: theme.textTheme.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class NewSiteSubscriptionInfo extends HookConsumerWidget {
  const NewSiteSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final uri = Uri.parse(subInfo.webPageUrl ?? "");
    var host = uri.host;
    if (["telegram.me", "t.me"].contains(host)) {
      host = "@${uri.path.split("/").last}";
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(subInfo.webPageUrl ?? "")),
      child: Column(
        children: [
          const Icon(FluentIcons.globe_person_24_filled, size: 24, color: Colors.blue),
          Text(t.components.subscriptionInfo.profileSite),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  host,
                  // style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// TODO change colors
class RemainingTrafficIndicator extends StatelessWidget {
  const RemainingTrafficIndicator(this.ratio, {super.key});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    // final startColor = ratio < 0.25
    //     ? const Color.fromRGBO(93, 205, 251, 1.0)
    //     : ratio < 0.65
    //         ? const Color.fromRGBO(205, 199, 64, 1.0)
    //         : const Color.fromRGBO(241, 82, 81, 1.0);
    // final endColor = ratio < 0.25
    //     ? const Color.fromRGBO(49, 146, 248, 1.0)
    //     : ratio < 0.65
    //         ? const Color.fromRGBO(98, 115, 32, 1.0)
    //         : const Color.fromRGBO(139, 30, 36, 1.0);
    return LinearProgressIndicator(value: ratio, borderRadius: BorderRadius.circular(16), minHeight: 6);
    // return HorizontalPercentIndicator(
    //   height: 6,

    //   borderRadius: 16,
    //   loadingPercent: ratio,
    //   // inactiveTrackColor: Color.fromRGBO(r, g, b, opacity),

    //   activeTrackColor: [startColor, endColor],
    // );
    // return LinearPercentIndicator(
    //     // percent: ratio,
    //     // animation: false,
    //     // padding: EdgeInsets.zero,
    //     // lineHeight: 6,
    //     // barRadius: const Radius.circular(16),
    //     // linearGradient: LinearGradient(
    //     //   colors: [startColor, endColor],
    //     // ),
    //     );
  }
}
