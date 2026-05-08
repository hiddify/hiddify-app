import 'package:flutter/material.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainModeIcon extends HookConsumerWidget {
  const ChainModeIcon({super.key, required this.mode, this.size = 16});

  final ChainMode mode;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Icon(mode.icon(), color: mode.color(), size: size);
  }
}
