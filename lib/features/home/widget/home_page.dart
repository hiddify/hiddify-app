import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:hiddify/features/settings/widget/settings_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/core/service/core_service.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiddify Core'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hiddify Core Integration'),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Core'),
              onPressed: () async {
                try {
                  final service = CoreService();
                  
                  // Load preferences
                  final bind = ref.read(CorePreferences.bindAddress);
                  final verbose = ref.read(CorePreferences.verboseLogging);
                  final endpoint = ref.read(CorePreferences.endpoint);
                  final license = ref.read(CorePreferences.licenseKey);
                  final dns = ref.read(CorePreferences.dns);
                  final gool = ref.read(CorePreferences.goolMode);
                  final masque = ref.read(CorePreferences.masqueMode);
                  final fallback = ref.read(CorePreferences.masqueAutoFallback);
                  final preferred = ref.read(CorePreferences.masquePreferred);
                  final noise = ref.read(CorePreferences.masqueNoise);
                  final preset = ref.read(CorePreferences.masqueNoisePreset);
                  final psiphon = ref.read(CorePreferences.psiphonEnabled);
                  final country = ref.read(CorePreferences.psiphonCountry);
                  final proxy = ref.read(CorePreferences.proxyAddress);
                  final scan = ref.read(CorePreferences.scanEnabled);
                  final rtt = ref.read(CorePreferences.scanRtt);

                  final supportDir = await getApplicationSupportDirectory();
                  final cacheDir = "${supportDir.path}/cache";
                  await Directory(cacheDir).create(recursive: true);

                  final config = {
                    "bind": bind,
                    "verbose": verbose,
                    "endpoint": endpoint,
                    "license": license,
                    "dns_addr": dns,
                    "gool": gool,
                    "masque": masque,
                    "masque_auto_fallback": fallback,
                    "masque_preferred": preferred,
                    "masque_noize": noise,
                    "masque_noize_preset": preset,
                    "psiphon_country": psiphon ? country : "",
                    "proxy_address": proxy,
                    "cache_dir": cacheDir,
                    "scan": scan,
                    "rtt": rtt,
                  };
                  
                  print("Starting Core with config: $config");
                  final error = service.start(config);
                  if (error != null) {
                    print("Error starting core: $error");
                    if(context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
                      );
                    }
                  } else {
                    print("Core started successfully!");
                     if(context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Core started successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  }
                } catch (e) {
                  print("Exception: $e");
                   if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exception: $e')),
                      );
                   }
                }
              },
            ),
            const SizedBox(height: 10),
             FilledButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('Stop Core'),
              onPressed: () {
                 try {
                  final service = CoreService();
                  service.stop();
                   if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Core stopped')),
                      );
                   }
                 } catch(e) {
                    print("Exception stopping: $e");
                 }
              },
               style: FilledButton.styleFrom(backgroundColor: Colors.red),
             )
          ],
        ),
      ),
    );
  }
}
