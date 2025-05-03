import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Collection references
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _matchesCollection =
  FirebaseFirestore.instance.collection('matches');
  final CollectionReference _messagesCollection =
  FirebaseFirestore.instance.collection('messages');
  final CollectionReference _swipesCollection =
  FirebaseFirestore.instance.collection('swipes');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or update user profile
  Future<void> updateUserProfile(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Create new user after registration
  Future<void> createNewUser(String userId, String name, String email) async {
    try {
      // Check if user already exists
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        return; // User already exists, no need to create
      }

      // Create a basic user profile
      final newUser = User(
        id: userId,
        name: name,
        age: 25, // Default age
        bio: 'Tell others about yourself...',
        imageUrls: ['https://i.pravatar.cc/300?img=33'], // Default image
        interests: ['Travel', 'Music', 'Movies'],
        location: 'New York, NY',
      );

      await _usersCollection.doc(userId).set(newUser.toJson());
    } catch (e) {
      print('Error creating new user: $e');
      throw e;
    }
  }

  // Get user data
  Future<User?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Get current user data
  Future<User?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    return await getUserData(currentUserId!);
  }
  // Get potential matches (users that are not current user and not already matched or swiped)
  Future<List<User>> getPotentialMatches() async {
    try {
      if (currentUserId == null) return [];

      // Get all swipes by current user
      QuerySnapshot swipesSnapshot = await _swipesCollection
          .where('swiperId', isEqualTo: currentUserId)
          .get();

      // Extract swiped user IDs
      List<String> swipedUserIds = swipesSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['swipedId'] as String)
          .toList();

      // Add current user to excluded list
      List<String> excludedUserIds = [...swipedUserIds, currentUserId!];

      // Get all users except those in the excluded list
      QuerySnapshot usersSnapshot = await _usersCollection.get();

      List<User> potentialMatches = [];
      for (var doc in usersSnapshot.docs) {
        String userId = doc.id;
        if (!excludedUserIds.contains(userId)) {
          potentialMatches.add(User.fromFirestore(doc));
        }
      }

      print('Found ${potentialMatches.length} potential matches in Firestore');
      return potentialMatches;
    } catch (e) {
      print('Error getting potential matches from Firestore: $e');
      throw e;
    }
  }

  // Record a swipe decision
  // In the FirestoreService class, let's modify the recordSwipe method:

  Future<bool> recordSwipe(String swipedUserId, bool isLike, {bool isSuperLike = false}) async {
    try {
      if (currentUserId == null) return false;

      // Record the swipe decision
      await _swipesCollection.add({
        'swiperId': currentUserId,
        'swipedId': swipedUserId,
        'liked': isLike,
        'superLiked': isSuperLike, // Add this field
        'timestamp': Timestamp.now(),
      });

      // If it was a dislike, we don't need to check for a match
      if (!isLike) return false;

      // Check if swiped user also liked current user or if this is a super like
      QuerySnapshot mutualLikeCheck = await _swipesCollection
          .where('swiperId', isEqualTo: swipedUserId)
          .where('swipedId', isEqualTo: currentUserId)
          .where('liked', isEqualTo: true)
          .get();

      // If mutual like or super like, create a match
      if (mutualLikeCheck.docs.isNotEmpty || isSuperLike) {
        String matchId = '$currentUserId-$swipedUserId';

        // Create match document with super like info
        await _matchesCollection.doc(matchId).set({
          'userId': currentUserId,
          'matchedUserId': swipedUserId,
          'timestamp': Timestamp.now(),
          'superLike': isSuperLike,
        });

        // Create reverse match for other user
        String reverseMatchId = '$swipedUserId-$currentUserId';
        await _matchesCollection.doc(reverseMatchId).set({
          'userId': swipedUserId,
          'matchedUserId': currentUserId,
          'timestamp': Timestamp.now(),
          'superLike': isSuperLike,
        });

        return true; // Match created
      }

      return false; // No match yet
    } catch (e) {
      print('Error recording swipe: $e');
      return false;
    }
  }


  // Get user matches
  Future<List<Match>> getUserMatches() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot matchesSnapshot = await _matchesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Match> matches = [];
      for (var doc in matchesSnapshot.docs) {
        matches.add(Match.fromFirestore(doc));
      }

      return matches;
    } catch (e) {
      print('Error getting matches: $e');
      return [];
    }
  }

  // Get matched users' profiles
  Future<List<User>> getMatchedUsers() async {
    try {
      List<Match> matches = await getUserMatches();
      List<User> matchedUsers = [];

      for (var match in matches) {
        User? user = await getUserData(match.matchedUserId);
        if (user != null) {
          matchedUsers.add(user);
        }
      }

      return matchedUsers;
    } catch (e) {
      print('Error getting matched users: $e');
      return [];
    }
  }
  // Get messages for a specific match
  Future<List<Message>> getMessages(String matchedUserId) async {
    try {
      if (currentUserId == null) return [];

      // Query messages where the conversation is between the current user and the matched user
      QuerySnapshot messagesSnapshot = await _messagesCollection
          .where('senderId', whereIn: [currentUserId, matchedUserId])
          .where('receiverId', whereIn: [currentUserId, matchedUserId])
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      List<Message> messages = [];
      for (var doc in messagesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Only include messages between these two specific users
        if ((data['senderId'] == currentUserId && data['receiverId'] == matchedUserId) ||
            (data['senderId'] == matchedUserId && data['receiverId'] == currentUserId)) {
          messages.add(Message.fromFirestore(doc));
        }
      }

      return messages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Send a message
  Future<bool> sendMessage(String receiverId, String text) async {
    try {
      if (currentUserId == null) return false;

      await _messagesCollection.add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': Timestamp.now(),
        'isRead': false,
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      if (currentUserId == null) return;

      QuerySnapshot unreadMessages = await _messagesCollection
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Listen to new messages stream
  Stream<List<Message>> messagesStream(String matchedUserId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _messagesCollection
        .where('senderId', whereIn: [currentUserId, matchedUserId])
        .where('receiverId', whereIn: [currentUserId, matchedUserId])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Message> messages = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Only include messages between these two specific users
        if ((data['senderId'] == currentUserId && data['receiverId'] == matchedUserId) ||
            (data['senderId'] == matchedUserId && data['receiverId'] == currentUserId)) {
          messages.add(Message.fromFirestore(doc));
        }
      }

      return messages;
    });
  }

  // Listen to matches stream
  Stream<List<Match>> matchesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _matchesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromFirestore(doc))
          .toList();
    });
  }
}