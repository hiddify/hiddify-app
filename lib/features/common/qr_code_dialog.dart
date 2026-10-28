import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// What another device needs to use a shared proxy by hand. [ip] is null until it's known.
typedef ProxyCredentials = ({InternetAddress? ip, int port, String username, String password});

class QrCodeDialog extends HookConsumerWidget {
  const QrCodeDialog(
    this.data, {
    super.key,
    required this.title,
    required this.link,
    this.subtitle,
    this.credentials,
    this.loading = false,
  });

  /// The text encoded in the QR code, or null when there's none.
  final String? data;
  final String title;
  final String? subtitle;

  /// Copied by the copy-full-link button, which is off while this is null.
  final String? link;

  /// Shown as copyable tiles under the title when set.
  final ProxyCredentials? credentials;

  /// Whether [data] is still on its way. A null [data] that isn't loading has no code to show.
  final bool loading;

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
              if (data != null) _QrCode(data) else _QrPlaceholder(loading: loading),
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
              if (credentials != null) ...[const Gap(16), _CredentialTiles(credentials!)],
              const Gap(12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
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
  const LanSharingQrDialog({super.key});

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
    final port = ref.watch(ConfigOptions.mixedPort);
    final password = ref.watch(ConfigOptions.lanSharingPassword);
    final name = ip?.isLoopback ?? false ? QrCodeDialogConst.localhostProfileName : QrCodeDialogConst.lanProfileName;
    final link = ip == null ? null : 'socks://$username:$password@${ip.address}:$port#$name';

    return QrCodeDialog(
      // The device that scans the code would reach itself at 127.0.0.1, so that gets no code.
      ip == null || ip.isLoopback ? null : '#profile-title: $name\n$link',
      title: name,
      subtitle: t.pages.settings.inbound.lanQrSubtitle,
      link: link,
      credentials: (ip: ip, port: port, username: username, password: password),
      loading: ip == null,
    );
  }
}

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
  const _CredentialTiles(this.credentials);

  final ProxyCredentials credentials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final revealed = useState(false);
    final ip = credentials.ip;

    final username = _CopyTile(
      label: t.dialogs.qrCode.username,
      value: _Value(credentials.username),
      copyText: credentials.username,
    );
    final password = _CopyTile(
      label: t.dialogs.qrCode.password,
      // Groups of four are easier to read and type by hand; the copy keeps the raw password.
      value: _Value(
        revealed.value ? RegExp('.{1,4}').allMatches(credentials.password).map((m) => m[0]).join(' ') : '••••••••',
      ),
      copyText: credentials.password,
      action: IconButton(
        tooltip: revealed.value ? t.dialogs.qrCode.hidePassword : t.dialogs.qrCode.showPassword,
        onPressed: () => revealed.value = !revealed.value,
        icon: Icon(revealed.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
