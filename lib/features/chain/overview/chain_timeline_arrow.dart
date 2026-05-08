import 'package:flutter/material.dart';

class ChainTimelineArrow extends StatelessWidget {
  final bool showArrow;

  const ChainTimelineArrow({super.key, this.showArrow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      margin: const EdgeInsetsDirectional.only(start: 8.5),
      child: CustomPaint(
        painter: _ChainTimeLineArrowPainter(showArrow: showArrow, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _ChainTimeLineArrowPainter extends CustomPainter {
  final bool showArrow;
  final Color color;

  _ChainTimeLineArrowPainter({required this.showArrow, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.0;

    final double bottomPadding = showArrow ? 6.0 : 0.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final bottomY = size.height - bottomPadding;
    final centerX = size.width / 2;

    canvas.drawLine(Offset(centerX, 0), Offset(centerX, bottomY), paint);

    if (showArrow) {
      paint.strokeJoin = StrokeJoin.round;
      final path = Path();
      path.moveTo(0, bottomY - 8);
      path.lineTo(centerX, bottomY);
      path.lineTo(size.width, bottomY - 8);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChainTimeLineArrowPainter oldDelegate) {
    return oldDelegate.showArrow != showArrow;
  }
}
