import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hiddify/utils/validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WarpOptionsTiles extends HookConsumerWidget {
  const WarpOptionsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final warpOptions = ref.watch(warpOptionNotifierProvider);
    final isWarpEnabled = ref.watch(ConfigOptions.enableWarp);
    return Column(
      children: [
        SwitchListTile.adaptive(
          title: Text(t.config.enableWarp),
          value: isWarpEnabled,
          onChanged: (value) async {
            await ref.read(ConfigOptions.enableWarp.notifier).update(value);
            await ref.read(warpOptionNotifierProvider.notifier).genWarps();
          },
        ),
        ListTile(
          title: Text(t.config.generateWarpConfig),
          subtitle: !isWarpEnabled
              ? null
              : warpOptions.when(
                  data: (_) => null,
                  error: (_, __) => Text(
                    t.config.missingWarpConfig,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  loading: () => const LinearProgressIndicator(),
                ),
          enabled: isWarpEnabled,
          onTap: () async {
            await ref.read(warpOptionNotifierProvider.notifier).genWarps();
          },
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.warpDetourMode),
          preferences: ref.watch(ConfigOptions.warpDetourMode.notifier),
          enabled: isWarpEnabled,
          choices: WarpDetourMode.values,
          title: t.config.warpDetourMode,
          presentChoice: (value) => value.present(t),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpLicenseKey),
          preferences: ref.watch(ConfigOptions.warpLicenseKey.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpLicenseKey,
          presentValue: (value) => value.isEmpty ? t.general.notSet : value,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpCleanIp),
          preferences: ref.watch(ConfigOptions.warpCleanIp.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpCleanIp,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpPort),
          preferences: ref.watch(ConfigOptions.warpPort.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpPort,
          inputToValue: int.tryParse,
          validateInput: isPort,
          digitsOnly: true,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoise),
          preferences: ref.watch(ConfigOptions.warpNoise.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpNoise,
          inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoiseMode),
          preferences: ref.watch(ConfigOptions.warpNoiseMode.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpNoiseMode,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoiseSize),
          preferences: ref.watch(ConfigOptions.warpNoiseSize.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpNoiseSize,
          inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoiseDelay),
          preferences: ref.watch(ConfigOptions.warpNoiseDelay.notifier),
          enabled: isWarpEnabled,
          title: t.config.warpNoiseDelay,
          inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
        ),
      ],
    );
  }
}

class WarpLicenseDialog extends HookConsumerWidget {
  const WarpLicenseDialog({super.key});

  // for focus management
  KeyEventResult _handleKeyEvent(KeyEvent event, String key) {
    if (KeyboardConst.select.contains(event.logicalKey) && event is KeyUpEvent) {
      UriUtils.tryLaunch(Uri.parse(WarpConst.url[key]!));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // for focus management
    final focusStates = <String, ValueNotifier<bool>>{
      WarpConst.warpTermsOfServiceKey: useState<bool>(false),
      WarpConst.warpPrivacyPolicyKey: useState<bool>(false),
    };
    final focusNodes = <String, FocusNode>{
      WarpConst.warpTermsOfServiceKey: useFocusNode(),
      WarpConst.warpPrivacyPolicyKey: useFocusNode(),
    };
    useEffect(() {
      for (final entry in focusNodes.entries) {
        entry.value.addListener(() => focusStates[entry.key]!.value = entry.value.hasPrimaryFocus);
      }
      return null;
    }, []);
    return AlertDialog(
      title: Text(t.config.warpConsent.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Focus(focusNode: focusNodes[WarpConst.warpTermsOfServiceKey], onKeyEvent: (node, event) => _handleKeyEvent(event, WarpConst.warpTermsOfServiceKey), child: const Gap(0.1)),
              Focus(focusNode: focusNodes[WarpConst.warpPrivacyPolicyKey], onKeyEvent: (node, event) => _handleKeyEvent(event, WarpConst.warpPrivacyPolicyKey), child: const Gap(0.1)),
              Text.rich(
                t.config.warpConsent.description(
                  tos: (text) => TextSpan(
                    text: text,
                    style: TextStyle(color: focusStates[WarpConst.warpTermsOfServiceKey]!.value ? Colors.green : Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await UriUtils.tryLaunch(
                          Uri.parse(Constants.cfWarpTermsOfService),
                        );
                      },
                  ),
                  privacy: (text) => TextSpan(
                    text: text,
                    style: TextStyle(color: focusStates[WarpConst.warpPrivacyPolicyKey]!.value ? Colors.green : Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await UriUtils.tryLaunch(
                          Uri.parse(Constants.cfWarpPrivacyPolicy),
                        );
                      },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(t.general.decline),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(t.general.agree),
        ),
      ],
    );
  }
}

class WarpConfigDialog extends HookConsumerWidget {
  const WarpConfigDialog({super.key, required this.content});
  final String content;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return ConstrainedBox(
      constraints: AlertDialogConst.boxConstraints,
      child: AlertDialog(
        title: Text(t.config.warpConfigGenerated),
        content: Text(content),
      ),
    );
  }
}
