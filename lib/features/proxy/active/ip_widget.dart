import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/utils/ip_utils.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import "package:simple_icons/simple_icons.dart";

final _showIp = StateProvider.autoDispose((ref) {
  ref.disposeDelay(const Duration(seconds: 20));
  ref.listenSelf((previous, next) {
    if (previous == false && next == true) {
      ref.read(hapticServiceProvider.notifier).mediumImpact();
    }
  });
  return false;
});

class IPText extends HookConsumerWidget {
  const IPText({
    required this.ip,
    required this.onLongPress,
    this.constrained = false,
    super.key,
  });

  final String ip;
  final VoidCallback onLongPress;
  final bool constrained;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isVisible = ref.watch(_showIp);
    final textTheme = Theme.of(context).textTheme;
    final ipStyle = (constrained ? textTheme.labelMedium : textTheme.labelLarge)?.copyWith(
      fontFamily: FontFamily.emoji,
    );

    return Semantics(
      label: t.proxies.ipInfoSemantics.address,
      child: InkWell(
        onTap: () {
          ref.read(_showIp.notifier).state = !isVisible;
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedCrossFade(
            firstChild: Text(
              ip,
              style: ipStyle,
              textDirection: TextDirection.ltr,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Padding(
              padding: constrained ? EdgeInsets.zero : const EdgeInsetsDirectional.only(end: 48),
              child: Text(
                obscureIp(ip),
                semanticsLabel: t.general.hidden,
                style: ipStyle,
                textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            crossFadeState: isVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ),
    );
  }
}

class UnknownIPText extends HookConsumerWidget {
  const UnknownIPText({
    required this.text,
    required this.onTap,
    this.constrained = false,
    super.key,
  });

  final String text;
  final VoidCallback onTap;
  final bool constrained;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final textTheme = Theme.of(context).textTheme;
    final style = constrained ? textTheme.bodySmall : textTheme.labelMedium;

    return Semantics(
      label: t.proxies.ipInfoSemantics.address,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            text,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class IPCountryFlag extends HookConsumerWidget {
  const IPCountryFlag({required this.countryCode, this.size = 24, super.key});

  final String countryCode;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Semantics(
      label: t.proxies.ipInfoSemantics.country,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        child: Center(
          child: CircleFlag(countryCode.toLowerCase() == "ir" ? "ir-shir" : countryCode),
        ),
      ),
    );
  }
}

class OrgIconData {
  final IconData icon;
  final Color color;

  const OrgIconData(this.icon, this.color);
}

// Map of organization keywords to icon and color
const Map<String, OrgIconData> organizationData = {
  "cloudflare": OrgIconData(SimpleIcons.cloudflare, SimpleIconColors.cloudflare),
  "hetzner": OrgIconData(SimpleIcons.hetzner, SimpleIconColors.hetzner),
  "ovh": OrgIconData(SimpleIcons.ovh, SimpleIconColors.ovh),
  "azure": OrgIconData(SimpleIcons.microsoftazure, SimpleIconColors.microsoftazure),
  "amazon": OrgIconData(SimpleIcons.amazonaws, SimpleIconColors.amazonaws),
  "oracle": OrgIconData(SimpleIcons.oracle, SimpleIconColors.oracle),
  "fastly": OrgIconData(SimpleIcons.fastly, SimpleIconColors.fastly),
  "digitalocean": OrgIconData(SimpleIcons.digitalocean, SimpleIconColors.digitalocean),
  "alibaba": OrgIconData(SimpleIcons.alibabacloud, SimpleIconColors.alibabacloud),
  "google": OrgIconData(SimpleIcons.googlecloud, SimpleIconColors.googlecloud),
  "starlink": OrgIconData(SimpleIcons.satellite, SimpleIconColors.satellite),
};

class OrganisationFlag extends HookConsumerWidget {
  const OrganisationFlag({required this.organization, this.size = 24, super.key});

  final String organization;
  final double size;

// Function to create flag widget with icon and color
  Widget getFlagWidget({
    required Widget widget,
    required String organization,
    required double size,
    required String label,
  }) {
    return Semantics(
      label: "$label $organization",
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.only(right: 4),
        child: Center(
          child: widget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    for (var entry in organizationData.entries) {
      if (organization.toLowerCase().contains(entry.key)) {
        return getFlagWidget(
          widget: Icon(
            entry.value.icon,
            color: entry.value.color,
            size: size - 4,
          ),
          organization: organization,
          size: size,
          label: t.proxies.ipInfoSemantics.organization,
        );
      }
    }

    // Return empty widget if no match is found
    return const SizedBox.shrink();
  }
}
