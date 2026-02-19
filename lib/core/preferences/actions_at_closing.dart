import 'package:hiddify/gen/translations.g.dart';

enum ActionsAtClosing {
  ask,
  hide,
  exit;

  String present(TranslationsEn t) => switch (this) {
    ask => t.dialogs.windowClosing.askEachTime,
    hide => t.common.hide,
    exit => t.common.exit,
  };
}
