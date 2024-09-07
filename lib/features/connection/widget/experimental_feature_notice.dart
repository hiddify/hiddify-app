import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

bool _testExperimentalNotice = false;

final disableExperimentalFeatureNoticeProvider = PreferencesNotifier.createAutoDispose(
  "disable_experimental_feature_notice",
  false,
  overrideValue: _testExperimentalNotice && kDebugMode ? false : null,
);

class ExperimentalFeatureNoticeDialog extends HookConsumerWidget {
  const ExperimentalFeatureNoticeDialog({super.key});

  Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final disableNotice = ref.watch(disableExperimentalFeatureNoticeProvider);

    return PlatformAlertDialog(
      title: Text(t.connection.experimentalNotice),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 468,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.connection.experimentalNoticeMsg),
              const Gap(8),
              CheckboxListTile(
                value: disableNotice,
                title: Text(t.connection.disableExperimentalNotice),
                secondary: const Icon(FluentIcons.eye_off_24_regular),
                onChanged: (value) async => ref.read(disableExperimentalFeatureNoticeProvider.notifier).update(value ?? false),
                dense: true,
              ),
              PlatformListTile(
                title: Text(t.config.pageTitle),
                leading: const Icon(FluentIcons.box_edit_24_regular),
                trailing: const Icon(FluentIcons.chevron_right_20_regular),
                onTap: () async {
                  await Navigator.of(context).maybePop(false);
                  if (context.mounted) {
                    const ConfigOptionsRoute().push(context);
                  }
                },
                material: (context, platform) => MaterialListTileData(
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(false),
          child: Text(
            MaterialLocalizations.of(context).cancelButtonLabel.toUpperCase(),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(true),
          child: Text(t.connection.connectAnyWay.toUpperCase()),
        ),
      ],
    );
  }
}
