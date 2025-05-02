// matching_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'location_service.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Calculate match score between two users (0-100)
  int calculateMatchScore(User currentUser, User potentialMatch) {
    int score = 0;

    // Age preference match (0-20 points)
    if (potentialMatch.age >= currentUser.ageRangeStart &&
        potentialMatch.age <= currentUser.ageRangeEnd) {
      score += 20;
    } else {
      return 0; // If age is outside preferences, immediately return 0
    }

    // Gender preference match (0-20 points)
    if (currentUser.lookingFor.isEmpty ||
        currentUser.lookingFor == potentialMatch.gender) {
      score += 20;
    } else {
      return 0; // If gender doesn't match preference, immediately return 0
    }

    // Shared interests (0-30 points, 5 points per shared interest)
    int sharedInterestsCount = currentUser.interests
        .where((interest) => potentialMatch.interests.contains(interest))
        .length;
    score += min(30, sharedInterestsCount * 5);

    // Location proximity (0-30 points)
    // Assuming both users have geoPoint field in Firestore
    // The closer, the higher the score
    if (currentUser.geoPoint != null && potentialMatch.geoPoint != null) {
      double distance = _locationService.calculateDistance(
          currentUser.geoPoint!,
          potentialMatch.geoPoint!
      );

      if (distance <= currentUser.distance) {
        // Give more points for closer users
        // 30 points if very close, decreasing as distance increases
        double distanceScore = 30 * (1 - (distance / currentUser.distance));
        score += distanceScore.round();
      } else {
        return 0; // If distance is outside preferences, immediately return 0
      }
    }

    return score;
  }

  // Get potential matches sorted by match score
  Future<List<User>> getPotentialMatchesByScore(String userId) async {
    try {
      // Get current user
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      User currentUser = User.fromFirestore(userDoc);

      // Get all users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      // Get already swiped user IDs
      QuerySnapshot swipesSnapshot = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: userId)
          .get();

      List<String> swipedUserIds = swipesSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['swipedId'] as String)
          .toList();

      // Calculate scores for potential matches
      List<Map<String, dynamic>> scoredMatches = [];

      for (var doc in usersSnapshot.docs) {
        String potentialMatchId = doc.id;

        // Skip current user and already swiped users
        if (potentialMatchId == userId || swipedUserIds.contains(potentialMatchId)) {
          continue;
        }

        User potentialMatch = User.fromFirestore(doc);
        int score = calculateMatchScore(currentUser, potentialMatch);

        // Only consider users with a score > 0
        if (score > 0) {
          scoredMatches.add({
            'user': potentialMatch,
            'score': score,
          });
        }
      }

      // Sort by score (highest first)
      scoredMatches.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Return sorted list of users
      return scoredMatches.map((item) => item['user'] as User).toList();
    } catch (e) {
      print('Error getting potential matches by score: $e');
      return [];
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}