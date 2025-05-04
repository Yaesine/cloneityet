// lib/services/rewind_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewindService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection for storing swipe history
  final CollectionReference _swipeHistoryCollection =
  FirebaseFirestore.instance.collection('swipe_history');

  // Save swipe to history
  Future<void> saveSwipeToHistory(String swipedUserId, bool isLike) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _swipeHistoryCollection.add({
        'swiperId': currentUserId,
        'swipedUserId': swipedUserId,
        'isLike': isLike,
        'timestamp': Timestamp.now(),
        'canRewind': true,
      });
    } catch (e) {
      print('Error saving swipe to history: $e');
    }
  }

  // Get last swipe
  Future<Map<String, dynamic>?> getLastSwipe() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      final querySnapshot = await _swipeHistoryCollection
          .where('swiperId', isEqualTo: currentUserId)
          .where('canRewind', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting last swipe: $e');
      return null;
    }
  }

  // Rewind last swipe
  Future<bool> rewindLastSwipe() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final lastSwipe = await getLastSwipe();
      if (lastSwipe == null) return false;

      // Remove the swipe from swipes collection
      final swipesQuery = await _firestore.collection('swipes')
          .where('swiperId', isEqualTo: currentUserId)
          .where('swipedId', isEqualTo: lastSwipe['swipedUserId'])
          .get();

      for (var doc in swipesQuery.docs) {
        await doc.reference.delete();
      }

      // Remove potential match if it was a like
      if (lastSwipe['isLike'] == true) {
        final matchId = '$currentUserId-${lastSwipe['swipedUserId']}';
        await _firestore.collection('matches').doc(matchId).delete();
      }

      // Mark swipe as rewound
      final historyQuery = await _swipeHistoryCollection
          .where('swiperId', isEqualTo: currentUserId)
          .where('swipedUserId', isEqualTo: lastSwipe['swipedUserId'])
          .where('canRewind', isEqualTo: true)
          .get();

      for (var doc in historyQuery.docs) {
        await doc.reference.update({'canRewind': false});
      }

      return true;
    } catch (e) {
      print('Error rewinding swipe: $e');
      return false;
    }
  }
}