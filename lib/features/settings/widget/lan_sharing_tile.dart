import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LanSharingPreferenceWidget extends HookConsumerWidget {
  const LanSharingPreferenceWidget({super.key, this.showLeading = true});

  /// Whether to show the leading icon of the [ListTile].
  ///
  /// Hidden when the widget is embedded in the quick settings modal.
  final bool showLeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    Future<String?> getSharingLink() async {
      final ipResult = await ref.read(hiddifyCoreServiceProvider).getLANIP().run();
      final ip = ipResult.fold((_) => null, (r) => r.ip);
      if (ip == null) {
        ref.read(inAppNotificationControllerProvider).showErrorToast(t.pages.settings.inbound.lanIPError);
        return null;
      }
      final port = ref.read(ConfigOptions.mixedPort);
      final password = ref.read(ConfigOptions.lanSharingPassword);
      if (password.isEmpty) {
        return 'socks://$ip:$port';
      } else {
        return 'socks://hiddify:$password@$ip:$port';
      }
    }

    Future<void> editPassword() async {
      final inputValue = await ref
          .read(dialogNotifierProvider.notifier)
          .showSettingInput(
            title: t.pages.settings.inbound.lanSharingPassword,
            initialValue: ref.read(ConfigOptions.lanSharingPassword),
            onReset: ref.read(ConfigOptions.lanSharingPassword.notifier).reset,
          );
      if (inputValue != null) {
        await ref.read(ConfigOptions.lanSharingPassword.notifier).update(inputValue);
      }
    }

    // The whole widget (tile + action buttons) is wrapped in a single
    // [InkWell] so the hover/tap animation covers the entire widget, while the
    // buttons live below the tile to avoid overflowing the tile on narrow
    // screens (e.g. iOS).
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: editPassword,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: showLeading ? const Icon(Icons.share_rounded) : null,
              title: Text(t.pages.settings.inbound.lanSharing),
              subtitle: Text(
                ref.watch(ConfigOptions.lanSharingPassword).isEmpty
                    ? t.pages.settings.inbound.lanSharingPasswordNotSet
                    : ref.watch(ConfigOptions.lanSharingPassword),
              ),
              trailing: Switch.adaptive(
                value: ref.watch(ConfigOptions.allowConnectionFromLan),
                onChanged: ref.read(ConfigOptions.allowConnectionFromLan.notifier).update,
              ),
            ),
            if (ref.watch(ConfigOptions.allowConnectionFromLan))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final link = await getSharingLink();
                          if (link != null) {
                            await Clipboard.setData(ClipboardData(text: link));
                            ref
                                .read(inAppNotificationControllerProvider)
                                .showSuccessToast(t.common.msg.export.clipboard.success);
                          }
                        },
                        icon: Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                        label: Text(
                          t.pages.settings.inbound.copyLink,
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final link = await getSharingLink();
                          if (link != null) {
                            final qrLink = '#profile-title: LAN only\n$link#LAN only';
                            await ref.read(dialogNotifierProvider.notifier).showQrCode(qrLink, message: link);
                          }
                        },
                        icon: Icon(Icons.qr_code_rounded, color: theme.colorScheme.primary),
                        label: Text(
                          t.pages.settings.inbound.qrCode,
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
