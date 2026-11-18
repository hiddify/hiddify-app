import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/log/data/lan_file_server.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart' show isLocalNetwork;
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';

/// On Android TV, what sharing a file means: a QR code a phone on the same Wi-Fi scans to
/// download it. The file is served only while this is open. Pops whether a phone downloaded it.
class DownloadToPhoneDialog extends ConsumerStatefulWidget {
  const DownloadToPhoneDialog({super.key, required this.file});

  final File file;

  @override
  ConsumerState<DownloadToPhoneDialog> createState() => _DownloadToPhoneDialogState();
}

class _DownloadToPhoneDialogState extends ConsumerState<DownloadToPhoneDialog> {
  LanFileServer? _server;
  StreamSubscription<InternetAddress>? _downloads;
  Object? _error;
  var _downloaded = false;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final lanIp = await ref
          .read(hiddifyCoreServiceProvider)
          .getLANIP()
          .run()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw const _NoNetwork());
      final address = lanIp.fold((_) => null, (r) => InternetAddress.tryParse(r.ip));
      // the core answers 127.0.0.1 when this device has no local network
      if (address == null || address.isLoopback || !isLocalNetwork(address)) throw const _NoNetwork();
      final server = await LanFileServer.start(address, widget.file);
      if (_disposed) return unawaited(server.close());
      _downloads = server.downloads.listen((_) {
        if (mounted) setState(() => _downloaded = true);
      });
      setState(() => _server = server);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_downloads?.cancel());
    unawaited(_server?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final toPhone = t.pages.logs.toPhone;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final server = _server;
    final error = _error;
    return AlertDialog(
      icon: const Icon(Icons.phone_android_rounded),
      title: Text(toPhone.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Row(
          children: [
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: switch ((server, error)) {
                (_, _?) => Icon(Icons.wifi_off_rounded, size: 56, color: s.error),
                (final server?, _) => QrImageView(data: server.url.toString(), padding: EdgeInsets.zero),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            const Gap(20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null)
                    Text(
                      error is _NoNetwork ? toPhone.noNetwork : t.presentShortError(error),
                      style: theme.textTheme.bodyMedium?.copyWith(color: s.error),
                    )
                  else ...[
                    Text(
                      toPhone.scan(name: p.basename(widget.file.path)),
                      style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                    ),
                    const Gap(8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.wifi_rounded, size: 18, color: s.primary),
                        const Gap(6),
                        Expanded(child: Text(toPhone.sameNetwork, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                    if (server != null) ...[
                      const Gap(8),
                      // for a phone that can not scan: the address to type
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: SelectableText(
                          '${server.url.authority}${server.url.path}',
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: s.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                    if (_downloaded) ...[
                      const Gap(12),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18, color: s.primary),
                          const Gap(6),
                          Flexible(child: Text(toPhone.downloaded, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(_downloaded),
          child: Text(t.common.close),
        ),
      ],
    );
  }
}

class _NoNetwork implements Exception {
  const _NoNetwork();
}
