import 'dart:io';

import 'package:hiddify/utils/utils.dart';
// import 'package:protocol_handler/protocol_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_notifier.g.dart';

typedef NewProfileLink = ({String? url, String? name});

@Riverpod(keepAlive: true)
class DeepLinkNotifier extends _$DeepLinkNotifier
    with InfraLogger {
  @override
  Future<NewProfileLink?> build() async {
    if (Platform.isLinux) return null;

    // Temporarily disabled protocol_handler to test Windows compatibility
    // for (final protocol in LinkParser.protocols) {
    //   await protocolHandler.register(protocol);
    // }
    // protocolHandler.addListener(this);
    // ref.onDispose(() {
    //   protocolHandler.removeListener(this);
    // });

    // final initialPayload = await protocolHandler.getInitialUrl();
    // if (initialPayload != null) {
    //   loggy.debug('initial payload: [$initialPayload]');
    //   final link = LinkParser.deep(initialPayload);
    //   return link;
    // }
    return null;
  }

  // @override
  // void onProtocolUrlReceived(String url) {
  //   super.onProtocolUrlReceived(url);
  //   loggy.debug("url received: [$url]");
  //   final link = LinkParser.deep(url);
  //   if (link == null) {
  //     loggy.debug("link was not valid");
  //     return;
  //   }
  //   update((_) => link);
  // }
}
