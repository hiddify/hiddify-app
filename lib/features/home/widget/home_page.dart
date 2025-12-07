import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/core/service/vwarp_service.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiddify Core'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('New Core Integration'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                try {
                  final service = VWarpService();
                  // Example config - in real app this comes from UI/Settings
                  final config = {
                    "bind": "127.0.0.1:8086",
                    "verbose": true,
                    // "masque": true, // Uncomment to test other modes
                  };
                  
                  print("Starting Core with config: $config");
                  final error = service.start(config);
                  if (error != null) {
                    print("Error starting core: $error");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  } else {
                    print("Core started successfully!");
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Core started successfully!')),
                    );
                  }
                } catch (e) {
                  print("Exception: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exception: $e')),
                    );
                }
              },
              child: const Text('Start Core'),
            ),
            const SizedBox(height: 10),
             FilledButton(
              onPressed: () {
                 try {
                  final service = VWarpService();
                  service.stop();
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Core stopped')),
                    );
                 } catch(e) {
                    print("Exception stopping: $e");
                 }
              },
               child: const Text('Stop Core'),
             )
          ],
        ),
      ),
    );
  }
}
