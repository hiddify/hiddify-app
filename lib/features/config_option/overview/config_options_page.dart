import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/tip_card.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/settings/widgets/sections_widgets.dart';
import 'package:hiddify/features/settings/widgets/settings_input_dialog.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:humanizer/humanizer.dart';

enum ConfigOptionSection {
  warp,
  fragment;

  static final _warpKey = GlobalKey(debugLabel: "warp-section-key");
  static final _fragmentKey = GlobalKey(debugLabel: "fragment-section-key");

  GlobalKey get key => switch (this) {
    ConfigOptionSection.warp => _warpKey,
    ConfigOptionSection.fragment => _fragmentKey,
  };
}

class ConfigOptionsPage extends HookConsumerWidget {
  ConfigOptionsPage({super.key, String? section})
    : section = section != null
          ? ConfigOptionSection.values.byName(section)
          : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final scrollController = useScrollController();

    useMemoized(() {
      if (section != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box =
              section!.key.currentContext?.findRenderObject() as RenderBox?;
          final offset = box?.localToGlobal(Offset.zero);
          if (offset == null) return;
          final height =
              scrollController.offset +
              offset.dy -
              MediaQueryData.fromView(View.of(context)).padding.top -
              kToolbarHeight;
          scrollController.animateTo(
            height,
            duration: const Duration(milliseconds: 500),
            curve: Curves.decelerate,
          );
        });
      }
    });

    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        shrinkWrap: true,
        slivers: [
          NestedAppBar(
            title: Text(t.config.pageTitle),
            actions: [
              PopupMenuButton(
                icon: Icon(AdaptiveIcon(context).more),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      onTap: () => ref
                          .read(configOptionProvider.notifier)
                          .exportJsonToClipboard()
                          .then((success) {
                            if (success) {
                              ref
                                  .read(inAppNotificationControllerProvider)
                                  .showSuccessToast(
                                    t.general.clipboardExportSuccessMsg,
                                  );
                            }
                          }),
                      child: Text(t.settings.exportOptions),
                    ),
                    // if (ref.watch(debugModeNotifierProvider))
                    PopupMenuItem(
                      onTap: () => ref
                          .read(configOptionProvider.notifier)
                          .exportJsonToClipboard(excludePrivate: false)
                          .then((success) {
                            if (success) {
                              ref
                                  .read(inAppNotificationControllerProvider)
                                  .showSuccessToast(
                                    t.general.clipboardExportSuccessMsg,
                                  );
                            }
                          }),
                      child: Text(t.settings.exportAllOptions),
                    ),
                    PopupMenuItem(
                      onTap: () async {
                        final shouldImport = await showConfirmationDialog(
                          context,
                          title: t.settings.importOptions,
                          message: t.settings.importOptionsMsg,
                        );
                        if (shouldImport) {
                          await ref
                              .read(configOptionProvider.notifier)
                              .importFromClipboard();
                        }
                      },
                      child: Text(t.settings.importOptions),
                    ),
                    PopupMenuItem(
                      child: Text(t.config.resetBtn),
                      onTap: () async {
                        await ref
                            .read(configOptionProvider.notifier)
                            .resetOption();
                      },
                    ),
                  ];
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TipCard(message: t.settings.experimentalMsg),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.logLevel),
                    preferences: ref.watch(ConfigOptions.logLevel.notifier),
                    choices: LogLevel.choices,
                    title: t.config.logLevel,
                    presentChoice: (value) => value.name.toUpperCase(),
                  ),

                  const SettingsDivider(),
                  SettingsSection(t.config.section.route),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.region),
                    preferences: ref.watch(ConfigOptions.region.notifier),
                    choices: Region.values,
                    title: t.settings.general.region,
                    presentChoice: (value) => value.present(t),
                    onChanged: (_) {
                      ref.read(ConfigOptions.directDnsAddress.notifier).reset();
                    },
                  ),
                  SwitchListTile(
                    title: Text(experimental(t.config.blockAds)),
                    value: ref.watch(ConfigOptions.blockAds),
                    onChanged: (v) {
                      ref.read(ConfigOptions.blockAds.notifier).update(v);
                    },
                  ),
                  SwitchListTile(
                    title: Text(experimental(t.config.bypassLan)),
                    value: ref.watch(ConfigOptions.bypassLan),
                    onChanged: (v) {
                      ref.read(ConfigOptions.bypassLan.notifier).update(v);
                    },
                  ),
                  SwitchListTile(
                    title: Text(t.config.resolveDestination),
                    value: ref.watch(ConfigOptions.resolveDestination),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.resolveDestination.notifier)
                          .update(v);
                    },
                  ),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.ipv6Mode),
                    preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
                    choices: IPv6Mode.values,
                    title: t.config.ipv6Mode,
                    presentChoice: (value) => value.present(t),
                  ),
                  const SettingsDivider(),
                  SettingsSection(t.config.section.dns),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.remoteDnsAddress),
                    preferences: ref.watch(
                      ConfigOptions.remoteDnsAddress.notifier,
                    ),
                    title: t.config.remoteDnsAddress,
                  ),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
                    preferences: ref.watch(
                      ConfigOptions.remoteDnsDomainStrategy.notifier,
                    ),
                    choices: DomainStrategy.values,
                    title: t.config.remoteDnsDomainStrategy,
                    presentChoice: (value) => value.displayName,
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.directDnsAddress),
                    preferences: ref.watch(
                      ConfigOptions.directDnsAddress.notifier,
                    ),
                    title: t.config.directDnsAddress,
                  ),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
                    preferences: ref.watch(
                      ConfigOptions.directDnsDomainStrategy.notifier,
                    ),
                    choices: DomainStrategy.values,
                    title: t.config.directDnsDomainStrategy,
                    presentChoice: (value) => value.displayName,
                  ),
                  SwitchListTile(
                    title: Text(t.config.enableDnsRouting),
                    value: ref.watch(ConfigOptions.enableDnsRouting),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.enableDnsRouting.notifier)
                          .update(v);
                    },
                  ),
                  const SettingsDivider(),
                  SettingsSection(t.config.section.inbound),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.serviceMode),
                    preferences: ref.watch(ConfigOptions.serviceMode.notifier),
                    choices: ServiceMode.choices,
                    title: t.config.serviceMode,
                    presentChoice: (value) => value.present(t),
                  ),
                  SwitchListTile(
                    title: Text(t.config.strictRoute),
                    value: ref.watch(ConfigOptions.strictRoute),
                    onChanged: (v) {
                      ref.read(ConfigOptions.strictRoute.notifier).update(v);
                    },
                  ),
                  ChoicePreferenceWidget(
                    selected: ref.watch(ConfigOptions.tunImplementation),
                    preferences: ref.watch(
                      ConfigOptions.tunImplementation.notifier,
                    ),
                    choices: TunImplementation.values,
                    title: t.config.tunImplementation,
                    presentChoice: (value) => value.name,
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.mixedPort),
                    preferences: ref.watch(ConfigOptions.mixedPort.notifier),
                    title: t.config.mixedPort,
                    inputToValue: int.tryParse,
                    digitsOnly: true,
                    validateInput: isPort,
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.tproxyPort),
                    preferences: ref.watch(ConfigOptions.tproxyPort.notifier),
                    title: t.config.tproxyPort,
                    inputToValue: int.tryParse,
                    digitsOnly: true,
                    validateInput: isPort,
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.localDnsPort),
                    preferences: ref.watch(ConfigOptions.localDnsPort.notifier),
                    title: t.config.localDnsPort,
                    inputToValue: int.tryParse,
                    digitsOnly: true,
                    validateInput: isPort,
                  ),
                  SwitchListTile(
                    title: Text(experimental(t.config.allowConnectionFromLan)),
                    value: ref.watch(ConfigOptions.allowConnectionFromLan),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.allowConnectionFromLan.notifier)
                          .update(v);
                    },
                  ),
                  const SettingsDivider(),
                  SettingsSection(
                    experimental(t.config.section.tlsTricks),
                    key: ConfigOptionSection._fragmentKey,
                  ),
                  SwitchListTile(
                    title: Text(t.config.enableTlsFragment),
                    value: ref.watch(ConfigOptions.enableTlsFragment),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.enableTlsFragment.notifier)
                          .update(v);
                    },
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.tlsFragmentSize),
                    preferences: ref.watch(
                      ConfigOptions.tlsFragmentSize.notifier,
                    ),
                    title: t.config.tlsFragmentSize,
                    inputToValue: OptionalRange.tryParse,
                    presentValue: (value) => value.present(t),
                    formatInputValue: (value) => value.format(),
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.tlsFragmentSleep),
                    preferences: ref.watch(
                      ConfigOptions.tlsFragmentSleep.notifier,
                    ),
                    title: t.config.tlsFragmentSleep,
                    inputToValue: OptionalRange.tryParse,
                    presentValue: (value) => value.present(t),
                    formatInputValue: (value) => value.format(),
                  ),
                  SwitchListTile(
                    title: Text(t.config.enableTlsMixedSniCase),
                    value: ref.watch(ConfigOptions.enableTlsMixedSniCase),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.enableTlsMixedSniCase.notifier)
                          .update(v);
                    },
                  ),
                  SwitchListTile(
                    title: Text(t.config.enableTlsPadding),
                    value: ref.watch(ConfigOptions.enableTlsPadding),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.enableTlsPadding.notifier)
                          .update(v);
                    },
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.tlsPaddingSize),
                    preferences: ref.watch(
                      ConfigOptions.tlsPaddingSize.notifier,
                    ),
                    title: t.config.tlsPaddingSize,
                    inputToValue: OptionalRange.tryParse,
                    presentValue: (value) => value.format(),
                    formatInputValue: (value) => value.format(),
                  ),
                  const SettingsDivider(),
                  SettingsSection(experimental(t.config.section.warp)),
                  WarpOptionsTiles(key: ConfigOptionSection._warpKey),
                  const SettingsDivider(),
                  SettingsSection(t.config.section.misc),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.connectionTestUrl),
                    preferences: ref.watch(
                      ConfigOptions.connectionTestUrl.notifier,
                    ),
                    title: t.config.connectionTestUrl,
                  ),
                  ListTile(
                    title: Text(t.config.urlTestInterval),
                    subtitle: Text(
                      ref
                          .watch(ConfigOptions.urlTestInterval)
                          .toApproximateTime(isRelativeToNow: false),
                    ),
                    onTap: () async {
                      final urlTestInterval = await SettingsSliderDialog(
                        title: t.config.urlTestInterval,
                        initialValue: ref
                            .watch(ConfigOptions.urlTestInterval)
                            .inMinutes
                            .clamp(1, 60)
                            .toDouble(),
                        onReset: ref
                            .read(ConfigOptions.urlTestInterval.notifier)
                            .reset,
                        min: 1,
                        max: 60,
                        divisions: 60,
                        labelGen: (value) => Duration(
                          minutes: value.toInt(),
                        ).toApproximateTime(isRelativeToNow: false),
                      ).show(context);
                      if (urlTestInterval == null) return;
                      await ref
                          .read(ConfigOptions.urlTestInterval.notifier)
                          .update(Duration(minutes: urlTestInterval.toInt()));
                    },
                  ),
                  ValuePreferenceWidget(
                    value: ref.watch(ConfigOptions.clashApiPort),
                    preferences: ref.watch(ConfigOptions.clashApiPort.notifier),
                    title: t.config.clashApiPort,
                    validateInput: isPort,
                    digitsOnly: true,
                    inputToValue: int.tryParse,
                  ),

                  SwitchListTile(
                    title: Text(
                      experimental(t.config.useXrayCoreWhenPossible.Label),
                    ),
                    subtitle: Text(
                      t.config.useXrayCoreWhenPossible.Description,
                    ),
                    value: ref.watch(ConfigOptions.useXrayCoreWhenPossible),
                    onChanged: (v) {
                      ref
                          .read(ConfigOptions.useXrayCoreWhenPossible.notifier)
                          .update(v);
                    },
                  ),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
