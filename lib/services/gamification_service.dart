// lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_badge_model.dart'; // Updated import

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track user streaks
  Future<void> updateStreak() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final userDoc = await _firestore.collection('user_streaks').doc(currentUserId).get();
    final now = DateTime.now();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final lastActiveDate = (data['lastActiveDate'] as Timestamp).toDate();
      final streak = data['streak'] ?? 0;

      // Check if streak should continue
      if (now.difference(lastActiveDate).inDays == 1) {
        // Continue streak
        await userDoc.reference.update({
          'streak': streak + 1,
          'lastActiveDate': Timestamp.fromDate(now),
        });
      } else if (now.difference(lastActiveDate).inDays > 1) {
        // Reset streak
        await userDoc.reference.update({
          'streak': 1,
          'lastActiveDate': Timestamp.fromDate(now),
        });
      }
    } else {
      // Create new streak
      await _firestore.collection('user_streaks').doc(currentUserId).set({
        'streak': 1,
        'lastActiveDate': Timestamp.fromDate(now),
      });
    }
  }

  // Achievements system
  Future<void> trackAchievement(String achievementId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('user_achievements').doc(currentUserId).collection('achievements').doc(achievementId).set({
      'unlockedAt': Timestamp.now(),
    });
  }

  // Badge system
  Future<List<UserBadge>> getUserBadges() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];

    final badgesSnapshot = await _firestore
        .collection('user_achievements')
        .doc(currentUserId)
        .collection('badges')
        .get();

    return badgesSnapshot.docs.map((doc) => UserBadge.fromFirestore(doc)).toList();
  }
}