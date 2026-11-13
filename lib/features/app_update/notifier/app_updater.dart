import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/app_update/model/install_kind.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_updater.g.dart';

/// How this copy of the app was installed (InstallKind.detect).
@Riverpod(keepAlive: true)
InstallKind installKind(Ref ref) => InstallKind.detect(ref.watch(appInfoProvider).requireValue.release);

/// Where an update stands once the user asked for it.
sealed class AppUpdaterState {
  const AppUpdaterState();
}

class AppUpdaterIdle extends AppUpdaterState {
  const AppUpdaterIdle();
}

/// [progress] from 0 to 1; null while the size is not known yet.
class AppUpdaterDownloading extends AppUpdaterState {
  const AppUpdaterDownloading(this.progress);
  final double? progress;
}

/// The installer runs; on desktop the app quits for it.
class AppUpdaterInstalling extends AppUpdaterState {
  const AppUpdaterInstalling();
}

/// Android asks the user to let this app install apps first; the settings page is open. [file] is
/// the verified download, installed as soon as the user comes back with the permission.
class AppUpdaterNeedsPermission extends AppUpdaterState {
  const AppUpdaterNeedsPermission(this.file);
  final File file;
}

class AppUpdaterFailed extends AppUpdaterState {
  const AppUpdaterFailed(this.error);
  final Object error;
}

/// Downloads the update for this install and starts its installer: the APK for the device, the
/// Windows setup, the AppImage (which takes the running one's place), the Debian package or the
/// macOS disk image. Other installs, and a release without the file, open the release page.
@Riverpod(keepAlive: true)
class AppUpdater extends _$AppUpdater with AppLogger {
  static const _platform = MethodChannel('com.hiddify.app/platform');

  CancelToken? _cancel;
  AppLifecycleListener? _resumeListener;

  @override
  AppUpdaterState build() {
    ref.onDispose(_stopWaitingForPermission);
    return const AppUpdaterIdle();
  }

  /// Updates to [release]; false when this install can not, and the release page should open.
  Future<bool> update(RemoteVersionEntity release) async {
    if (state is AppUpdaterDownloading || state is AppUpdaterInstalling) return true;
    // the APK is already here: only the installer has to start again
    if (state case AppUpdaterNeedsPermission(:final file) when file.existsSync()) {
      await _retryInstall(file);
      return true;
    }
    final kind = ref.read(installKindProvider);
    final abis = kind == InstallKind.androidApk ? await _supportedAbis() : const <String>[];
    final asset = kind.installsItself
        ? kind.assetIn(release, abis: abis, arm64: Abi.current() == Abi.linuxArm64)
        : null;
    if (asset == null) return false;
    try {
      state = const AppUpdaterDownloading(null);
      final file = await _download(asset);
      state = const AppUpdaterInstalling();
      await _install(kind, file);
      return true;
    } catch (error, stackTrace) {
      if (error is DioException && CancelToken.isCancel(error)) {
        state = const AppUpdaterIdle();
        return true;
      }
      loggy.warning("could not update to ${release.version}", error, stackTrace);
      state = AppUpdaterFailed(error);
      return true;
    }
  }

  void cancel() => _cancel?.cancel();

  void reset() {
    _stopWaitingForPermission();
    state = const AppUpdaterIdle();
  }

  Future<void> _retryInstall(File file) async {
    try {
      state = const AppUpdaterInstalling();
      await _install(InstallKind.androidApk, file);
    } catch (error, stackTrace) {
      loggy.warning("could not start the installer", error, stackTrace);
      state = AppUpdaterFailed(error);
    }
  }

  /// Back from the settings page with the permission given, the installer starts by itself.
  void _waitForPermission(File file) {
    _stopWaitingForPermission();
    _resumeListener = AppLifecycleListener(
      onResume: () async {
        if (state is! AppUpdaterNeedsPermission) return _stopWaitingForPermission();
        final allowed = await _platform.invokeMethod<bool>('can_install_apks').catchError((_) => false);
        if (allowed != true || state is! AppUpdaterNeedsPermission) return;
        _stopWaitingForPermission();
        await _retryInstall(file);
      },
    );
  }

  void _stopWaitingForPermission() {
    _resumeListener?.dispose();
    _resumeListener = null;
  }

  Future<File> _download(ReleaseAsset asset) async {
    final digest = asset.digest;
    if (digest == null || digest.length != 71 || !RegExp(r'^sha256:[0-9a-fA-F]{64}$').hasMatch(digest)) {
      throw StateError('${asset.name}: the release has no valid SHA-256 digest; the update was not downloaded.');
    }
    // on Android the cache, which the installer may read (res/xml/update_paths.xml)
    final directory = Directory(p.join((await getTemporaryDirectory()).path, 'updates'));
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, asset.name));
    if (file.existsSync()) {
      // a download the installer did not take yet, e.g. while the user gave the permission
      if (await _matches(file, asset.size, digest)) return file;
      await file.delete();
    }
    _cancel = CancelToken();
    await ref
        .read(httpClientProvider)
        .download(
          asset.url,
          file.path,
          cancelToken: _cancel,
          onReceiveProgress: (received, total) {
            final size = total > 0 ? total : asset.size;
            state = AppUpdaterDownloading(size > 0 ? (received / size).clamp(0, 1) : null);
          },
        );
    final length = await file.length();
    if (asset.size > 0 && length != asset.size) {
      throw Exception("${asset.name}: got $length of ${asset.size} bytes");
    }
    // Stream the artifact so verifying an AppImage/APK does not load it all into memory.
    final actualDigest = await sha256.bind(file.openRead()).first;
    if (_cancel?.cancelError case final cancellation?) throw cancellation;
    if (actualDigest.toString() != digest.substring(7).toLowerCase()) {
      await file.delete();
      throw StateError('${asset.name}: SHA-256 verification failed; the update was not installed.');
    }
    return file;
  }

  static Future<bool> _matches(File file, int size, String digest) async {
    try {
      if (size > 0 && await file.length() != size) return false;
      final actual = await sha256.bind(file.openRead()).first;
      return actual.toString() == digest.substring(7).toLowerCase();
    } on FileSystemException {
      return false;
    }
  }

  Future<void> _install(InstallKind kind, File file) async {
    switch (kind) {
      case InstallKind.androidApk:
        final started = await _platform.invokeMethod<String>('install_apk', file.path);
        if (started == 'store') throw StateError("Google Play installed this copy; it updates it.");
        if (started == 'permission') {
          state = AppUpdaterNeedsPermission(file);
          _waitForPermission(file);
        } else {
          state = const AppUpdaterIdle();
        }
      case InstallKind.windowsSetup:
        // the setup closes the app itself (CloseApplications=force) and installs over it
        await Process.start(file.path, const [], mode: ProcessStartMode.detached);
        await _quit();
      case InstallKind.linuxAppImage:
        final running = Platform.environment['APPIMAGE']!;
        // next to the running AppImage, so taking its place is a rename on one file system
        final next = File('$running.new');
        await file.copy(next.path);
        await Process.run('chmod', ['755', next.path]);
        await next.rename(running);
        await Process.start(running, const [], mode: ProcessStartMode.detached);
        await _quit();
      case InstallKind.linuxDeb:
        await Process.start('xdg-open', [file.path], mode: ProcessStartMode.detached);
        state = const AppUpdaterIdle();
      case InstallKind.macOS:
        await Process.start('open', [file.path], mode: ProcessStartMode.detached);
        state = const AppUpdaterIdle();
      case InstallKind.store || InstallKind.windowsPortable || InstallKind.linuxOther:
        throw StateError("$kind does not install itself");
    }
  }

  Future<List<String>> _supportedAbis() async {
    try {
      return await _platform.invokeListMethod<String>('supported_abis') ?? const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<void> _quit() => ref.read(windowNotifierProvider.notifier).exit();
}
