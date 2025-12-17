import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:riverpod/riverpod.dart';

final fontPreferencesProvider =
    NotifierProvider<
      FontPreferencesNotifier,
      ({String fontFamily, double scaleFactor})
    >(FontPreferencesNotifier.new);

class FontPreferencesNotifier
    extends Notifier<({String fontFamily, double scaleFactor})> {
  @override
  ({String fontFamily, double scaleFactor}) build() {
    final prefs = ref.watch(sharedPreferencesProvider).requireValue;
    final family = prefs.getString('font_family') ?? '';
    final scale = prefs.getDouble('font_scale') ?? 1.0;
    return (fontFamily: family, scaleFactor: scale);
  }

  Future<void> setFontFamily(String family) async {
    state = (fontFamily: family, scaleFactor: state.scaleFactor);
    await ref
        .read(sharedPreferencesProvider)
        .requireValue
        .setString('font_family', family);
  }

  Future<void> setScaleFactor(double scale) async {
    state = (fontFamily: state.fontFamily, scaleFactor: scale);
    await ref
        .read(sharedPreferencesProvider)
        .requireValue
        .setDouble('font_scale', scale);
  }
}
