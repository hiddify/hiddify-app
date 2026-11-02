import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/one_tap/mit_brand.dart';
import 'package:hiddify/features/one_tap/mit_connection_controls.dart';
import 'package:hiddify/features/one_tap/mit_release.dart';
import 'package:hiddify/features/one_tap/mit_resilience_page.dart';
import 'package:hiddify/features/one_tap/mit_resilience.dart';
import 'package:hiddify/features/one_tap/mit_profile_names.dart';
import 'package:hiddify/features/one_tap/mit_updates_page.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MitIntroPage extends HookConsumerWidget {
  const MitIntroPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);
    return MitPage(title: MitBrand.name, child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        const MitLogo(size: 180),
        const SizedBox(height: 24),
        const Text('Ваш VPN. Одна кнопка.', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        const Text('Добавьте профиль VLESS + REALITY или AmneziaWG и подключитесь. Российские сайты и локальная сеть идут напрямую, остальной трафик — через VPN.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const Text('Разрешение Android VPN запрашивается при первом подключении. Ключ профиля вводится только на вашем устройстве.', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: busy.value ? null : () async {
          busy.value = true;
          try {
            await ref.read(Preferences.introCompleted.notifier).update(true);
          } finally {
            if (context.mounted) busy.value = false;
          }
        }, child: const Text('Начать')),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MitLegalPage())), child: const Text('Лицензии и исходный код')),
      ]),
    ));
  }
}

class MitSettingsPage extends ConsumerWidget {
  const MitSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MitPage(title: 'Настройки', child: ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Center(child: MitLogo(size: 84)),
      const SizedBox(height: 20),
      ListTile(leading: const Icon(Icons.folder_outlined, color: mitGreen), title: const Text('Мои профили'), subtitle: const Text('Выбор, название и удаление'),
        onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview()),
      const Divider(),
      const ListTile(leading: Icon(Icons.alt_route, color: mitGreen), title: Text('Умный маршрут'), subtitle: Text('Россия и локальная сеть — напрямую. Остальной трафик — VPN.')),
      ListTile(leading: const Icon(Icons.shield_outlined, color: mitGreen), title: const Text('Защита и восстановление'),
        subtitle: const Text('Повторы, резервные профили и безопасный отчёт'),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MitResiliencePage()))),
      ListTile(leading: const Icon(Icons.system_update_outlined, color: mitGreen), title: const Text('Обновления'),
        subtitle: const Text('Проверка новой Beta и установка поверх'),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MitUpdatesPage()))),
      const LocalePrefTile(),
      const EnableAnalyticsPrefTile(),
      const Divider(),
      ListTile(leading: const Icon(Icons.info_outline, color: mitGreen), title: const Text('О приложении'),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MitAboutPage()))),
      ListTile(leading: const Icon(Icons.home_outlined, color: mitGreen), title: const Text('На главный экран'), onTap: () => context.goNamed('home')),
    ],
  ));
}

class MitAboutPage extends StatelessWidget {
  const MitAboutPage({super.key});
  @override
  Widget build(BuildContext context) => MitPage(title: 'О приложении', child: ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Center(child: MitLogo(size: 140)),
      const SizedBox(height: 20),
      const Text(MitBrand.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Тестовая Android-версия', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('${MitRelease.label} · ${MitRelease.buildName} (${MitRelease.buildNumber})', textAlign: TextAlign.center),
      const SizedBox(height: 24),
      const Text('Подключение VLESS + REALITY или AmneziaWG и автоматическая маршрутизация. Прямые соединения с российскими ресурсами и локальной сетью не проходят через VPN.'),
      const SizedBox(height: 16),
      const Text('Профили сохраняются в данных приложения. Диагностические логи могут содержать технические сведения; не передавайте их вместе с ключами или ссылками профилей.'),
      const SizedBox(height: 20),
      ListTile(leading: const Icon(Icons.code, color: mitGreen), title: const Text('Исходный код Mit’s VPN'),
        onTap: () => UriUtils.tryLaunch(Uri.parse(MitBrand.sourceUrl))),
      ListTile(leading: const Icon(Icons.description_outlined, color: mitGreen), title: const Text('Лицензии и сведения об авторах'),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MitLegalPage()))),
    ],
  ));
}

class MitLegalPage extends StatelessWidget {
  const MitLegalPage({super.key});
  @override
  Widget build(BuildContext context) => MitPage(title: 'Лицензии и исходный код', child: FutureBuilder<String>(
    future: DefaultAssetBundle.of(context).loadString('assets/legal/NOTICE.txt'),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Не удалось открыть сведения о лицензиях.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(24), children: [
        SelectableText(snapshot.data!, style: const TextStyle(fontSize: 13, height: 1.6)),
        TextButton(onPressed: () => showLicensePage(context: context, applicationName: MitBrand.name), child: const Text('Лицензии зависимостей')),
      ]);
    },
  ));
}

class MitProfilesSheet extends HookConsumerWidget {
  const MitProfilesSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesNotifierProvider);
    final status = ref.watch(connectionNotifierProvider);
    final names = ref.watch(mitProfileNamesProvider);
    final recovery = ref.watch(mitRecoveryViewProvider);
    final busy = useState(false);
    bool canEdit() => !busy.value && !ref.read(mitRecoveryViewProvider).active &&
        (ref.read(connectionNotifierProvider).valueOrNull?.isDisconnected ?? false);

    Future<void> select(ProfileEntity profile) async {
      if (!canEdit()) return;
      busy.value = true;
      try {
        await ref.read(profilesNotifierProvider.notifier).selectActiveProfile(profile.id);
        if (context.mounted) Navigator.pop(context);
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось выбрать профиль.')));
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> remove(ProfileEntity profile) async {
      if (!canEdit()) return;
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Удалить профиль?'),
        content: const Text('Для повторного подключения понадобится снова добавить профиль.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ));
      if (confirmed != true || !context.mounted || !canEdit()) return;
      busy.value = true;
      try {
        await ref.read(profilesNotifierProvider.notifier).deleteProfile(profile);
        await ref.read(mitProfileNamesProvider.notifier).rename(profile.id, '');
        final backups = ref.read(MitResiliencePreferences.backupProfiles);
        await ref.read(MitResiliencePreferences.backupProfiles.notifier).update([...backups]..remove(profile.id));
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось удалить профиль.')));
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> rename(ProfileEntity profile) async {
      if (!canEdit()) return;
      final name = await showDialog<String>(context: context,
        builder: (_) => _MitRenameDialog(initial: names[profile.id] ?? ''));
      if (name == null || !context.mounted || !canEdit()) return;
      busy.value = true;
      try { await ref.read(mitProfileNamesProvider.notifier).rename(profile.id, name); }
      catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось сохранить название.'))); }
      finally { if (context.mounted) busy.value = false; }
    }

    final enabled = !busy.value && !recovery.active && (status.valueOrNull?.isDisconnected ?? false);
    return Theme(data: mitTheme(), child: Material(color: mitBackground, child: SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .65,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(20), child: Text('Мои профили', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
        if (!enabled) const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Для изменения профилей отключите VPN.')),
        Expanded(child: profiles.when(
          data: (items) => items.isEmpty ? const Center(child: Text('Добавьте профиль на главном экране.')) : ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final profile = items[index];
              return ListTile(
                leading: Icon(profile.active ? Icons.check_circle : Icons.circle_outlined, color: profile.active ? mitGreen : Colors.white54),
                title: Text(names[profile.id] ?? 'Профиль ${index + 1}', maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${profile.active ? 'Выбран' : 'Нажмите для выбора'} · ${mitProfileProtocolLabel(profile.userOverride?.name)}'),
                onTap: enabled ? () => select(profile) : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'Название профиля', icon: const Icon(Icons.edit_outlined), onPressed: enabled ? () => rename(profile) : null),
                  IconButton(tooltip: 'Удалить профиль', icon: const Icon(Icons.delete_outline), onPressed: enabled ? () => remove(profile) : null),
                ]),
              );
            },
          ),
          error: (_, _) => const Center(child: Text('Не удалось загрузить профили.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        )),
      ]),
    ))));
  }
}

class _MitRenameDialog extends StatefulWidget {
  const _MitRenameDialog({required this.initial});
  final String initial;
  @override
  State<_MitRenameDialog> createState() => _MitRenameDialogState();
}
class _MitRenameDialogState extends State<_MitRenameDialog> {
  late final input = TextEditingController(text: widget.initial);
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Название профиля'),
    content: TextField(controller: input, maxLength: 60, autofocus: true, autocorrect: false,
      enableSuggestions: false, enableIMEPersonalizedLearning: false,
      decoration: const InputDecoration(hintText: 'Например: Основной или Резерв')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
      TextButton(onPressed: () => Navigator.pop(context, input.text), child: const Text('Сохранить')),
    ]);
}
