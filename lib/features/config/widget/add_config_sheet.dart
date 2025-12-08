import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/data/config_repository.dart';
import '../../config/logic/config_parser.dart';
import '../../subscription/widget/subscription_preview_page.dart';

class AddConfigSheet extends HookConsumerWidget {
  const AddConfigSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
              if (data?.text != null) {
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
                MaterialPageRoute(builder: (_) => const QRScannerPage())
              );
              if (result != null) {
                _processContent(context, ref, result.toString(), 'qr_camera');
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
                     if (code != null) {
                        _processContent(context, ref, code, 'qr_image');
                     }
                   }
                 }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Manual Entry'),
            onTap: () {
               // Show dialog
            },
          ),
        ],
      ),
    );
  }

  void _processContent(BuildContext context, WidgetRef ref, String content, String source) {
    // Check if subscription
    if (content.startsWith('http')) {
      Navigator.pop(context); // Close sheet
      Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionPreviewPage(url: content)));
      return;
    }

    final config = ConfigParser.parse(content, source: source);
    if (config != null) {
      ref.read(configRepositoryProvider).value?.addConfig(config);
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
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Scan QR')),
            body: MobileScanner(
                onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
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
}
