import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone_to_country/timezone_to_country.dart';

class IntroPage extends HookConsumerWidget with PresLogger {
  const IntroPage({super.key});

  static bool locationInfoLoaded = false;

  // for focus management
  KeyEventResult _handleKeyEvent(KeyEvent event, String key) {
    if (KeyboardConst.select.contains(event.logicalKey) && event is KeyUpEvent) {
      UriUtils.tryLaunch(Uri.parse(IntroConst.url[key]!));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final isStarting = useState(false);

    if (!locationInfoLoaded) {
      autoSelectRegion(ref).then((value) => loggy.debug("Auto Region selection finished!"));
      locationInfoLoaded = true;
    }

    // for focus management
    final focusStates = <String, ValueNotifier<bool>>{
      IntroConst.termsAndConditionsKey: useState<bool>(false),
      IntroConst.githubKey: useState<bool>(false),
      IntroConst.licenseKey: useState<bool>(false),
    };
    final focusNodes = <String, FocusNode>{
      IntroConst.termsAndConditionsKey: useFocusNode(),
      IntroConst.githubKey: useFocusNode(),
      IntroConst.licenseKey: useFocusNode(),
    };
    useEffect(() {
      for (final entry in focusNodes.entries) {
        entry.value.addListener(() => focusStates[entry.key]!.value = entry.value.hasPrimaryFocus);
      }
      return null;
    }, []);

    return Scaffold(
      body: Center(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth > IntroConst.maxwidth
                          ? IntroConst.maxwidth
                          : constraints.maxWidth;
                      final size = width * 0.4;
                      return Assets.images.logo.svg(width: size, height: size);
                    },
                  ),
                  const Gap(16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      t.intro.banner,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(24),
                  const LocalePrefTile(),
                  const RegionPrefTile(),
                  const EnableAnalyticsPrefTile(),
                  const Gap(24),
                  Focus(
                    focusNode: focusNodes[IntroConst.termsAndConditionsKey],
                    onKeyEvent: (node, event) => _handleKeyEvent(event, IntroConst.termsAndConditionsKey),
                    child: Text.rich(
                      t.intro.termsAndPolicyCaution(
                        tap: (text) => TextSpan(
                          text: text,
                          style: TextStyle(
                            color: focusStates[IntroConst.termsAndConditionsKey]!.value ? Colors.green : Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl));
                            },
                        ),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Gap(8),
                  Focus(
                    focusNode: focusNodes[IntroConst.githubKey],
                    onKeyEvent: (node, event) => _handleKeyEvent(event, IntroConst.githubKey),
                    child: Text.rich(
                      t.intro.info(
                        tap_source: (text) => TextSpan(
                          text: text,
                          style: TextStyle(
                            color: focusStates[IntroConst.githubKey]!.value ? Colors.green : Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await UriUtils.tryLaunch(Uri.parse(Constants.githubUrl));
                            },
                        ),
                        tap_license: (text) => TextSpan(
                          text: text,
                          style: TextStyle(
                            color: focusStates[IntroConst.githubKey]!.value ? Colors.green : Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await UriUtils.tryLaunch(Uri.parse(Constants.licenseUrl));
                            },
                        ),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  // only for managing license node focus
                  Focus(
                    focusNode: focusNodes[IntroConst.licenseKey],
                    onKeyEvent: (node, event) => _handleKeyEvent(event, IntroConst.licenseKey),
                    child: const Gap(88),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: isStarting.value
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
            : const Icon(Icons.rocket_launch),
        label: Text(t.common.start, style: theme.textTheme.titleMedium),
        onPressed: () async {
          if (isStarting.value) return;
          isStarting.value = true;
          if (!ref.read(analyticsControllerProvider).requireValue) {
            loggy.info("disabling analytics per user request");
            try {
              await ref.read(analyticsControllerProvider.notifier).disableAnalytics();
            } catch (error, stackTrace) {
              loggy.error("could not disable analytics", error, stackTrace);
            }
          }
          await ref.read(Preferences.introCompleted.notifier).update(true);
        },
      ),
    );
  }

  Future<void> autoSelectRegion(WidgetRef ref) async {
    try {
      final countryCode = await TimeZoneToCountry.getLocalCountryCode();
      final regionLocale = _getRegionLocale(countryCode);
      loggy.debug('Timezone Region: ${regionLocale.region} Locale: ${regionLocale.locale}');
      await ref.read(ConfigOptions.region.notifier).update(regionLocale.region);
      await ref.watch(ConfigOptions.directDnsAddress.notifier).reset();
      await ref.read(localePreferencesProvider.notifier).changeLocale(regionLocale.locale);
      return;
    } catch (e) {
      loggy.warning('Could not get the local country code based on timezone', e);
    }

    try {
      final DioHttpClient client = DioHttpClient(
        timeout: const Duration(seconds: 2),
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0",
        debug: true,
      );
      final response = await client.get<Map<String, dynamic>>('https://api.ip.sb/geoip/');

      if (response.statusCode == 200) {
        final jsonData = response.data!;
        final regionLocale = _getRegionLocale(jsonData['country_code']?.toString() ?? "");

        loggy.debug('Region: ${regionLocale.region} Locale: ${regionLocale.locale}');
        await ref.read(ConfigOptions.region.notifier).update(regionLocale.region);
        await ref.read(localePreferencesProvider.notifier).changeLocale(regionLocale.locale);
      } else {
        loggy.warning('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      loggy.warning('Could not get the local country code from ip');
    }
  }

  RegionLocale _getRegionLocale(String country) {
    switch (country.toUpperCase()) {
      case "IR":
        return RegionLocale(Region.ir, AppLocale.fa);
      case "CN":
        return RegionLocale(Region.cn, AppLocale.zhCn);
      case "RU":
        return RegionLocale(Region.ru, AppLocale.ru);
      case "AF":
        return RegionLocale(Region.af, AppLocale.fa);
      case "BR":
        return RegionLocale(Region.other, AppLocale.ptBr);
      case "TR":
        return RegionLocale(Region.other, AppLocale.tr);
      default:
        return RegionLocale(Region.other, AppLocale.en);
    }
  }
}

class RegionLocale {
  final Region region;
  final AppLocale locale;

  RegionLocale(this.region, this.locale);
}
