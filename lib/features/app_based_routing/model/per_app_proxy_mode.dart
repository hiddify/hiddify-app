import 'package:hiddify/core/localization/translations.dart';

enum AppProxyMode {
  include,
  exclude;

  String present(Translations t) => switch (this) {
    include => t.pages.settings.routing.appBasedRouting.modes.proxy,
    exclude => t.pages.settings.routing.appBasedRouting.modes.bypass,
  };

  /// Title of the app list page.
  String listTitle(Translations t) => switch (this) {
    include => t.pages.settings.routing.appBasedRouting.listTitle.proxy,
    exclude => t.pages.settings.routing.appBasedRouting.listTitle.bypass,
  };
}
