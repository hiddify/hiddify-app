import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

extension OutboundInfoSecurity on OutboundInfo {
  /// The core says why the proxy's traffic can be read or changed on the way to its server
  /// (sing-box option.InsecureReason). A core without the field says nothing, and nothing is
  /// marked: its is_secure is false for every proxy.
  bool get isNotSecure => insecureReason.isNotEmpty;
}

/// Why a proxy with [reason] is not secure, in the user's words.
String insecureReasonText(Translations t, String reason) {
  final s = t.pages.proxies.insecure;
  return switch (reason) {
    'plaintext' => s.plaintext,
    'no_cipher' => s.noCipher,
    'weak_cipher' => s.weakCipher,
    'tls_insecure' => s.tlsInsecure,
    _ => s.unknown(reason: reason),
  };
}

Color _warningColor(BuildContext context) => Theme.of(context).colorScheme.error;

/// The "Not secure" mark of a proxy row; a tap on it says why.
class InsecureProxyBadge extends ConsumerWidget {
  const InsecureProxyBadge(this.proxy, {super.key, this.faded = false});

  final OutboundInfo proxy;
  final bool faded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final color = _warningColor(context).withValues(alpha: faded ? .5 : 1);
    return Semantics(
      button: true,
      label: t.pages.proxies.insecure.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showInsecureProxyNote(context, proxy),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 6, top: 2, bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_open_rounded, size: 14, color: color),
              const Gap(3),
              Text(
                t.pages.proxies.insecure.badge,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dialog that says why [proxy] is not secure.
Future<void> showInsecureProxyNote(BuildContext context, OutboundInfo proxy) => showDialog<void>(
  context: context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final t = ref.watch(translationsProvider).requireValue;
      return AlertDialog(
        icon: Icon(Icons.lock_open_rounded, color: _warningColor(context)),
        title: Text(t.pages.proxies.insecure.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(child: InsecureProxyNote(proxy, framed: false)),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.close))],
      );
    },
  ),
);

/// Why [proxy] is not secure and what to do about it; [framed] puts it in a warning box, as the
/// proxy's details show it.
class InsecureProxyNote extends ConsumerWidget {
  const InsecureProxyNote(this.proxy, {super.key, this.framed = true});

  final OutboundInfo proxy;
  final bool framed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final textColor = framed ? s.onErrorContainer : null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (framed) ...[
          Row(
            children: [
              Icon(Icons.lock_open_rounded, size: 18, color: textColor),
              const Gap(8),
              Expanded(
                child: Text(
                  t.pages.proxies.insecure.title,
                  style: theme.textTheme.labelLarge?.copyWith(color: textColor),
                ),
              ),
            ],
          ),
          const Gap(8),
        ],
        Text(
          insecureReasonText(t, proxy.insecureReason),
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
        const Gap(8),
        Text(
          t.pages.proxies.insecure.advice,
          style: theme.textTheme.bodySmall?.copyWith(color: textColor ?? s.onSurfaceVariant),
        ),
      ],
    );
    if (!framed) return body;
    return DecoratedBox(
      decoration: BoxDecoration(color: s.errorContainer.withValues(alpha: .6), borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(12), child: body),
    );
  }
}
