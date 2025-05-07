// lib/widgets/components/neomorphic_container.dart
import 'package:flutter/material.dart';

class NeomorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final double depth;
  final Offset lightSource;
  final bool isPressed;

  const NeomorphicContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.color = Colors.white,
    this.depth = 4.0,
    this.lightSource = const Offset(-1, -1),
    this.isPressed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkShadowColor = isPressed
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.2);
    final lightShadowColor = isPressed
        ? Colors.white.withOpacity(0.6)
        : Colors.white.withOpacity(0.8);

    if (isPressed) {
      // Inner shadow effect for pressed state
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: darkShadowColor,
                offset: lightSource.scale(depth / 2, depth / 2),
                blurRadius: depth,
              ),
              BoxShadow(
                color: lightShadowColor,
                offset: lightSource.scale(-depth / 2, -depth / 2),
                blurRadius: depth,
              ),
            ],
          ),
          // Use negative margin to create inner shadow effect
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              margin: EdgeInsets.all(-depth / 2),
              padding: EdgeInsets.all(depth / 2),
              child: Material(
                color: Colors.transparent,
                child: child,
              ),
            ),
          ),
        ),
      );
    } else {
      // Outer shadow for normal state
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: darkShadowColor,
              offset: lightSource.scale(depth, depth),
              blurRadius: depth * 2,
            ),
            BoxShadow(
              color: lightShadowColor,
              offset: lightSource.scale(-depth, -depth),
              blurRadius: depth * 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      );
    }
  }
}