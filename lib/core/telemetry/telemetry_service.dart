import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:hiddify/core/telemetry/telemetry_config.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Minimal telemetry service for the panel backend.
///
/// Sends an install ping on first launch and a throttled heartbeat on
/// subsequent launches.  All calls are fire-and-forget: network or
/// server errors are silently caught so the app never crashes because of
/// telemetry.
class TelemetryService {
  TelemetryService._();

  static final _log = Loggy<TelemetryService>('TelemetryService');

  /// Entry point – call once after Flutter binding and SharedPreferences are
  /// ready.  Safe to call on any platform; on non-Android it is a no-op.
  static Future<void> initAndSend(SharedPreferences prefs) async {
    if (!TelemetryConfig.isEnabled) {
      _log.debug('telemetry disabled (PANEL_API_BASE_URL is empty)');
      return;
    }

    // Phase-1 targets Android only; skip silently on other platforms so
    // Windows / Linux / macOS builds stay unaffected.
    if (!Platform.isAndroid) {
      _log.debug('telemetry skipped on ${Platform.operatingSystem}');
      return;
    }

    try {
      await _run(prefs);
    } catch (e, st) {
      // Belt-and-suspenders: nothing from telemetry should ever propagate.
      _log.warning('telemetry failed', e, st);
    }
  }

  /// Link a Pasarguard username to this device's installId.
  ///
  /// Returns `true` on success (2xx), `false` on any failure.
  /// Never throws.
  static Future<bool> linkUser(
    SharedPreferences prefs,
    String pasarguardUsername,
  ) async {
    if (!TelemetryConfig.isEnabled) return false;

    try {
      final installId = _getOrCreateInstallId(prefs);
      final url = Uri.parse(
        '${TelemetryConfig.panelBaseUrl}/telemetry/link-user',
      );
      final body = <String, dynamic>{
        'installId': installId,
        'pasarguardUsername': pasarguardUsername,
      };

      _log.debug('linking user to $url');
      final ok = await _post(url, body);
      if (ok) {
        await prefs.setString(
          TelemetryConfig.linkedUsernameKey,
          pasarguardUsername,
        );
      }
      return ok;
    } catch (e, st) {
      _log.warning('linkUser failed', e, st);
      return false;
    }
  }

  /// Returns the previously linked username, or `null` if not yet linked.
  static String? getLinkedUsername(SharedPreferences prefs) {
    final value = prefs.getString(TelemetryConfig.linkedUsernameKey);
    return (value != null && value.isNotEmpty) ? value : null;
  }

  // ── private implementation ────────────────────────────────────────────

  static Future<void> _run(SharedPreferences prefs) async {
    final isFirstRun = !prefs.containsKey(TelemetryConfig.installIdKey);

    // 1) Resolve or generate install ID
    final installId = _getOrCreateInstallId(prefs);

    // 2) Collect metadata
    final metadata = await _collectMetadata();

    if (isFirstRun) {
      await _sendInstall(installId, metadata);
    } else {
      await _maybeSendHeartbeat(installId, metadata, prefs);
    }
  }

  /// Returns the persisted install ID or generates + saves a new UUID v4.
  static String _getOrCreateInstallId(SharedPreferences prefs) {
    final existing = prefs.getString(TelemetryConfig.installIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newId = const Uuid().v4();
    // Fire-and-forget; SharedPreferences.setString is async but we don't
    // need to await – the value is already in memory for the current session.
    prefs.setString(TelemetryConfig.installIdKey, newId);
    _log.info('generated new install id');
    return newId;
  }

  /// POST /telemetry/install
  static Future<void> _sendInstall(
    String installId,
    _DeviceMetadata meta,
  ) async {
    final url = Uri.parse(
      '${TelemetryConfig.panelBaseUrl}/telemetry/install',
    );
    final body = <String, dynamic>{
      'installId': installId,
      'platform': 'ANDROID',
      'appVersion': meta.appVersion,
      if (meta.deviceModel != null) 'deviceModel': meta.deviceModel,
      if (meta.osVersion != null) 'osVersion': meta.osVersion,
      if (meta.locale != null) 'locale': meta.locale,
    };

    _log.debug('sending install ping to $url');
    await _post(url, body);
  }

  /// POST /telemetry/heartbeat (throttled to once per 6 h).
  static Future<void> _maybeSendHeartbeat(
    String installId,
    _DeviceMetadata meta,
    SharedPreferences prefs,
  ) async {
    final lastMs = prefs.getInt(TelemetryConfig.lastHeartbeatKey) ?? 0;
    final lastHeartbeat = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final elapsed = DateTime.now().difference(lastHeartbeat);

    if (elapsed < TelemetryConfig.heartbeatInterval) {
      _log.debug(
        'heartbeat throttled (${elapsed.inMinutes} min since last)',
      );
      return;
    }

    final url = Uri.parse(
      '${TelemetryConfig.panelBaseUrl}/telemetry/heartbeat',
    );
    final body = <String, dynamic>{
      'installId': installId,
      if (meta.appVersion.isNotEmpty) 'appVersion': meta.appVersion,
      if (meta.deviceModel != null) 'deviceModel': meta.deviceModel,
      if (meta.osVersion != null) 'osVersion': meta.osVersion,
    };

    _log.debug('sending heartbeat to $url');
    final ok = await _post(url, body);
    if (ok) {
      await prefs.setInt(
        TelemetryConfig.lastHeartbeatKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Fire a POST request.  Returns `true` on 2xx, `false` otherwise.
  /// Never throws.
  static Future<bool> _post(Uri url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(TelemetryConfig.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.debug('telemetry POST $url → ${response.statusCode}');
        return true;
      }
      _log.warning(
        'telemetry POST $url → ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e) {
      _log.warning('telemetry POST $url failed: $e');
      return false;
    }
  }

  /// Gather device / app metadata.  Never throws.
  static Future<_DeviceMetadata> _collectMetadata() async {
    String appVersion = '';
    String? deviceModel;
    String? osVersion;
    String? locale;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        deviceModel = '${android.manufacturer} ${android.model}';
        osVersion = 'Android ${android.version.release} '
            '(SDK ${android.version.sdkInt})';
      }
    } catch (_) {}

    try {
      locale = PlatformDispatcher.instance.locale.toLanguageTag();
    } catch (_) {}

    return _DeviceMetadata(
      appVersion: appVersion,
      deviceModel: deviceModel,
      osVersion: osVersion,
      locale: locale,
    );
  }
}

/// Simple DTO for device metadata.
class _DeviceMetadata {
  const _DeviceMetadata({
    required this.appVersion,
    this.deviceModel,
    this.osVersion,
    this.locale,
  });

  final String appVersion;
  final String? deviceModel;
  final String? osVersion;
  final String? locale;
}
