import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(
    this.proxy, {
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final OutboundInfo proxy;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        proxy.tagDisplay,
        overflow: TextOverflow.ellipsis,
        style: PlatformUtils.isWindows ? const TextStyle(fontFamily: FontFamily.emoji) : null,
      ),
      leading: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IPCountryFlag(
          countryCode: proxy.ipinfo.countryCode,
          organization: proxy.ipinfo.org,
          size: 36,
        ),
      ),

      subtitle: Text.rich(
        TextSpan(
          text: proxy.type,
          children: [
            if (proxy.isGroup)
              TextSpan(
                text: ' (${proxy.groupSelectedOutbound.tagDisplay.trim()})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: proxy.urlTestDelay != 0
          ? Text(
              proxy.urlTestDelay > 65000 ? "×" : proxy.urlTestDelay.toString(),
              style: TextStyle(color: delayColor(context, proxy.urlTestDelay)),
            )
          : null,
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer,
      onTap: onSelect,
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: SelectionArea(child: Text(proxy.tagDisplay)),
            content: OutboundInfoWidget(outboundInfo: proxy),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              ),
            ],
          ),
        );
      },
      horizontalTitleGap: 4,
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) { < 800 => Colors.lightGreen, < 1500 => Colors.orange, _ => Colors.redAccent };
    }
    return switch (delay) { < 800 => Colors.green, < 1500 => Colors.deepOrangeAccent, _ => Colors.red };
  }
}

class OutboundInfoWidget extends HookConsumerWidget {
  final OutboundInfo outboundInfo;

  const OutboundInfoWidget({super.key, required this.outboundInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(height: 16.0),
        _buildInfoRow(t.outboundInfo.fullTag, outboundInfo.tag),
        _buildInfoRow(t.outboundInfo.type, outboundInfo.type),
        _buildInfoRow(t.outboundInfo.url_test_time, DateFormat('yyyy-MM-dd HH:mm:ss').format(outboundInfo.urlTestTime.toDateTime().toLocal())),
        _buildInfoRow(t.outboundInfo.url_test_delay, '${outboundInfo.urlTestDelay} ms'),
        _buildIpInfo(outboundInfo.ipinfo, ref),
        _buildInfoRow(t.outboundInfo.is_selected, outboundInfo.isSelected ? '✅' : '❌'),
        _buildInfoRow(t.outboundInfo.is_group, outboundInfo.isGroup ? '✅' : '❌'),
        _buildInfoRow(t.outboundInfo.is_secure, outboundInfo.isSecure ? '✅' : '❌'),
        // _buildInfoRow('Is Visible:', outboundInfo.isVisible ? '✅' : '❌'),
        _buildInfoRow(t.outboundInfo.port, outboundInfo.port.toString()),
        _buildInfoRow(t.outboundInfo.host, outboundInfo.host),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value, {Future<bool>? Function()? onTap}) {
    if (value.isEmpty || value == '0' || value == '0.0, 0.0') {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8.0),
          Flexible(
              child: onTap != null
                  ? GestureDetector(
                      onTap: onTap,
                      child: SelectableText(value, textAlign: TextAlign.right, style: TextStyle(decoration: TextDecoration.underline)),
                    )
                  : SelectableText(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildIpInfo(IpInfo ipInfo, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('IP Info:', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildInfoRow(t.outboundInfo.ip, ipInfo.ip),
        _buildInfoRow(t.outboundInfo.country_code, ipInfo.countryCode),
        _buildInfoRow(t.outboundInfo.region, ipInfo.region), // Handle optional fields
        _buildInfoRow(t.outboundInfo.city, ipInfo.city),
        _buildInfoRow(t.outboundInfo.asn, ipInfo.asn.toString()),
        _buildInfoRow(t.outboundInfo.organization, ipInfo.org),
        // _buildInfoRow(t.outboundInfo.latitude, ipInfo.latitude.toString()),
        // _buildInfoRow(t.outboundInfo.longitude, ipInfo.longitude.toString()),
        _buildInfoRow(
          t.outboundInfo.location,
          "${ipInfo.latitude}, ${ipInfo.longitude}",
          onTap: () => launchUrl(
            Uri.parse(!PlatformUtils.isInAppStore ? 'https://maps.apple.com/?ll=${ipInfo.latitude},${ipInfo.longitude}' : 'https://www.google.com/maps/@${ipInfo.latitude},${ipInfo.longitude},18z'),
          ),
        ),
        _buildInfoRow(t.outboundInfo.postal_code, ipInfo.postalCode),
      ],
    );
  }
}
