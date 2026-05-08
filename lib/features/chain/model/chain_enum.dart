import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

// UI helper
enum ChainType {
  extraSecurity,
  unblocker;

  String present(Translations t) => switch (this) {
    extraSecurity => t.pages.settings.chain.levels.extraSecurity.title,
    unblocker => t.pages.settings.chain.levels.unblocker.title,
  };

  bool isDisable(ChainStatus status) => name != status.name;
  bool isEnable(ChainStatus status) => name == status.name;

  bool isUnblocker() => this == unblocker;
  bool isNotUnblocker() => this != unblocker;
  bool isExtraSecurity() => this == extraSecurity;
  bool isNotExtraSecurity() => this != extraSecurity;
}

// UI helper
enum ChainTimelineLevel {
  app,
  extraSecurity,
  mainProfile,
  unblocker,
  filtering;

  ({String title, String message}) present(Translations t) => switch (this) {
    app => (title: t.pages.settings.chain.levels.app.title, message: t.pages.settings.chain.levels.app.msg),
    extraSecurity => (
      title: t.pages.settings.chain.levels.extraSecurity.title,
      message: t.pages.settings.chain.levels.extraSecurity.msg,
    ),
    mainProfile => (title: t.pages.settings.chain.levels.mainProfile.title, message: ''),
    ChainTimelineLevel.unblocker => (
      title: t.pages.settings.chain.levels.unblocker.title,
      message: t.pages.settings.chain.levels.unblocker.msg,
    ),
    ChainTimelineLevel.filtering => (
      title: t.pages.settings.chain.levels.filtering.title,
      message: t.pages.settings.chain.levels.filtering.msg,
    ),
  };

  IconData icon() => switch (this) {
    ChainTimelineLevel.app => ChainConst.iconByPlatform(),
    ChainTimelineLevel.extraSecurity => Icons.security_rounded,
    ChainTimelineLevel.mainProfile => Icons.lan_rounded,
    ChainTimelineLevel.unblocker => Icons.lock_open_rounded,
    ChainTimelineLevel.filtering => Icons.wifi_rounded,
  };

  bool isApp() => this == app;
  bool isExtraSecurity() => this == extraSecurity;
  bool isMainProfile() => this == mainProfile;
  bool isUnblocker() => this == unblocker;
  bool isFiltering() => this == filtering;
}
