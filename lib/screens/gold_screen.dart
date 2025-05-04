// lib/screens/gold_screen.dart - Read receipts and verification features
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoldFeatures {
  // Read receipts
  static Widget buildReadReceipt(bool isRead) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check,
          size: 12,
          color: isRead ? AppColors.secondary : Colors.grey,
        ),
        if (isRead)
          Icon(
            Icons.check,
            size: 12,
            color: AppColors.secondary,
          ),
      ],
    );
  }

  // Priority Likes indicator
  static Widget buildPriorityLikeIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.red],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Priority Like',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}