import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_update_state.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appInfo = ref.watch(appInfoProvider).requireValue;
    final appUpdate = ref.watch(appUpdateNotifierProvider);

    ref.listen(appUpdateNotifierProvider, (_, next) async {
      if (!context.mounted) return;
      switch (next) {
        case AppUpdateStateAvailable(:final versionInfo) || AppUpdateStateIgnored(:final versionInfo):
          return await ref
              .read(dialogNotifierProvider.notifier)
              .showNewVersion(currentVersion: appInfo.presentVersion, newVersion: versionInfo, canIgnore: false);
        case AppUpdateStateError(:final error):
          return CustomToast.error(t.presentShortError(error)).show(context);
        case AppUpdateStateNotAvailable():
          return CustomToast.success(t.pages.about.notAvailableMsg).show(context);
      }
    });

    final conditionalTiles = [
      if (appInfo.release.allowCustomUpdateChecker)
        ListTile(
          title: Text(t.pages.about.checkForUpdate),
          trailing: switch (appUpdate) {
            AppUpdateStateChecking() => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            _ => const Icon(FluentIcons.arrow_sync_24_regular),
          },
          onTap: () async {
            await ref.read(appUpdateNotifierProvider.notifier).check();
          },
        ),
      if (PlatformUtils.isDesktop)
        ListTile(
          title: Text(t.pages.about.openWorkingDir),
          trailing: const Icon(FluentIcons.open_folder_24_regular),
          onTap: () async {
            final path = ref.watch(appDirectoriesProvider).requireValue.workingDir.uri;
            await UriUtils.tryLaunch(path);
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.about.title),
        actions: [
          PopupMenuButton(
            icon: Icon(AdaptiveIcon(context).more),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text(t.common.addToClipboard),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: appInfo.format()));
                  },
                ),
              ];
            },
          ),
          const Gap(8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.images.logo.svg(width: 64, height: 64),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.common.appTitle, style: Theme.of(context).textTheme.titleLarge),
                      const Gap(4),
                      Text("${t.common.version} ${appInfo.presentVersion}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ...conditionalTiles,
              if (conditionalTiles.isNotEmpty) const Divider(),
              ListTile(
                title: Text(t.pages.about.sourceCode),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.githubUrl));
                },
              ),
              ListTile(
                title: Text(t.pages.about.telegramChannel),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.telegramChannelUrl));
                },
              ),
              ListTile(
                title: Text(t.pages.about.termsAndConditions),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl));
                },
              ),
              ListTile(
                title: Text(t.pages.about.privacyPolicy),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl));
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
