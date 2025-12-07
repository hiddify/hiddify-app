import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
                // TODO: Start Core
              },
              child: const Text('Start Core'),
            ),
          ],
        ),
      ),
    );
  }
}
