import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';

enum ProfilesSort {
  lastUpdate,
  name;

  String present(Translations t) {
    return switch (this) {
      lastUpdate => t.profile.sortBy.lastUpdate,
      name => t.profile.sortBy.name,
    };
  }

  IconData get icon => switch (this) {
        lastUpdate => FluentIcons.history_24_regular,
        name => FluentIcons.text_sort_ascending_24_regular,
      };
}

enum SortMode { ascending, descending }
