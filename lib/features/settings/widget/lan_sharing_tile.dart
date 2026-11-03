import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LanSharingPreferenceWidget extends ConsumerWidget {
  const LanSharingPreferenceWidget({super.key, this.showLeading = true});

  /// Whether to show the leading icon of the [ListTile].
  ///
  /// Hidden when the widget is embedded in the quick settings modal.
  final bool showLeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final enabled = ref.watch(ConfigOptions.allowConnectionFromLan);

    // every install has a secret (PreferencesVersion4Migration); one the user removed stays removed
    Future<void> setEnabled(bool value) => ref.read(ConfigOptions.allowConnectionFromLan.notifier).update(value);

    return ListTile(
      leading: showLeading ? const Icon(Icons.share_rounded, size: 28) : null,
      title: Text(t.pages.settings.inbound.lanSharing),
      onTap: () => setEnabled(!enabled),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled) ...[
            IconButton(
              tooltip: t.pages.settings.inbound.qrCode,
              onPressed: () => ref.read(dialogNotifierProvider.notifier).showLanSharingQr(),
              icon: const Icon(Icons.qr_code_rounded),
            ),
            SizedBox(height: 32, child: VerticalDivider(width: 16, color: theme.colorScheme.outlineVariant)),
          ],
          Switch.adaptive(value: enabled, onChanged: setEnabled),
        ],
      ),
    );
  }
}
