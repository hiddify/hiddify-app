import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/config/logic/config_parser.dart';
import 'package:hiddify/features/subscription/widget/subscription_preview_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddConfigSheet extends HookConsumerWidget {
  const AddConfigSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('From Clipboard'),
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null && context.mounted) {
                _processContent(context, ref, data!.text!, 'clipboard');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan QR Code'),
            onTap: () async {
              // Open QR Scanner
              final result = await Navigator.push(
                context, 
                MaterialPageRoute<String?>(builder: (_) => const QRScannerPage()),
              );
              if (result != null && context.mounted) {
                _processContent(context, ref, result, 'qr_camera');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('From Image'),
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
          ),
        ],
      ),
    );

  void _processContent(BuildContext context, WidgetRef ref, String content, String source) {
    // Check if subscription
    if (content.startsWith('http')) {
      Navigator.pop(context); // Close sheet
      unawaited(Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionPreviewPage(url: content))));
      return;
    }

    final config = ConfigParser.parse(content, source: source);
    if (config != null) {
      unawaited(ref.read(configControllerProvider.notifier).add(config));
      Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config added!')));
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid config')));
    }
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
