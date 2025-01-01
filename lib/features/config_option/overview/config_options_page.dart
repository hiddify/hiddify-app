import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import 'package:hiddify/features/config_option/overview/dns_options_widgets.dart';
import 'package:hiddify/features/config_option/overview/inbound_options_widgets.dart';
import 'package:hiddify/features/config_option/overview/route_options_widgets.dart';
import 'package:hiddify/features/config_option/overview/tlsfragment_widgets.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/log/overview/logs_overview_page.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/settings/about/about_page.dart';
import 'package:hiddify/features/settings/notifier/platform_settings_notifier.dart';
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
    final t = ref.watch(translationsProvider).requireValue;
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

    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    return Scaffold(
      body: CustomScrollView(
        // controller: scrollController,
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
                      onTap: () async => ref.read(configOptionNotifierProvider.notifier).exportJsonToClipboard().then((success) {
                        if (success) {
                          ref.read(inAppNotificationControllerProvider).showSuccessToast(
                                t.general.clipboardExportSuccessMsg,
                              );
                        }
                      }),
                      child: Text(t.settings.exportOptions),
                    ),
                    // if (ref.watch(debugModeNotifierProvider))
                    PopupMenuItem(
                      onTap: () async => ref.read(configOptionNotifierProvider.notifier).exportJsonToClipboard(excludePrivate: false).then((success) {
                        if (success) {
                          ref.read(inAppNotificationControllerProvider).showSuccessToast(
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
                          await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
                        }
                      },
                      child: Text(t.settings.importOptions),
                    ),
                    PopupMenuItem(
                      child: Text(t.config.resetBtn),
                      onTap: () async {
                        await ref.read(configOptionNotifierProvider.notifier).resetOption();
                      },
                    ),
                  ];
                },
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
                    items: const [
                      GeneralSettingTiles(),
                      PlatformSettingsTiles(),
                      AdvancedSettingTiles(),
                    ],
                  ),

                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.route),
                    sectionTitle: t.config.section.route,
                    items: const [
                      RouteOptionsTiles(),
                    ],
                  ),
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.globe),
                    sectionTitle: t.config.section.dns,
                    items: const [DnsOptionsTiles()],
                  ),
                  PlatformListSection(
                    sectionIcon: const Icon(FontAwesomeIcons.rightToBracket),
                    sectionTitle: t.config.section.inbound,
                    items: const [InboundOptionsTiles()],
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
                  if (PlatformUtils.isIOS)
                    Material(
                      child: ListTile(
                        title: Text(t.settings.advanced.resetTunnel),
                        leading: const Icon(FluentIcons.arrow_reset_24_regular),
                        onTap: () async {
                          await ref.read(resetTunnelProvider.notifier).run();
                        },
                      ),
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
  return null;
  // if (Theme.of(context)?.isDark == true) {
  //   return PlatformTheme.of(context)?.cupertinoDarkTheme?.textTheme.textStyle ?? PlatformTheme.of(context)?.materialDarkTheme?.textTheme.labelMedium;
  // }
  // return PlatformTheme.of(context)?.cupertinoLightTheme?.textTheme.textStyle ?? PlatformTheme.of(context)?.materialLightTheme?.textTheme.labelMedium;
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
    title: Text(
      title ?? "",
      style: textTheme(context),
    ),
    subtitle: subtitle != null
        ? Text(
            subtitle,
            style: textTheme(context),
          )
        : null,
    value: value,
    onChanged: onChanged,
  );
}
