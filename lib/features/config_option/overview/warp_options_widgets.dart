import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/widget/custom_alert_dialog.dart';
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
    final t = ref.watch(translationsProvider);

    final warpOptions = ref.watch(warpOptionNotifierProvider);
    final warpPrefaceCompleted = warpOptions.consentGiven;
    final enableWarp = ref.watch(ConfigOptions.enableWarp);
    final canChangeOptions = warpPrefaceCompleted && enableWarp;

    ref.listen(
      warpOptionNotifierProvider.select((value) => value.configGeneration),
      (previous, next) async {
        if (next case AsyncData(value: final log) when log.isNotEmpty) {
          await CustomAlertDialog(
            title: t.config.warpConfigGenerated,
            message: log,
          ).show(context);
        }
      },
    );

    return Column(
      children: [
        SwitchListTile(
          title: Text(t.config.enableWarp),
          value: enableWarp,
          onChanged: (value) async {
            if (!warpPrefaceCompleted) {
              final agreed = await showDialog<bool>(
                context: context,
                builder: (context) => const WarpLicenseAgreementModal(),
              );
              if (agreed ?? false) {
                await ref.read(warpOptionNotifierProvider.notifier).agree();
                await ref.read(ConfigOptions.enableWarp.notifier).update(value);
              }
            } else {
              await ref.read(ConfigOptions.enableWarp.notifier).update(value);
            }
          },
        ),
        ListTile(
          title: Text(t.config.generateWarpConfig),
          subtitle: canChangeOptions
              ? switch (warpOptions.configGeneration) {
                  AsyncLoading() => const LinearProgressIndicator(),
                  AsyncError() => Text(
                      t.config.missingWarpConfig,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  _ => null,
                }
              : null,
          enabled: canChangeOptions,
          onTap: () async {
            await ref.read(warpOptionNotifierProvider.notifier).generateWarpConfig();
            await ref.read(warpOptionNotifierProvider.notifier).generateWarp2Config();
          },
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.warpDetourMode),
          preferences: ref.watch(ConfigOptions.warpDetourMode.notifier),
          enabled: canChangeOptions,
          choices: WarpDetourMode.values,
          title: t.config.warpDetourMode,
          presentChoice: (value) => value.present(t),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpLicenseKey),
          preferences: ref.watch(ConfigOptions.warpLicenseKey.notifier),
          enabled: canChangeOptions,
          title: t.config.warpLicenseKey,
          presentValue: (value) => value.isEmpty ? t.general.notSet : value,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpCleanIp),
          preferences: ref.watch(ConfigOptions.warpCleanIp.notifier),
          enabled: canChangeOptions,
          title: t.config.warpCleanIp,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpPort),
          preferences: ref.watch(ConfigOptions.warpPort.notifier),
          enabled: canChangeOptions,
          title: t.config.warpPort,
          inputToValue: int.tryParse,
          validateInput: isPort,
          digitsOnly: true,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoise),
          preferences: ref.watch(ConfigOptions.warpNoise.notifier),
          enabled: canChangeOptions,
          title: t.config.warpNoise,
          inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoiseMode),
          preferences: ref.watch(ConfigOptions.warpNoiseMode.notifier),
          enabled: canChangeOptions,
          title: t.config.warpNoiseMode,
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoiseSize),
          preferences: ref.watch(ConfigOptions.warpNoiseSize.notifier),
          enabled: canChangeOptions,
          title: t.config.warpNoiseSize,
          inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.warpNoiseDelay),
          preferences: ref.watch(ConfigOptions.warpNoiseDelay.notifier),
          enabled: canChangeOptions,
          title: t.config.warpNoiseDelay,
          inputToValue: (input) => OptionalRange.tryParse(input, allowEmpty: true),
          presentValue: (value) => value.present(t),
          formatInputValue: (value) => value.format(),
        ),
      ],
    );
  }
}

class WarpLicenseAgreementModal extends HookConsumerWidget {
  const WarpLicenseAgreementModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return AlertDialog(
      title: Text(t.config.warpConsent.title),
      content: Text.rich(
        t.config.warpConsent.description(
          tos: (text) => TextSpan(
            text: text,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await UriUtils.tryLaunch(
                  Uri.parse(Constants.cfWarpTermsOfService),
                );
              },
          ),
          privacy: (text) => TextSpan(
            text: text,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await UriUtils.tryLaunch(
                  Uri.parse(Constants.cfWarpPrivacyPolicy),
                );
              },
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
