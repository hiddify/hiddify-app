import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

part 'core_settings_notifier.freezed.dart';
part 'core_settings_notifier.g.dart';

@freezed
class CoreSettings with _$CoreSettings {
  const factory CoreSettings({
    @Default("127.0.0.1:8086") String bindAddress,
    @Default("1.1.1.1") String dnsAddress,
    @Default(false) bool verbose,
    @Default(false) bool enableGool, // Warp in Warp
    @Default(false) bool enablePsiphon,
    @Default("AT") String psiphonCountry,
    @Default(false) bool enableMasque,
    @Default(false) bool masqueAutoFallback,
    @Default(false) bool masquePreferred,
    @Default(false) bool enableMasqueNoize,
    @Default("medium") String masqueNoizePreset,
    @Default("") String licenseKey,
    @Default("") String customEndpoint,
    @Default("") String proxyAddress,
    @Default(false) bool enableScan,
    @Default(1000) int scanRtt,
  }) = _CoreSettings;

  factory CoreSettings.fromJson(Map<String, dynamic> json) => _$CoreSettingsFromJson(json);
}

@riverpod
class CoreSettingsNotifier extends _$CoreSettingsNotifier {
  static const _key = 'core_settings_v1';

  @override
  CoreSettings build() {
    _load();
    return const CoreSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        state = CoreSettings.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        // ignore error, use default
      }
    }
  }

  Future<void> _save(CoreSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
    state = settings;
  }

  void updateBindAddress(String val) => _save(state.copyWith(bindAddress: val));
  void updateDnsAddress(String val) => _save(state.copyWith(dnsAddress: val));
  void toggleVerbose(bool val) => _save(state.copyWith(verbose: val));
  
  void toggleGool(bool val) => _save(state.copyWith(enableGool: val, enablePsiphon: false, enableMasque: false));
  
  void togglePsiphon(bool val) => _save(state.copyWith(enablePsiphon: val, enableGool: false, enableMasque: false));
  void updatePsiphonCountry(String val) => _save(state.copyWith(psiphonCountry: val));
  
  void toggleMasque(bool val) => _save(state.copyWith(enableMasque: val, enableGool: false, enablePsiphon: false));
  void toggleMasqueAutoFallback(bool val) => _save(state.copyWith(masqueAutoFallback: val));
  void toggleMasquePreferred(bool val) => _save(state.copyWith(masquePreferred: val));
  void toggleMasqueNoize(bool val) => _save(state.copyWith(enableMasqueNoize: val));
  void updateMasqueNoizePreset(String val) => _save(state.copyWith(masqueNoizePreset: val));

  void updateLicenseKey(String val) => _save(state.copyWith(licenseKey: val));
  void updateCustomEndpoint(String val) => _save(state.copyWith(customEndpoint: val));
  void updateProxyAddress(String val) => _save(state.copyWith(proxyAddress: val));
  void toggleScan(bool val) => _save(state.copyWith(enableScan: val));
  void updateScanRtt(int val) => _save(state.copyWith(scanRtt: val));
}
