// lib/widgets/components/animated_progress_indicator.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedProgressIndicator extends StatefulWidget {
  final double value;
  final double size;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const AnimatedProgressIndicator({
    Key? key,
    required this.value,
    this.size = 40,
    required this.color,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  @override
  _AnimatedProgressIndicatorState createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _oldValue;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _oldValue + (_animation.value * (widget.value - _oldValue));
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ProgressPainter(
              value: currentValue,
              color: widget.color,
              backgroundColor: widget.backgroundColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Text(
                '${(currentValue * 100).toInt()}%',
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size / 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / 2;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * value, // End based on progress value
      false,
      progressPaint,
    );

    // Add a subtle glowing effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      glowPaint,
    );

    // Add small circles at the end of the progress arc for decoration
    if (value > 0) {
      final endAngle = -math.pi / 2 + 2 * math.pi * value;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), strokeWidth / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
          oldDelegate.color != color ||
          oldDelegate.backgroundColor != backgroundColor ||
          oldDelegate.strokeWidth != strokeWidth;
}