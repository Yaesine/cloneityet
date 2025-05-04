// lib/services/advanced_matching_service.dart - Fixed version
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';  // Add this import to use pow function
import '../models/user_model.dart';
import '../services/location_service.dart';

class AdvancedMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // ELO-style rating system
  Future<double> updateELORating(String userId, bool didMatch) async {
    try {
      final userDoc = await _firestore.collection('user_ratings').doc(userId).get();

      double currentRating = 1000.0; // Default starting rating
      int gamesPlayed = 0;

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        currentRating = data['rating'] ?? 1000.0;
        gamesPlayed = data['gamesPlayed'] ?? 0;
      }

      // Calculate K-factor (higher for newer players)
      double kFactor = 32.0;
      if (gamesPlayed > 30) {
        kFactor = 16.0;
      } else if (gamesPlayed > 10) {
        kFactor = 24.0;
      }

      // Update rating based on match result
      double expectedScore = 1 / (1 + pow(10, (1000 - currentRating) / 400) as double);
      double actualScore = didMatch ? 1.0 : 0.0;
      double newRating = currentRating + kFactor * (actualScore - expectedScore);

      // Update in Firestore
      await _firestore.collection('user_ratings').doc(userId).set({
        'rating': newRating,
        'gamesPlayed': gamesPlayed + 1,
        'lastUpdated': Timestamp.now(),
      });

      return newRating;
    } catch (e) {
      print('Error updating ELO rating: $e');
      return 1000.0;
    }
  }

  // Advanced matching algorithm incorporating multiple factors
  Future<List<User>> getOptimizedMatches(String userId) async {
    try {
      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final currentUser = User.fromFirestore(userDoc);

      // Get user's ELO rating
      final ratingDoc = await _firestore.collection('user_ratings').doc(userId).get();
      double userRating = 1000.0;
      if (ratingDoc.exists) {
        userRating = (ratingDoc.data() as Map<String, dynamic>)['rating'] ?? 1000.0;
      }

      // Get all potential matches
      final usersSnapshot = await _firestore.collection('users').get();
      List<User> allUsers = [];

      for (var doc in usersSnapshot.docs) {
        if (doc.id != userId) {
          allUsers.add(User.fromFirestore(doc));
        }
      }

      // Filter and sort potential matches
      List<Map<String, dynamic>> scoredMatches = [];

      for (var user in allUsers) {
        // Get potential match's ELO rating
        final potentialRatingDoc = await _firestore.collection('user_ratings').doc(user.id).get();
        double potentialRating = 1000.0;
        if (potentialRatingDoc.exists) {
          potentialRating = (potentialRatingDoc.data() as Map<String, dynamic>)['rating'] ?? 1000.0;
        }

        // Calculate comprehensive match score
        double score = await _calculateMatchScore(currentUser, user, userRating, potentialRating);

        if (score > 0) {
          scoredMatches.add({
            'user': user,
            'score': score,
          });
        }
      }

      // Sort by score and return top matches
      scoredMatches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      return scoredMatches.take(50).map((item) => item['user'] as User).toList();
    } catch (e) {
      print('Error getting optimized matches: $e');
      return [];
    }
  }

  // Calculate comprehensive match score
  Future<double> _calculateMatchScore(User currentUser, User potentialMatch, double userRating, double potentialRating) async {
    double score = 0.0;

    // 1. ELO Rating Similarity (20% weight)
    double ratingDifference = (userRating - potentialRating).abs();
    double ratingScore = ratingDifference <= 200 ? 20.0 * (1 - ratingDifference / 200) : 0.0;
    score += ratingScore;

    // 2. Interest Compatibility (25% weight) - FIXED
    int sharedInterests = currentUser.interests
        .where((interest) => potentialMatch.interests.contains(interest))
        .length;
    double interestScore = (sharedInterests * 5.0).clamp(0.0, 25.0); // Fixed type conversion
    score += interestScore;

    // 3. Profile Completion (10% weight)
    double profileCompletionScore = _calculateProfileCompleteness(potentialMatch) * 10;
    score += profileCompletionScore;

    // 4. Activity Level (15% weight)
    double activityScore = await _calculateActivityScore(potentialMatch.id);
    score += activityScore;

    // 5. Location Proximity (15% weight)
    if (currentUser.geoPoint != null && potentialMatch.geoPoint != null) {
      double distance = _locationService.calculateDistance(
        currentUser.geoPoint!,
        potentialMatch.geoPoint!,
      );

      if (distance <= currentUser.distance) {
        double locationScore = 15.0 * (1 - distance / currentUser.distance);
        score += locationScore;
      }
    }

    // 6. Photo Quality (15% weight)
    double photoScore = _calculatePhotoScore(potentialMatch);
    score += photoScore;

    return score;
  }

  double _calculateProfileCompleteness(User user) {
    double completeness = 0.0;

    if (user.bio.isNotEmpty) completeness += 0.2;
    if (user.interests.isNotEmpty) completeness += 0.2;
    if (user.imageUrls.length >= 3) completeness += 0.3;
    if (user.location.isNotEmpty) completeness += 0.1;
    if (user.gender.isNotEmpty) completeness += 0.1;
    if (user.lookingFor.isNotEmpty) completeness += 0.1;

    return completeness;
  }

  Future<double> _calculateActivityScore(String userId) async {
    try {
      // Check last swipe activity
      final swipesSnapshot = await _firestore.collection('swipes')
          .where('swiperId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (swipesSnapshot.docs.isEmpty) return 5.0; // Default for inactive users

      final lastSwipeTime = (swipesSnapshot.docs.first.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
      final now = DateTime.now();
      final daysSinceLastSwipe = now.difference(lastSwipeTime.toDate()).inDays;

      // Score based on recent activity
      if (daysSinceLastSwipe == 0) return 15.0;
      if (daysSinceLastSwipe <= 1) return 12.0;
      if (daysSinceLastSwipe <= 3) return 8.0;
      if (daysSinceLastSwipe <= 7) return 5.0;
      return 2.0;
    } catch (e) {
      print('Error calculating activity score: $e');
      return 5.0;
    }
  }

  double _calculatePhotoScore(User user) {
    double score = 0.0;

    // Number of photos
    if (user.imageUrls.length >= 6) score += 7.0;
    else if (user.imageUrls.length >= 4) score += 5.0;
    else if (user.imageUrls.length >= 2) score += 3.0;
    else score += 1.0;

    // Quality indicators (simplified)
    // In a real app, you'd analyze image quality, diversity, etc.
    score += 8.0; // Assume good quality for now

    return score;
  }
}