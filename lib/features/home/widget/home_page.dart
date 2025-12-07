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
              label: const Text('Start Xray'),
              onPressed: () async {
                try {
                  final service = CoreService();
                  
                  // Load preferences
                  final configContent = ref.read(CorePreferences.configContent);
                  final assetPath = ref.read(CorePreferences.assetPath);

                  // Setup environment variables for assets if needed
                  if (assetPath.isNotEmpty) {
                    // Dart's Platform.environment is read-only. We set it in Go via os.Setenv technically,
                    // but since we are calling Go, we should pass it or Go should default.
                    // For now, let's assume assets are in place or config handles absolute paths.
                    // Mobile wrapper typically sets XRAY_LOCATION_ASSET in Go `init()` or pass it.
                    // But our Start() only takes one string.
                    // We will rely on simple config for now.
                  }

                  // config map to json string? No, configContent IS json string.
                  final config = configContent;
                  
                  print("Starting Xray Core...");
                  final error = service.start({'config_is_string': true}); // The service expects map?
                  // Wait, CoreService.start logic:
                  // final jsonStr = jsonEncode(config);
                  // It encodes the map to json.
                  // But Xray expects the "config file content" (JSON).
                  
                  // If we pass a Map, jsonEncode will produce JSON string.
                  // If we pass a String (configContent), jsonEncode will produce escaped string "{\"log...\"}".
                  // That is NOT what we want.
                  
                  // We need to update CoreService to accept String directly or handle Map -> String correctly.
                  // Xray Bridge expects `configStr` which IS the JSON config.
                  
                  // Let's modify CoreService to accept String? 
                  // Or we cheat: pass Map, but maybe we can't easily map the unstructured JSON text to Map without decoding first.
                  
                  // Better: Decode the user's JSON string to Map, then pass it to service.start, which re-encodes it.
                  // This validates JSON too.
                  
                  import 'dart:convert';
                  
                  Map<String, dynamic> configMap;
                  try {
                    configMap = jsonDecode(configContent);
                  } catch (e) {
                      if(context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: Colors.red),
                      );
                    }
                    return;
                  }

                  final errorResult = service.start(configMap);
                  
                  if (errorResult != null) {
                    print("Error starting core: $errorResult");
                    if(context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $errorResult'), backgroundColor: Colors.red),
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
