import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/access/model/access_state.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/nova_ritual_hero.dart';
import 'package:hiddify/features/identity/data/identity_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum NovaHomeServerAction { addProfile, showProfiles, showProxies }

NovaRitualState novaRitualStateForConnection(AsyncValue<ConnectionStatus> connection) {
  return switch (connection) {
    AsyncError() => NovaRitualState.error,
    AsyncData(value: Disconnected(connectionFailure: ConnectionFailure())) => NovaRitualState.error,
    AsyncData(value: Connected()) => NovaRitualState.connected,
    AsyncData(value: Connecting()) || AsyncData(value: Disconnecting()) => NovaRitualState.connecting,
    _ => NovaRitualState.disconnected,
  };
}

NovaHomeServerAction? novaHomeServerActionForStates({
  required AsyncValue<ProfileEntity?> profile,
  required AsyncValue<OutboundInfo?> proxy,
}) {
  if (profile case AsyncData(value: null)) return NovaHomeServerAction.addProfile;
  if (profile is! AsyncData<ProfileEntity?>) return null;
  if (proxy is! AsyncData<OutboundInfo?>) return null;
  return proxy.value == null ? NovaHomeServerAction.showProfiles : NovaHomeServerAction.showProxies;
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connection = ref.watch(connectionNotifierProvider);
    final activeProfileState = ref.watch(activeProfileProvider);
    final activeProxyState = ref.watch(activeProxyNotifierProvider);
    final activeProfile = activeProfileState.valueOrNull;
    final activeProxy = activeProxyState.valueOrNull;
    final nova = NovaThemeData.of(context);
    final isConnected = connection.valueOrNull?.isConnected ?? false;
    final ritualState = novaRitualStateForConnection(connection);
    final serverAction = novaHomeServerActionForStates(profile: activeProfileState, proxy: activeProxyState);
    final serverLoading = activeProfileState.isLoading || (activeProfile != null && activeProxyState.isLoading);
    final serverError = activeProfileState.hasError || (activeProfile != null && activeProxyState.hasError);
    final accessState = switch (activeProfileState) {
      AsyncLoading() => AccessState.loading,
      AsyncError() => AccessState.temporarilyUnavailable,
      AsyncData(value: null) => AccessState.notConfigured,
      AsyncData(value: RemoteProfileEntity(:final subInfo)) => AccessState.derive(
        hasProfile: true,
        now: DateTime.now(),
        expiresAt: subInfo?.expire,
      ),
      AsyncData() => AccessState.activeMetadataUnavailable,
      _ => AccessState.loading,
    };
    ref.watch(installationIdentityProvider);
    final subscription = switch (activeProfile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    return Scaffold(
      backgroundColor: nova.background,
      body: ColoredBox(
        color: nova.background,
        child: Semantics(
          label: t.pages.home.title,
          container: true,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _NovaHeader(
                  addProfileLabel: t.pages.profiles.add,
                  identityLabel: t.pages.identity.title,
                  settingsLabel: t.pages.settings.title,
                  onAddProfile: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
                  onIdentity: () => context.pushNamed('identityProfile'),
                  onSettings: () => context.goNamed('settings'),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: NovaRitualHero(
                              state: ritualState,
                              statusLabel: ritualState == NovaRitualState.error
                                  ? t.errors.connection.connectionError
                                  : null,
                              child: const ConnectionButton(),
                            ),
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
                                NovaServerCard(
                                  profile: activeProfile,
                                  proxy: activeProxy,
                                  addProfileLabel: t.pages.profiles.add,
                                  profilesLabel: t.pages.profiles.title,
                                  errorLabel: t.pages.profiles.failedToLoad,
                                  isLoading: serverLoading,
                                  hasError: serverError,
                                  onTap: serverAction == null
                                      ? null
                                      : () {
                                          switch (serverAction) {
                                            case NovaHomeServerAction.addProfile:
                                              ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
                                            case NovaHomeServerAction.showProfiles:
                                              ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
                                            case NovaHomeServerAction.showProxies:
                                              context.goNamed('proxies');
                                          }
                                        },
                                ),
                                if (subscription != null) ...[
                                  const SizedBox(height: NovaSpacing.lg),
                                  _NovaSubscriptionCard(
                                    subscription,
                                    expireDateLabel: t.components.subscriptionInfo.expireDate,
                                  ),
                                ],
                                if (accessState == AccessState.expired) ...[
                                  const SizedBox(height: NovaSpacing.lg),
                                  _NovaAccessWarning(label: t.components.subscriptionInfo.expired),
                                ],
                                if (isConnected) ...[
                                  const SizedBox(height: NovaSpacing.lg),
                                  _NovaStatsSection(
                                    delay: activeProxy?.urlTestDelay ?? 0,
                                    downlinkLabel: t.components.stats.downlink,
                                    uplinkLabel: t.components.stats.uplink,
                                    delayLabel: t.pages.proxies.testDelay,
                                    trafficLabel: t.components.stats.totalTransferred,
                                  ),
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
      ),
    );
  }
}

class NovaServerCard extends StatelessWidget {
  const NovaServerCard({
    required this.profile,
    required this.proxy,
    required this.addProfileLabel,
    required this.profilesLabel,
    required this.errorLabel,
    required this.isLoading,
    required this.hasError,
    required this.onTap,
  });

  final ProfileEntity? profile;
  final OutboundInfo? proxy;
  final String addProfileLabel;
  final String profilesLabel;
  final String errorLabel;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final proxyCity = proxy?.ipinfo.city ?? '';
    final proxyType = proxy?.type ?? '';
    final resolvedSubtitle = proxyCity.isNotEmpty
        ? proxyCity
        : proxyType.isNotEmpty
        ? proxyType
        : profile == null
        ? addProfileLabel
        : profilesLabel;
    final subtitle = hasError ? errorLabel : resolvedSubtitle;

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
                      proxy?.tagDisplay ?? profile?.name ?? Constants.appName,
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
              if (isLoading)
                SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: nova.accent))
              else if (hasError)
                Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error)
              else
                Icon(Icons.chevron_right_rounded, color: nova.tertiaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _NovaAccessWarning extends StatelessWidget {
  const _NovaAccessWarning({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(NovaSpacing.md),
        decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(NovaRadii.large)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}

class _NovaSubscriptionCard extends StatelessWidget {
  const _NovaSubscriptionCard(this.info, {required this.expireDateLabel});

  final SubscriptionInfo info;
  final String expireDateLabel;

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
                          text: info.total > 0 ? ' / ${info.total.size()}' : '',
                          style: TextStyle(color: nova.tertiaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  info.remaining.inDays > 365 ? '∞' : '$expireDateLabel: ${info.expire.format()}',
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

class _NovaStatsSection extends ConsumerWidget {
  const _NovaStatsSection({
    required this.delay,
    required this.downlinkLabel,
    required this.uplinkLabel,
    required this.delayLabel,
    required this.trafficLabel,
  });

  final int delay;
  final String downlinkLabel;
  final String uplinkLabel;
  final String delayLabel;
  final String trafficLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsNotifierProvider).valueOrNull ?? SystemInfo.create();
    return _NovaStatsGrid(
      stats: stats,
      delay: delay,
      downlinkLabel: downlinkLabel,
      uplinkLabel: uplinkLabel,
      delayLabel: delayLabel,
      trafficLabel: trafficLabel,
    );
  }
}

class _NovaStatsGrid extends StatelessWidget {
  const _NovaStatsGrid({
    required this.stats,
    required this.delay,
    required this.downlinkLabel,
    required this.uplinkLabel,
    required this.delayLabel,
    required this.trafficLabel,
  });

  final SystemInfo stats;
  final int delay;
  final String downlinkLabel;
  final String uplinkLabel;
  final String delayLabel;
  final String trafficLabel;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      (downlinkLabel, '${stats.downlink.toInt().speed()} ↓'),
      (uplinkLabel, '${stats.uplink.toInt().speed()} ↑'),
      (delayLabel, delay > 0 && delay < 65000 ? '$delay ms' : '—'),
      (trafficLabel, (stats.downlinkTotal + stats.uplinkTotal).toInt().size()),
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
          children: items.map((item) => _NovaStat(label: item.$1, value: item.$2)).toList(),
        ),
      ),
    );
  }
}

class _NovaStat extends StatelessWidget {
  const _NovaStat({required this.label, required this.value});

  final String label;
  final String value;

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
          style: TextStyle(color: nova.primaryText, fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w600),
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
    final shadowColor = Theme.of(context).shadowColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: elevated ? nova.elevatedSurface : nova.surface,
        borderRadius: BorderRadius.circular(NovaRadii.large),
        border: Border.all(color: nova.border),
        boxShadow: elevated
            ? [BoxShadow(color: shadowColor.withValues(alpha: 0.24), blurRadius: 18, offset: const Offset(0, 8))]
            : null,
      ),
      child: child,
    );
  }
}

class _NovaHeader extends StatelessWidget {
  const _NovaHeader({
    required this.addProfileLabel,
    required this.identityLabel,
    required this.settingsLabel,
    required this.onAddProfile,
    required this.onIdentity,
    required this.onSettings,
  });

  final String addProfileLabel;
  final String identityLabel;
  final String settingsLabel;
  final VoidCallback onAddProfile;
  final VoidCallback onIdentity;
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
            child: Text(
              Constants.appName,
              textAlign: TextAlign.center,
              style: TextStyle(color: nova.primaryText, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
            ),
          ),
          IconButton(
            tooltip: identityLabel,
            onPressed: onIdentity,
            icon: Icon(Icons.person_outline_rounded, color: nova.secondaryText),
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
