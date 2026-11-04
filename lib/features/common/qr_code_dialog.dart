import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/utils/proxy_secret.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/proxy_secret_editor.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// What another device needs to use a shared proxy by hand. [ip] is null until it's known;
/// [password] is null for a port that asks for none, and empty for one whose secret was removed.
typedef ProxyCredentials = ({InternetAddress? ip, int port, String username, String? password});

class QrCodeDialog extends HookConsumerWidget {
  const QrCodeDialog(
    this.data, {
    super.key,
    required this.title,
    required this.link,
    this.subtitle,
    this.icon,
    this.intro,
    this.credentials,
    this.loading = false,
    this.showCode = true,
    this.footer,
    this.onEditPassword,
    this.header,
  });

  /// At the top, over everything else.
  final Widget? header;

  /// The text encoded in the QR code, or null when there's none.
  final String? data;
  final String title;
  final String? subtitle;

  /// Above the title, when there is no code to show.
  final IconData? icon;

  /// Under the title, in place of [subtitle].
  final Widget? intro;

  /// Copied by the copy-full-link button, which is off while this is null.
  final String? link;

  /// Shown as copyable tiles under the title when set.
  final ProxyCredentials? credentials;

  /// Whether [data] is still on its way. A null [data] that isn't loading has no code to show.
  final bool loading;

  /// False for a proxy only this device can reach: there is no code to scan, nor its place.
  final bool showCode;

  /// Over the buttons.
  final Widget? footer;

  /// Changes the password, offered next to it once it is shown.
  final VoidCallback? onEditPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final linkCopied = _useCopiedFlag();
    final data = this.data;
    final link = this.link;

    return Dialog(
      child: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (header case final header?) ...[header, const Gap(20)],
              if (showCode) ...[if (data != null) _QrCode(data) else _QrPlaceholder(loading: loading), const Gap(16)],
              if (icon case final icon? when !showCode) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 28, color: theme.colorScheme.onPrimaryContainer),
                ),
                const Gap(12),
              ],
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              if (intro case final intro?) ...[
                const Gap(8),
                intro,
              ] else if (subtitle != null) ...[
                const Gap(4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (credentials != null) ...[
                const Gap(16),
                _CredentialTiles(credentials!, onEditPassword: onEditPassword),
              ],
              if (footer case final footer?) ...[const Gap(8), footer],
              const Gap(12),
              Row(
                children: [
                  TextButton(
                    onPressed: link == null
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: link));
                            linkCopied.show();
                          },
                    child: _CopiedSwap(
                      label: t.dialogs.qrCode.copyFullLink,
                      copied: linkCopied.value,
                      alignment: Alignment.center,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The QR dialog for LAN sharing. It opens at once and looks up this device's local IP while open.
class LanSharingQrDialog extends HookConsumerWidget {
  const LanSharingQrDialog({super.key, this.header});

  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // One lookup per opening. The time limit keeps a core that never answers from leaving the
    // dialog loading forever.
    final lookup = useFuture(
      useMemoized(() => _findLanIp(ref).timeout(const Duration(seconds: 10), onTimeout: () => null)),
    );
    // Null while the lookup runs. A lookup that ends without an address gets 127.0.0.1, the same
    // answer the core gives when this device has no local network.
    final ip = lookup.connectionState == ConnectionState.done ? (lookup.data ?? InternetAddress.loopbackIPv4) : null;
    const username = 'hiddify';
    // the network has a port of its own, apart from this device's
    final port = ref.watch(ConfigOptions.lanSharingPort);
    final password = ref.watch(ConfigOptions.lanSharingPassword);
    final name = ip?.isLoopback ?? false ? QrCodeDialogConst.localhostProfileName : QrCodeDialogConst.lanProfileName;
    final link = ip == null ? null : 'socks://${_userInfo(password)}${ip.address}:$port#$name';

    return QrCodeDialog(
      // The device that scans the code would reach itself at 127.0.0.1, so that gets no code.
      ip == null || ip.isLoopback ? null : '#profile-title: $name\n$link',
      title: name,
      subtitle: t.pages.settings.inbound.lanQrSubtitle,
      link: link,
      credentials: (ip: ip, port: port, username: username, password: password),
      loading: ip == null,
      onEditPassword: () => editProxySecret(ref),
      header: header,
    );
  }
}

/// The local proxy for this device and for other devices on the network, one tab each. Shown when
/// the user picks proxy mode ([onPick]), from the Manual tab on the home page, and from LAN sharing
/// ([otherDevices]).
class ProxyDialog extends HookWidget {
  const ProxyDialog({super.key, this.onPick = false, this.otherDevices = false});

  final bool onPick;
  final bool otherDevices;

  @override
  Widget build(BuildContext context) {
    final other = useState(otherDevices);
    final header = Consumer(
      builder: (context, ref, _) {
        final t = ref.watch(translationsProvider).requireValue;
        return SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(t.dialogs.localProxy.thisDevice)),
              ButtonSegment(value: true, label: Text(t.dialogs.localProxy.otherDevices)),
            ],
            selected: {other.value},
            onSelectionChanged: (value) => other.value = value.first,
          ),
        );
      },
    );
    return other.value ? LanSharingQrDialog(header: header) : LocalProxyDialog(onPick: onPick, header: header);
  }
}

/// What other apps on this device need to use the local proxy: proxy mode routes nothing by itself,
/// each app is set to use it in its own settings. The port and the password are edited in place.
/// [onPick] offers not to show it again on picking proxy mode.
class LocalProxyDialog extends HookConsumerWidget {
  const LocalProxyDialog({super.key, this.onPick = false, this.header});

  final bool onPick;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.localProxy;
    final port = ref.watch(ConfigOptions.mixedPort);
    final auth = ref.watch(ConfigOptions.localProxyAuth);
    // the one secret of the user "hiddify", shared with the local network's port
    final secret = ref.watch(ConfigOptions.lanSharingPassword);
    final editing = useState<_Field?>(null);
    final linkCopied = _useCopiedFlag();
    const username = 'hiddify';

    // the local port asks for the secret only while the user has it ask
    final asked = auth ? secret : '';
    final link = 'socks://${_userInfo(asked)}127.0.0.1:$port#${QrCodeDialogConst.localhostProfileName}';
    final telegram = Uri(
      scheme: 'tg',
      host: 'socks',
      queryParameters: {
        'server': '127.0.0.1',
        'port': '$port',
        if (asked.isNotEmpty) ...{'user': username, 'pass': asked},
      },
    ).toString();
    void copyLink(String value) {
      Clipboard.setData(ClipboardData(text: value));
      linkCopied.show();
    }

    // A password that is asked must exist: one the user removed in the settings gets a new one.
    Future<void> setPassword() async {
      if (secret.isEmpty) await ref.read(ConfigOptions.lanSharingPassword.notifier).update(generateProxySecret());
      await ref.read(ConfigOptions.localProxyAuth.notifier).update(true);
    }

    Widget editor(_Field field) => _FieldEditor(
      label: field == _Field.port ? t.dialogs.qrCode.port : t.dialogs.qrCode.password,
      initial: field == _Field.port ? '$port' : secret,
      mono: field == _Field.password,
      validate: (value) => switch (field) {
        _Field.port => switch (int.tryParse(value)) {
          final p? when p >= 1024 && p <= 65535 => null,
          _ => text.portRange,
        },
        _Field.password => value.length < 4 ? text.passwordTooShort : null,
      },
      onSave: (value) async {
        if (field == _Field.port) {
          await ref.read(ConfigOptions.mixedPort.notifier).update(int.parse(value));
        } else {
          await ref.read(ConfigOptions.lanSharingPassword.notifier).update(value);
        }
        editing.value = null;
      },
      onCancel: () => editing.value = null,
    );
    Widget edit(_Field field) => _TileIcon(text.edit, Icons.edit_outlined, () => editing.value = field);

    return Dialog(
      child: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (header case final header?) ...[header, const Gap(20)],
              _Steps(text.steps),
              const Gap(16),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    if (editing.value == _Field.port)
                      editor(_Field.port)
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _CopyTile(
                              label: text.server,
                              value: const _Value('127.0.0.1'),
                              copyText: '127.0.0.1',
                            ),
                          ),
                          const Gap(8),
                          IntrinsicWidth(
                            child: _CopyTile(
                              label: t.dialogs.qrCode.port,
                              value: _Value('$port'),
                              copyText: '$port',
                              action: edit(_Field.port),
                            ),
                          ),
                        ],
                      ),
                    const Gap(8),
                    if (!auth)
                      _NoPasswordBar(text.noPassword, action: text.setPassword, onAction: setPassword)
                    else if (editing.value == _Field.password)
                      editor(_Field.password)
                    else
                      Row(
                        children: [
                          IntrinsicWidth(
                            child: _CopyTile(
                              label: t.dialogs.qrCode.username,
                              value: const _Value(username),
                              copyText: username,
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: _CopyTile(
                              label: t.dialogs.qrCode.password,
                              // seen only while edited
                              value: const _Value('••••••••'),
                              copyText: secret,
                              action: edit(_Field.password),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (onPick) ...[const Gap(8), const _DontShowAgain()],
              const Gap(4),
              Row(
                children: [
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.telegram, color: _telegramBlue),
                        onPressed: () => copyLink(telegram),
                        child: Text(text.telegramLink),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.link_rounded),
                        onPressed: () => copyLink(link),
                        child: Text(text.fullLink),
                      ),
                    ],
                    builder: (context, menu, _) => TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                      child: _CopiedSwap(label: text.copyLink, copied: linkCopied.value, alignment: Alignment.center),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The values of the local proxy dialog that can be edited.
enum _Field { port, password }

/// Telegram's own blue, beside its link.
const _telegramBlue = Color(0xFF2AABEE);

/// A value while it is edited, in place of its tile. [validate] says what is wrong with the text, or
/// null; only a valid text can be saved, and the error shows only for an invalid one.
class _FieldEditor extends HookWidget {
  const _FieldEditor({
    required this.label,
    required this.initial,
    required this.validate,
    required this.onSave,
    required this.onCancel,
    this.mono = false,
  });

  final String label;
  final String initial;
  final String? Function(String) validate;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = useTextEditingController(text: initial);
    useListenable(controller);
    final value = controller.text.trim();
    final error = validate(value);
    void save() {
      if (error == null) onSave(value);
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: error != null ? theme.colorScheme.error : theme.colorScheme.primary, width: 2),
    );
    final style = theme.textTheme.bodyLarge;
    return TextField(
      controller: controller,
      autofocus: true,
      textDirection: TextDirection.ltr,
      keyboardType: mono ? TextInputType.visiblePassword : TextInputType.number,
      inputFormatters: mono ? null : [FilteringTextInputFormatter.digitsOnly],
      style: mono ? ProxySecretText.styleOf(style) : style,
      onSubmitted: (_) => save(),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        errorText: error,
        enabledBorder: border,
        focusedBorder: border,
        errorBorder: border,
        focusedErrorBorder: border,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 14, 4, 14),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              visualDensity: VisualDensity.compact,
            ),
            IconButton.filled(
              tooltip: MaterialLocalizations.of(context).saveButtonLabel,
              onPressed: error == null ? save : null,
              // the app's icon theme would tint it like the surface around it
              icon: Icon(Icons.check_rounded, color: error == null ? theme.colorScheme.onPrimary : null),
              visualDensity: VisualDensity.compact,
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}

/// Under the local proxy's address while it asks for no password, with the action that turns it on.
class _NoPasswordBar extends StatelessWidget {
  const _NoPasswordBar(this.text, {required this.action, required this.onAction});

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 2, 4, 2),
      decoration: BoxDecoration(color: error.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: error)),
          ),
          TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

/// In the local proxy dialog shown on picking proxy mode, over its buttons: not to show it then again.
class _DontShowAgain extends ConsumerWidget {
  const _DontShowAgain();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final hide = ref.watch(ConfigOptions.hideLocalProxyOnPick);
    void toggle() => ref.read(ConfigOptions.hideLocalProxyOnPick.notifier).update(!hide);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: toggle,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: hide, onChanged: (_) => toggle(), visualDensity: VisualDensity.compact),
              Text(
                t.dialogs.localProxy.dontShowAgain,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The steps of a setup, each by its number.
class _Steps extends StatelessWidget {
  const _Steps(this.steps);

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: .14), shape: BoxShape.circle),
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(step, style: theme.textTheme.bodyMedium),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The user and secret of a socks link, or none when the proxy has no secret.
String _userInfo(String secret) => secret.isEmpty ? '' : 'hiddify:${Uri.encodeComponent(secret)}@';

/// This device's address on the local network as the core reports it, or null if the core can't say.
Future<InternetAddress?> _findLanIp(WidgetRef ref) async {
  final result = await ref.read(hiddifyCoreServiceProvider).getLANIP().run();
  return result.fold((_) => null, (r) => InternetAddress.tryParse(r.ip));
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
      width: QrCodeDialogConst.qrBoxSize,
      height: QrCodeDialogConst.qrBoxSize,
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

/// Holds the QR code's place, at its size: loading, or saying why there's no code. The only
/// dialog without a code is LAN sharing on 127.0.0.1.
class _QrPlaceholder extends ConsumerWidget {
  const _QrPlaceholder({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return Container(
      width: QrCodeDialogConst.qrBoxSize,
      height: QrCodeDialogConst.qrBoxSize,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: loading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.devices_rounded, size: 44, color: theme.colorScheme.onSurfaceVariant),
                const Gap(10),
                Text(t.dialogs.qrCode.localOnlyTitle, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                const Gap(4),
                Text(
                  t.dialogs.qrCode.localOnlyMessage,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _CredentialTiles extends HookConsumerWidget {
  const _CredentialTiles(this.credentials, {this.onEditPassword});

  final ProxyCredentials credentials;
  final VoidCallback? onEditPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final revealed = useState(false);
    final ip = credentials.ip;
    final secret = credentials.password;

    final username = _CopyTile(
      label: t.dialogs.qrCode.username,
      value: _Value(credentials.username),
      copyText: credentials.username,
    );
    final password = _CopyTile(
      label: t.dialogs.qrCode.password,
      value: revealed.value ? ProxySecretText(secret ?? '') : const _Value('••••••••'),
      copyText: secret,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (revealed.value && onEditPassword != null)
            _TileIcon(t.dialogs.localProxy.changePassword, Icons.edit_outlined, onEditPassword!),
          _TileIcon(
            revealed.value ? t.dialogs.qrCode.hidePassword : t.dialogs.qrCode.showPassword,
            revealed.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            () => revealed.value = !revealed.value,
          ),
        ],
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CopyTile(
                label: t.dialogs.qrCode.ip,
                value: ip != null
                    ? _Value(ip.address)
                    // Held at the text's line height so the tile keeps its height once the IP lands.
                    : const SizedBox(
                        height: 24,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ShimmerSkeleton(width: 96, height: 16),
                        ),
                      ),
                copyText: ip?.address,
              ),
            ),
            const Gap(8),
            IntrinsicWidth(
              child: _CopyTile(
                label: t.dialogs.qrCode.port,
                value: _Value('${credentials.port}'),
                copyText: '${credentials.port}',
              ),
            ),
          ],
        ),
        // a port that asks for nothing has nothing more to set
        if (secret == null)
          const SizedBox.shrink()
        // no secret: anyone who reaches the port can use it, without a user or password
        else if (secret.isEmpty) ...[
          const Gap(8),
          _NoSecretWarning(
            t.pages.settings.inbound.noSecret,
            onSet: onEditPassword,
            setLabel: t.dialogs.localProxy.setPassword,
          ),
        ]
        // A revealed password needs the full width to fit on one line.
        else if (revealed.value) ...[
          const Gap(8),
          username,
          const Gap(8),
          password,
        ] else ...[
          const Gap(8),
          Row(
            children: [
              Expanded(child: username),
              const Gap(8),
              Expanded(child: password),
            ],
          ),
        ],
      ],
    );
  }
}

/// A labelled value that copies [copyText] when tapped. Without [copyText] it isn't tappable.
class _CopyTile extends HookWidget {
  const _CopyTile({required this.label, required this.value, required this.copyText, this.action});

  final String label;
  final Widget value;
  final String? copyText;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copied = _useCopiedFlag();
    final copyText = this.copyText;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: copyText == null
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: copyText));
                copied.show();
              },
        child: Padding(
          // The action's own padding stands in for the end padding.
          padding: EdgeInsetsDirectional.fromSTEB(12, 6, action == null ? 12 : 2, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CopiedSwap(
                      label: label,
                      copied: copied.value,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Gap(2),
                    value,
                  ],
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

/// A proxy secret as it is, in a monospace font that keeps look-alike characters apart. A generated
/// one is in parts of four joined by dashes (generateProxySecret), so it needs no spacing here.
class ProxySecretText extends StatelessWidget {
  const ProxySecretText(this.secret, {super.key, this.style});

  final String secret;
  final TextStyle? style;

  /// [base] in the monospace look of a secret.
  static TextStyle? styleOf(TextStyle? base) =>
      base?.copyWith(fontFamily: 'monospace', fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: .5);

  @override
  Widget build(BuildContext context) =>
      Text(secret, textDirection: TextDirection.ltr, style: styleOf(style ?? Theme.of(context).textTheme.bodyLarge));
}

/// An icon button of a credential tile.
class _TileIcon extends StatelessWidget {
  const _TileIcon(this.tooltip, this.icon, this.onPressed);

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    iconSize: 20,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
  );
}

class _NoSecretWarning extends StatelessWidget {
  const _NoSecretWarning(this.text, {this.onSet, required this.setLabel});

  final String text;
  final VoidCallback? onSet;
  final String setLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open_rounded, size: 20, color: theme.colorScheme.error),
          const Gap(10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          if (onSet != null) TextButton(onPressed: onSet, child: Text(setLabel)),
        ],
      ),
    );
  }
}

/// A tile's value text.
class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // Addresses and passwords read left to right in every language.
      textDirection: TextDirection.ltr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

/// A flag that turns itself off a moment after each [show], for a short "copied" confirmation.
({bool value, VoidCallback show}) _useCopiedFlag() {
  final copied = useState(false);
  final timer = useRef<Timer?>(null);
  useEffect(
    () =>
        () => timer.value?.cancel(),
    const [],
  );
  return (
    value: copied.value,
    show: () {
      copied.value = true;
      timer.value?.cancel();
      timer.value = Timer(const Duration(milliseconds: 1400), () => copied.value = false);
    },
  );
}

/// Shows [label], or a green "Copied" in its place while [copied] is true. Keeps the size of
/// the wider of the two so nothing around it shifts.
class _CopiedSwap extends ConsumerWidget {
  const _CopiedSwap({
    required this.label,
    required this.copied,
    this.style,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final String label;
  final bool copied;
  final TextStyle? style;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    // M3 has no success color role; these greens stay readable on light and dark surfaces.
    final green = theme.brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800;
    const duration = Duration(milliseconds: 200);

    // The hidden text is still laid out to hold the size, so keep it out of hit tests and semantics.
    Widget slot(Widget child, {required bool visible, required Offset hiddenOffset}) => IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : hiddenOffset,
          duration: duration,
          child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: duration, child: child),
        ),
      ),
    );

    return Stack(
      alignment: alignment,
      children: [
        slot(
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          visible: !copied,
          hiddenOffset: const Offset(0, -0.4),
        ),
        slot(
          Semantics(
            liveRegion: true,
            child: Text(
              t.dialogs.qrCode.copied,
              maxLines: 1,
              style: (style ?? DefaultTextStyle.of(context).style).copyWith(color: green),
            ),
          ),
          visible: copied,
          hiddenOffset: const Offset(0, 0.4),
        ),
      ],
    );
  }
}
