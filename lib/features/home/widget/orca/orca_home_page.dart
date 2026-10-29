import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'connect_ring.dart';
import 'glass_kit.dart';
import 'orca_home_body.dart';
import 'orca_strings.dart';

/// Home screen wired to Hiddify's real providers.
class OrcaHomePage extends ConsumerWidget {
  const OrcaHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = OrcaStrings.of(context);
    final status = ref.watch(connectionNotifierProvider);

    final uiState = switch (status.valueOrNull) {
      Connected() || NoAvailableProxies() => OrcaConnectionState.connected,
      Connecting() || Waiting() || Disconnecting() || HotReloading() => OrcaConnectionState.connecting,
      _ => OrcaConnectionState.disconnected,
    };

    // Same rules as Hiddify's own connect button: the core decides what a tap does.
    final VoidCallback? onToggle = switch (status) {
      AsyncData(value: Disconnected()) || AsyncError() => () => _connect(ref),
      AsyncData(value: Connected() || Waiting() || NoAvailableProxies() || Connecting() || HotReloading()) =>
        () => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
      _ => null,
    };

    final running = ref.watch(serviceRunningProvider);
    final proxy = running ? ref.watch(activeProxyNotifierProvider).valueOrNull : null;
    final profileName = ref.watch(activeProfileProvider).valueOrNull?.name;

    final countryCode = proxy?.ipinfo.countryCode ?? '';
    final tag = (proxy?.tagDisplay.isNotEmpty ?? false) ? proxy!.tagDisplay : (proxy?.tag ?? '');

    final String title;
    final String subtitle;
    if (running && tag.isNotEmpty) {
      title = tag;
      final city = proxy?.ipinfo.city ?? '';
      subtitle = city.isNotEmpty ? city : strings.selectedServer;
    } else if (profileName != null && profileName.isNotEmpty) {
      title = profileName;
      subtitle = strings.selectedServer;
    } else {
      title = '—';
      subtitle = strings.noServer;
    }

    final delay = proxy?.urlTestDelay ?? 0;
    final pingMs = running && ConnectionConst.isValidDelay(delay) ? delay : null;

    final Widget flag = countryCode.isNotEmpty
        ? IPCountryFlag(countryCode: countryCode, organization: proxy?.ipinfo.org, size: 52)
        : const SizedBox(
            width: 52,
            height: 52,
            child: ColoredBox(
              color: Color(0xFF16205E),
              child: Icon(Icons.public_rounded, color: OrcaColors.cyan, size: 30),
            ),
          );

    return OrcaHomeBody(
      state: uiState,
      onToggle: onToggle,
      flag: flag,
      serverTitle: title,
      serverSubtitle: subtitle,
      pingMs: pingMs,
      strings: strings,
      onOpenServers: () => context.goNamed('proxies'),
      onOpenSettings: () => context.go('/settings'),
    );
  }

  Future<void> _connect(WidgetRef ref) async {
    final dialogs = ref.read(dialogNotifierProvider.notifier);
    if (ref.read(activeProfileProvider).valueOrNull == null) {
      await dialogs.showNoActiveProfile();
      ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
      return;
    }
    if (await dialogs.showExperimentalFeatureNotice()) {
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }
}
