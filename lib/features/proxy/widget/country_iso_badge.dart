import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CountryIsoBadge extends ConsumerWidget {
  const CountryIsoBadge({required this.countryCode, this.size = 40, super.key});

  final String? countryCode;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryLabel = ref.watch(translationsProvider).requireValue.pages.proxies.ipInfo.country;
    final code = normalizedCountryCode(countryCode);
    final displayCode = code.isEmpty ? '?' : code;

    return Semantics(
      label: '$countryLabel: $displayCode',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: BlizzardPalette.selected, borderRadius: BorderRadius.circular(12)),
        child: Text(
          displayCode,
          textDirection: TextDirection.ltr,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: BlizzardPalette.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

String normalizedCountryCode(String? value) {
  final code = value?.trim().toUpperCase() ?? '';
  return RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : '';
}

String proxyDisplayName(OutboundInfo proxy) {
  final display = proxy.tagDisplay.trim();
  return display.isNotEmpty ? display : proxy.tag.trim();
}

String proxyServerSubtitle(OutboundInfo proxy) {
  final selected = proxy.groupSelectedTagDisplay.trim();
  final actualServer = selected.isNotEmpty ? selected : proxyDisplayName(proxy);
  return [actualServer, proxy.type.trim()].where((value) => value.isNotEmpty).join(' · ');
}
