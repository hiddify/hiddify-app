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
    ir => t.settings.general.regions.ir,
    cn => t.settings.general.regions.cn,
    ru => t.settings.general.regions.ru,
    tr => t.settings.general.regions.tr,
    af => t.settings.general.regions.af,
    id => t.settings.general.regions.id,
    br => t.settings.general.regions.br,
    other => t.settings.general.regions.other,
  };
}
