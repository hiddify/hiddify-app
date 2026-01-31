import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/theme/app_tokens.dart';

class AppTextFieldTile extends StatefulWidget {
  const AppTextFieldTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onSubmitted,
    super.key,
    this.subtitle,
    this.width = 90,
    this.keyboardType,
    this.hintText,
    this.textAlign = TextAlign.center,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final double width;
  final TextInputType? keyboardType;
  final String? hintText;
  final TextAlign textAlign;
  final ValueChanged<String> onSubmitted;

  @override
  State<AppTextFieldTile> createState() => _AppTextFieldTileState();
}

class _AppTextFieldTileState extends State<AppTextFieldTile> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextFieldTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onSubmitted(_controller.text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    final iconBackground = colors.secondaryContainer;
    final iconColor = colors.onSecondaryContainer;

    return InkWell(
      onTap: () => _focusNode.requestFocus(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.x4,
          vertical: tokens.spacing.x3,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spacing.x2),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(tokens.radius.sm),
              ),
              child: Icon(widget.icon, size: 20, color: iconColor),
            ),
            SizedBox(width: tokens.spacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: widget.width,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textAlign: widget.textAlign,
                inputFormatters: widget.keyboardType == TextInputType.number
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radius.sm),
                  ),
                  isDense: true,
                  hintText: widget.hintText,
                ),
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
