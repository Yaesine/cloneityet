// lib/widgets/components/app_button.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppButtonType { primary, secondary, text, outline }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine button styling based on type
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    double elevation;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        elevation = 2;
        break;
      case AppButtonType.secondary:
        backgroundColor = AppColors.secondary;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        elevation = 2;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
        elevation = 0;
        break;
      case AppButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderColor = Colors.transparent;
        elevation = 0;
        break;
    }

    // Determine button size
    double horizontalPadding;
    double verticalPadding;
    double fontSize;

    switch (size) {
      case AppButtonSize.small:
        horizontalPadding = 16;
        verticalPadding = 8;
        fontSize = 14;
        break;
      case AppButtonSize.medium:
        horizontalPadding = 24;
        verticalPadding = 12;
        fontSize = 16;
        break;
      case AppButtonSize.large:
        horizontalPadding = 32;
        verticalPadding = 16;
        fontSize = 18;
        break;
    }

    // Build the button content
    Widget buttonContent = isLoading
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(textColor),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    // Create the button with appropriate styling
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      child: type == AppButtonType.text
          ? TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          foregroundColor: textColor,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: buttonContent,
      )
          : ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: elevation,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
        ),
        child: buttonContent,
      ),
    );
  }
}