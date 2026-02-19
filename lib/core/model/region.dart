import 'package:hiddify/core/localization/translations.dart';

enum Region {
  ir,
  cn,
  ru,
  af,
  id,
  tr,
  br,
  other;

  String present(TranslationsEn t) => switch (this) {
    ir => t.pages.settings.routing.regions.ir,
    cn => t.pages.settings.routing.regions.cn,
    ru => t.pages.settings.routing.regions.ru,
    af => t.pages.settings.routing.regions.af,
    id => t.pages.settings.routing.regions.id,
    tr => t.pages.settings.routing.regions.tr,
    br => t.pages.settings.routing.regions.br,
    other => t.pages.settings.routing.regions.other,
  };
}
