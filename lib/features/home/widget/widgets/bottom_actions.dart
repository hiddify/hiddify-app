import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';

class BottomActions extends StatelessWidget {
  const BottomActions({required this.t, super.key});

  final TranslationsEn t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final buttonColor = tokens.surface.card;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => AddConfigSheet.show(context),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(t.home.addConfig),
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: colors.onSurface,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: tokens.spacing.x3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radius.md),
              ),
            ),
          ),
        ),
        Gap(tokens.spacing.x3),
        FilledButton.icon(
          onPressed: () {
            unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LogViewerPage()),
              ),
            );
          },
          icon: const Icon(Icons.terminal_rounded, size: 20),
          label: Text(t.logs.pageTitle),
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: colors.onSurface,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              vertical: tokens.spacing.x3,
              horizontal: tokens.spacing.x5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius.md),
            ),
          ),
        ),
      ],
    );
  }
}
