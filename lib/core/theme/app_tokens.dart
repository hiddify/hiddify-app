import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_colors.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.spacing,
    required this.radius,
    required this.motion,
    required this.surface,
    required this.status,
  });

  final AppSpacingTokens spacing;
  final AppRadiusTokens radius;
  final AppMotionTokens motion;
  final AppSurfaceTokens surface;
  final AppStatusTokens status;

  factory AppTokens.fromScheme(
    ColorScheme scheme, {
    required bool trueBlack,
    Color? scaffoldBackgroundColor,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final isTrueBlack = isDark && trueBlack;

    final scaffold = scaffoldBackgroundColor ?? scheme.surface;

    final card = isDark ? const Color(0xFF1A1A1E) : scheme.surfaceContainerHigh;

    final cardSubtle = isDark
        ? const Color(0xFF121214)
        : scheme.surfaceContainer;

    final field = isDark
        ? const Color(0xFF1A1A1E)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final disconnectedFill = isDark
        ? const Color(0xFF3B3B44)
        : scheme.surfaceContainerHighest;

    return AppTokens(
      spacing: AppSpacingTokens.standard,
      radius: AppRadiusTokens.standard,
      motion: AppMotionTokens.defaults,
      surface: AppSurfaceTokens(
        scaffold: isTrueBlack ? Colors.black : scaffold,
        card: card,
        cardSubtle: cardSubtle,
        field: field,
      ),
      status: AppStatusTokens(
        success: AppColors.success,
        warning: AppColors.warning,
        info: AppColors.info,
        danger: scheme.error,
        connected: AppColors.connected,
        connecting: AppColors.connecting,
        disconnected: AppColors.disconnected,
        disconnectedFill: disconnectedFill,
        upload: const Color(0xFF10B981),
        download: const Color(0xFF3B82F6),
      ),
    );
  }

  @override
  AppTokens copyWith({
    AppSpacingTokens? spacing,
    AppRadiusTokens? radius,
    AppMotionTokens? motion,
    AppSurfaceTokens? surface,
    AppStatusTokens? status,
  }) => AppTokens(
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
    motion: motion ?? this.motion,
    surface: surface ?? this.surface,
    status: status ?? this.status,
  );

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;

    return AppTokens(
      spacing: spacing.lerp(other.spacing, t),
      radius: radius.lerp(other.radius, t),
      motion: motion.lerp(other.motion, t),
      surface: surface.lerp(other.surface, t),
      status: status.lerp(other.status, t),
    );
  }
}

@immutable
class AppSpacingTokens {
  const AppSpacingTokens({
    required this.x0,
    required this.x1,
    required this.x2,
    required this.x3,
    required this.x4,
    required this.x5,
    required this.x6,
    required this.x7,
    required this.x8,
  });

  static const standard = AppSpacingTokens(
    x0: 0,
    x1: 4,
    x2: 8,
    x3: 12,
    x4: 16,
    x5: 20,
    x6: 24,
    x7: 32,
    x8: 48,
  );

  final double x0;
  final double x1;
  final double x2;
  final double x3;
  final double x4;
  final double x5;
  final double x6;
  final double x7;
  final double x8;

  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: x5);

  AppSpacingTokens copyWith({
    double? x0,
    double? x1,
    double? x2,
    double? x3,
    double? x4,
    double? x5,
    double? x6,
    double? x7,
    double? x8,
  }) => AppSpacingTokens(
    x0: x0 ?? this.x0,
    x1: x1 ?? this.x1,
    x2: x2 ?? this.x2,
    x3: x3 ?? this.x3,
    x4: x4 ?? this.x4,
    x5: x5 ?? this.x5,
    x6: x6 ?? this.x6,
    x7: x7 ?? this.x7,
    x8: x8 ?? this.x8,
  );

  AppSpacingTokens lerp(AppSpacingTokens other, double t) => AppSpacingTokens(
    x0: lerpDouble(x0, other.x0, t) ?? x0,
    x1: lerpDouble(x1, other.x1, t) ?? x1,
    x2: lerpDouble(x2, other.x2, t) ?? x2,
    x3: lerpDouble(x3, other.x3, t) ?? x3,
    x4: lerpDouble(x4, other.x4, t) ?? x4,
    x5: lerpDouble(x5, other.x5, t) ?? x5,
    x6: lerpDouble(x6, other.x6, t) ?? x6,
    x7: lerpDouble(x7, other.x7, t) ?? x7,
    x8: lerpDouble(x8, other.x8, t) ?? x8,
  );
}

@immutable
class AppRadiusTokens {
  const AppRadiusTokens({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  static const standard = AppRadiusTokens(
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24,
    full: 9999,
  );

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;

  AppRadiusTokens copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? full,
  }) => AppRadiusTokens(
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    full: full ?? this.full,
  );

  AppRadiusTokens lerp(AppRadiusTokens other, double t) => AppRadiusTokens(
    sm: lerpDouble(sm, other.sm, t) ?? sm,
    md: lerpDouble(md, other.md, t) ?? md,
    lg: lerpDouble(lg, other.lg, t) ?? lg,
    xl: lerpDouble(xl, other.xl, t) ?? xl,
    full: lerpDouble(full, other.full, t) ?? full,
  );
}

@immutable
class AppMotionTokens {
  const AppMotionTokens({
    required this.quick,
    required this.standard,
    required this.slow,
    required this.curve,
  });

  static const defaults = AppMotionTokens(
    quick: Duration(milliseconds: 150),
    standard: Duration(milliseconds: 300),
    slow: Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
  );

  final Duration quick;
  final Duration standard;
  final Duration slow;
  final Curve curve;

  AppMotionTokens copyWith({
    Duration? quick,
    Duration? standard,
    Duration? slow,
    Curve? curve,
  }) => AppMotionTokens(
    quick: quick ?? this.quick,
    standard: standard ?? this.standard,
    slow: slow ?? this.slow,
    curve: curve ?? this.curve,
  );

  AppMotionTokens lerp(AppMotionTokens other, double t) => AppMotionTokens(
    quick: _lerpDuration(quick, other.quick, t),
    standard: _lerpDuration(standard, other.standard, t),
    slow: _lerpDuration(slow, other.slow, t),
    curve: t < 0.5 ? curve : other.curve,
  );

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final value = lerpDouble(
      a.inMicroseconds.toDouble(),
      b.inMicroseconds.toDouble(),
      t,
    );
    return Duration(
      microseconds: (value ?? a.inMicroseconds.toDouble()).round(),
    );
  }
}

@immutable
class AppSurfaceTokens {
  const AppSurfaceTokens({
    required this.scaffold,
    required this.card,
    required this.cardSubtle,
    required this.field,
  });

  final Color scaffold;
  final Color card;
  final Color cardSubtle;
  final Color field;

  AppSurfaceTokens copyWith({
    Color? scaffold,
    Color? card,
    Color? cardSubtle,
    Color? field,
  }) => AppSurfaceTokens(
    scaffold: scaffold ?? this.scaffold,
    card: card ?? this.card,
    cardSubtle: cardSubtle ?? this.cardSubtle,
    field: field ?? this.field,
  );

  AppSurfaceTokens lerp(AppSurfaceTokens other, double t) => AppSurfaceTokens(
    scaffold: Color.lerp(scaffold, other.scaffold, t) ?? scaffold,
    card: Color.lerp(card, other.card, t) ?? card,
    cardSubtle: Color.lerp(cardSubtle, other.cardSubtle, t) ?? cardSubtle,
    field: Color.lerp(field, other.field, t) ?? field,
  );
}

@immutable
class AppStatusTokens {
  const AppStatusTokens({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.connected,
    required this.connecting,
    required this.disconnected,
    required this.disconnectedFill,
    required this.upload,
    required this.download,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color danger;
  final Color connected;
  final Color connecting;
  final Color disconnected;
  final Color disconnectedFill;
  final Color upload;
  final Color download;

  AppStatusTokens copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    Color? connected,
    Color? connecting,
    Color? disconnected,
    Color? disconnectedFill,
    Color? upload,
    Color? download,
  }) => AppStatusTokens(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    danger: danger ?? this.danger,
    connected: connected ?? this.connected,
    connecting: connecting ?? this.connecting,
    disconnected: disconnected ?? this.disconnected,
    disconnectedFill: disconnectedFill ?? this.disconnectedFill,
    upload: upload ?? this.upload,
    download: download ?? this.download,
  );

  AppStatusTokens lerp(AppStatusTokens other, double t) => AppStatusTokens(
    success: Color.lerp(success, other.success, t) ?? success,
    warning: Color.lerp(warning, other.warning, t) ?? warning,
    info: Color.lerp(info, other.info, t) ?? info,
    danger: Color.lerp(danger, other.danger, t) ?? danger,
    connected: Color.lerp(connected, other.connected, t) ?? connected,
    connecting: Color.lerp(connecting, other.connecting, t) ?? connecting,
    disconnected:
        Color.lerp(disconnected, other.disconnected, t) ?? disconnected,
    disconnectedFill:
        Color.lerp(disconnectedFill, other.disconnectedFill, t) ??
        disconnectedFill,
    upload: Color.lerp(upload, other.upload, t) ?? upload,
    download: Color.lerp(download, other.download, t) ?? download,
  );
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
