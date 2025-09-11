import 'package:hiddify/core/localization/translations.dart';

enum PerAppProxyMode {
  off,
  include,
  exclude;

  bool get enabled => this != off;

  ({String title, String message}) present(Translations t) => switch (this) {
        off => (
            title: t.settings.network.perAppProxyModes.off,
            message: t.settings.network.perAppProxyModes.offMsg,
          ),
        include => (
            title: t.settings.network.perAppProxyModes.include,
            message: t.settings.network.perAppProxyModes.includeMsg,
          ),
        exclude => (
            title: t.settings.network.perAppProxyModes.exclude,
            message: t.settings.network.perAppProxyModes.excludeMsg,
          ),
      };
}
