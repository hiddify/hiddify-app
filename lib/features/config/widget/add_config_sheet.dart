import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/config/logic/config_import_service.dart';
import 'package:hiddify/features/subscription/widget/subscription_preview_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class AddConfigSheet {
  static void show(BuildContext context) {
    unawaited(WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text(
            'Add Configuration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isTopBarLayerAlwaysVisible: true,
          child: const _AddConfigContent(),
        ),
      ],
    ));
  }
}

class _AddConfigContent extends ConsumerWidget {
  const _AddConfigContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _buildOption(
            context,
            icon: Icons.paste_rounded,
            title: 'From Clipboard',
            subtitle: 'Paste config or link from clipboard',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null && context.mounted) {
                _processContent(context, ref, data!.text!, 'clipboard');
              }
            },
            theme: theme,
          ),
          const Gap(12),
          _buildOption(
            context,
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Code',
            subtitle: 'Scan a QR code from camera',
            onTap: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute<String?>(builder: (_) => const QRScannerPage()),
              );
              if (result != null && context.mounted) {
                _processContent(context, ref, result, 'qr_camera');
              }
            },
             theme: theme,
          ),
          const Gap(12),
          _buildOption(
            context,
            icon: Icons.image_rounded,
            title: 'From Image',
            subtitle: 'Import QR code from gallery',
            onTap: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                 final controller = MobileScannerController();
                 final capture = await controller.analyzeImage(image.path);
                 if (capture != null) {
                   final barcodes = capture.barcodes;
                   if (barcodes.isNotEmpty) {
                     final code = barcodes.first.rawValue;
                     if (code != null && context.mounted) {
                        _processContent(context, ref, code, 'qr_image');
                     }
                   }
                 }
              }
            },
             theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) =>
      Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );

  void _processContent(BuildContext context, WidgetRef ref, String content, String source) {
    final trimmed = content.trim();
    if (trimmed.startsWith('http')) {
      Navigator.pop(context); // Close sheet
      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SubscriptionPreviewPage(url: trimmed),
          ),
        ),
      );
      return;
    }

    final result = ConfigImportService.importContent(trimmed, source: source);

    if (result.items.length == 1 &&
        result.failures.isEmpty &&
        result.remainingText.isEmpty &&
        result.items.first.warnings.isEmpty) {
      final config = result.items.first.config;
      unawaited(ref.read(configControllerProvider.notifier).add(config));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config added!')),
      );
      return;
    }

    Navigator.pop(context); // Close sheet
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SubscriptionPreviewPage.raw(
            content: trimmed,
            source: source,
          ),
        ),
      ),
    );
  }
}

class QRScannerPage extends StatelessWidget {
    const QRScannerPage({super.key});
    @override
    Widget build(BuildContext context) => Scaffold(
            appBar: AppBar(title: const Text('Scan QR')),
            body: MobileScanner(
                onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                       if(barcode.rawValue != null) {
                           Navigator.pop(context, barcode.rawValue);
                           return;
                       }
                    }
                },
            ),
        );
}
