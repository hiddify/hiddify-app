import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/one_tap/mit_connection_backdrop.dart';
import 'package:hiddify/features/one_tap/mit_connection_controls.dart';
import 'package:hiddify/features/one_tap/mit_profile_import_dialog.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';
import 'package:hiddify/features/one_tap/mit_resilience.dart';
import 'package:hiddify/features/one_tap/mit_profile_names.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OneTapHomePage extends HookConsumerWidget {
  const OneTapHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProfileProvider);
    final status = ref.watch(connectionNotifierProvider);
    final recovery = ref.watch(mitRecoveryViewProvider);
    final names = ref.watch(mitProfileNamesProvider);
    final busy = useState(false);
    final current = status.valueOrNull;
    final protocolLabel = active.valueOrNull == null ? 'VLESS / AWG'
        : mitProfileProtocolLabel(active.valueOrNull?.userOverride?.name);
    final canImport = !busy.value && current is Disconnected && !recovery.active;
    final canStop = switch (current) {
      Connected() || Connecting() || Waiting() || NoAvailableProxies() || HotReloading() => true,
      _ => false,
    };
    final canToggle = !busy.value && (canStop ||
        (active.hasValue && (current is Disconnected || (status.hasError && active.valueOrNull != null))));

    Future<void> importProfile() async {
      if (busy.value || ref.read(mitRecoveryViewProvider).active || ref.read(connectionNotifierProvider).valueOrNull is! Disconnected) return;
      final input = await showDialog<String>(context: context, builder: (_) => const MitProfileImportDialog());
      if (input == null || !context.mounted) return;
      if (ref.read(mitRecoveryViewProvider).active || ref.read(connectionNotifierProvider).valueOrNull is! Disconnected) return;
      busy.value = true;
      try {
        final prepared = prepareVpnProfile(input);
        final repo = await ref.read(profileRepositoryProvider.future);
        if (ref.read(connectionNotifierProvider).valueOrNull is! Disconnected) return;
        final result = await repo.addLocal(prepared.content, userOverride: UserOverride(name: prepared.protocol.profileName)).run();
        if (result.isLeft()) throw StateError('profile validation failed');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль добавлен')));
        }
      } catch (error) {
        if (context.mounted) {
          // Only our input validator can supply a safe, fixed error message.
          final message = error is VpnProfileException
              ? error.message
              : 'Не удалось добавить профиль. Проверьте ключ и совместимость конфигурации.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> powerPressed() async {
      final latest = ref.read(connectionNotifierProvider);
      if (busy.value || latest.valueOrNull is Disconnecting) return;
      final stopping = ref.read(mitRecoveryViewProvider).active || switch (latest.valueOrNull) {
        Connected() || Connecting() || Waiting() || NoAvailableProxies() || HotReloading() => true,
        _ => false,
      };
      if (!stopping) {
        if (ref.read(activeProfileProvider).valueOrNull == null) {
          await importProfile();
          return;
        }
        if (!await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) return;
        if (!context.mounted) return;
        final afterNotice = ref.read(connectionNotifierProvider);
        // Consent must never turn into an unintended disconnect if native status changed.
        if (!(afterNotice.hasError || afterNotice.valueOrNull is Disconnected)) return;
      }
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }

    void openProfiles() {
      if (busy.value || ref.read(connectionNotifierProvider).valueOrNull is! Disconnected) return;
      if (active.valueOrNull == null) {
        importProfile();
      } else {
        ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
      }
    }

    Future<void> openMenu() async {
      final choice = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.add_rounded), title: const Text('Добавить профиль'), enabled: canImport,
                onTap: canImport ? () => Navigator.pop(context, 0) : null),
            ListTile(leading: const Icon(Icons.folder_outlined), title: const Text('Выбрать профиль'), enabled: canImport,
                onTap: canImport ? () => Navigator.pop(context, 1) : null),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Настройки'),
                onTap: () => Navigator.pop(context, 2)),
          ]),
        ),
      );
      if (!context.mounted) return;
      switch (choice) {
        case 0: await importProfile();
        case 1: openProfiles();
        case 2: context.goNamed('settings');
        default: break;
      }
    }

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: mitBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: mitGreen, brightness: Brightness.dark, surface: mitBackground),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: mitBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: mitBackground,
          body: Stack(
            children: [
              Positioned.fill(child: MitConnectionBackdrop(connected: current is Connected && !status.hasError && !recovery.active)),
              SafeArea(
                child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      Row(children: [
                        IconButton(onPressed: openMenu, icon: const Icon(Icons.menu_rounded, color: Colors.white), tooltip: 'Меню'),
                        const Expanded(child: Center(child: Text.rich(
                          TextSpan(children: [TextSpan(text: 'Mit’s ', style: TextStyle(color: Colors.white)), TextSpan(text: 'VPN', style: TextStyle(color: mitGreen))]),
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.8),
                        ))),
                        IconButton(onPressed: () => _showRouting(context), icon: const Icon(Icons.verified_user_outlined, color: mitGreen), tooltip: 'О маршрутизации'),
                      ]),
                      SizedBox(height: (constraints.maxHeight * .11).clamp(30.0, 86.0)),
                      MitConnectionControls(
                        status: current, hasProfile: active.valueOrNull != null, hasError: status.hasError,
                        importing: busy.value, onPressed: canToggle ? powerPressed : null,
                        recoveryLabel: recovery.label,
                      ),
                      const SizedBox(height: 22),
                      Icon(Icons.shield_outlined, color: current is Connected && !status.hasError && !recovery.active ? mitGreen : mitIdle, size: 28),
                      const SizedBox(height: 8),
                      const Text('Подключение под вашим контролем', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB1BDB4), fontSize: 12)),
                      const SizedBox(height: 24),
                      _MitCard(child: ListTile(
                        key: const ValueKey('mit-profile-card'),
                        onTap: canImport ? openProfiles : null,
                        leading: const Icon(Icons.language_rounded, color: mitGreen, size: 32),
                        title: const Text('Активный профиль', style: TextStyle(color: Color(0xFFADB9B0), fontSize: 12)),
                        subtitle: Text(active.isLoading ? 'Загрузка…' : active.hasError ? 'Профиль недоступен' : active.valueOrNull == null ? 'Добавить профиль' : names[active.valueOrNull!.id] ?? 'Основной профиль', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFADB9B0)),
                      )),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Expanded(child: _FeatureCard(icon: Icons.alt_route_rounded, title: 'Умный маршрут', caption: 'РФ напрямую')),
                        const SizedBox(width: 8),
                        Expanded(child: _FeatureCard(icon: Icons.shield_outlined, title: 'Профиль VPN', caption: protocolLabel)),
                        const SizedBox(width: 8),
                        const Expanded(child: _FeatureCard(icon: Icons.touch_app_outlined, title: 'Одна кнопка', caption: 'Ваш контроль')),
                      ]),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        key: const ValueKey('add-reality-profile'),
                        style: OutlinedButton.styleFrom(foregroundColor: mitGreen, side: const BorderSide(color: Color(0xFF33572D))),
                        onPressed: canImport ? importProfile : null,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(busy.value ? 'Проверка профиля…' : 'Добавить профиль'),
                      ),
                      const SizedBox(height: 12),
                      const Text('Маршрут при подключении:\nРоссия — напрямую · Остальной трафик — VPN', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFB1BDB4), fontSize: 11, height: 1.6)),
                    ],
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showRouting(BuildContext context) {
  showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: const Text('Умная маршрутизация'),
    content: const Text('Российские домены и IP-адреса, а также локальная сеть идут напрямую. Остальной трафик направляется через выбранный VPN-профиль. Прямые соединения не проходят через VPN.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
  ));
}

class _MitCard extends StatelessWidget {
  const _MitCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF25492C)),
      gradient: const LinearGradient(colors: [Color(0xF00D1910), Color(0xF0080E0A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: child,
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.caption});
  final IconData icon;
  final String title;
  final String caption;
  @override
  Widget build(BuildContext context) => _MitCard(
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15), child: Column(children: [
      Icon(icon, color: mitGreen, size: 29),
      const SizedBox(height: 9),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4)),
      const SizedBox(height: 4),
      Text(caption, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFADB9B0), fontSize: 10, height: 1.4)),
    ])),
  );
}
