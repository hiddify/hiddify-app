import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/proxy_secret.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_notifier.dart';
import 'package:hiddify/features/profile/add/phone_import/send_to_tv.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends HookConsumerWidget {
  const QrCodeDialog(this.data, {super.key, required this.title, required this.link});

  /// The text encoded in the QR code.
  final String data;
  final String title;

  /// Copied by the copy-full-link button.
  final String link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final linkCopied = _useCopiedFlag();

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
              const Gap(12),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
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

/// How a profile can be shared: its link as a QR code and to copy, when it has one (a remote
/// profile), then its configuration to copy, share or save. The configuration is built when the
/// dialog opens; copying is offered only when it fits the clipboard.
///
/// Also shares a single proxy ([title] and [configHint] then say so): it has no link, so its
/// configuration itself is the QR code when it is small enough to scan.
class ShareProfileDialog extends HookConsumerWidget {
  const ShareProfileDialog({
    super.key,
    required this.name,
    required this.loadConfig,
    this.link,
    this.title,
    this.configHint,
    this.configQr = false,
  });

  final String name;

  /// Above [name]; "Share profile" when null.
  final String? title;

  /// Under the configuration's heading; says it is the profile's full JSON when null.
  final String? configHint;

  /// Shows the configuration as a QR code, without its indentation, when it is at most
  /// [maxQrChars] long: Hiddify's scanner imports it like a pasted config.
  final bool configQr;

  /// The most a QR code holds that a phone camera still reads well.
  static const maxQrChars = 1000;

  /// The subscription link; null for a profile without one.
  final String? link;

  /// Builds the configuration JSON.
  final Future<String> Function() loadConfig;

  /// The most the clipboard takes. Android sends a copy through a binder transaction of at most
  /// 1 MB, two bytes a character, shared with the rest of the call; other platforms take far more.
  static int get maxClipboardChars => Platform.isAndroid ? 256 * 1024 : 4 * 1024 * 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final share = t.pages.profiles.share;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final config = useFuture(useMemoized(loadConfig));
    final link = this.link;
    final qrConfig = useMemoized(() {
      if (!configQr || config.data == null) return null;
      try {
        final compact = jsonEncode(jsonDecode(config.data!));
        return compact.length <= maxQrChars ? compact : null;
      } catch (_) {
        return null;
      }
    }, [config.data]);

    return Dialog(
      child: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.ios_share_rounded, color: s.onPrimaryContainer),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? share.title,
                          style: theme.textTheme.labelLarge?.copyWith(color: s.onSurfaceVariant),
                        ),
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
              if (link != null) ...[
                const Gap(20),
                Center(child: _QrCode(link)),
                const Gap(10),
                Text(
                  share.scanHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                ),
                const Gap(14),
                _CopyTile(
                  label: share.link,
                  value: _Value(link),
                  copyText: link,
                  action: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8, end: 10),
                    child: Icon(Icons.copy_rounded, size: 20, color: s.onSurfaceVariant),
                  ),
                ),
                if (_canSendToTv && ref.watch(isAndroidTvProvider).valueOrNull == false) ...[
                  const Gap(8),
                  _SendToTv(link),
                ],
              ],
              if (qrConfig != null) ...[
                const Gap(20),
                Center(child: _QrCode(qrConfig)),
                const Gap(10),
                Text(
                  share.scanHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                ),
              ],
              const Gap(22),
              Row(
                children: [
                  Icon(Icons.data_object_rounded, size: 18, color: s.primary),
                  const Gap(8),
                  Expanded(child: Text(share.config, style: theme.textTheme.titleSmall)),
                  if (config.data case final json?)
                    Text(
                      _formatSize(utf8.encode(json).length),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
                    ),
                ],
              ),
              const Gap(4),
              Text(
                configHint ?? share.configHint,
                style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
              ),
              const Gap(12),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: AlignmentDirectional.topCenter,
                child: switch (config) {
                  AsyncSnapshot(hasError: true) => Text(
                    share.configFailed,
                    style: theme.textTheme.bodyMedium?.copyWith(color: s.error),
                  ),
                  AsyncSnapshot(:final data?) => _ConfigActions(json: data, name: name),
                  _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(4))),
                  ),
                },
              ),
              const Gap(8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Phones only: they have the camera to scan the TV's code.
  static bool get _canSendToTv => Platform.isAndroid || Platform.isIOS;

  static String _formatSize(int bytes) => switch (bytes) {
    < 1024 => '$bytes B',
    < 1024 * 1024 => '${(bytes / 1024).toStringAsFixed(1)} KB',
    _ => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB',
  };
}

/// Sends [link] to Hiddify on a TV on the same network: scans the code the TV shows in its add
/// profile sheet, then sends the link to it, where the TV user imports it.
class _SendToTv extends HookConsumerWidget {
  const _SendToTv(this.link);

  final String link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.profiles.share.toTv;
    final sending = useState(false);

    Future<void> send() async {
      if (sending.value) return;
      final scanned = await ref.read(dialogNotifierProvider.notifier).showQrScanner(hint: text.scanHint);
      if (scanned == null || !context.mounted) return;
      sending.value = true;
      final result = await sendLinkToTv(scanned, link);
      if (!context.mounted) return;
      sending.value = false;
      final notifications = ref.read(inAppNotificationControllerProvider);
      switch (result) {
        case SendToTvResult.sent:
          notifications.showSuccessToast(text.sent);
        case SendToTvResult.notTvCode:
          notifications.showErrorToast(text.notTvCode);
        case SendToTvResult.expired:
          notifications.showErrorToast(text.expired);
        case SendToTvResult.busy:
          notifications.showErrorToast(text.busy);
        case SendToTvResult.unreachable:
          notifications.showErrorToast(text.unreachable);
      }
    }

    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: sending.value ? null : send,
      icon: sending.value
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.tv_rounded),
      label: Text(text.button),
    );
  }
}

/// The configuration's actions, side by side: copy (when it fits the clipboard), share (where the
/// platform has a share sheet for files) and save.
class _ConfigActions extends HookConsumerWidget {
  const _ConfigActions({required this.json, required this.name});

  final String json;
  final String name;

  /// Share sheets that take a file: Linux has none, and Windows' does not take files.
  static bool get _canShareFiles => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  String get _fileName {
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
    return '${safe.isEmpty ? 'profile' : safe}.json';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final share = t.pages.profiles.share;
    final theme = Theme.of(context);
    final copied = _useCopiedFlag();
    final fits = json.length <= ShareProfileDialog.maxClipboardChars;
    final notifications = ref.read(inAppNotificationControllerProvider);

    Future<void> copy() async {
      try {
        await Clipboard.setData(ClipboardData(text: json));
        copied.show();
      } on PlatformException {
        notifications.showInfoToast(t.common.msg.export.clipboard.contentTooLarge);
      }
    }

    Future<void> shareFile() async {
      final file = File('${(await getTemporaryDirectory()).path}/$_fileName');
      await file.writeAsString(json);
      // text/plain, not application/json: Android lists only the apps that take the type, and
      // many (Telegram among them) do not take JSON
      await UriUtils.tryShareFile(file.uri, mimeType: 'text/plain');
    }

    Future<void> save() async {
      try {
        final bytes = utf8.encode(json);
        final path = await FilePicker.platform.saveFile(
          fileName: _fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        if (path == null) return;
        // on desktop the picker only names the file
        if (PlatformUtils.isDesktop) await File(path).writeAsBytes(bytes);
        notifications.showSuccessToast(t.common.msg.export.file.success);
      } catch (_) {
        notifications.showErrorToast(t.common.msg.export.file.failure);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (fits) ...[
              Expanded(
                child: _ActionTile(
                  icon: copied.value ? Icons.check_rounded : Icons.content_copy_rounded,
                  label: _CopiedSwap(label: share.copy, copied: copied.value, alignment: Alignment.center),
                  onTap: copy,
                ),
              ),
              const Gap(8),
            ],
            if (_canShareFiles) ...[
              Expanded(
                child: _ActionTile(icon: Icons.share_rounded, label: Text(share.shareFile), onTap: shareFile),
              ),
              const Gap(8),
            ],
            Expanded(
              child: _ActionTile(icon: Icons.save_alt_rounded, label: Text(share.saveFile), onTap: save),
            ),
          ],
        ),
        if (!fits) ...[
          const Gap(10),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const Gap(6),
              Expanded(
                child: Text(
                  share.tooLargeToCopy,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A tonal square for one action: its icon over its label.
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final Widget label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Material(
      color: s.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, key: ValueKey(icon), color: s.onSecondaryContainer),
              ),
              const Gap(6),
              DefaultTextStyle.merge(
                style: theme.textTheme.labelLarge?.copyWith(color: s.onSecondaryContainer),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The local proxy for this device and for other devices on the network, one tab each. Shown when
/// the user picks proxy mode ([onPick]), from the Manual tab on the home page, and from LAN sharing
/// ([otherDevices]). In VPN mode this device's apps already go through the VPN, so only other
/// devices are shown, without the tabs.
class ProxyDialog extends HookConsumerWidget {
  const ProxyDialog({super.key, this.onPick = false, this.otherDevices = false});

  final bool onPick;
  final bool otherDevices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = useState(otherDevices);
    final mode = ref.watch(ConfigOptions.serviceMode);
    if (mode == ServiceMode.tun || mode == ServiceMode.router) return const LanSharingQrDialog();
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

/// What another device on the local network needs to use the shared proxy: a code to scan, and the
/// values to enter by hand. It opens at once and looks up this device's local IP while open. The
/// network's port always asks for the password.
class LanSharingQrDialog extends HookConsumerWidget {
  const LanSharingQrDialog({super.key, this.header});

  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    // One lookup per opening. The time limit keeps a core that never answers from leaving the
    // dialog loading forever.
    final lookup = useFuture(
      useMemoized(() => _findLanIp(ref).timeout(const Duration(seconds: 10), onTimeout: () => null)),
    );
    // Null while the lookup runs. A lookup that ends without an address gets 127.0.0.1, the same
    // answer the core gives when this device has no local network.
    final ip = lookup.connectionState == ConnectionState.done ? (lookup.data ?? InternetAddress.loopbackIPv4) : null;
    // the network has a port of its own, apart from this device's
    final port = ref.watch(ConfigOptions.lanSharingPort);
    final secret = ref.watch(ConfigOptions.lanSharingPassword);
    final shared = ref.watch(ConfigOptions.allowConnectionFromLan);
    Future<void> turnOn() => ref.read(ConfigOptions.allowConnectionFromLan.notifier).update(true);
    // The device that scans would reach itself at 127.0.0.1, so that gets no code and no link.
    final host = ip == null || ip.isLoopback ? null : ip.address;
    const name = QrCodeDialogConst.lanProfileName;
    final link = host == null ? null : 'socks://${_userInfo(secret)}$host:$port#$name';

    final content = Column(
      children: [
        if (link != null) _QrCode('#profile-title: $name\n$link') else _QrPlaceholder(loading: ip == null),
        const Gap(10),
        Text(
          t.dialogs.qrCode.lanLine,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const Gap(14),
        _ProxyFields(
          hostLabel: t.dialogs.qrCode.ip,
          host: ip?.address,
          port: port,
          onPortSaved: ref.read(ConfigOptions.lanSharingPort.notifier).update,
          // one the user removed in the settings leaves the port open to the whole network
          password: secret.isEmpty ? null : secret,
          onSetPassword: () => ref.read(ConfigOptions.lanSharingPassword.notifier).update(generateProxySecret()),
        ),
      ],
    );

    return _ProxyDialogFrame(
      header: header,
      links: host == null ? null : (telegram: _telegramLink(host, port, secret), full: link!),
      // while it is off there is no link to copy
      copyLink: shared,
      children: [
        if (shared)
          content
        else
          // what turning it on gives, faint and out of reach, under the button that does it
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: .25, child: IgnorePointer(child: content)),
              FilledButton.icon(
                onPressed: turnOn,
                icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                label: Text(t.dialogs.localProxy.turnOnSharing),
              ),
            ],
          ),
      ],
    );
  }
}

/// What other apps on this device need to use the local proxy: proxy mode routes nothing by itself,
/// each app is set to use it in its own settings. [onPick] offers not to show it again on picking
/// proxy mode.
class LocalProxyDialog extends ConsumerWidget {
  const LocalProxyDialog({super.key, this.onPick = false, this.header});

  final bool onPick;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final port = ref.watch(ConfigOptions.mixedPort);
    final auth = ref.watch(ConfigOptions.localProxyAuth);
    // the one secret of the user "hiddify", shared with the local network's port
    final secret = ref.watch(ConfigOptions.lanSharingPassword);
    // the local port asks for the secret only while the user has it ask
    final asked = auth ? secret : '';
    const host = '127.0.0.1';
    final link = 'socks://${_userInfo(asked)}$host:$port#${QrCodeDialogConst.localhostProfileName}';

    // A password that is asked must exist: one the user removed in the settings gets a new one.
    Future<void> setPassword() async {
      if (secret.isEmpty) await ref.read(ConfigOptions.lanSharingPassword.notifier).update(generateProxySecret());
      await ref.read(ConfigOptions.localProxyAuth.notifier).update(true);
    }

    return _ProxyDialogFrame(
      header: header,
      links: (telegram: _telegramLink(host, port, asked), full: link),
      footer: onPick ? const _DontShowAgain() : null,
      children: [
        _Steps(t.dialogs.localProxy.steps),
        const Gap(16),
        _ProxyFields(
          hostLabel: t.dialogs.localProxy.server,
          host: host,
          port: port,
          onPortSaved: ref.read(ConfigOptions.mixedPort.notifier).update,
          password: asked.isEmpty ? null : asked,
          onSetPassword: setPassword,
        ),
      ],
    );
  }
}

/// The two links of a proxy dialog's Copy link menu.
typedef _Links = ({String telegram, String full});

/// A proxy dialog: [header] (the tabs), [children], [footer], then Copy link — off while [links]
/// is null, and left out unless [copyLink] — and Close.
class _ProxyDialogFrame extends StatelessWidget {
  const _ProxyDialogFrame({
    required this.header,
    required this.links,
    required this.children,
    this.footer,
    this.copyLink = true,
  });

  final Widget? header;
  final _Links? links;
  final List<Widget> children;
  final Widget? footer;
  final bool copyLink;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (header case final header?) ...[header, const Gap(20)],
              ...children,
              if (footer case final footer?) ...[const Gap(8), footer],
              const Gap(12),
              Row(
                children: [
                  if (copyLink) _CopyLinkButton(links),
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

/// Copy link: a menu of the Telegram and the full link. Picking one closes it and the button says
/// Copied for a moment.
class _CopyLinkButton extends HookConsumerWidget {
  const _CopyLinkButton(this.links);

  final _Links? links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(translationsProvider).requireValue.dialogs.localProxy;
    final copied = _useCopiedFlag();
    final links = this.links;
    void copy(String value) {
      Clipboard.setData(ClipboardData(text: value));
      copied.show();
    }

    return MenuAnchor(
      menuChildren: [
        if (links != null) ...[
          MenuItemButton(
            leadingIcon: const Icon(Icons.telegram, color: _telegramBlue),
            onPressed: () => copy(links.telegram),
            child: Text(text.telegramLink),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.link_rounded),
            onPressed: () => copy(links.full),
            child: Text(text.fullLink),
          ),
        ],
      ],
      builder: (context, menu, _) => TextButton(
        onPressed: links == null ? null : () => menu.isOpen ? menu.close() : menu.open(),
        child: _CopiedSwap(label: text.copyLink, copied: copied.value, alignment: Alignment.center),
      ),
    );
  }
}

/// The copyable values of a proxy: [host] (null while it is looked up) and [port], then the user
/// and [password], or, while no password is asked ([password] null), a warning with [onSetPassword].
/// The port and the password are edited in place; the password is seen only while edited.
class _ProxyFields extends HookConsumerWidget {
  const _ProxyFields({
    required this.hostLabel,
    required this.host,
    required this.port,
    required this.onPortSaved,
    required this.password,
    required this.onSetPassword,
  });

  final String hostLabel;
  final String? host;
  final int port;
  final Future<void> Function(int) onPortSaved;
  final String? password;
  final VoidCallback onSetPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.localProxy;
    final editing = useState<_Field?>(null);
    final host = this.host;
    final password = this.password;
    const username = 'hiddify';

    Widget editor(_Field field) => _FieldEditor(
      label: field == _Field.port ? t.dialogs.qrCode.port : t.dialogs.qrCode.password,
      initial: field == _Field.port ? '$port' : password ?? '',
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
          await onPortSaved(int.parse(value));
        } else {
          await ref.read(ConfigOptions.lanSharingPassword.notifier).update(value);
        }
        editing.value = null;
      },
      onCancel: () => editing.value = null,
    );
    Widget edit(_Field field) => _TileIcon(text.edit, Icons.edit_outlined, () => editing.value = field);

    return AnimatedSize(
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
                    label: hostLabel,
                    value: host != null
                        ? _Value(host)
                        // Held at the text's line height so the tile keeps its height once the IP lands.
                        : const SizedBox(
                            height: 24,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ShimmerSkeleton(width: 96, height: 16),
                            ),
                          ),
                    copyText: host,
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
          if (password == null)
            _NoPasswordBar(text.noPassword, action: text.setPassword, onAction: onSetPassword)
          else if (editing.value == _Field.password)
            editor(_Field.password)
          else
            Row(
              children: [
                IntrinsicWidth(
                  child: _CopyTile(label: t.dialogs.qrCode.username, value: const _Value(username), copyText: username),
                ),
                const Gap(8),
                Expanded(
                  child: _CopyTile(
                    label: t.dialogs.qrCode.password,
                    value: const _Value('••••••••'),
                    copyText: password,
                    action: edit(_Field.password),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A link that adds the proxy to Telegram, with the user and [secret] when there is one.
String _telegramLink(String host, int port, String secret) => Uri(
  scheme: 'tg',
  host: 'socks',
  queryParameters: {
    'server': host,
    'port': '$port',
    if (secret.isNotEmpty) ...{'user': 'hiddify', 'pass': secret},
  },
).toString();

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

/// Holds the QR code's place, at its size: loading, or saying there's no local network to share on.
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
                Icon(Icons.wifi_off_rounded, size: 44, color: theme.colorScheme.onSurfaceVariant),
                const Gap(10),
                Text(t.dialogs.qrCode.noLocalNetwork, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
              ],
            ),
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
