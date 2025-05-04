// lib/widgets/components/verification_badge.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({
    Key? key,
    this.isVerified = false,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}
