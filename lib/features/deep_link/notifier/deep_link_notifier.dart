import 'dart:io';

import 'package:hiddify/utils/utils.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_notifier.g.dart';

typedef NewProfileLink = ({String? url, String? name});

@Riverpod(keepAlive: true)
class DeepLinkNotifier extends _$DeepLinkNotifier 
    with InfraLogger, ProtocolListener {
  @override
  Future<NewProfileLink?> build() async {
    if (Platform.isLinux) return null;

    // Register protocols using protocol_handler
    for (final protocol in LinkParser.protocols) {
      try {
        await protocolHandler.register(protocol);
        loggy.debug('registered protocol: $protocol');
      } catch (e) {
        loggy.warning('failed to register protocol $protocol: $e');
      }
    }
    
    // Add listener for protocol events
    protocolHandler.addListener(this);
    ref.onDispose(() {
      protocolHandler.removeListener(this);
    });

    // Check for initial URL
    final initialPayload = await protocolHandler.getInitialUrl();
    if (initialPayload != null) {
      loggy.debug('initial payload: [$initialPayload]');
      final link = LinkParser.deep(initialPayload);
      return link;
    }

    return null;
  }

  @override
  void onProtocolUrlReceived(String url) {
    loggy.debug("url received: [$url]");
    final link = LinkParser.deep(url);
    if (link == null) {
      loggy.debug("link was not valid");
      return;
    }
    state = AsyncValue.data(link);
  }
}
