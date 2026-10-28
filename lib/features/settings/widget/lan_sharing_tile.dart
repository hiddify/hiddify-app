import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Characters used for the generated LAN sharing password.
///
/// Visually ambiguous characters (`0`/`O`, `1`/`l`/`I`) are left out so the
/// password stays readable when it is typed from a QR code by hand.
const _passwordAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

const _passwordLength = 16;

String _generatePassword() {
  final random = Random.secure();
  return List.generate(_passwordLength, (_) => _passwordAlphabet[random.nextInt(_passwordAlphabet.length)]).join();
}

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
    final enabled = ref.watch(ConfigOptions.allowConnectionFromLan);

    /// Creates the password the first time sharing is turned on and keeps it
    /// for every later session, so the user never has to pick or manage one.
    Future<void> ensurePassword() async {
      if (ref.read(ConfigOptions.lanSharingPassword).isEmpty) {
        await ref.read(ConfigOptions.lanSharingPassword.notifier).update(_generatePassword());
      }
    }

    // Covers sharing that was already enabled before the password became
    // mandatory.
    useEffect(() {
      if (enabled) ensurePassword();
      return null;
    }, [enabled]);

    Future<void> setEnabled(bool value) async {
      if (value) await ensurePassword();
      await ref.read(ConfigOptions.allowConnectionFromLan.notifier).update(value);
    }

    return ListTile(
      leading: showLeading ? const Icon(Icons.share_rounded) : null,
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
