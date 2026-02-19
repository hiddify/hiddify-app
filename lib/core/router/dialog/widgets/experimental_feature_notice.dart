import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final disableNotice = ref.watch(disableExperimentalFeatureNoticeProvider);

    return AlertDialog(
      title: Text(t.dialogs.experimentalNotice.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 468,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.dialogs.experimentalNotice.msg),
              const Gap(8),
              CheckboxListTile(
                value: disableNotice,
                title: Text(t.dialogs.experimentalNotice.disable),
                secondary: const Icon(FluentIcons.eye_off_24_regular),
                onChanged: (value) async =>
                    await ref.read(disableExperimentalFeatureNoticeProvider.notifier).update(value ?? false),
                dense: true,
              ),
              ListTile(
                title: Text(t.pages.settings.title),
                leading: const Icon(FluentIcons.box_edit_24_regular),
                trailing: const Icon(FluentIcons.chevron_right_20_regular),
                onTap: () {
                  context.pop(false);
                  context.goNamed('settings');
                },
                dense: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel.toUpperCase()),
        ),
        TextButton(onPressed: () => context.pop(true), child: Text(t.connection.connect)),
      ],
    );
  }
}
