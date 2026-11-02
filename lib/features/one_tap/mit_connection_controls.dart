import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';

const mitIdle = Color(0xFFF5F7F5);
const mitGreen = Color(0xFF78FF45);
const mitBackground = Color(0xFF030805);
const mitConnectionTransition = Duration(milliseconds: 900);

/// Presentation only: the caller supplies core status and the real action.
class MitConnectionControls extends StatelessWidget {
  const MitConnectionControls({
    super.key,
    required this.status,
    required this.hasProfile,
    required this.hasError,
    required this.importing,
    required this.onPressed,
    this.recoveryLabel,
  });

  final ConnectionStatus? status;
  final bool hasProfile;
  final bool hasError;
  final bool importing;
  final VoidCallback? onPressed;
  final String? recoveryLabel;

  @override
  Widget build(BuildContext context) {
    final failed = hasError || (switch (status) {
      Disconnected(connectionFailure: _?) => true,
      _ => false,
    });
    final (label, action, color) = importing
        ? ('Проверка профиля…', 'Подождите', const Color(0xFFFFCA70))
        : recoveryLabel != null
        ? (recoveryLabel!, 'Отключить', const Color(0xFFFFCA70))
        : failed
        ? ('Не удалось подключиться', hasProfile ? 'Повторить' : 'Добавить профиль', const Color(0xFFFF8E8E))
        : switch (status) {
            Connected() => ('VPN подключён', 'Отключить', mitGreen),
            Connecting() => ('Подключение…', 'Отменить', const Color(0xFFFFCA70)),
            Waiting() => ('Проверяем соединение…', 'Отключить', const Color(0xFFFFCA70)),
            NoAvailableProxies() => ('Нет доступного соединения', 'Отключить', const Color(0xFFFFCA70)),
            HotReloading() => ('Обновление подключения…', 'Отключить', const Color(0xFFFFCA70)),
            Disconnecting() => ('Отключение…', 'Подождите', const Color(0xFFFFCA70)),
            Disconnected() when !hasProfile => ('Добавьте профиль для подключения', 'Добавить профиль', mitIdle),
            Disconnected() => ('Готов к подключению', 'Подключить', mitIdle),
            _ => ('Подготовка VPN…', 'Подождите', const Color(0xFFACB7AE)),
          };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: onPressed != null,
          label: action,
          value: label,
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: 226,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : mitConnectionTransition,
                curve: Curves.easeInOutCubic,
                builder: (context, animatedColor, child) {
                  final glow = animatedColor ?? color;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: glow.withValues(alpha: .20)),
                      boxShadow: [BoxShadow(color: glow.withValues(alpha: .20), blurRadius: 40, spreadRadius: 4)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: DecoratedBox(
                        key: const ValueKey('mit-power-ring'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color.lerp(mitBackground, glow, .12)!, mitBackground]),
                          border: Border.all(color: glow, width: 4),
                          boxShadow: [BoxShadow(color: glow.withValues(alpha: .44), blurRadius: 19, spreadRadius: 1)],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: const ValueKey('mit-power-button'),
                            customBorder: const CircleBorder(),
                            onTap: onPressed,
                            child: Icon(
                              Icons.power_settings_new_rounded,
                              color: glow,
                              size: 94,
                              shadows: [Shadow(color: glow.withValues(alpha: .5), blurRadius: 22)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Semantics(
          liveRegion: true,
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: failed ? color : Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 6),
        Text(action, style: TextStyle(color: color, fontSize: 13)),
        if (failed) ...[
          const SizedBox(height: 8),
          const Text('Проверьте сеть и профиль', style: TextStyle(color: Color(0xFFBBC4BD)), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
