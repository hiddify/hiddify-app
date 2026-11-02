import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_import_notifier.g.dart';

/// Whether this is an Android TV: the only place a phone can send a link to the app.
@Riverpod(keepAlive: true)
Future<bool> isAndroidTv(Ref ref) async {
  if (!Platform.isAndroid) return false;
  try {
    return await const MethodChannel('com.hiddify.app/platform').invokeMethod<bool>('is_television') ?? false;
  } on PlatformException {
    return false;
  }
}

/// This TV has no address on a local network, so no phone could reach it.
class PhoneImportNoNetwork implements Exception {
  const PhoneImportNoNetwork();
}

class PhoneImportState {
  const PhoneImportState({required this.url, required this.entries, this.locked = false});

  /// The page's address with its secret, for the QR code.
  final Uri url;

  /// What phones sent, oldest first, waiting for the TV user.
  final List<PhoneEntry> entries;

  /// Too many wrong codes were tried: the page answers no one until the sheet is opened again.
  final bool locked;

  PhoneImportState copyWith({List<PhoneEntry>? entries, bool? locked}) =>
      PhoneImportState(url: url, entries: entries ?? this.entries, locked: locked ?? this.locked);
}

/// The page a phone sends a link to, served while something watches this: the add profile sheet
/// on Android TV. It closes with the sheet, so each opening has a new address and secret.
@riverpod
class PhoneImport extends _$PhoneImport {
  PhoneImportServer? _server;

  @override
  Future<PhoneImportState> build() async {
    final lanIp = await ref
        .read(hiddifyCoreServiceProvider)
        .getLANIP()
        .run()
        .timeout(const Duration(seconds: 10), onTimeout: () => throw const PhoneImportNoNetwork());
    final address = lanIp.fold((_) => null, (r) => InternetAddress.tryParse(r.ip));
    // the core answers 127.0.0.1 when this device has no local network
    if (address == null || address.isLoopback || !isLocalNetwork(address)) throw const PhoneImportNoNetwork();

    final t = ref.read(translationsProvider).requireValue;
    final page = t.pages.profiles.fromPhone.page;
    final lang = t.$meta.locale.languageCode;
    final steps = page.steps;
    final server = await PhoneImportServer.start(address, (
      lang: lang,
      rtl: const {'ar', 'fa', 'he', 'ur'}.contains(lang),
      title: page.title,
      intro: page.intro,
      network: (title: steps.network.title, body: steps.network.body),
      copy: (title: steps.copy.title, body: steps.copy.body),
      paste: (title: steps.paste.title, body: steps.paste.body),
      confirm: (title: steps.confirm.title, body: steps.confirm.body),
      label: page.label,
      hint: page.hint,
      send: page.send,
      sentTitle: page.sentTitle,
      sent: page.sent,
      empty: page.empty,
      footer: page.footer,
    ));
    _server = server;
    final entries = server.entries.listen((entry) {
      final current = state.valueOrNull;
      if (current != null) state = AsyncData(current.copyWith(entries: [...current.entries, entry]));
    });
    unawaited(
      server.whenLocked.then((_) {
        final current = state.valueOrNull;
        if (current != null) state = AsyncData(current.copyWith(locked: true));
      }),
    );
    ref.onDispose(() {
      unawaited(entries.cancel());
      unawaited(server.close());
    });
    return PhoneImportState(url: server.url, entries: const []);
  }

  /// [entry] was imported or discarded on the TV.
  void handled(PhoneEntry entry) {
    final current = state.valueOrNull;
    if (current == null) return;
    _server?.handled();
    state = AsyncData(current.copyWith(entries: current.entries.where((e) => e != entry).toList()));
  }
}
