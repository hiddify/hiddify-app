import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// What another device needs to use a shared proxy by hand.
typedef ProxyCredentials = ({String ip, int port, String username, String password});

class QrCodeDialog extends HookConsumerWidget {
  const QrCodeDialog(this.data, {super.key, required this.title, required this.link, this.subtitle, this.credentials});

  /// The text encoded in the QR code.
  final String data;
  final String title;
  final String? subtitle;

  /// Copied by the copy-full-link button.
  final String link;

  /// Shown as copyable tiles under the title when set.
  final ProxyCredentials? credentials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    Future<void> copy(String value) async {
      await Clipboard.setData(ClipboardData(text: value));
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
    }

    return Dialog(
      child: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QrCode(data),
              const Gap(16),
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const Gap(4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (credentials != null) ...[const Gap(16), _CredentialTiles(credentials!, onCopy: copy)],
              const Gap(12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(onPressed: () => copy(link), child: Text(t.dialogs.qrCode.copyFullLink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCode extends StatelessWidget {
  const _QrCode(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    // The code always sits on white so any scanner reads it, so its colors come from the
    // light tones of the theme's primary color, whatever the app's own brightness is.
    final colors = ColorScheme.fromSeed(seedColor: Theme.of(context).colorScheme.primary);

    return Container(
      width: 208,
      height: 208,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            padding: EdgeInsets.zero,
            // Leaves room for the logo, which covers the middle of the code.
            errorCorrectionLevel: QrErrorCorrectLevel.Q,
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: colors.primary),
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: colors.onSurface),
          ),
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Assets.images.logo.svg(colorFilter: ColorFilter.mode(colors.onPrimary, BlendMode.srcIn)),
          ),
        ],
      ),
    );
  }
}

class _CredentialTiles extends HookConsumerWidget {
  const _CredentialTiles(this.credentials, {required this.onCopy});

  final ProxyCredentials credentials;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final revealed = useState(false);

    final username = _CopyTile(
      label: t.dialogs.qrCode.username,
      value: credentials.username,
      onTap: () => onCopy(credentials.username),
    );
    final password = _CopyTile(
      label: t.dialogs.qrCode.password,
      // Groups of four are easier to read and type by hand; the copy keeps the raw password.
      value: revealed.value ? RegExp('.{1,4}').allMatches(credentials.password).map((m) => m[0]).join(' ') : '••••••••',
      onTap: () => onCopy(credentials.password),
      action: IconButton(
        tooltip: revealed.value ? t.dialogs.qrCode.hidePassword : t.dialogs.qrCode.showPassword,
        onPressed: () => revealed.value = !revealed.value,
        icon: Icon(revealed.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 24),
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CopyTile(label: t.dialogs.qrCode.ip, value: credentials.ip, onTap: () => onCopy(credentials.ip)),
            ),
            const Gap(8),
            IntrinsicWidth(
              child: _CopyTile(
                label: t.dialogs.qrCode.port,
                value: '${credentials.port}',
                onTap: () => onCopy('${credentials.port}'),
              ),
            ),
          ],
        ),
        const Gap(8),
        // A revealed password needs the full width to fit on one line.
        if (revealed.value) ...[
          username,
          const Gap(8),
          password,
        ] else
          Row(
            children: [
              Expanded(child: username),
              const Gap(8),
              Expanded(child: password),
            ],
          ),
      ],
    );
  }
}

/// A labelled value that copies itself when tapped.
class _CopyTile extends StatelessWidget {
  const _CopyTile({required this.label, required this.value, required this.onTap, this.action});

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Gap(2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      // Addresses and passwords read left to right in every language.
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  ?action,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
