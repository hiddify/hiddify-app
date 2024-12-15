import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/tip_card.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/PlatformListSection.dart';
import 'package:hiddify/features/config_option/overview/tlsfragment_widgets.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/log/overview/logs_overview_page.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/settings/about/about_page.dart';
import 'package:hiddify/features/settings/widgets/advanced_setting_tiles.dart';
import 'package:hiddify/features/settings/widgets/general_setting_tiles.dart';
import 'package:hiddify/features/settings/widgets/platform_settings_tiles.dart';
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
  ConfigOptionsPage({super.key, String? section}) : section = section != null ? ConfigOptionSection.values.byName(section) : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    // final scrollController = useScrollController();

    // useMemoized(
    //   () {
    //     if (section != null) {
    //       WidgetsBinding.instance.addPostFrameCallback(
    //         (_) {
    //           final box = section!.key.currentContext?.findRenderObject() as RenderBox?;

    //           final offset = box?.localToGlobal(Offset.zero);
    //           if (offset == null) return;
    //           final height = scrollController.offset + offset.dy - MediaQueryData.fromView(View.of(context)).padding.top - kToolbarHeight;
    //           scrollController.animateTo(
    //             height,
    //             duration: const Duration(milliseconds: 500),
    //             curve: Curves.decelerate,
    //           );
    //         },
    //       );
    //     }
    //   },
    // );
    Widget SwitchListTileAdaptive({
      Key? key,
      String? title,
      String? subtitle,
      bool value = false,
      ValueChanged<bool>? onChanged,
    }) {
      return switchListTileAdaptive(context, key: key, title: title, subtitle: subtitle, value: value, onChanged: onChanged);
    }

    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    final perAppProxy = ref.watch(Preferences.perAppProxyMode).enabled;

    return PlatformScaffold(
      body: CustomScrollView(
        // controller: scrollController,
        shrinkWrap: true,
        slivers: [
          NestedAppBar(
            title: Text(t.config.pageTitle),
            actions: [
              PlatformPopupMenu(
                icon: Icon(AdaptiveIcon(context).more),
                options: [
                  PopupMenuOption(
                    onTap: (option) async => ref.read(configOptionNotifierProvider.notifier).exportJsonToClipboard().then((success) {
                      if (success) {
                        ref.read(inAppNotificationControllerProvider).showSuccessToast(
                              t.general.clipboardExportSuccessMsg,
                            );
                      }
                    }),
                    label: t.settings.exportOptions,
                  ),
                  // if (ref.watch(debugModeNotifierProvider))
                  PopupMenuOption(
                    onTap: (option) async => ref.read(configOptionNotifierProvider.notifier).exportJsonToClipboard(excludePrivate: false).then((success) {
                      if (success) {
                        ref.read(inAppNotificationControllerProvider).showSuccessToast(
                              t.general.clipboardExportSuccessMsg,
                            );
                      }
                    }),
                    label: t.settings.exportAllOptions,
                  ),
                  PopupMenuOption(
                    onTap: (option) async {
                      final shouldImport = await showConfirmationDialog(
                        context,
                        title: t.settings.importOptions,
                        message: t.settings.importOptionsMsg,
                      );
                      if (shouldImport) {
                        await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
                      }
                    },
                    label: t.settings.importOptions,
                  ),
                  PopupMenuOption(
                    label: t.config.resetBtn,
                    onTap: (option) async {
                      await ref.read(configOptionNotifierProvider.notifier).resetOption();
                    },
                  ),
                ],
              )
            ],
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TipCard(message: t.settings.experimentalMsg),
                  if (Breakpoints.small.isActive(context)) ...[
                    PlatformListSection(
                      sectionIcon: const Icon(FluentIcons.info_20_filled),
                      sectionTitle: t.about.pageTitle,
                      page: const AboutPage(),
                      showAppBar: false,
                    ),
                    PlatformListSection(
                      sectionIcon: const Icon(FluentIcons.document_text_20_filled),
                      sectionTitle: t.logs.pageTitle,
                      page: const LogsOverviewPage(),
                      showAppBar: false,
                    )
                    // ListTile(
                    //   leading: const Icon(FluentIcons.document_text_20_filled),
                    //   title: Text(t.logs.pageTitle),
                    //   onTap: () => const LogsOverviewRoute().push(context),
                    //   trailing: const Icon(FluentIcons.chevron_right_20_regular),
                    // ),
                  ],
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.layerGroup),
                    sectionTitle: t.settings.general.sectionTitle,
                    items: [
                      const GeneralSettingTiles(),
                      const PlatformSettingsTiles(),
                      const AdvancedSettingTiles(),
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.logLevel),
                        preferences: ref.watch(ConfigOptions.logLevel.notifier),
                        choices: LogLevel.choices,
                        title: t.config.logLevel,
                        presentChoice: (value) => value.name.toUpperCase(),
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.connectionTestUrl),
                        preferences: ref.watch(ConfigOptions.connectionTestUrl.notifier),
                        title: t.config.connectionTestUrl,
                      ),
                      PlatformListTile(
                        title: Text(t.config.urlTestInterval),
                        subtitle: Text(
                          ref.watch(ConfigOptions.urlTestInterval).toApproximateTime(isRelativeToNow: false),
                        ),
                        onTap: () async {
                          final urlTestInterval = await SettingsSliderDialog(
                            title: t.config.urlTestInterval,
                            initialValue: ref.watch(ConfigOptions.urlTestInterval).inMinutes.coerceIn(0, 60).toDouble(),
                            onReset: ref.read(ConfigOptions.urlTestInterval.notifier).reset,
                            min: 1,
                            max: 60,
                            divisions: 60,
                            labelGen: (value) => Duration(minutes: value.toInt()).toApproximateTime(isRelativeToNow: false),
                          ).show(context);
                          if (urlTestInterval == null) return;
                          await ref.read(ConfigOptions.urlTestInterval.notifier).update(Duration(minutes: urlTestInterval.toInt()));
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
                      SwitchListTileAdaptive(
                        title: experimental(t.config.useXrayCoreWhenPossible.Label),
                        subtitle: t.config.useXrayCoreWhenPossible.Description,
                        value: ref.watch(ConfigOptions.useXrayCoreWhenPossible),
                        onChanged: ref.watch(ConfigOptions.useXrayCoreWhenPossible.notifier).update,
                      ),
                    ],
                  ),

                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.route),
                    sectionTitle: t.config.section.route,
                    items: [
                      if (PlatformUtils.isAndroid)
                        ListTile(
                          title: Text(t.settings.network.perAppProxyPageTitle),
                          leading: const Icon(FluentIcons.apps_list_detail_24_regular),
                          trailing: Switch(
                            value: perAppProxy,
                            onChanged: (value) async {
                              final newMode = perAppProxy ? PerAppProxyMode.off : PerAppProxyMode.exclude;
                              await ref.read(Preferences.perAppProxyMode.notifier).update(newMode);
                              if (!perAppProxy && context.mounted) {
                                const PerAppProxyRoute().go(context);
                              }
                            },
                          ),
                          onTap: () async {
                            if (!perAppProxy) {
                              await ref.read(Preferences.perAppProxyMode.notifier).update(PerAppProxyMode.exclude);
                            }
                            // if (context.mounted) await const PerAppProxyRoute().push(context);
                          },
                        ),
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.region),
                        preferences: ref.watch(ConfigOptions.region.notifier),
                        choices: Region.values,
                        title: t.settings.general.region,
                        presentChoice: (value) => value.present(t),
                        onChanged: (val) => ref.watch(ConfigOptions.directDnsAddress.notifier).reset(),
                      ),
                      SwitchListTileAdaptive(
                        title: experimental(t.config.blockAds),
                        value: ref.watch(ConfigOptions.blockAds),
                        onChanged: ref.watch(ConfigOptions.blockAds.notifier).update,
                      ),
                      SwitchListTileAdaptive(
                        title: experimental(t.config.bypassLan),
                        value: ref.watch(ConfigOptions.bypassLan),
                        onChanged: ref.watch(ConfigOptions.bypassLan.notifier).update,
                      ),
                      SwitchListTileAdaptive(
                        title: t.config.resolveDestination,
                        value: ref.watch(ConfigOptions.resolveDestination),
                        onChanged: ref.watch(ConfigOptions.resolveDestination.notifier).update,
                      ),
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.ipv6Mode),
                        preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
                        choices: IPv6Mode.values,
                        title: t.config.ipv6Mode,
                        presentChoice: (value) => value.present(t),
                      ),
                    ],
                  ),
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.globe),
                    sectionTitle: t.config.section.dns,
                    items: [
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.remoteDnsAddress),
                        preferences: ref.watch(ConfigOptions.remoteDnsAddress.notifier),
                        title: t.config.remoteDnsAddress,
                      ),
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
                        preferences: ref.watch(ConfigOptions.remoteDnsDomainStrategy.notifier),
                        choices: DomainStrategy.values,
                        title: t.config.remoteDnsDomainStrategy,
                        presentChoice: (value) => value.displayName,
                      ),
                      ValuePreferenceWidget(
                        value: ref.watch(ConfigOptions.directDnsAddress),
                        preferences: ref.watch(ConfigOptions.directDnsAddress.notifier),
                        title: t.config.directDnsAddress,
                      ),
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
                        preferences: ref.watch(ConfigOptions.directDnsDomainStrategy.notifier),
                        choices: DomainStrategy.values,
                        title: t.config.directDnsDomainStrategy,
                        presentChoice: (value) => value.displayName,
                      ),
                      SwitchListTileAdaptive(
                        title: t.config.enableDnsRouting,
                        value: ref.watch(ConfigOptions.enableDnsRouting),
                        onChanged: ref.watch(ConfigOptions.enableDnsRouting.notifier).update,
                      ),
                      // const SettingsDivider(),
                      // SettingsSection(experimental(t.config.section.mux)),
                      // SwitchListTileAdaptive(
                      //   title: t.config.enableMux,
                      //   value: ref.watch(ConfigOptions.enableMux),
                      //   onChanged:
                      //       ref.watch(ConfigOptions.enableMux.notifier).update,
                      // ),
                      // ChoicePreferenceWidget(
                      //   selected: ref.watch(ConfigOptions.muxProtocol),
                      //   preferences: ref.watch(ConfigOptions.muxProtocol.notifier),
                      //   choices: MuxProtocol.values,
                      //   title: t.config.muxProtocol,
                      //   presentChoice: (value) => value.name,
                      // ),
                      // ValuePreferenceWidget(
                      //   value: ref.watch(ConfigOptions.muxMaxStreams),
                      //   preferences:
                      //       ref.watch(ConfigOptions.muxMaxStreams.notifier),
                      //   title: t.config.muxMaxStreams,
                      //   inputToValue: int.tryParse,
                      //   digitsOnly: true,
                      // ),
                    ],
                  ),
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.rightToBracket),
                    sectionTitle: t.config.section.inbound,
                    items: [
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.serviceMode),
                        preferences: ref.watch(ConfigOptions.serviceMode.notifier),
                        choices: ServiceMode.choices,
                        title: t.config.serviceMode,
                        presentChoice: (value) => value.present(t),
                      ),
                      SwitchListTileAdaptive(
                        title: t.config.strictRoute,
                        value: ref.watch(ConfigOptions.strictRoute),
                        onChanged: ref.watch(ConfigOptions.strictRoute.notifier).update,
                      ),
                      ChoicePreferenceWidget(
                        selected: ref.watch(ConfigOptions.tunImplementation),
                        preferences: ref.watch(ConfigOptions.tunImplementation.notifier),
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
                      SwitchListTileAdaptive(
                        title: experimental(t.config.allowConnectionFromLan),
                        value: ref.watch(ConfigOptions.allowConnectionFromLan),
                        onChanged: ref.read(ConfigOptions.allowConnectionFromLan.notifier).update,
                      ),
                    ],
                  ),
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.expeditedssl),
                    sectionTitle: experimental(t.config.section.tlsTricks),
                    items: const [TlsfragmentTiles()],
                  ),
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.cloudflare),
                    sectionTitle: t.config.section.warp,
                    items: [
                      WarpOptionsTiles(key: ConfigOptionSection._warpKey),
                    ],
                    openOnLoad: section == ConfigOptionSection.warp,
                  ),

                  // const AboutPage()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? textTheme(BuildContext context) {
  if (PlatformTheme.of(context)?.isDark == true) {
    return PlatformTheme.of(context)?.cupertinoDarkTheme?.textTheme.textStyle ?? PlatformTheme.of(context)?.materialDarkTheme?.textTheme.labelMedium;
  }
  return PlatformTheme.of(context)?.cupertinoLightTheme?.textTheme.textStyle ?? PlatformTheme.of(context)?.materialLightTheme?.textTheme.labelMedium;
}

Widget switchListTileAdaptive(
  BuildContext context, {
  Key? key,
  String? title,
  String? subtitle,
  bool value = false,
  ValueChanged<bool>? onChanged,
}) {
  return SwitchListTile.adaptive(
    key: key,
    title: PlatformText(
      title ?? "",
      style: textTheme(context),
    ),
    subtitle: subtitle != null
        ? PlatformText(
            subtitle,
            style: textTheme(context),
          )
        : null,
    value: value,
    onChanged: onChanged,
  );
}
