import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/core/service/vwarp_service.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/settings/notifier/core_settings_notifier.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(coreSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiddify Core'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => const CoreSettingsRoute().push(context),
          ),
        ],
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
                  // Map CoreSettings to JSON config
                  final config = {
                    "bind": settings.bindAddress,
                    "dns_addr": settings.dnsAddress,
                    "verbose": settings.verbose,
                    "gool": settings.enableGool,
                    "masque": settings.enableMasque,
                    "masque_auto_fallback": settings.masqueAutoFallback,
                    "masque_preferred": settings.masquePreferred,
                    "masque_noize": settings.enableMasqueNoize,
                    "masque_noize_preset": settings.masqueNoizePreset,
                    "endpoint": settings.customEndpoint, // or logic for default
                    "license": settings.licenseKey,
                    "proxy_address": settings.proxyAddress,
                    "scan": settings.enableScan,
                    "rtt": settings.scanRtt,
                  };

                  if (settings.enablePsiphon) {
                     config["psiphon_country"] = settings.psiphonCountry;
                  }
                  
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
