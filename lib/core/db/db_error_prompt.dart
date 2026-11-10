import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/uri_utils.dart';

/// Shown on startup, before the app itself, when the saved data can not be opened: written by a
/// newer version (the user went back to an older release), or broken, as by a failed migration.
/// The user can wipe it, and the profiles that can still be read are added back; for newer data,
/// installing the latest version is offered first. Completes once the user chose to wipe.
Future<void> askWipeDb(AppLocale locale, Translations t, Object error) {
  final wipeChosen = Completer<void>();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: _Prompt(t: t, error: error, onWipe: wipeChosen.complete),
    ),
  );
  return wipeChosen.future;
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.t, required this.error, required this.onWipe});

  final Translations t;
  final Object error;
  final VoidCallback onWipe;

  bool get _newer => error is DbNewerThanAppException;

  @override
  Widget build(BuildContext context) {
    final newer = t.dialogs.dbNewerThanApp;
    final broken = t.dialogs.dbBroken;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded),
            title: Text(_newer ? newer.title : broken.title),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_newer ? newer.msg : broken.msg),
                  if (!_newer) ...[
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          '$error',
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!_newer)
                TextButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: '$error')),
                  child: Text(broken.copyError),
                ),
              if (_newer)
                TextButton(onPressed: () => _confirmWipe(context), child: Text(newer.deleteData))
              else
                FilledButton(onPressed: () => _confirmWipe(context), child: Text(broken.wipeData)),
              if (_newer)
                FilledButton(
                  onPressed: () => UriUtils.tryLaunch(Uri.parse(Constants.githubLatestReleaseUrl)),
                  child: Text(newer.downloadLatest),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmWipe(BuildContext context) async {
    final label = _newer ? t.dialogs.dbNewerThanApp.deleteData : t.dialogs.dbBroken.wipeData;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(_newer ? t.dialogs.dbNewerThanApp.deleteConfirm : t.dialogs.dbBroken.wipeConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.common.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(label)),
        ],
      ),
    );
    if (confirmed ?? false) onWipe();
  }
}
