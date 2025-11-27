import 'dart:io';

import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_notifier.g.dart';

typedef NewProfileLink = ({String? url, String? name});

@Riverpod(keepAlive: true)
class DeepLinkNotifier extends _$DeepLinkNotifier with InfraLogger {
  @override
  Future<NewProfileLink?> build() async {
    if (Platform.isLinux) return null;

    // Desktop: read initial deep link from process arguments if present
    String? initialPayload;
    try {
      final args = Platform.executableArguments;
      // Heuristic: first arg that looks like our custom scheme
      initialPayload = args.firstWhere(
        (a) => LinkParser.protocols.any((p) => a.startsWith('$p://')),
        orElse: () => '',
      );
      if (initialPayload.isEmpty) initialPayload = null;
    } catch (_) {}
    if (initialPayload != null) {
      loggy.debug('initial payload: [$initialPayload]');
      final link = LinkParser.deep(initialPayload);
      return link;
    }
    return null;
  }

  // Runtime updates from OS association are not supported without a plugin.
}
