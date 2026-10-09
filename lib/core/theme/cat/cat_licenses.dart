import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/gen/assets.gen.dart';

/// Lists the cat theme's rounded font among the app's licenses.
void registerCatThemeLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const ['Nunito'], await rootBundle.loadString(Assets.fonts.nunitoOFL));
  });
}
