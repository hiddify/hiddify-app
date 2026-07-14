import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/deep_linking/my_app_links.dart';
import 'package:hiddify/utils/link_parsers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// For temporary storage of the link received from AppLinks.
String newUrlFromAppLink = '';

String? takeIncomingAppLink(Uri routeUri) {
  final String? url;
  if (LinkParser.protocols.contains(routeUri.scheme)) {
    url = routeUri.toString();
  } else if (newUrlFromAppLink.isNotEmpty) {
    url = newUrlFromAppLink;
  } else {
    return null;
  }
  newUrlFromAppLink = '';
  return url;
}

class RefreshListenable extends ChangeNotifier {
  RefreshListenable(this.ref) {
    ref.listen(myAppLinksProvider, (_, next) {
      if (next.value != null) {
        newUrlFromAppLink = next.value!;
        notifyListeners();
      }
    });
    ref.listen(Preferences.introCompleted, (_, _) => notifyListeners());
  }
  final Ref ref;
}
