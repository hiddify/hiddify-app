import 'package:flutter/material.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.isDesktop) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 32,
      color: colors.surface,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hiddify',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          _WindowCaptionButton.minimize(colors: colors),
          _WindowCaptionButton.maximize(colors: colors),
          _WindowCaptionButton.close(colors: colors),
        ],
      ),
    );
  }
}

class _WindowCaptionButton extends StatefulWidget {
  const _WindowCaptionButton({
    required this.icon,
    required this.onTap,
    required this.colors,
    this.isClose = false,
  });

  factory _WindowCaptionButton.minimize({required ColorScheme colors}) =>
      _WindowCaptionButton(
        icon: Icons.remove_rounded,
        onTap: windowManager.minimize,
        colors: colors,
      );

  factory _WindowCaptionButton.maximize({required ColorScheme colors}) =>
      _WindowCaptionButton(
        icon: Icons.crop_square_rounded,
        onTap: () async {
          if (await windowManager.isMaximized()) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        },
        colors: colors,
      );

  factory _WindowCaptionButton.close({required ColorScheme colors}) =>
      _WindowCaptionButton(
        icon: Icons.close_rounded,
        onTap: windowManager.close,
        colors: colors,
        isClose: true,
      );

  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colors;
  final bool isClose;

  @override
  State<_WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<_WindowCaptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isClose && _isHovered
        ? widget.colors.error
        : _isHovered
        ? widget.colors.onSurface
        : widget.colors.onSurfaceVariant;

    final backgroundColor = widget.isClose && _isHovered
        ? widget.colors.errorContainer
        : _isHovered
        ? widget.colors.surfaceContainerHighest
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 32,
          color: backgroundColor,
          child: Icon(widget.icon, size: 16, color: color),
        ),
      ),
    );
  }
}
