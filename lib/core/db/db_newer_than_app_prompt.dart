import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/uri_utils.dart';

/// Shown on startup, before the app itself, when the saved data was written by
/// a newer version (the user went back to an older release). The app cannot
/// read it, so the user either deletes it or installs the latest version.
/// Completes once the user chose to delete the data.
Future<void> askDeleteDbNewerThanApp(AppLocale locale, Translations t, DbNewerThanAppException error) {
  final deleteChosen = Completer<void>();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: _Prompt(t: t, error: error, onDelete: deleteChosen.complete),
    ),
  );
  return deleteChosen.future;
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.t, required this.error, required this.onDelete});

  final Translations t;
  final DbNewerThanAppException error;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = t.dialogs.dbNewerThanApp;
    return Scaffold(
      body: Center(
        child: AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: Text(strings.title),
          content: Text(strings.msg),
          actions: [
            TextButton(onPressed: () => _confirmDelete(context), child: Text(strings.deleteData)),
            FilledButton(
              onPressed: () => UriUtils.tryLaunch(Uri.parse(Constants.githubLatestReleaseUrl)),
              child: Text(strings.downloadLatest),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final strings = t.dialogs.dbNewerThanApp;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteData),
        content: Text(strings.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.common.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(strings.deleteData)),
        ],
      ),
    );
    if (confirmed ?? false) onDelete();
  }
}
