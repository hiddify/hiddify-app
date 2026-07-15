import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

void main() {
  double contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  test('defines the Woman in Red dark semantic hierarchy', () {
    expect(NovaColors.voidBackground, const Color(0xFF060608));
    expect(NovaColors.groupedBackground, const Color(0xFF000000));
    expect(NovaColors.surface, const Color(0xFF1C1C1E));
    expect(NovaColors.elevatedSurface, const Color(0xFF2C2C2E));
    expect(NovaColors.pressedSurface, const Color(0xFF3A3A3C));
    expect(NovaColors.ritualRed, const Color(0xFFFF2D3E));
    expect(NovaThemeData.dark.background, NovaColors.voidBackground);
    expect(NovaThemeData.dark.groupedBackground, NovaColors.groupedBackground);
    expect(NovaThemeData.dark.separator, NovaColors.separator);
    expect(NovaThemeData.dark.accent, NovaColors.ritualRed);
  });

  test('keeps the dock accessibility contract', () {
    expect(NovaDockTokens.height, 64);
    expect(NovaAccessibilityTokens.minimumTapTarget, 44);
    expect(NovaDockTokens.horizontalInset, 12);
    expect(NovaDockTokens.bottomGap, 8);
  });

  test('keeps tertiary small text legible on production dark surfaces', () {
    for (final background in const [
      NovaColors.voidBackground,
      NovaColors.groupedBackground,
      NovaColors.surface,
      NovaColors.elevatedSurface,
    ]) {
      expect(
        contrastRatio(NovaColors.tertiaryText, background),
        greaterThanOrEqualTo(4.5),
        reason: 'tertiary text must remain readable on $background',
      );
    }
  });
}
