// lib/widgets/components/gradient_text.dart
import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const GradientText({
    Key? key,
    required this.text,
    required this.style,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
      ).createShader(bounds),
      child: Text(
        text,
        style: style,
      ),
    );
  }
}