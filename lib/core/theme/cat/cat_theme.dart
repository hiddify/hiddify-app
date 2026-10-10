import 'package:flutter/material.dart';

/// Colors of the cats drawn across the app: the big one on the home page, the
/// small ones in toasts and the app bar, the paws, ears and the loafing cat.
///
/// Three cats live here, one per theme mode: a ginger tabby for light, a grey
/// night cat with amber eyes for dark, and a black cat with glowing eyes for
/// true black.
@immutable
class CatTheme extends ThemeExtension<CatTheme> {
  const CatTheme({
    required this.fur,
    required this.furShade,
    required this.muzzle,
    required this.innerEar,
    required this.nose,
    required this.iris,
    required this.pupil,
    required this.eyeShine,
    required this.whisker,
    required this.blush,
    required this.line,
    required this.outline,
    required this.pawPrint,
    required this.auraIdle,
    required this.auraBusy,
    required this.auraConnected,
    required this.auraCurious,
    required this.auraError,
    required this.heart,
    this.glowingEyes = false,
    this.stripes = true,
  });

  /// Main coat color.
  final Color fur;

  /// Darker coat color, for the tabby stripes, the tail tip and fur details.
  final Color furShade;

  /// The light fur around the nose and mouth.
  final Color muzzle;
  final Color innerEar;
  final Color nose;
  final Color iris;
  final Color pupil;
  final Color eyeShine;
  final Color whisker;
  final Color blush;

  /// Drawn lines on the face: the mouth, closed eyes and eyelids.
  final Color line;

  /// A thin line around the head, so a dark cat still reads on a dark page.
  final Color outline;

  /// Paw prints on backgrounds, loaders and progress bars.
  final Color pawPrint;

  /// The glow behind the home cat, one per connection state.
  final Color auraIdle;
  final Color auraBusy;
  final Color auraConnected;
  final Color auraCurious;
  final Color auraError;

  final Color heart;

  /// Black cats get a soft glow around the eyes, so they read in the dark.
  final bool glowingEyes;

  /// Tabby stripes on the forehead.
  final bool stripes;

  static const CatTheme ginger = CatTheme(
    fur: Color(0xFFF5A35C),
    furShade: Color(0xFFDB7633),
    muzzle: Color(0xFFFFF4E6),
    innerEar: Color(0xFFF9B4C2),
    nose: Color(0xFFEF7D95),
    iris: Color(0xFF8BC34A),
    pupil: Color(0xFF2B2118),
    eyeShine: Color(0xFFFFFFFF),
    whisker: Color(0xFF9C7A63),
    blush: Color(0xFFFF8FA3),
    line: Color(0xFF4A2E1C),
    outline: Color(0xFFC2662B),
    pawPrint: Color(0xFFB0683A),
    auraIdle: Color(0xFF9E8CDB),
    auraBusy: Color(0xFFF2B33D),
    auraConnected: Color(0xFF4CAF50),
    auraCurious: Color(0xFF26A69A),
    auraError: Color(0xFFE53935),
    heart: Color(0xFFFF5C8A),
  );

  static const CatTheme night = CatTheme(
    fur: Color(0xFF9A93B8),
    furShade: Color(0xFF6F6890),
    muzzle: Color(0xFFDCD8EE),
    innerEar: Color(0xFFE7A3BC),
    nose: Color(0xFFE88AA8),
    iris: Color(0xFFFFC94D),
    pupil: Color(0xFF1A1424),
    eyeShine: Color(0xFFFFFFFF),
    whisker: Color(0xFFDCD8EE),
    blush: Color(0xFFFF8FB1),
    line: Color(0xFF2A2238),
    outline: Color(0xFF4B4566),
    pawPrint: Color(0xFFB9B1DE),
    auraIdle: Color(0xFF7E6FD1),
    auraBusy: Color(0xFFFFC94D),
    auraConnected: Color(0xFF66D17A),
    auraCurious: Color(0xFF4DD0C4),
    auraError: Color(0xFFFF6B6B),
    heart: Color(0xFFFF7AA2),
  );

  static const CatTheme black = CatTheme(
    fur: Color(0xFF1F1E24),
    furShade: Color(0xFF34323C),
    muzzle: Color(0xFF2C2A33),
    innerEar: Color(0xFF6E3F57),
    nose: Color(0xFF9A5E75),
    iris: Color(0xFFD9F45E),
    pupil: Color(0xFF050505),
    eyeShine: Color(0xFFFFFFFF),
    whisker: Color(0xFFA8A6B4),
    blush: Color(0xFF8C4A66),
    line: Color(0xFFB8B5C4),
    outline: Color(0xFF55525F),
    pawPrint: Color(0xFFD9F45E),
    auraIdle: Color(0xFF6F62C4),
    auraBusy: Color(0xFFFFD54F),
    auraConnected: Color(0xFFB4F25E),
    auraCurious: Color(0xFF4DD0C4),
    auraError: Color(0xFFFF5252),
    heart: Color(0xFFFF6E9C),
    glowingEyes: true,
    stripes: false,
  );

  /// The cat of the current theme, ginger when a theme has none.
  static CatTheme of(BuildContext context) => Theme.of(context).extension<CatTheme>() ?? ginger;

  @override
  CatTheme copyWith({
    Color? fur,
    Color? furShade,
    Color? muzzle,
    Color? innerEar,
    Color? nose,
    Color? iris,
    Color? pupil,
    Color? eyeShine,
    Color? whisker,
    Color? blush,
    Color? line,
    Color? outline,
    Color? pawPrint,
    Color? auraIdle,
    Color? auraBusy,
    Color? auraConnected,
    Color? auraCurious,
    Color? auraError,
    Color? heart,
    bool? glowingEyes,
    bool? stripes,
  }) => CatTheme(
    fur: fur ?? this.fur,
    furShade: furShade ?? this.furShade,
    muzzle: muzzle ?? this.muzzle,
    innerEar: innerEar ?? this.innerEar,
    nose: nose ?? this.nose,
    iris: iris ?? this.iris,
    pupil: pupil ?? this.pupil,
    eyeShine: eyeShine ?? this.eyeShine,
    whisker: whisker ?? this.whisker,
    blush: blush ?? this.blush,
    line: line ?? this.line,
    outline: outline ?? this.outline,
    pawPrint: pawPrint ?? this.pawPrint,
    auraIdle: auraIdle ?? this.auraIdle,
    auraBusy: auraBusy ?? this.auraBusy,
    auraConnected: auraConnected ?? this.auraConnected,
    auraCurious: auraCurious ?? this.auraCurious,
    auraError: auraError ?? this.auraError,
    heart: heart ?? this.heart,
    glowingEyes: glowingEyes ?? this.glowingEyes,
    stripes: stripes ?? this.stripes,
  );

  @override
  CatTheme lerp(covariant ThemeExtension<CatTheme>? other, double t) {
    if (other is! CatTheme) return this;
    return CatTheme(
      fur: Color.lerp(fur, other.fur, t)!,
      furShade: Color.lerp(furShade, other.furShade, t)!,
      muzzle: Color.lerp(muzzle, other.muzzle, t)!,
      innerEar: Color.lerp(innerEar, other.innerEar, t)!,
      nose: Color.lerp(nose, other.nose, t)!,
      iris: Color.lerp(iris, other.iris, t)!,
      pupil: Color.lerp(pupil, other.pupil, t)!,
      eyeShine: Color.lerp(eyeShine, other.eyeShine, t)!,
      whisker: Color.lerp(whisker, other.whisker, t)!,
      blush: Color.lerp(blush, other.blush, t)!,
      line: Color.lerp(line, other.line, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      pawPrint: Color.lerp(pawPrint, other.pawPrint, t)!,
      auraIdle: Color.lerp(auraIdle, other.auraIdle, t)!,
      auraBusy: Color.lerp(auraBusy, other.auraBusy, t)!,
      auraConnected: Color.lerp(auraConnected, other.auraConnected, t)!,
      auraCurious: Color.lerp(auraCurious, other.auraCurious, t)!,
      auraError: Color.lerp(auraError, other.auraError, t)!,
      heart: Color.lerp(heart, other.heart, t)!,
      glowingEyes: t < .5 ? glowingEyes : other.glowingEyes,
      stripes: t < .5 ? stripes : other.stripes,
    );
  }
}
