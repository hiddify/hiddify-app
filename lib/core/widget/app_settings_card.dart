import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_tokens.dart';

class AppSettingsCard extends StatelessWidget {
  const AppSettingsCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Card(
      elevation: 0,
      color: tokens.surface.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
