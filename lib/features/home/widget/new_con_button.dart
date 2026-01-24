import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

class CircleDesignWidget extends StatelessWidget {
  final double animationValue;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final String label;

  const CircleDesignWidget({
    Key? key,
    required this.animationValue,
    required this.color,
    required this.onTap,
    required this.enabled,
    required this.label,
  }) : super(key: key);
  // GestureDetector(
  //       onTap: onTap,
  //       child: CustomPaint(
  //         size: const Size(168, 168),
  //         painter: CirclePainter(
  //           animationValue: animationValue,
  //           baseColor: color,
  //         ),
  //       )
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // CircleDesignWidget(newButtonColor: newButtonColor, onTap: onTap, animated: animated),
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              // boxShadow: [
              //   BoxShadow(
              //     blurRadius: 16,
              //     color: color.withOpacity(0.5),
              //   ),
              // ],
            ),
            width: 168,
            height: 168,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              // color: Colors.white,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: TweenAnimationBuilder(
                    tween: ColorTween(end: color),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: CirclePainter(animationValue: animationValue, baseColor: value!),
                      );
                      // return Assets.images.logo.svg(
                      //   colorFilter: ColorFilter.mode(
                      //     value!,
                      //     BlendMode.srcIn,
                      //   ),
                      // );
                    },
                  ),
                ),
              ),
            ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
          ).animate(target: enabled ? 0 : 1).scaleXY(end: .88, curve: Curves.easeIn),
        ),
        const Gap(16),
        ExcludeSemantics(child: AnimatedText(label, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}

class CirclePainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;

  CirclePainter({required this.animationValue, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final innerCircleColor = [baseColor.withAlpha(230), baseColor];

    // Outer circle (pulsing animation for connecting state)
    final Paint outerCirclePaint = Paint()
      ..color = baseColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final double outerRadius = 84 * animationValue;

    canvas.drawCircle(Offset(cx, cy), outerRadius, outerCirclePaint);

    // Middle circle
    final Paint middleCirclePaint = Paint()
      ..color = baseColor.withOpacity(.3)
      ..style = PaintingStyle.fill;
    final double middleRadius = 60 * animationValue + (1 - animationValue) / 3;
    canvas.drawCircle(Offset(cx, cy), middleRadius, middleCirclePaint);

    // Inner circle with gradient
    final Paint innerCirclePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: innerCircleColor,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    final double innerRadius = 36;
    canvas.drawCircle(Offset(cx, cy), innerRadius, innerCirclePaint);

    // Draw path and vertical line (same as original)
    final Paint pathPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.80952
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path curvePath = Path()
      ..moveTo(92.4867, 75.52)
      ..cubicTo(94.1645, 77.1984, 95.307, 79.3366, 95.7697, 81.6643)
      ..cubicTo(96.2324, 83.9919, 95.9946, 86.4045, 95.0862, 88.597)
      ..cubicTo(94.1778, 90.7895, 92.6397, 92.6634, 90.6664, 93.9818)
      ..cubicTo(88.6931, 95.3002, 86.3732, 96.0039, 84, 96.0039)
      ..cubicTo(81.6268, 96.0039, 79.3069, 95.3002, 77.3336, 93.9818)
      ..cubicTo(75.3603, 92.6634, 73.8222, 90.7895, 72.9138, 88.597)
      ..cubicTo(72.0055, 86.4045, 71.7676, 83.9919, 72.2303, 81.6643)
      ..cubicTo(72.693, 79.3366, 73.8355, 77.1984, 75.5133, 75.52);
    canvas.drawPath(curvePath, pathPaint);

    final Path linePath = Path()
      ..moveTo(84.0066, 72)
      ..lineTo(84.0066, 82.6667);

    // Draw the vertical line
    canvas.drawPath(linePath, pathPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
