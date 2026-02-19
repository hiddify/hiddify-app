import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// // const permissions = [Permissions.CAMERA];
// // const permissionGroup = [PermissionGroup.Camera];

// class QRCodeScannerScreen extends StatefulHookConsumerWidget {
//   const QRCodeScannerScreen({super.key});

//   Future<String?> open(BuildContext context) async {
//     return Navigator.of(context, rootNavigator: true).push(
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder: (context) => const QRCodeScannerScreen(),
//       ),
//     );
//   }

//   @override
//   ConsumerState<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
// }

// class _QRCodeScannerScreenState extends ConsumerState<QRCodeScannerScreen> with WidgetsBindingObserver, PresLogger {
//   final MobileScannerController controller = MobileScannerController(
//     detectionTimeoutMs: 500,
//     autoStart: false,
//   );
//   bool started = false;

//   // late FlutterEasyPermission _easyPermission;
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     // _initializeScanner();

//     // _easyPermission = FlutterEasyPermission()
//     //   ..addPermissionCallback(onGranted: (requestCode, androidPerms, iosPerm) {
//     //     debugPrint("android:$androidPerms");
//     //     debugPrint("iOS:$iosPerm");
//     //     startQrScannerIfPermissionGranted();
//     //   }, onDenied: (requestCode, androidPerms, iosPerm, isPermanent) {
//     //     if (isPermanent) {
//     //       FlutterEasyPermission.showAppSettingsDialog(title: "Camera");
//     //     } else {
//     //       debugPrint("android:$androidPerms");
//     //       debugPrint("iOS:$iosPerm");
//     //     }
//     //   }, onSettingsReturned: () {
//     //     startQrScannerIfPermissionGranted();
//     //   });
//   }

// //   Future<bool> _requestCameraPermission() async {
// //     final hasPermission = await FlutterEasyPermission.has(
// //       perms: permissions,
// //       permsGroup: permissionGroup,
// //     );

// //     if (hasPermission) return true;

// //     final completer = Completer<bool>();

// //     void permissionCallback(int requestCode, List<Permissions>? perms, PermissionGroup? perm) {
// //       if (!completer.isCompleted) {
// //         completer.complete(true);
// //       }
// //     }

// //     void permissionDeniedCallback(int requestCode, List<Permissions>? perms, PermissionGroup? perm, bool isPermanent) {
// //       if (!completer.isCompleted) {
// //         completer.complete(false);
// //       }
// //     }

// //     FlutterEasyPermission().addPermissionCallback(
// //       onGranted: permissionCallback,
// //       onDenied: permissionDeniedCallback,
// //     );

// //     FlutterEasyPermission.request(
// //       perms: permissions,
// //       permsGroup: permissionGroup,
// //       rationale: "Camera permission is required to scan QR codes.",
// //     );

// //     return completer.future;
// //   }

// //   Future<void> _initializeScanner() async {
// //     final hasPermission = await _requestCameraPermission();
// //     if (hasPermission) {
// //       _startScanner();
// //     } else {
// //       _showPermissionDialog();
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     controller.dispose();
// //     // _easyPermission.dispose();
// //     FlutterEasyPermission().dispose();
// //     WidgetsBinding.instance.removeObserver(this);
// //     super.dispose();
// //   }

// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     /// Checking app cycle so that when user returns from settings, need to recheck for permissions
// //     if (state == AppLifecycleState.resumed) {
// //       _checkPermissionAndStartScanner();
// //     }
// //   }

// //   Future<void> _checkPermissionAndStartScanner() async {
// //     final hasPermission = await FlutterEasyPermission.has(
// //       perms: permissions,
// //       permsGroup: permissionGroup,
// //     );
// //     if (hasPermission) {
// //       _startScanner();
// //     } else {
// //       setState(() {}); // Trigger rebuild to show permission denied UI
// //     }
// //   }

// //   Future<void> _startScanner() async {
// //     loggy.info("Starting scanner");
// //     await controller.stop();
// //     await controller.start().whenComplete(() {
// //       setState(() {
// //         started = true;
// //       });
// //     }).catchError((error) {
// //       loggy.warning("Error starting scanner: $error");
// //     });
// //   }

// //   Future<void> startQrScannerIfPermissionIsGranted() async {
// //     final hasPermission = await FlutterEasyPermission.has(
// //       perms: permissions,
// //       permsGroup: permissionGroup,
// //     );
// //     if (hasPermission) {
// //       _startScanner();
// //       // } else {
// //       //   _showPermissionDialog();
// //     }
// //   }

// //   // void startQrScannerIfPermissionGranted() {
// //   //   FlutterEasyPermission.has(perms: permissions, permsGroup: permissionGroup).then((value) {
// //   //     if (value) {
// //   //       controller.start().then((result) {
// //   //         if (result != null) {
// //   //           setState(() {
// //   //             started = true;
// //   //           });
// //   //         }
// //   //       }).catchError((error) {
// //   //         loggy.warning("Error starting scanner: $error");
// //   //       });
// //   //     } else {}
// //   //   });
// //   // }

// //   void _showPermissionDialog() {
// //     FlutterEasyPermission.showAppSettingsDialog(
// //       title: "Camera Access Required",
// //       rationale: "Permission to camera to scan QR Code",
// //       positiveButtonText: "Settings",
// //       negativeButtonText: "Cancel",
// //     );
// //   }

//   @override
//   Widget build(BuildContext context) {
//     final Translations t = ref.watch(translationsProvider).requireValue;
//     // return FutureBuilder(
//     //   future: FlutterEasyPermission.has(
//     //     perms: permissions,
//     //     permsGroup: permissionGroup,
//     //   ),
//     //   builder: (context, snapshot) {
//     //     if (snapshot.connectionState == ConnectionState.waiting) {
//     //       return const Center(child: CircularProgressIndicator());
//     //     }

//     //     if (snapshot.data == true) {
//     //       return _buildScannerUI(context, t);
//     //     } else {
//     //       return _buildPermissionDeniedUI(context, t);
//     //     }
//     //   },
//     // );
//     return MobileScanner(
//       overlayBuilder: (context, constraints) => ScannerOverlay(),
//       onDetect: (barcodes) {
//         final rawData = barcodes.barcodes.first.rawValue;
//         loggy.debug('captured raw: [$rawData]');
//         if (rawData != null) {
//           final uri = Uri.tryParse(rawData);
//           if (context.mounted && uri != null) {
//             loggy.debug('captured url: [$uri]');
//             Navigator.of(context, rootNavigator: true).pop(uri.toString());
//           }
//         } else {
//           loggy.warning("unable to capture");
//         }
//       },
//     );
//     return _buildScannerUI(context, t);
//   }

//   Widget _buildScannerUI(BuildContext context, Translations t) {
//     final size = MediaQuery.sizeOf(context);
//     final overlaySize = (size.shortestSide - 12).coerceAtMost(248);
//     // _startScanner();
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         iconTheme: Theme.of(context).iconTheme.copyWith(
//               color: Colors.white,
//               size: 32,
//             ),
//         actions: [
//           IconButton(
//             icon: const Icon(FluentIcons.flash_24_regular),
//             tooltip: t.profile.add.qrScanner.torchSemanticLabel,
//             onPressed: () => controller.toggleTorch(),
//           ),
//           // IconButton(
//           //   icon: ValueListenableBuilder(
//           //     valueListenable: controller.torchState,
//           //     builder: (context, state, child) {
//           //       switch (state) {
//           //         case TorchState.off:
//           //           return const Icon(
//           //             FluentIcons.flash_off_24_regular,
//           //             color: Colors.grey,
//           //           );
//           //         case TorchState.on:
//           //           return const Icon(
//           //             FluentIcons.flash_24_regular,
//           //             color: Colors.yellow,
//           //           );
//           //       }
//           //     },
//           //   ),
//           //   tooltip: t.profile.add.qrScanner.torchSemanticLabel,
//           //   onPressed: () => controller.toggleTorch(),
//           // ),
//           IconButton(
//             icon: const Icon(FluentIcons.camera_switch_24_regular),
//             tooltip: t.profile.add.qrScanner.facingSemanticLabel,
//             onPressed: () => controller.switchCamera(),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           MobileScanner(
//             controller: controller,
//             onDetect: (capture) {
//               final rawData = capture.barcodes.first.rawValue;
//               loggy.debug('captured raw: [$rawData]');
//               if (rawData != null) {
//                 final uri = Uri.tryParse(rawData);
//                 if (context.mounted && uri != null) {
//                   loggy.debug('captured url: [$uri]');
//                   Navigator.of(context, rootNavigator: true).pop(uri.toString());
//                 }
//               } else {
//                 loggy.warning("unable to capture");
//               }
//             },
//             errorBuilder: (_, error, __) {
//               final message = switch (error.errorCode) {
//                 MobileScannerErrorCode.permissionDenied => t.profile.add.qrScanner.permissionDeniedError,
//                 _ => t.profile.add.qrScanner.unexpectedError,
//               };

//               return Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Padding(
//                       padding: EdgeInsets.only(bottom: 8),
//                       child: Icon(
//                         FluentIcons.error_circle_24_regular,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(message),
//                     Text(error.errorDetails?.message ?? ''),
//                   ],
//                 ),
//               );
//             },
//           ),
//           if (started)
//             CustomPaint(
//               painter: ScannerOverlay(
//                 Rect.fromCenter(
//                   center: size.center(Offset.zero),
//                   width: overlaySize,
//                   height: overlaySize,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPermissionDeniedUI(BuildContext context, Translations t) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         iconTheme: Theme.of(context).iconTheme.copyWith(
//               color: Colors.white,
//               size: 32,
//             ),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(t.profile.add.qrScanner.permissionDeniedError),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               // onPressed: _showPermissionDialog,
//               onPressed: () {},
//               child: const Text("Settings"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ScannerOverlay extends CustomPainter {
//   ScannerOverlay(this.scanWindow);

//   final Rect scanWindow;
//   final double borderRadius = 12.0;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final backgroundPath = Path()..addRect(Rect.largest);
//     final cutoutPath = Path()
//       ..addRRect(
//         RRect.fromRectAndCorners(
//           scanWindow,
//           topLeft: Radius.circular(borderRadius),
//           topRight: Radius.circular(borderRadius),
//           bottomLeft: Radius.circular(borderRadius),
//           bottomRight: Radius.circular(borderRadius),
//         ),
//       );

//     final backgroundPaint = Paint()
//       ..color = Colors.black.withValues(alpha: .5)
//       ..style = PaintingStyle.fill
//       ..blendMode = BlendMode.dstOut;

//     final backgroundWithCutout = Path.combine(
//       PathOperation.difference,
//       backgroundPath,
//       cutoutPath,
//     );

//     final borderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0;

//     final borderRect = RRect.fromRectAndCorners(
//       scanWindow,
//       topLeft: Radius.circular(borderRadius),
//       topRight: Radius.circular(borderRadius),
//       bottomLeft: Radius.circular(borderRadius),
//       bottomRight: Radius.circular(borderRadius),
//     );

//     canvas.drawPath(backgroundWithCutout, backgroundPaint);
//     canvas.drawRRect(borderRect, borderPaint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

class QrCodeScannerDialog extends ConsumerWidget {
  const QrCodeScannerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.read(translationsProvider).requireValue;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              placeholderBuilder: (p0, p1) => const Center(child: CircularProgressIndicator()),
              overlayBuilder: (context, constraints) => Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 4),
                ),
              ),
              errorBuilder: (p0, p1, p2) => Center(child: Text(t.common.msg.permission.denied)),
              onDetect: (barcodes) {
                final rawData = barcodes.barcodes.first.rawValue;
                if (rawData != null) context.pop(rawData);
                // loggy.debug('captured raw: [$rawData]');
                // if (rawData != null) {
                //   context.pop(rawData);
                //   final uri = Uri.tryParse(rawData);
                //   if (context.mounted && uri != null) {
                //     // loggy.debug('captured url: [$uri]');
                //     context.pop(uri.toString());
                //   }
                // } else {
                //   // loggy.warning("unable to capture");
                // }
              },
            ),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(1000),
                ),
                margin: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  splashRadius: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
