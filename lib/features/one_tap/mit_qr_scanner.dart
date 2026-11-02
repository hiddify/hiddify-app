import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/features/one_tap/mit_brand.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final mitQrLoaderProvider = Provider<Future<String?> Function(BuildContext)>((ref) => (context) =>
  Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const MitQrScanner())));

bool isMitProfileQr(String value) {
  try { prepareVpnProfile(value); return true; } catch (_) { return false; }
}

class MitQrScanner extends StatefulWidget {
  const MitQrScanner({super.key});
  @override
  State<MitQrScanner> createState() => _MitQrScannerState();
}
class _MitQrScannerState extends State<MitQrScanner> with WidgetsBindingObserver {
  final controller = MobileScannerController(formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates, returnImage: false);
  bool accepted = false;
  String? error;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); unawaited(controller.dispose()); super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission || accepted) return;
    unawaited(camera(state == AppLifecycleState.resumed));
  }
  Future<void> camera(bool start) async {
    try { if (start) { await controller.start(); } else { await controller.stop(); } }
    catch (_) { if (mounted) setState(() => error = 'Камера недоступна. Можно вставить ссылку вручную.'); }
  }
  Future<void> detected(BarcodeCapture capture) async {
    if (accepted) return;
    for (final code in capture.barcodes) {
      final value = code.rawValue;
      if (value == null) continue;
      if (!isMitProfileQr(value)) {
        if (mounted) setState(() => error = 'Этот QR-код не содержит поддерживаемый профиль VPN.');
        continue;
      }
      accepted = true;
      try { await controller.stop(); } catch (_) { /* Disposal also stops the camera. */ }
      if (mounted) Navigator.pop(context, value);
      return;
    }
  }
  @override
  Widget build(BuildContext context) => MitPage(title: 'QR-код профиля', child: Column(children: [
    const Padding(padding: EdgeInsets.all(16), child: Text('Наведите камеру на QR-код клиентского профиля. Затем подтвердите добавление.')),
    Expanded(child: MobileScanner(controller: controller, onDetect: detected,
      errorBuilder: (context, _) => const Center(child: Padding(padding: EdgeInsets.all(24),
        child: Text('Камера недоступна. Разрешите доступ к камере в настройках Android или вставьте ссылку вручную.'))))),
    if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
  ]));
}
