import 'package:hiddify/core/localization/translations.dart';

enum PerAppProxyMode {
  off,
  include,
  exclude;

  bool get enabled => this != off;

  ({String title, String message}) present(TranslationsEn t) => switch (this) {
    off => (
      title: t.pages.settings.routing.perAppProxy.modes.all,
      message: t.pages.settings.routing.perAppProxy.modes.allMsg,
    ),
    include => (
      title: t.pages.settings.routing.perAppProxy.modes.proxy,
      message: t.pages.settings.routing.perAppProxy.modes.proxyMsg,
    ),
    exclude => (
      title: t.pages.settings.routing.perAppProxy.modes.bypass,
      message: t.pages.settings.routing.perAppProxy.modes.bypassMsg,
    ),
  };

  AppProxyMode? toAppProxy() => switch (this) {
    PerAppProxyMode.off => null,
    PerAppProxyMode.include => AppProxyMode.include,
    PerAppProxyMode.exclude => AppProxyMode.exclude,
  };
}

enum AppProxyMode {
  include,
  exclude;

  PerAppProxyMode toPerAppProxy() => switch (this) {
    AppProxyMode.include => PerAppProxyMode.include,
    AppProxyMode.exclude => PerAppProxyMode.exclude,
  };

  ({String title, String message}) present(Translations t) => switch (this) {
    include => (
      title: t.pages.settings.routing.perAppProxy.modes.proxy,
      message: t.pages.settings.routing.perAppProxy.modes.proxyMsg,
    ),
    exclude => (
      title: t.pages.settings.routing.perAppProxy.modes.bypass,
      message: t.pages.settings.routing.perAppProxy.modes.bypassMsg,
    ),
  };
}
