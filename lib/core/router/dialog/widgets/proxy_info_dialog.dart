import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProxyInfoDialog extends HookConsumerWidget {
  const ProxyInfoDialog({super.key, required this.outboundInfo});

  final OutboundInfo outboundInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: SelectionArea(child: Text(outboundInfo.tagDisplay)),
      content: OutboundInfoWidget(outboundInfo: outboundInfo),
      actions: [TextButton(onPressed: context.pop, child: Text(t.common.close))],
    );
  }
}

class OutboundInfoWidget extends HookConsumerWidget {
  final OutboundInfo outboundInfo;

  const OutboundInfoWidget({super.key, required this.outboundInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // final subOutboundInfo = outboundInfo.groupSelectedTag ?? outboundInfo;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // SizedBox(height: 16.0),
          _buildInfoRow(t.dialogs.proxyInfo.fullTag, outboundInfo.tag),
          _buildInfoRow(t.dialogs.proxyInfo.type, outboundInfo.type),
          _buildInfoRow(
            t.dialogs.proxyInfo.testTime,
            DateFormat('yyyy-MM-dd HH:mm:ss').format(outboundInfo.urlTestTime.toDateTime().toLocal()),
          ),
          _buildInfoRow(t.dialogs.proxyInfo.testDelay, '${outboundInfo.urlTestDelay} ms'),
          _buildIpInfo(outboundInfo.ipinfo, ref),
          _buildInfoRow(t.dialogs.proxyInfo.upload, formatBytes(outboundInfo.upload.toInt())),
          _buildInfoRow(t.dialogs.proxyInfo.download, formatBytes(outboundInfo.download.toInt())),
          _buildInfoRow(t.dialogs.proxyInfo.isSelected, outboundInfo.isSelected ? '✅' : '❌'),
          _buildInfoRow(t.dialogs.proxyInfo.isGroup, outboundInfo.isGroup ? '✅' : '❌'),
          _buildInfoRow(t.dialogs.proxyInfo.isSecure, outboundInfo.isSecure ? '✅' : '❌'),
          // _buildInfoRow('Is Visible:', outboundInfo.isVisible ? '✅' : '❌'),
          _buildInfoRow(t.dialogs.proxyInfo.port, outboundInfo.port.toString()),
          _buildInfoRow(t.dialogs.proxyInfo.host, outboundInfo.host),
        ],
      ),
    );
  }

  String formatBytes(int bytes, {int decimals = 3}) {
    if (bytes <= 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals2 = switch (unitIndex) {
      0 => 0,
      1 => 0,
      2 => 1,
      _ => decimals,
    };

    return '${size.toStringAsFixed(decimals2)} ${units[unitIndex]}';
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8.0),
          Flexible(
            child: onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    child: SelectableText(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(decoration: TextDecoration.underline),
                    ),
                  )
                : SelectableText(value, textAlign: TextAlign.right),
          ),
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
        _buildInfoRow(t.dialogs.proxyInfo.ip, ipInfo.ip),
        _buildInfoRow(t.dialogs.proxyInfo.countryCode, ipInfo.countryCode),
        _buildInfoRow(t.dialogs.proxyInfo.region, ipInfo.region), // Handle optional fields
        _buildInfoRow(t.dialogs.proxyInfo.city, ipInfo.city),
        _buildInfoRow(t.dialogs.proxyInfo.asn, ipInfo.asn.toString()),
        _buildInfoRow(t.dialogs.proxyInfo.organization, ipInfo.org),
        // _buildInfoRow(t.outboundInfo.latitude, ipInfo.latitude.toString()),
        // _buildInfoRow(t.outboundInfo.longitude, ipInfo.longitude.toString()),
        _buildInfoRow(
          t.dialogs.proxyInfo.location,
          "${ipInfo.latitude}, ${ipInfo.longitude}",
          onTap: () => launchUrl(
            Uri.parse(
              !PlatformUtils.isInAppStore
                  ? 'https://maps.apple.com/?ll=${ipInfo.latitude},${ipInfo.longitude}'
                  : 'https://www.google.com/maps/@${ipInfo.latitude},${ipInfo.longitude},18z',
            ),
          ),
        ),
        _buildInfoRow(t.dialogs.proxyInfo.postalCode, ipInfo.postalCode),
      ],
    );
  }
}
