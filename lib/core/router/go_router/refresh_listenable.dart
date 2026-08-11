import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/deep_linking/my_app_links.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// For temporary storage of the link received from AppLinks.
String newUrlFromAppLink = '';

class RefreshListenable extends ChangeNotifier {
  RefreshListenable(this.ref) {
    ref.listen(myAppLinksProvider, (_, next) {
      if (next.value != null) {
        newUrlFromAppLink = next.value!;
        notifyListeners();
      }
    });
    ref.listen(Preferences.introCompleted, (_, _) => notifyListeners());
    // Re-run router redirects when the auth state changes (e.g. login/logout/
    // force-logout), so the user is moved to/from /login automatically.
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}
