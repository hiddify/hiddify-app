import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pbenum.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

import 'fixtures/awg_fixture.dart';

void main() {
  test('native core validates AWG client exports without downgrading or losing obfuscation', () async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      markTestSkipped('Native AWG contract test uses a desktop host');
      return;
    }
    final library = Platform.isWindows ? 'hiddify-core/hiddify-core.dll'
        : Platform.isMacOS ? 'hiddify-core/hiddify-core.dylib' : 'hiddify-core/hiddify-core.so';
    if (!File(library).existsSync()) {
      expect(Platform.environment['MIT_REQUIRE_AWG_NATIVE_TESTS'], isNot('true'), reason: 'Native AWG validation is mandatory in Android CI');
      markTestSkipped('Prepare the native core to run the AWG contract test');
      return;
    }
    final original = Directory.current;
    final tmp = await Directory.systemTemp.createTemp('mits-awg-validation-');
    final core = CoreInterfaceDesktop(port: 17179);
    addTearDown(() async {
      try { CoreInterfaceDesktop.nativeLibrary.closeGrpc(SetupMode.GRPC_NORMAL.value); } catch (_) {}
      Directory.current = original;
      await tmp.delete(recursive: true);
    });
    final setup = await core.setup((baseDir: tmp, workingDir: tmp, tempDir: tmp), false, SetupMode.GRPC_NORMAL.value);
    expect(setup, isEmpty, reason: 'Native test setup must succeed');
    final samples = <String, String>{
      for (final version in [1, 2, 3]) '$version': amneziaTestLink(amneziaTestContainer(awgTestConfig(version: version))),
      'structured export': amneziaTestLink(amneziaStructuredContainer()),
      'empty optional fields': amneziaTestLink(amneziaTestContainer(awgOptionalEmptyConfig())),
      'vpn file': decodeVpnProfileBytes(utf8.encode(jsonEncode(amneziaStructuredContainer()))),
      'Base64 header key and on flags': amneziaTestLink(amneziaTestContainer(awgBase64HeaderConfig())),
      'Amnezia DNS tokens and keepalive range': amneziaTestLink(amneziaTestContainer(awgAmneziaPlaceholderConfig())),
    };
    for (final sample in samples.entries) {
      final version = sample.key;
      final prepared = prepareVpnProfile(sample.value);
      final response = await core.fgClient.parse(ParseRequest(content: prepared.content, debug: false));
      expect(response.responseCode, ResponseCode.OK, reason: 'Native AWG $version: ${response.message}');
      final result = (jsonDecode(response.content)['endpoints'] as List).single as Map;
      expect(result['type'], 'awg', reason: 'Must never silently downgrade to ordinary WireGuard');
      expect(result['private_key'], testWgKey(1));
      final peer = (result['peers'] as List).single as Map;
      expect(peer['preshared_key'], testWgKey(33));
      expect(peer['allowed_ips'], ['0.0.0.0/0', '::/0']);
      expect(peer['persistent_keepalive_interval'], jsonDecode(prepared.content)['endpoints'][0]['peers'][0]['persistent_keepalive_interval']);
      final expected = jsonDecode(prepared.content)['endpoints'][0]['awg'] as Map;
      final actual = result['awg'] as Map;
      for (final field in expected.entries) {
        expect(actual[field.key] ?? (field.value == 0 || field.value == false ? field.value : null), field.value,
          reason: 'AWG $version must preserve ${field.key}');
      }
      final again = await core.fgClient.parse(ParseRequest(content: response.content, debug: false));
      expect(again.responseCode, ResponseCode.OK, reason: 'Saved native profile must remain valid');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
