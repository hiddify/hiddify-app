import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/nova_ritual_hero.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connection = ref.watch(connectionNotifierProvider);
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
    final activeProxy = ref.watch(activeProxyNotifierProvider).valueOrNull;
    final stats = ref.watch(statsNotifierProvider).valueOrNull ?? SystemInfo.create();
    final nova = NovaThemeData.of(context);
    final isConnected = connection.valueOrNull is Connected;
    final ritualState = switch (connection) {
      AsyncError() => NovaRitualState.error,
      AsyncData(value: Connected()) => NovaRitualState.connected,
      AsyncData(value: Connecting()) || AsyncData(value: Disconnecting()) => NovaRitualState.connecting,
      _ => NovaRitualState.disconnected,
    };

    final subscription = switch (activeProfile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    return Scaffold(
      backgroundColor: nova.background,
      body: ColoredBox(
        color: nova.background,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _NovaHeader(
                addProfileLabel: t.pages.profiles.add,
                settingsLabel: t.pages.settings.title,
                onAddProfile: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
                onSettings: () => context.goNamed('settings'),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: NovaRitualHero(state: ritualState, child: const ConnectionButton()),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            NovaSpacing.gutter,
                            NovaSpacing.xs,
                            NovaSpacing.gutter,
                            MediaQuery.paddingOf(context).bottom + NovaSpacing.xl,
                          ),
                          sliver: SliverList.list(
                            children: [
                              _NovaServerCard(
                                profile: activeProfile,
                                proxy: activeProxy,
                                onTap: () {
                                  if (activeProfile == null) {
                                    ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
                                  } else if (activeProxy == null) {
                                    ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
                                  } else {
                                    context.goNamed('proxies');
                                  }
                                },
                              ),
                              if (subscription != null) ...[
                                const SizedBox(height: NovaSpacing.lg),
                                _NovaSubscriptionCard(subscription),
                              ],
                              if (isConnected) ...[
                                const SizedBox(height: NovaSpacing.lg),
                                _NovaStatsGrid(stats: stats, delay: activeProxy?.urlTestDelay ?? 0),
                              ],
                              if (activeProfile != null) ...[
                                const SizedBox(height: NovaSpacing.lg),
                                _NovaQuickSettings(
                                  label: t.pages.home.quickSettings,
                                  onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NovaServerCard extends StatelessWidget {
  const _NovaServerCard({required this.profile, required this.proxy, required this.onTap});

  final ProfileEntity? profile;
  final OutboundInfo? proxy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final proxyCity = proxy?.ipinfo.city ?? '';
    final proxyType = proxy?.type ?? '';
    final subtitle = proxyCity.isNotEmpty
        ? proxyCity
        : proxyType.isNotEmpty
        ? proxyType
        : profile == null
        ? 'Добавьте профиль'
        : 'Активный профиль';

    return _NovaCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NovaRadii.large),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.lg, vertical: 14),
          child: Row(
            children: [
              if (proxy != null && proxy!.ipinfo.countryCode.isNotEmpty)
                IPCountryFlag(countryCode: proxy!.ipinfo.countryCode, organization: proxy!.ipinfo.org, size: 42)
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: nova.accentFill, shape: BoxShape.circle),
                  child: Icon(Icons.public_rounded, color: nova.accentHover, size: 22),
                ),
              const SizedBox(width: NovaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proxy?.tagDisplay ?? profile?.name ?? 'Woman in Red',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: nova.primaryText, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: NovaSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: nova.tertiaryText, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: nova.tertiaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _NovaSubscriptionCard extends StatelessWidget {
  const _NovaSubscriptionCard(this.info);

  final SubscriptionInfo info;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final progress = info.total > 0 ? info.ratio : 0.0;

    return _NovaCard(
      elevated: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.lg, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, size: 16, color: nova.tertiaryText),
                const SizedBox(width: NovaSpacing.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(color: nova.primaryText, fontFamily: 'monospace'),
                      children: [
                        TextSpan(
                          text: info.consumption.size(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: info.total > 0 ? ' из ${info.total.size()}' : '',
                          style: TextStyle(color: nova.tertiaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  info.remaining.inDays > 365 ? '∞' : 'до ${info.expire.format()}',
                  style: TextStyle(color: nova.secondaryText, fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: NovaSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(NovaRadii.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                color: nova.accent,
                backgroundColor: nova.pressedSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovaStatsGrid extends StatelessWidget {
  const _NovaStatsGrid({required this.stats, required this.delay});

  final SystemInfo stats;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final items = <(String, String, Color?)>[
      ('ПРИЁМ', '${stats.downlink.toInt().speed()} ↓', nova.accentHover),
      ('ОТДАЧА', '${stats.uplink.toInt().speed()} ↑', NovaColors.signalGood),
      ('ЗАДЕРЖКА', delay > 0 && delay < 65000 ? '$delay ms' : '—', null),
      ('ТРАФИК', (stats.downlinkTotal + stats.uplinkTotal).toInt().size(), null),
    ];

    return _NovaCard(
      child: Padding(
        padding: const EdgeInsets.all(NovaSpacing.lg),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.25,
          mainAxisSpacing: NovaSpacing.lg,
          crossAxisSpacing: NovaSpacing.md,
          children: items.map((item) => _NovaStat(label: item.$1, value: item.$2, color: item.$3)).toList(),
        ),
      ),
    );
  }
}

class _NovaStat extends StatelessWidget {
  const _NovaStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: nova.tertiaryText, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? nova.primaryText,
            fontFamily: 'monospace',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NovaQuickSettings extends StatelessWidget {
  const _NovaQuickSettings({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: nova.secondaryText),
        icon: const Icon(Icons.tune_rounded, size: 17),
        label: Text(label),
      ),
    );
  }
}

class _NovaCard extends StatelessWidget {
  const _NovaCard({required this.child, this.elevated = true});

  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: elevated ? nova.elevatedSurface : nova.surface,
        borderRadius: BorderRadius.circular(NovaRadii.large),
        border: Border.all(color: nova.border),
        boxShadow: elevated ? const [BoxShadow(color: Color(0x3D000000), blurRadius: 18, offset: Offset(0, 8))] : null,
      ),
      child: child,
    );
  }
}

class _NovaHeader extends StatelessWidget {
  const _NovaHeader({
    required this.addProfileLabel,
    required this.settingsLabel,
    required this.onAddProfile,
    required this.onSettings,
  });

  final String addProfileLabel;
  final String settingsLabel;
  final VoidCallback onAddProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: NovaSpacing.sm),
          IconButton(
            tooltip: addProfileLabel,
            onPressed: onAddProfile,
            icon: Icon(Icons.add_circle_outline_rounded, color: nova.secondaryText),
          ),
          Expanded(
            child: Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                style: TextStyle(
                  color: nova.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                children: [
                  const TextSpan(text: 'Woman in '),
                  TextSpan(
                    text: 'Red',
                    style: TextStyle(color: nova.accentHover),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: settingsLabel,
            onPressed: onSettings,
            icon: Icon(Icons.settings_outlined, color: nova.secondaryText),
          ),
          const SizedBox(width: NovaSpacing.sm),
        ],
      ),
    );
  }
}
