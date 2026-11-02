import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/one_tap/mit_brand.dart';
import 'package:hiddify/features/one_tap/mit_resilience.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MitResiliencePage extends ConsumerStatefulWidget {
  const MitResiliencePage({super.key});
  @override
  ConsumerState<MitResiliencePage> createState() => _MitResiliencePageState();
}

class _MitResiliencePageState extends ConsumerState<MitResiliencePage> with WidgetsBindingObserver {
  MitVpnEnvironment? environment;
  bool checking = false;
  String? error;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    Future.microtask(refresh);
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
  Future<void> refresh() async {
    if (!mounted || checking) return;
    setState(() { checking = true; error = null; });
    try {
      final value = await ref.read(mitVpnPlatformProvider).environment();
      if (mounted) setState(() => environment = value);
    } catch (_) {
      if (mounted) setState(() { environment = null; error = 'Не удалось прочитать состояние Android.'; });
    } finally { if (mounted) setState(() => checking = false); }
  }
  Future<void> openSettings(Future<void> Function() action) async {
    try { await action(); } catch (_) {
      if (mounted) setState(() => error = 'Откройте настройки VPN вручную в настройках Android.');
    }
  }
  Future<void> diagnostic() async {
    await refresh();
    if (!mounted) return;
    final report = mitSafeDiagnosticReport(status: ref.read(connectionNotifierProvider).valueOrNull,
      recovery: ref.read(mitRecoveryViewProvider), autoRecovery: ref.read(MitResiliencePreferences.autoRecovery),
      backupCount: ref.read(MitResiliencePreferences.backupProfiles).length, environment: environment);
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: const Text('Безопасный отчёт'), scrollable: true,
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Только версия и состояния. Без ключей, адресов серверов, имён профилей и сырых логов. Просмотрите отчёт перед копированием.'),
        const SizedBox(height: 12), SelectableText(report),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        TextButton(onPressed: () async {
          await Clipboard.setData(ClipboardData(text: report));
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Копировать')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auto = ref.watch(MitResiliencePreferences.autoRecovery);
    final backups = ref.watch(MitResiliencePreferences.backupProfiles);
    final connection = ref.watch(connectionNotifierProvider).valueOrNull;
    final recovery = ref.watch(mitRecoveryViewProvider);
    final editable = connection?.isDisconnected == true && !recovery.active;
    final profiles = ref.watch(profilesNotifierProvider);
    String flag(bool? value) => value == null ? 'неизвестно' : value ? 'включено' : 'выключено';
    final protected = environment?.alwaysOn == true && environment?.lockdown == true;
    return MitPage(title: 'Защита и восстановление', child: ListView(
      padding: const EdgeInsets.all(20), children: [
        SwitchListTile(title: const Text('Автовосстановление'), value: auto,
          subtitle: const Text('До 6 попыток с задержками. После ручного отключения повторы прекращаются. Включение действует со следующего подключения.'),
          onChanged: (value) => ref.read(MitResiliencePreferences.autoRecovery.notifier).update(value)),
        const Text('Смену Wi-Fi и мобильной сети отслеживает Android-служба. Дополнительные повторы и выбор резервов работают, пока процесс приложения жив. Для остановки процесса и перезапуска устройства настройте постоянный VPN в Android.'),
        if (recovery.active) Text(recovery.label!),
        if (recovery.phase == 'exhausted') const Text('Попытки исчерпаны. Проверьте сеть и подключитесь вручную.'),
        const Divider(),
        const Text('Резервные профили', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Выберите заранее импортированные локальные профили. После двух неудачных повторов используется следующий выбранный резерв. При рабочем соединении профиль не меняется.'),
        if (!editable) const Text('Для изменения резервов отключите VPN и автовосстановление текущего соединения кнопкой питания.'),
        if (profiles.isLoading) const LinearProgressIndicator(),
        if (profiles.hasError) const Text('Не удалось получить список профилей.'),
        for (final profile in profiles.valueOrNull ?? <ProfileEntity>[]) if (profile is LocalProfileEntity)
          CheckboxListTile(value: backups.contains(profile.id),
            title: Text(profile.name),
            subtitle: Text('${mitProfileProtocolLabel(profile.userOverride?.name)}${profile.active ? ' · активный' : ''}${backups.contains(profile.id) ? ' · резерв ${backups.indexOf(profile.id) + 1}' : ''}'),
            onChanged: !editable ? null : (value) async {
              final next = [...backups]..remove(profile.id);
              if (value == true) next.add(profile.id);
              await ref.read(MitResiliencePreferences.backupProfiles.notifier).update(next);
            }),
        if (profiles.hasValue && (profiles.valueOrNull ?? []).whereType<LocalProfileEntity>().isEmpty)
          const Text('Сначала добавьте локальный профиль через меню главного экрана.'),
        const Divider(),
        const Text('Строгая защита Android', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('В настройках Android откройте Mit’s VPN и включите «Постоянный VPN» и «Блокировать соединения без VPN». При разрыве или остановке службы Android блокирует соединения вне VPN. Это отдельная системная настройка, приложение не может включить её само.'),
        Text(protected ? 'Обе системные настройки включены.' : 'Защита пока не подтверждена.'),
        Text('Постоянный VPN: ${flag(environment?.alwaysOn)}\nБлокировка без VPN: ${flag(environment?.lockdown)}'),
        if (environment?.protectionSupported == false) const Text('На этой версии Android проверка статуса недоступна. Проверьте переключатели вручную.'),
        if (environment?.protectionSupported == true && environment?.alwaysOn == null)
          const Text('Подключите VPN и нажмите «Обновить статус», чтобы проверить настройки.'),
        const Text('При включённой системной блокировке ручное отключение VPN может оставить устройство без интернета до повторного подключения или отключения блокировки в Android.'),
        TextButton(onPressed: () => openSettings(ref.read(mitVpnPlatformProvider).openProtectionSettings), child: const Text('Настройки VPN в Android')),
        TextButton(onPressed: checking ? null : refresh, child: const Text('Обновить статус')),
        TextButton(onPressed: () => openSettings(ref.read(mitVpnPlatformProvider).openBatterySettings), child: const Text('Настройки фоновой работы')),
        const Divider(),
        TextButton.icon(onPressed: checking ? null : diagnostic, icon: const Icon(Icons.description_outlined), label: const Text('Просмотреть безопасный отчёт')),
        if (error != null) Text(error!),
      ],
    ));
  }
}
