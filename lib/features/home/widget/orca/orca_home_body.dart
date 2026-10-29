import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'connect_ring.dart';
import 'glass_kit.dart';
import 'orca_background.dart';
import 'orca_strings.dart';

/// Body of the home screen (no Scaffold, no nav bar — Hiddify's shell owns those).
/// Pure UI: all state and callbacks come in from [OrcaHomePage].
class OrcaHomeBody extends StatelessWidget {
  const OrcaHomeBody({
    super.key,
    required this.state,
    required this.onToggle,
    required this.flag,
    required this.serverTitle,
    required this.serverSubtitle,
    required this.pingMs,
    required this.strings,
    this.onOpenServers,
    this.onOpenSettings,
    this.bottomInset = 0,
  });

  final OrcaConnectionState state;
  final VoidCallback? onToggle;
  final Widget flag;
  final String serverTitle; // e.g. "Netherlands · Amsterdam"
  final String serverSubtitle; // "Selected server"
  final int? pingMs;
  final OrcaStrings strings;
  final VoidCallback? onOpenServers;
  final VoidCallback? onOpenSettings;

  /// Space reserved for the floating nav bar.
  final double bottomInset;

  String get _status => switch (state) {
        OrcaConnectionState.disconnected => strings.readyToConnect,
        OrcaConnectionState.connecting => strings.connecting,
        OrcaConnectionState.connected => strings.youAreConnected,
      };

  String get _button => switch (state) {
        OrcaConnectionState.disconnected => strings.secureConnect,
        OrcaConnectionState.connecting => strings.connecting,
        OrcaConnectionState.connected => strings.disconnect,
      };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // The reference layout is visually LTR with Persian text inside.
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          const Positioned.fill(child: OrcaBackground()),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = math.min(box.maxWidth, 600.0);
                final ringSize = math.min(
                  w * 0.80,
                  math.max(200.0, box.maxHeight - 440 - bottomInset),
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 8),
                      child: Column(
                        children: [
                          _Header(onSettings: onOpenSettings),
                          Expanded(
                            child: Center(
                              child: ConnectRing(
                                state: state,
                                statusLabel: _status,
                                size: ringSize,
                              ),
                            ),
                          ),
                          _ConnectButton(
                            label: _button,
                            state: state,
                            onTap: onToggle,
                          ),
                          const SizedBox(height: 14),
                          _ServerCard(
                            flag: flag,
                            title: serverTitle,
                            subtitle: serverSubtitle,
                            pingMs: pingMs,
                            onTap: onOpenServers,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _PingCard(
                                  pingMs: pingMs,
                                  label: strings.ping,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _StatusCard(
                                  state: state,
                                  strings: strings,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({this.onSettings});
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    const title = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      height: 1.1,
      color: Colors.white,
      letterSpacing: 0.2,
    );
    return Row(
      children: [
        Image.asset('assets/images/orca/orca_logo_small.png', width: 62, height: 62),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Orca', style: title),
                  const GradientText('Net', style: title),
                  const Text(' Client', style: title),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Next-Gen Privacy & Proxy Tunnel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  letterSpacing: 0.6,
                  color: OrcaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GlassCard(
          onTap: onSettings,
          radius: 18,
          padding: const EdgeInsets.all(13),
          blur: 16,
          child: const Icon(
            Icons.settings_outlined,
            color: OrcaColors.textPrimary,
            size: 26,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Connect button ─────────────────────────

class _ConnectButton extends StatefulWidget {
  const _ConnectButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final OrcaConnectionState state;
  final VoidCallback? onTap;

  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final connected = widget.state == OrcaConnectionState.connected;
    final gradient = connected
        ? const LinearGradient(colors: [
            Color(0xFF12C26B),
            Color(0xFF0FA3C9),
            Color(0xFF2D6BFF),
          ])
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              OrcaColors.cyan,
              Color(0xFF2A62FF),
              OrcaColors.violet,
              OrcaColors.pink,
            ],
            stops: [0, 0.35, 0.72, 1],
          );

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: OrcaColors.violet.withValues(alpha: 0.55),
                blurRadius: 34,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: OrcaColors.cyan.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(-8, 0),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // glass sheen
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.state == OrcaConnectionState.connecting
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.power_settings_new_rounded,
                          color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Positioned(
                right: 22,
                child: Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 34),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Server card ─────────────────────────

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.pingMs,
    this.onTap,
  });

  final Widget flag;
  final String title;
  final String subtitle;
  final int? pingMs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _FlagBadge(child: flag),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: OrcaColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: OrcaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _PingChip(pingMs: pingMs),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: OrcaColors.textPrimary, size: 28),
        ],
      ),
    );
  }
}

/// Gradient ring around whatever flag widget the caller supplies.
class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [OrcaColors.cyan, OrcaColors.violet],
        ),
        boxShadow: [
          BoxShadow(
            color: OrcaColors.blue.withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipOval(child: FittedBox(fit: BoxFit.cover, child: child)),
    );
  }
}

class _PingChip extends StatelessWidget {
  const _PingChip({required this.pingMs});
  final int? pingMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: OrcaColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: OrcaColors.success.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pingMs == null ? '— ms' : '$pingMs ms',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: OrcaColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Stat cards ─────────────────────────

class _IconOrb extends StatelessWidget {
  const _IconOrb({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: -4),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _PingCard extends StatelessWidget {
  const _PingCard({required this.pingMs, required this.label});
  final int? pingMs;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 90,
                  height: 36,
                  child: CustomPaint(painter: _WavePainter()),
                ),
              ),
            ),
            Row(
              children: [
                const _IconOrb(
                  icon: Icons.wifi_tethering_rounded,
                  color: Color(0xFF9B6BFF),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: OrcaColors.textSecondary,
                      ),
                    ),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: pingMs?.toString() ?? '—',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: ' ms',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]),
                      style: const TextStyle(color: OrcaColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height * 0.85);
    for (double x = 0; x <= size.width; x++) {
      final u = x / size.width;
      final y = size.height * (0.55 - 0.42 * math.sin(u * math.pi * 1.4 - 0.4)) +
          6 * u;
      path.lineTo(x, y.clamp(0, size.height));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Colors.transparent, OrcaColors.blue, OrcaColors.cyan],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.strings});
  final OrcaConnectionState state;
  final OrcaStrings strings;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      OrcaConnectionState.disconnected => (strings.readyToConnect, OrcaColors.cyan),
      OrcaConnectionState.connecting => (strings.connecting, OrcaColors.pink),
      OrcaConnectionState.connected => (strings.connected, OrcaColors.success),
    };
    return GlassCard(
      radius: 24,
      glow: OrcaColors.blue,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _IconOrb(icon: Icons.verified_user_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.status,
                    style: const TextStyle(
                      fontSize: 15,
                      color: OrcaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: OrcaColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

