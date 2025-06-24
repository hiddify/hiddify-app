import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/tip_card.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

class SettingsPage extends HookConsumerWidget {
  SettingsPage({super.key, String? section}) : section = section != null ? ConfigOptionSection.values.byName(section) : null;

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
      appBar: AppBar(
        title: Text(t.config.pageTitle),
        actions: [
          PopupMenuButton<dynamic>(
            icon: Icon(AdaptiveIcon(context).more),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonClipboard().then((success) {
                  if (success) {
                    ref.read(inAppNotificationControllerProvider).showSuccessToast(t.general.clipboardExportSuccessMsg);
                  }
                }),
                child: Text(t.settings.exportOptions),
              ),
              PopupMenuItem(
                onTap: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonClipboard(excludePrivate: false).then((success) {
                  if (success) {
                    ref.read(inAppNotificationControllerProvider).showSuccessToast(t.general.clipboardExportSuccessMsg);
                  }
                }),
                child: Text(t.settings.exportAllOptions),
              ),
              PopupMenuItem(
                onTap: () async => await ref
                    .read(dialogNotifierProvider.notifier)
                    .showConfirmation(
                      title: t.settings.importOptions,
                      message: t.settings.importOptionsMsg,
                    )
                    .then((shouldImport) async {
                  if (shouldImport) {
                    await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
                  }
                }),
                child: Text(t.settings.importOptions),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonFile().then((success) {
                  if (success) {
                    ref.read(inAppNotificationControllerProvider).showSuccessToast(t.general.jsonFileExportSuccessMsg);
                  }
                }),
                child: Text(t.settings.exportOptionsFile),
              ),
              PopupMenuItem(
                onTap: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonFile(excludePrivate: false).then((success) {
                  if (success) {
                    ref.read(inAppNotificationControllerProvider).showSuccessToast(t.general.jsonFileExportSuccessMsg);
                  }
                }),
                child: Text(t.settings.exportAllOptionsFile),
              ),
              PopupMenuItem(
                onTap: () async => await ref
                    .read(dialogNotifierProvider.notifier)
                    .showConfirmation(
                      title: t.settings.importOptions,
                      message: t.settings.importOptionsMsg,
                    )
                    .then((shouldImport) async {
                  if (shouldImport) {
                    await ref.read(configOptionNotifierProvider.notifier).importFromJsonFile();
                  }
                }),
                child: Text(t.settings.importOptionsFile),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: Text(t.config.resetBtn),
                onTap: () async => await ref.read(configOptionNotifierProvider.notifier).resetOption(),
              ),
            ],
          ),
          const Gap(8),
        ],
      ),
      body: ListView(
        children: [
          TipCard(message: t.settings.experimentalMsg),
          SettingsSection(
            title: t.settings.general.sectionTitle,
            icon: Icons.layers_rounded,
            namedLocation: context.namedLocation('general'),
          ),
          SettingsSection(
            title: t.config.section.route,
            icon: Icons.route_rounded,
            namedLocation: context.namedLocation('routeOptions'),
          ),
          SettingsSection(
            title: t.config.section.dns,
            icon: Icons.dns_rounded,
            namedLocation: context.namedLocation('dnsOptions'),
          ),
          SettingsSection(
            title: t.config.section.inbound,
            icon: Icons.input_rounded,
            namedLocation: context.namedLocation('inboundOptions'),
          ),
          SettingsSection(
            title: experimental(t.config.section.tlsTricks),
            icon: Icons.content_cut_rounded,
            namedLocation: context.namedLocation('tlsTricks'),
          ),
          SettingsSection(
            title: t.config.section.warp,
            icon: Icons.cloud_rounded,
            namedLocation: context.namedLocation('warpOptions'),
          ),
          if (PlatformUtils.isIOS)
            Material(
              child: ListTile(
                title: Text(t.settings.advanced.resetTunnel),
                leading: const Icon(Icons.autorenew_rounded),
                onTap: () async {
                  await ref.read(resetTunnelNotifierProvider.notifier).run();
                },
              ),
            ),
          if (Breakpoints.small.isActive(context)) ...[
            SettingsSection(
              title: t.logs.pageTitle,
              icon: Icons.description_rounded,
              namedLocation: context.namedLocation('logs'),
            ),
            SettingsSection(
              title: t.about.pageTitle,
              icon: Icons.info_rounded,
              namedLocation: context.namedLocation('about'),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsSection extends HookConsumerWidget {
  const SettingsSection({super.key, required this.title, required this.icon, required this.namedLocation});

  final String title;
  final IconData icon;
  final String namedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go(namedLocation),
    );
  }
}
