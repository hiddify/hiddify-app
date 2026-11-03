import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/proxy_secret.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Edits the password of the user "hiddify" that the local proxy asks for: typed, a new one made,
/// or removed, at the user's own risk, after saying what that means.
Future<void> editProxySecret(WidgetRef ref) async {
  final text = ref.read(translationsProvider).requireValue.pages.settings.inbound;
  final dialogs = ref.read(dialogNotifierProvider.notifier);
  final secret = ref.read(ConfigOptions.lanSharingPassword);
  var generate = false;
  final typed = await dialogs.showSettingInput<String>(
    title: text.proxySecret,
    initialValue: secret,
    mapTo: (value) => value.trim(),
    // empty removes it
    validator: (value) => value.trim().isEmpty || value.trim().length >= 4,
    optionalAction: (text.generateSecret, () => generate = true),
  );
  final input = generate ? generateProxySecret() : typed;
  if (input == null || input == secret) return;
  // no secret: any app or device that reaches the port may use it
  if (input.isEmpty && !await dialogs.showConfirmation(title: text.removeSecret, message: text.removeSecretMsg)) {
    return;
  }
  await ref.read(ConfigOptions.lanSharingPassword.notifier).update(input);
}
