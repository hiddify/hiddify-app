import 'package:hiddify/gen/translations.g.dart';

enum ActionsAtClosing {
  ask,
  hide,
  exit;

  String present(TranslationsEn t) => switch (this) {
        ask => t.settings.general.actionsAtClosing.askEachTime,
        hide => t.settings.general.actionsAtClosing.hide,
        exit => t.settings.general.actionsAtClosing.exit,
      };
}
