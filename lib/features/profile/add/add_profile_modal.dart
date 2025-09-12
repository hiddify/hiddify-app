import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/qr_code_scanner_screen.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';

import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddProfileModal extends HookConsumerWidget {
  const AddProfileModal({
    super.key,
    this.url,
    this.scrollController,
  });
  static const warpConsentGiven = "warp_consent_given";
  final String? url;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final addProfileState = ref.watch(addProfileProvider);

    ref.listen(
      addProfileProvider,
      (previous, next) {
        if (next case AsyncData(value: final _?)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (context.mounted && context.canPop()) context.pop();
            },
          );
        }
      },
    );

    useMemoized(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (url != null && context.mounted) {
        if (addProfileState.isLoading) return;
        ref.read(addProfileProvider.notifier).add(url!);
      }
    });

    final theme = Theme.of(context);
    const buttonsPadding = 24.0;
    const buttonsGap = 16.0;

    return SingleChildScrollView(
      controller: scrollController,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // temporary solution, aspect ratio widget relies on height and in a row there no height!
            final buttonWidth = constraints.maxWidth / 2 - (buttonsPadding + (buttonsGap / 2));

            return AnimatedCrossFade(
              firstChild: SizedBox(
                height: buttonWidth.clamp(0, 168),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.profile.add.addingProfileMsg,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Gap(8),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                      ),
                      const Gap(8),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(addProfileProvider);
                        },
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              secondChild: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: buttonsPadding),
                    child: Row(
                      children: [
                        _Button(
                          key: const ValueKey("add_from_clipboard_button"),
                          label: t.profile.add.fromClipboard,
                          icon: FluentIcons.clipboard_paste_24_regular,
                          size: buttonWidth,
                          onTap: () async {
                            final captureResult = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text ?? '');
                            if (addProfileState.isLoading) return;
                            ref.read(addProfileProvider.notifier).add(captureResult);
                          },
                        ),
                        const Gap(buttonsGap),
                        if (!PlatformUtils.isDesktop)
                          _Button(
                            key: const ValueKey("add_by_qr_code_button"),
                            label: t.profile.add.scanQr,
                            icon: FluentIcons.qr_code_24_regular,
                            size: buttonWidth,
                            onTap: () async {
                              final cr = await const QRCodeScannerScreen().open(context);

                              if (cr == null) return;
                              if (addProfileState.isLoading) return;
                              ref.read(addProfileProvider.notifier).add(cr);
                            },
                          )
                        else
                          _Button(
                            key: const ValueKey("add_manually_button"),
                            label: t.profile.add.manually,
                            icon: FluentIcons.add_24_regular,
                            size: buttonWidth,
                            onTap: () async {
                              context.pop();
                              await const NewProfileRoute().push(context);
                            },
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: buttonsPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          button: true,
                          child: SizedBox(
                            height: 36,
                            child: Material(
                              key: const ValueKey("add_warp_button"),
                              elevation: 8,
                              color: theme.colorScheme.surface,
                              surfaceTintColor: theme.colorScheme.surfaceTint,
                              shadowColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () async {
                                  await addProfileModal(context, ref);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FluentIcons.add_24_regular,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.profile.add.addWarp,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!PlatformUtils.isDesktop) const SizedBox(height: 16), // Spacing between the buttons
                        if (!PlatformUtils.isDesktop)
                          Semantics(
                            button: true,
                            child: SizedBox(
                              height: 36,
                              child: Material(
                                key: const ValueKey("add_manually_button"),
                                elevation: 8,
                                color: theme.colorScheme.surface,
                                surfaceTintColor: theme.colorScheme.surfaceTint,
                                shadowColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () async {
                                    context.pop();
                                    await const NewProfileRoute().push(context);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FluentIcons.add_24_regular,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t.profile.add.manually,
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(24),
                ],
              ),
              crossFadeState: addProfileState.isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            );
          },
        ),
      ),
    );
  }

  Future<void> addProfileModal(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    final warp = ref.read(warpOptionNotifierProvider.notifier);
    final profile = ref.read(addProfileProvider.notifier);
    final consent = prefs.getBool(warpConsentGiven) ?? false;
    final region = ref.read(ConfigOptions.region.notifier).raw();
    context.pop();

    final t = ref.read(translationsProvider);
    final notification = ref.read(inAppNotificationControllerProvider);

    if (!consent) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => const WarpLicenseAgreementModal(),
      );

      if (agreed != true) return;
    }
    await prefs.setBool(warpConsentGiven, true);
    var toast = notification.showInfoToast(t.profile.add.addingWarpMsg, duration: const Duration(milliseconds: 100));
    toast?.pause();
    await warp.generateWarpConfig();
    toast?.start();

    // final accountId = _prefs.getString("warp2-account-id");
    // final accessToken = _prefs.getString("warp2-access-token");
    // final hasWarp2Config = accountId != null && accessToken != null;

    // if (!hasWarp2Config || true) {
    toast = notification.showInfoToast(t.profile.add.addingWarpMsg, duration: const Duration(milliseconds: 100));
    toast?.pause();
    await warp.generateWarp2Config();
    toast?.start();
    // }
    if (region == "cn") {
      await profile.add("#profile-title: Hiddify WARP\nwarp://p1@auto#National&&detour=warp://p2@auto#WoW"); //
    } else {
      await profile.add("https://raw.githubusercontent.com/hiddify/hiddify-next/main/test.configs/warp"); //
    }
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.label,
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Semantics(
      button: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          elevation: 8,
          color: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surfaceTint,
          shadowColor: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: size / 3,
                  color: color,
                ),
                const Gap(16),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
