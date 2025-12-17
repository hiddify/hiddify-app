import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/connection/connection.dart';
import 'package:hiddify/gen/assets.gen.dart';

class ConnectionButton extends StatelessWidget {
  const ConnectionButton({
    required this.state,
    required this.onTap,
    required this.t,
    super.key,
  });

  final ConnectionStatus state;
  final VoidCallback onTap;
  final TranslationsEn t;

  String get _label {
    switch (state) {
      case ConnectionStatus.connected:
        return t.connection.connected;
      case ConnectionStatus.connecting:
        return '${t.connection.connecting}...';
      case ConnectionStatus.error:
        return t.failure.connection.connectionError;
      case ConnectionStatus.disconnected:
        return t.connection.tapToConnect;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnecting = state == ConnectionStatus.connecting;
    final isConnected = state == ConnectionStatus.connected;
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    final gradientColors = isConnected
        ? [AppColors.gradientStart, AppColors.gradientEnd]
        : [AppColors.brandColor, AppColors.secondaryBrandColor];

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isConnected || isConnecting)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) => Container(
                        width: 180 + (40 * value),
                        height: 180 + (40 * value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gradientColors.last.withValues(
                            alpha: 0.2 * (1 - value),
                          ),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isConnected
                          ? LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isConnected ? null : colors.surface,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isConnected
                                      ? gradientColors.last
                                      : colors.shadow)
                                  .withValues(alpha: isConnected ? 0.4 : 0.1),
                          blurRadius: 30,
                          spreadRadius: isConnected ? 5 : 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: isConnected
                          ? null
                          : Border.all(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                              width: 2,
                            ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(36),
                          child: Assets.images.logo.svg(
                            colorFilter: ColorFilter.mode(
                              isConnected ? Colors.white : AppColors.brandColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        if (isConnecting)
                          const SizedBox(
                            width: 176,
                            height: 176,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.brandColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gap(tokens.spacing.x4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _label,
                key: ValueKey(state),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isConnected ? AppColors.gradientEnd : colors.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
