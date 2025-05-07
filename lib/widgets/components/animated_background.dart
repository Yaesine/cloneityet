// lib/widgets/components/animated_background.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final List<Color> colors;
  final double speed;

  const AnimatedBackground({
    Key? key,
    required this.colors,
    this.speed = 1.0,
  }) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: (10 / widget.speed).round()),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            colors: widget.colors,
            animation: _controller,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final List<Color> colors;
  final Animation<double> animation;

  _BackgroundPainter({
    required this.colors,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Create a gradient with animated stops
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: [
        0.0,
        animation.value,
        1.0,
      ],
      transform: GradientRotation(animation.value * 2 * math.pi),
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Add a subtle pattern overlay
    final patternPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final spacing = 20.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      final start = Offset(i, 0);
      final end = Offset(0, i);
      final offset = math.sin(animation.value * math.pi * 2 + i / 50) * 5;
      canvas.drawLine(
          start.translate(offset, 0),
          end.translate(0, offset),
          patternPaint
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.animation != animation;
}