import 'package:flutter/material.dart';

enum ConnectionStateStatus { disconnected, connecting, connected, error }

class CircleDesignWidget extends StatefulWidget {
  @override
  _CircleDesignWidgetState createState() => _CircleDesignWidgetState();
}

class _CircleDesignWidgetState extends State<CircleDesignWidget> with SingleTickerProviderStateMixin {
  ConnectionStateStatus _currentState = ConnectionStateStatus.disconnected;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation controller for the connecting state
    _controller = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void changeState(ConnectionStateStatus state) {
    setState(() {
      _currentState = state;
      if (state == ConnectionStateStatus.connecting || state == ConnectionStateStatus.connected) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Change the state for demo purposes
        switch (_currentState) {
          case ConnectionStateStatus.disconnected:
            changeState(ConnectionStateStatus.connecting);
            break;
          case ConnectionStateStatus.connecting:
            changeState(ConnectionStateStatus.connected);
            break;
          case ConnectionStateStatus.connected:
            changeState(ConnectionStateStatus.error);
            break;
          case ConnectionStateStatus.error:
            changeState(ConnectionStateStatus.disconnected);
            break;
        }
      },
      child: CustomPaint(
        size: const Size(168, 168),
        painter: CirclePainter(currentState: _currentState, animationValue: _animation.value),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final ConnectionStateStatus currentState;
  final double animationValue;

  CirclePainter({required this.currentState, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    Color baseColor;
    var innerCircleColor = [const Color(0xFF455FE9), const Color(0xFF3446A5)];
    if (currentState == ConnectionStateStatus.connected) {
      baseColor = Colors.green.shade900;
    } else if (currentState == ConnectionStateStatus.error) {
      baseColor = Colors.red.shade900;
    } else {
      // baseColor = const Color(0xFFB8C7F4);
      baseColor = const Color(0xFF3446A5);
    }
    innerCircleColor = [
      baseColor.withAlpha(230),
      baseColor,
      // Color.fromARGB(73, 27, 80, 43),
      // Color.fromARGB(71, 12, 48, 21),
    ];

    // Outer circle (pulsing animation for connecting state)
    final Paint outerCirclePaint = Paint()
      ..color = baseColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    // double outerRadius = (size.width / 2) * (currentState == ConnectionStateStatus.connecting ? animationValue : 1);
    final double outerRadius =
        84 *
        ([ConnectionStateStatus.connecting, ConnectionStateStatus.connected].contains(currentState)
            ? animationValue
            : 1);

    canvas.drawCircle(Offset(cx, cy), outerRadius, outerCirclePaint);

    // Middle circle
    final Paint middleCirclePaint = Paint()
      ..color = baseColor.withOpacity(.3)
      ..style = PaintingStyle.fill;
    final double middleRadius =
        60 *
        ([ConnectionStateStatus.connecting, ConnectionStateStatus.connected].contains(currentState)
            ? animationValue + (1 - animationValue) / 3
            : 1);
    canvas.drawCircle(Offset(cx, cy), middleRadius, middleCirclePaint);

    // Inner circle with gradient
    final Paint innerCirclePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: innerCircleColor,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    final double innerRadius = 36; //* (currentState == ConnectionStateStatus.connecting ? animationValue : 1);
    canvas.drawCircle(Offset(cx, cy), innerRadius, innerCirclePaint);
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
    // Vertical line
    final Path linePath = Path()
      ..moveTo(84.0066, 72)
      ..lineTo(84.0066, 82.6667);

    // Draw the vertical line
    canvas.drawPath(linePath, pathPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
