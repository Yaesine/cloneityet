import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import 'notification_manager.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final NotificationManager _notificationManager = NotificationManager();

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

  // Add this to FirestoreService class
  Future<void> verifyFirestoreConnection() async {
    try {
      print('Verifying Firestore connection...');
      final snapshot = await _firestore.collection('users').limit(5).get();

      print('Firestore connection successful');
      print('Number of users in database: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('WARNING: No users found in the database!');
      } else {
        print('Users found in database:');
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          print('- ${data['name'] ?? 'Unknown'} (ID: ${doc.id})');
        }
      }
    } catch (e) {
      print('ERROR connecting to Firestore: $e');
      throw e;
    }
  }

  // Add to FirestoreService class
  Future<void> createTestUsersIfNeeded() async {
    try {
      // Check if we have at least 3 users
      final snapshot = await _firestore.collection('users').limit(3).get();
      if (snapshot.docs.length < 3) {
        print('Creating test users for development...');

        // Create test users with different data
        List<Map<String, dynamic>> testUsers = [
          {
            'id': 'test_user_1',
            'name': 'Sophie',
            'age': 28,
            'bio': 'Travel enthusiast and coffee addict',
            'imageUrls': ['https://i.pravatar.cc/300?img=5'],
            'interests': ['Travel', 'Coffee', 'Photography'],
            'location': 'New York, NY',
            'gender': 'Female',
            'lookingFor': '',
            'distance': 50,
            'ageRangeStart': 25,
            'ageRangeEnd': 35,
          },
          {
            'id': 'test_user_2',
            'name': 'James',
            'age': 32,
            'bio': 'Software developer by day, chef by night',
            'imageUrls': ['https://i.pravatar.cc/300?img=7'],
            'interests': ['Coding', 'Cooking', 'Movies'],
            'location': 'San Francisco, CA',
            'gender': 'Male',
            'lookingFor': '',
            'distance': 40,
            'ageRangeStart': 24,
            'ageRangeEnd': 40,
          },
          {
            'id': 'test_user_3',
            'name': 'Emma',
            'age': 26,
            'bio': 'Art lover and yoga instructor',
            'imageUrls': ['https://i.pravatar.cc/300?img=9'],
            'interests': ['Yoga', 'Art', 'Reading'],
            'location': 'Chicago, IL',
            'gender': 'Female',
            'lookingFor': '',
            'distance': 30,
            'ageRangeStart': 26,
            'ageRangeEnd': 35,
          },
        ];

        // Add test users to Firestore
        for (var userData in testUsers) {
          String id = userData['id'];
          await _firestore.collection('users').doc(id).set(userData);
        }

        print('Test users created successfully');
      }
    } catch (e) {
      print('ERROR creating test users: $e');
    }
  }

  // Create or update user profile
  Future<void> updateUserProfile(User user) async {
    try {
      print('Updating user profile for ${user.id}');
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Create new user after registration
  Future<void> createNewUser(String userId, String name, String email) async {
    try {
      print('Creating user profile for $userId in Firestore');

      // Check if user already exists
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        print('User profile for $userId already exists');
        return;
      }

      // Create basic user profile
      Map<String, dynamic> userData = {
        'id': userId,
        'name': name,
        'email': email,
        'age': 25,
        'bio': 'Tell others about yourself...',
        'imageUrls': ['https://i.pravatar.cc/300?img=33'],
        'interests': ['Travel', 'Music', 'Movies'],
        'location': 'New York, NY',
        'gender': '',
        'lookingFor': '',
        'distance': 50,
        'ageRangeStart': 18,
        'ageRangeEnd': 50,
      };

      // Directly set the document with a map instead of using User model
      await _usersCollection.doc(userId).set(userData);
      print('User profile created successfully for $userId');
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Get user data
  Future<User?> getUserData(String userId) async {
    try {
      print('Fetching user data for $userId');
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      print('User $userId not found');
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Get current user data
  Future<User?> getCurrentUserData() async {
    if (currentUserId == null) {
      print('No current user ID available');
      return null;
    }
    print('Getting current user data for $currentUserId');
    return await getUserData(currentUserId!);
  }

  // Get potential matches (users that are not current user and not already matched or swiped)
  // Get potential matches (users that are not current user and not already matched or swiped)
  Future<List<User>> getPotentialMatches() async {
    try {
      if (currentUserId == null) {
        print('No current user ID available for potential matches');
        return [];
      }

      print('Fetching ALL users from Firestore to find potential matches');

      // Get ALL users except the current user
      List<User> allUsers = [];

      // Fetch all users from Firestore
      QuerySnapshot usersSnapshot = await _usersCollection.get();

      print('Found ${usersSnapshot.docs.length} total users in database');

      // Filter out the current user
      for (var doc in usersSnapshot.docs) {
        String userId = doc.id;
        if (userId != currentUserId) {
          try {
            User user = User.fromFirestore(doc);
            allUsers.add(user);
            print('Added user ${user.name} (ID: ${user.id}) to potential matches list');
          } catch (e) {
            print('Error parsing user data for $userId: $e');
          }
        }
      }

      // Get all swipes by current user
      QuerySnapshot swipesSnapshot = await _swipesCollection
          .where('swiperId', isEqualTo: currentUserId)
          .get();

      print('User has ${swipesSnapshot.docs.length} swipe records');

      // Extract swiped user IDs
      List<String> swipedUserIds = [];
      for (var doc in swipesSnapshot.docs) {
        try {
          String swipedId = (doc.data() as Map<String, dynamic>)['swipedId'] as String;
          swipedUserIds.add(swipedId);
        } catch (e) {
          print('Error parsing swipe record: $e');
        }
      }

      // Filter out users that have already been swiped
      List<User> potentialMatches = allUsers.where((user) =>
      !swipedUserIds.contains(user.id)).toList();

      print('After filtering, found ${potentialMatches.length} potential matches');

      return potentialMatches;
    } catch (e) {
      print('Error getting potential matches from Firestore: $e');
      throw e;
    }
  }

  // Get all users (for debugging)
  Future<List<User>> getAllUsers() async {
    try {
      print('GETTING ALL USERS FOR DEBUGGING');

      List<User> allUsers = [];
      QuerySnapshot usersSnapshot = await _usersCollection.get();

      print('Total users in database: ${usersSnapshot.docs.length}');

      for (var doc in usersSnapshot.docs) {
        try {
          User user = User.fromFirestore(doc);
          allUsers.add(user);
          print('Found user: ${user.name} (ID: ${user.id})');
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }

      return allUsers;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Record a swipe decision
  Future<bool> recordSwipe(String swipedUserId, bool isLike, {bool isSuperLike = false}) async {
    try {
      if (currentUserId == null) return false;

      // Record the swipe decision
      await _swipesCollection.add({
        'swiperId': currentUserId,
        'swipedId': swipedUserId,
        'liked': isLike,
        'superLiked': isSuperLike,
        'timestamp': Timestamp.now(),
      });

      if (!isLike) return false;

      print('${isLike ? "Like" : "Dislike"} recorded from $currentUserId to $swipedUserId');

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

        // Send match notification
        DocumentSnapshot currentUserDoc =
        await _usersCollection.doc(currentUserId).get();
        Map<String, dynamic>? currentUserData =
        currentUserDoc.data() as Map<String, dynamic>?;
        String currentUserName = currentUserData?['name'] ?? 'Someone';

        await _notificationManager.sendMatchNotification(
            swipedUserId,
            currentUserName
        );



        print('Match created between $currentUserId and $swipedUserId');
        return true; // Match created
      }

      print('No match yet between $currentUserId and $swipedUserId');
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

      print('Getting matches for user $currentUserId');
      QuerySnapshot matchesSnapshot = await _matchesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Match> matches = [];
      for (var doc in matchesSnapshot.docs) {
        matches.add(Match.fromFirestore(doc));
      }

      print('Found ${matches.length} matches');
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

      print('Loading profile details for ${matches.length} matches');
      for (var match in matches) {
        User? user = await getUserData(match.matchedUserId);
        if (user != null) {
          matchedUsers.add(user);
        }
      }

      print('Loaded ${matchedUsers.length} matched user profiles');
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

      // Get sender's name
      DocumentSnapshot senderDoc =
      await _usersCollection.doc(currentUserId).get();
      Map<String, dynamic>? senderData =
      senderDoc.data() as Map<String, dynamic>?;
      String senderName = senderData?['name'] ?? 'Someone';

      // Send message notification
      await _notificationManager.sendMessageNotification(
          receiverId,
          senderName,
          text
      );

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