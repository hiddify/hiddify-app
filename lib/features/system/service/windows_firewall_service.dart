import 'dart:async';
import 'dart:io';

import 'package:hiddify/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WindowsFirewallService {
  WindowsFirewallService._();

  static final instance = WindowsFirewallService._();

  static const _ruleName = 'Hiddify VPN';
  static const _ruleDescription = 'Hiddify Network Security Rules';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!Platform.isWindows) return;
    if (_isInitialized) return;

    _isInitialized = true;
    Logger.security.info('Windows Firewall Service initialized');
  }

  Future<bool> enableFirewall() async {
    if (!Platform.isWindows) return false;

    try {
      final result = await Process.run('netsh', [
        'advfirewall',
        'set',
        'allprofiles',
        'state',
        'on',
      ], runInShell: true);

      if (result.exitCode == 0) {
        Logger.security.info('Windows Firewall enabled');
        return true;
      } else {
        Logger.security.error('Failed to enable firewall: ${result.stderr}');
        return false;
      }
    } catch (e) {
      Logger.security.error('Error enabling firewall: $e');
      return false;
    }
  }

  Future<bool> disableFirewall() async {
    if (!Platform.isWindows) return false;

    try {
      final result = await Process.run('netsh', [
        'advfirewall',
        'set',
        'allprofiles',
        'state',
        'off',
      ], runInShell: true);

      if (result.exitCode == 0) {
        Logger.security.info('Windows Firewall disabled');
        return true;
      } else {
        Logger.security.error('Failed to disable firewall: ${result.stderr}');
        return false;
      }
    } catch (e) {
      Logger.security.error('Error disabling firewall: $e');
      return false;
    }
  }

  Future<bool> addVpnRules({
    required int vpnPort,
    required String vpnExecutablePath,
  }) async {
    if (!Platform.isWindows) return false;

    try {
      await _addFirewallRule(
        name: '$_ruleName Inbound',
        direction: 'in',
        action: 'allow',
        program: vpnExecutablePath,
        description: '$_ruleDescription - Inbound VPN traffic',
      );
      await _addFirewallRule(
        name: '$_ruleName Outbound',
        direction: 'out',
        action: 'allow',
        program: vpnExecutablePath,
        description: '$_ruleDescription - Outbound VPN traffic',
      );
      await _addFirewallRule(
        name: '$_ruleName Local Proxy',
        direction: 'in',
        action: 'allow',
        localPort: '2334,2335',
        protocol: 'tcp',
        description: '$_ruleDescription - Local proxy ports',
      );

      Logger.security.info('VPN firewall rules added');
      return true;
    } catch (e) {
      Logger.security.error('Error adding VPN rules: $e');
      return false;
    }
  }

  Future<bool> removeVpnRules() async {
    if (!Platform.isWindows) return false;

    try {
      await _deleteFirewallRule(name: '$_ruleName Inbound');
      await _deleteFirewallRule(name: '$_ruleName Outbound');
      await _deleteFirewallRule(name: '$_ruleName Local Proxy');

      Logger.security.info('VPN firewall rules removed');
      return true;
    } catch (e) {
      Logger.security.error('Error removing VPN rules: $e');
      return false;
    }
  }

  Future<bool> blockTcpPorts(List<String> ports) async {
    if (!Platform.isWindows) return false;
    if (ports.isEmpty) return true;

    try {
      await _addFirewallRule(
        name: '$_ruleName Block TCP Ports',
        direction: 'out',
        action: 'block',
        remotePort: ports.join(','),
        protocol: 'tcp',
        description: '$_ruleDescription - Blocked TCP ports',
      );

      Logger.security.info('Blocked TCP ports: ${ports.join(',')}');
      return true;
    } catch (e) {
      Logger.security.error('Error blocking TCP ports: $e');
      return false;
    }
  }

  Future<bool> blockUdpPorts(List<String> ports) async {
    if (!Platform.isWindows) return false;
    if (ports.isEmpty) return true;

    try {
      await _addFirewallRule(
        name: '$_ruleName Block UDP Ports',
        direction: 'out',
        action: 'block',
        remotePort: ports.join(','),
        protocol: 'udp',
        description: '$_ruleDescription - Blocked UDP ports',
      );

      Logger.security.info('Blocked UDP ports: ${ports.join(',')}');
      return true;
    } catch (e) {
      Logger.security.error('Error blocking UDP ports: $e');
      return false;
    }
  }

  Future<bool> enableKillSwitch({required String vpnInterfaceName}) async {
    if (!Platform.isWindows) return false;

    try {
      await _addFirewallRule(
        name: '$_ruleName Kill Switch',
        direction: 'out',
        action: 'block',
        description: '$_ruleDescription - Kill switch to prevent leaks',
      );
      await _addFirewallRule(
        name: '$_ruleName VPN Interface',
        direction: 'out',
        action: 'allow',
        interfaceType: vpnInterfaceName,
        description: '$_ruleDescription - Allow VPN interface',
      );
      await _addFirewallRule(
        name: '$_ruleName Loopback',
        direction: 'out',
        action: 'allow',
        remoteAddress: '127.0.0.1,::1',
        description: '$_ruleDescription - Allow loopback traffic',
      );
      await _addFirewallRule(
        name: '$_ruleName LAN',
        direction: 'out',
        action: 'allow',
        remoteAddress: '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
        description: '$_ruleDescription - Allow LAN traffic',
      );

      Logger.security.info('Kill switch enabled');
      return true;
    } catch (e) {
      Logger.security.error('Error enabling kill switch: $e');
      return false;
    }
  }

  Future<bool> disableKillSwitch() async {
    if (!Platform.isWindows) return false;

    try {
      await _deleteFirewallRule(name: '$_ruleName Kill Switch');
      await _deleteFirewallRule(name: '$_ruleName VPN Interface');
      await _deleteFirewallRule(name: '$_ruleName Loopback');
      await _deleteFirewallRule(name: '$_ruleName LAN');

      Logger.security.info('Kill switch disabled');
      return true;
    } catch (e) {
      Logger.security.error('Error disabling kill switch: $e');
      return false;
    }
  }

  Future<bool> blockIncomingConnections() async {
    if (!Platform.isWindows) return false;

    try {
      final result = await Process.run('netsh', [
        'advfirewall',
        'set',
        'allprofiles',
        'firewallpolicy',
        'blockinbound,allowoutbound',
      ], runInShell: true);

      if (result.exitCode == 0) {
        Logger.security.info('Incoming connections blocked');
        return true;
      }
      return false;
    } catch (e) {
      Logger.security.error('Error blocking incoming connections: $e');
      return false;
    }
  }

  
  Future<Map<String, dynamic>> getFirewallStatus() async {
    if (!Platform.isWindows) {
      return {'enabled': false, 'platform': 'unsupported'};
    }

    try {
      final result = await Process.run('netsh', [
        'advfirewall',
        'show',
        'allprofiles',
        'state',
      ], runInShell: true);

      final output = result.stdout as String;
      final isEnabled = output.contains('ON') || output.contains('رو');

      return {'enabled': isEnabled, 'platform': 'windows', 'profiles': output};
    } catch (e) {
      return {'enabled': false, 'platform': 'windows', 'error': e.toString()};
    }
  }

  
  Future<List<String>> listHiddifyRules() async {
    if (!Platform.isWindows) return [];

    try {
      final result = await Process.run('netsh', [
        'advfirewall',
        'firewall',
        'show',
        'rule',
        'name=all',
      ], runInShell: true);

      final output = result.stdout as String;
      final lines = output.split('\n');
      final hiddifyRules = <String>[];

      for (final line in lines) {
        if (line.contains(_ruleName)) {
          hiddifyRules.add(line.trim());
        }
      }

      return hiddifyRules;
    } catch (e) {
      Logger.security.error('Error listing rules: $e');
      return [];
    }
  }

  
  Future<void> cleanup() async {
    if (!Platform.isWindows) return;

    try {
      final rules = await listHiddifyRules();
      for (final rule in rules) {
        if (rule.contains(_ruleName)) {
          await _deleteFirewallRule(name: rule);
        }
      }
      await _deleteFirewallRule(name: '$_ruleName Inbound');
      await _deleteFirewallRule(name: '$_ruleName Outbound');
      await _deleteFirewallRule(name: '$_ruleName Local Proxy');
      await _deleteFirewallRule(name: '$_ruleName Block TCP Ports');
      await _deleteFirewallRule(name: '$_ruleName Block UDP Ports');
      await _deleteFirewallRule(name: '$_ruleName Kill Switch');
      await _deleteFirewallRule(name: '$_ruleName VPN Interface');
      await _deleteFirewallRule(name: '$_ruleName Loopback');
      await _deleteFirewallRule(name: '$_ruleName LAN');

      Logger.security.info('Firewall rules cleaned up');
    } catch (e) {
      Logger.security.error('Error cleaning up firewall rules: $e');
    }
  }

  Future<bool> _addFirewallRule({
    required String name,
    required String direction,
    required String action,
    String? program,
    String? localPort,
    String? remotePort,
    String? localAddress,
    String? remoteAddress,
    String? protocol,
    String? interfaceType,
    String? description,
  }) async {
    final args = [
      'advfirewall',
      'firewall',
      'add',
      'rule',
      'name=$name',
      'dir=$direction',
      'action=$action',
    ];

    if (program != null) args.add('program=$program');
    if (localPort != null) args.add('localport=$localPort');
    if (remotePort != null) args.add('remoteport=$remotePort');
    if (localAddress != null) args.add('localip=$localAddress');
    if (remoteAddress != null) args.add('remoteip=$remoteAddress');
    if (protocol != null) args.add('protocol=$protocol');
    if (interfaceType != null) args.add('interfacetype=$interfaceType');
    if (description != null) args.add('description=$description');

    final result = await Process.run('netsh', args, runInShell: true);
    return result.exitCode == 0;
  }

  Future<bool> _deleteFirewallRule({required String name}) async {
    final result = await Process.run('netsh', [
      'advfirewall',
      'firewall',
      'delete',
      'rule',
      'name=$name',
    ], runInShell: true);
    return result.exitCode == 0;
  }
}


final windowsFirewallServiceProvider = Provider<WindowsFirewallService>(
  (ref) => WindowsFirewallService.instance,
);


final firewallStatusProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(windowsFirewallServiceProvider);
  return service.getFirewallStatus();
});
