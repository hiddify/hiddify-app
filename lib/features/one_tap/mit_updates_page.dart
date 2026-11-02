import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/features/one_tap/mit_brand.dart';
import 'package:hiddify/features/one_tap/mit_release.dart';
import 'package:hiddify/features/one_tap/mit_updates.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MitUpdatesPage extends ConsumerStatefulWidget {
  const MitUpdatesPage({super.key});
  @override
  ConsumerState<MitUpdatesPage> createState() => _MitUpdatesPageState();
}
class _MitUpdatesPageState extends ConsumerState<MitUpdatesPage> {
  CancelToken? token;
  MitUpdateCandidate? candidate;
  bool busy = false, ready = false, permission = false;
  double progress = 0;
  String? message;
  @override
  void dispose() { token?.cancel(); super.dispose(); }
  Future<void> check() async {
    setState(() { busy = true; ready = false; permission = false; candidate = null; message = null; });
    final request = CancelToken(); token = request;
    try {
      final update = await ref.read(mitUpdateServiceProvider).check(request);
      if (mounted) setState(() { candidate = update; message = update == null ? 'Обновлений не найдено.' : null; });
    } catch (_) { if (mounted) setState(() => message = request.isCancelled ? 'Проверка отменена.' : 'Не удалось проверить обновления. Повторите позже.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> download() async {
    final update = candidate; if (update == null || busy) return;
    final request = CancelToken(); token = request;
    setState(() { busy = true; progress = 0; ready = false; message = 'Скачивание APK…'; });
    try {
      final platform = ref.read(mitUpdatePlatformProvider);
      final directory = await platform.directory();
      await ref.read(mitUpdateServiceProvider).download(update, directory, request, (received, total) {
        if (mounted) setState(() => progress = received / total);
      });
      if (!mounted || request.isCancelled) return;
      setState(() => message = 'Проверка файла и подписи…');
      await platform.verify(update);
      if (mounted && !request.isCancelled) setState(() { ready = true; message = 'Файл и подпись проверены. Можно обновить приложение.'; });
    } catch (_) {
      if (mounted) setState(() => message = request.isCancelled ? 'Скачивание отменено.' : 'Обновление не прошло проверку или не скачалось. Установка заблокирована.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> install() async {
    final update = candidate; if (update == null || !ready || busy) return;
    setState(() { busy = true; message = null; });
    try {
      final result = await ref.read(mitUpdatePlatformProvider).install(update);
      if (mounted) setState(() {
        permission = result == 'permission_required';
        message = permission ? 'Разрешите установку обновлений для Mit’s VPN в Android, затем нажмите «Установить» снова.'
          : result == 'launched' ? 'Подтвердите обновление в окне Android.' : 'Не удалось открыть установку.';
      });
    } catch (_) { if (mounted) setState(() { ready = false; message = 'Обновление не прошло проверку. Установка заблокирована.'; }); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => MitPage(title: 'Обновления', child: ListView(padding: const EdgeInsets.all(24), children: [
    const Text('Установлена ${MitRelease.label} · ${MitRelease.buildName} (${MitRelease.buildNumber})'),
    const SizedBox(height: 16),
    const Text('Проверка запускается по нажатию. Обновления — из релизов Mit’s VPN. Установка поверх сохраняет данные при совместимой подписи и требует подтверждения Android.'),
    const SizedBox(height: 16),
    FilledButton(onPressed: busy ? null : check, child: const Text('Проверить обновления')),
    if (candidate case final update?) ...[
      const SizedBox(height: 16), Text('Доступна ${update.version}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(update.notes),
      const SizedBox(height: 8),
      if (!ready) OutlinedButton(onPressed: busy ? null : download, child: const Text('Скачать обновление')),
      if (ready) FilledButton(onPressed: busy ? null : install, child: const Text('Установить')),
    ],
    if (busy) ...[const SizedBox(height: 12), LinearProgressIndicator(value: progress > 0 ? progress : null),
      TextButton(onPressed: () => token?.cancel(), child: const Text('Отменить'))],
    if (permission) TextButton(onPressed: busy ? null : () async {
      try { await ref.read(mitUpdatePlatformProvider).openPermission(); }
      catch (_) { if (mounted) setState(() => message = 'Откройте разрешение установки приложений вручную в Android.'); }
    }, child: const Text('Разрешить обновления в Android')),
    if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
  ]));
}
