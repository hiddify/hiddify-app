import 'package:flutter/material.dart';

/// Approved Blizzard Dark v1 semantic colors. RGBA source tokens use ARGB here.
abstract final class BlizzardPalette {
  static const background = Color(0xFF06121D);
  static const surface = Color(0xFF102235);
  static const elevated = Color(0xFF19374C);
  static const selected = Color(0xFF1B455D);
  static const primary = Color(0xFFEFF7FD);
  static const secondary = Color(0xFFBACDDB);
  static const muted = Color(0xFF9BB3C5);
  static const disabled = Color(0xFF7895A9);
  static const accent = Color(0xFF72D1FF);
  static const border = Color(0xFF55758B);
  static const separator = Color(0xFF2C485B);
  static const error = Color(0xFFF7AAAA);
  static const warning = Color(0xFFEAC586);
  static const glass = Color(0x18163C51);
  static const glassHighlight = Color(0x2EEFF7FD);
  static const glassEdge = Color(0xB3DFF7FF);
  static const glassShade = Color(0x2906121D);
  static const scrim = Color(0x80000000);
  static const shadow = Color(0x40000000);
  static const particleFar = Color(0xFFA1D8FA);
  static const particleNear = Color(0xFFD6F2FF);
  static const ribbonShade = Color(0xFF28A9DA);
  static const ribbonCrest = Color(0xFF65D6FF);
  static const glow = Color(0x3372D1FF);
  static const connectionGlass = Color(0x660C344C);
  static const connectionHighlight = Color(0x386DBCE0);
  static const connectionHalo = Color(0x1472D1FF);
}

abstract final class BlizzardRadii {
  static const field = 8.0;
  static const row = 12.0;
  static const card = 20.0;
  static const sheet = 24.0;
  static const dialog = 24.0;
  static const tab = 26.0;
  static const dock = 32.0;
  static const connection = 44.0;
  static const pill = 999.0;
}

abstract final class BlizzardMetrics {
  static const minimumTarget = 44.0;
  static const dockWidth = 320.0;
  static const dockHeight = 64.0;
  static const dockTabWidth = 152.0;
  static const dockTabHeight = 52.0;
  static const connectionButton = 148.0;
  static const connectionStatusHeight = 98.0;
  static const connectionControlGroupHeight = 210.0;
  static const connectionLabelGap = 16.0;
  static const waveSize = Size(353, 260);
  static const waveDuration = Duration(seconds: 12);
  static const waveTopFromStatus = 76.0;
  static const controlTopFromStatus = 116.0;
}

/// Optical controls transmit the scene; content surfaces remain opaque.
abstract final class BlizzardGlassMetrics {
  static const blur = 1.6;
  static const connectionBlur = 3.5;
  static const lensScale = 1.055;
  static const edgeWidth = 1.2;
}

/// Opaque content keeps decoration from reducing readability.
@immutable
class BlizzardMaterials {
  const BlizzardMaterials({this.highContrast = false});
  final bool highContrast;
  Color get content => highContrast ? BlizzardPalette.background : BlizzardPalette.surface;
  Color get control => highContrast ? BlizzardPalette.surface : BlizzardPalette.elevated;
  Color get edge => highContrast ? BlizzardPalette.secondary : BlizzardPalette.border;
  Color get opaqueFallback => BlizzardPalette.background;
}
