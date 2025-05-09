// lib/providers/user_provider.dart - Updated with likes and visitors functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;  // Use alias for Firebase Auth
import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/user_model.dart';  // Only import once
import '../models/match_model.dart';
import '../services/firestore_service.dart';


class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<User> _potentialMatches = [];
  List<Match> _matches = [];
  List<User> _matchedUsers = [];
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // New properties for likes tab
  List<User> _usersWhoLikedMe = [];
  List<Map<String, dynamic>> _profileVisitors = [];

  // Getters
  List<User> get potentialMatches => _potentialMatches;
  List<Match> get matches => _matches;
  List<User> get matchedUsers => _matchedUsers;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // New getters for likes tab
  List<User> get usersWhoLikedMe => _usersWhoLikedMe;
  List<Map<String, dynamic>> get profileVisitors => _profileVisitors;

  // Initialize and load current user data
  Future<void> initialize() async {
    await loadCurrentUser();
    await loadPotentialMatches();
    await loadMatches();
    await loadUsersWhoLikedMe();
    await loadProfileVisitors();
  }

  // Improved SuperLike function with visual feedback and special match handling
  Future<User?> superLike(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      bool isMatch = await _firestoreService.recordSwipe(userId, true, isSuperLike: true);
      User? matchedUser;

      if (isMatch) {
        // If it's a match, load the matched user
        matchedUser = await _firestoreService.getUserData(userId);
        if (matchedUser != null) {
          // Create match objects
          final newMatch = Match(
            id: '${_firestoreService.currentUserId}-$userId',
            userId: _firestoreService.currentUserId!,
            matchedUserId: userId,
            timestamp: DateTime.now(),
            // Add superLike flag to indicate this was a super like match
            superLike: true,
          );

          _matches.add(newMatch);
          _matchedUsers.add(matchedUser);

          // Send special notification for SuperLike matches
          await _firestoreService.sendSuperLikeMatchNotification(
              userId,
              _currentUser?.name ?? 'Someone'
          );
        }
      } else {
        // Even if not a match, notify the user about the SuperLike
        await _firestoreService.sendSuperLikeNotification(
            userId,
            _currentUser?.name ?? 'Someone'
        );
      }

      // Remove from potential matches and users who liked me lists
      _potentialMatches.removeWhere((user) => user.id == userId);
      _usersWhoLikedMe.removeWhere((user) => user.id == userId);

      _isLoading = false;
      notifyListeners();

      // Return the matched user if there was a match
      return matchedUser;
    } catch (e) {
      print('Error super liking: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Load current user data
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getCurrentUserData();
      print('Current user loaded: ${_currentUser?.name}');
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
      print('Error loading current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load potential matches
  Future<void> loadPotentialMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('==== LOADING POTENTIAL MATCHES ====');
      print('Current user ID: ${_firestoreService.currentUserId}');

      if (_firestoreService.currentUserId == null) {
        print('ERROR: No current user ID available');
        throw Exception('No current user ID available');
      }

      print('Attempting to load potential matches from Firestore...');
      _potentialMatches = await _firestoreService.getPotentialMatches();
      print('Loaded ${_potentialMatches.length} potential matches');

      // Print each potential match for debugging
      if (_potentialMatches.isNotEmpty) {
        print('Potential matches:');
        for (var match in _potentialMatches) {
          print('- User: ${match.name} (ID: ${match.id})');
        }
      }

      // Only use dummy data if Firebase returned no results
      if (_potentialMatches.isEmpty) {
        print('No potential matches found in Firestore, using dummy data');
        _potentialMatches = DummyData.getDummyUsers();
      }
    } catch (e) {
      _errorMessage = 'Failed to load potential matches: $e';
      print('ERROR loading potential matches: $e');
      // Fall back to dummy data on error
      print('Falling back to dummy data due to error');
      _potentialMatches = DummyData.getDummyUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
      print('==== FINISHED LOADING POTENTIAL MATCHES ====');
    }
  }

  // Load users who have liked the current user
  Future<void> loadUsersWhoLikedMe() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_firestoreService.currentUserId == null) {
        throw Exception('No current user ID available');
      }

      _usersWhoLikedMe = await _firestoreService.getUsersWhoLikedMe();
      print('Loaded ${_usersWhoLikedMe.length} users who liked me');
    } catch (e) {
      print('Error loading users who liked me: $e');
      _usersWhoLikedMe = []; // Reset to empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load users who have visited current user's profile
  Future<void> loadProfileVisitors() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_firestoreService.currentUserId == null) {
        throw Exception('No current user ID available');
      }

      _profileVisitors = await _firestoreService.getProfileVisitors();
      print('Loaded ${_profileVisitors.length} profile visitors');
    } catch (e) {
      print('Error loading profile visitors: $e');
      _profileVisitors = []; // Reset to empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // In lib/providers/user_provider.dart - forceSyncCurrentUser() method
  // Modified forceSyncCurrentUser method for lib/providers/user_provider.dart
// Replace the existing method with this updated version

  Future<void> forceSyncCurrentUser() async {
    try {
      // Get the current Firebase Auth user
      final authInstance = auth.FirebaseAuth.instance;
      final userId = authInstance.currentUser?.uid;

      if (userId == null) {
        print('No authenticated user found');
        return;
      }

      // Check if user exists in Firestore
      User? existingUser = await _firestoreService.getUserData(userId);

      if (existingUser == null) {
        print('User document does not exist in Firestore. Creating it now...');

        // Get user's name from Firebase Auth
        final userName = authInstance.currentUser?.displayName ?? 'New User';

        // Create basic profile - without any default profile image
        User newUser = User(
          id: userId,
          name: userName,
          age: 25,
          bio: 'Tell others about yourself...',
          imageUrls: [], // Empty array - we won't add any default image
          interests: ['Travel', 'Music', 'Movies'],
          location: 'New York, NY',
          gender: '',
          lookingFor: '',
          distance: 50,
          ageRangeStart: 18,
          ageRangeEnd: 50,
        );

        // Use the update method from FirestoreService
        await _firestoreService.updateUserProfile(newUser);
        print('Created user document in Firestore');

        // Update current user
        _currentUser = newUser;
        notifyListeners();
      } else {
        print('User document exists in Firestore');
        _currentUser = existingUser;
        notifyListeners();
      }
    } catch (e) {
      print('Error in forceSyncCurrentUser: $e');
    }
  }

  // Load user matches
  Future<void> loadMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _matches = await _firestoreService.getUserMatches();
      _matchedUsers = await _firestoreService.getMatchedUsers();
      print('Loaded ${_matches.length} matches and ${_matchedUsers.length} matched users');
    } catch (e) {
      _errorMessage = 'Failed to load matches: $e';
      print('Error loading matches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Swipe left (dislike)
  Future<void> swipeLeft(String userId) async {
    try {
      await _firestoreService.recordSwipe(userId, false);
      _potentialMatches.removeWhere((user) => user.id == userId);
      _usersWhoLikedMe.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      print('Error swiping left: $e');
    }
  }

  // Swipe right (like)
  Future<User?> swipeRight(String userId) async {
    try {
      bool isMatch = await _firestoreService.recordSwipe(userId, true);
      User? matchedUser;

      if (isMatch) {
        // If it's a match, load the matched user
        matchedUser = await _firestoreService.getUserData(userId);
        if (matchedUser != null) {
          // Create match objects
          final newMatch = Match(
            id: '${_firestoreService.currentUserId}-$userId',
            userId: _firestoreService.currentUserId!,
            matchedUserId: userId,
            timestamp: DateTime.now(),
          );

          _matches.add(newMatch);
          _matchedUsers.add(matchedUser);

          // Send match notification
          await _firestoreService.sendMatchNotification(
              userId,
              _currentUser?.name ?? 'Someone'
          );
        }
      }

      // Remove from potential matches and users who liked me lists
      _potentialMatches.removeWhere((user) => user.id == userId);
      _usersWhoLikedMe.removeWhere((user) => user.id == userId);
      notifyListeners();

      // Return the matched user if there was a match
      return matchedUser;
    } catch (e) {
      print('Error swiping right: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      print('User profile updated successfully: ${updatedUser.name}');
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      print('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to matches stream
  void startMatchesStream() {
    _firestoreService.matchesStream().listen((matches) {
      _matches = matches;
      _loadMatchedUsers();
      notifyListeners();
    });
  }

  // Start visitors and likes streams
  void startVisitorsAndLikesStreams() {
    // Listen for profile visitors
    _firestoreService.profileVisitorsStream().listen((visitors) {
      _profileVisitors = visitors;
      notifyListeners();
    });

    // Listen for users who liked me
    _firestoreService.usersWhoLikedMeStream().listen((users) {
      _usersWhoLikedMe = users;
      notifyListeners();
    });
  }

  // Helper method to load matched users
  Future<void> _loadMatchedUsers() async {
    _matchedUsers = [];
    for (var match in _matches) {
      final user = await _firestoreService.getUserData(match.matchedUserId);
      if (user != null) {
        _matchedUsers.add(user);
      }
    }
    notifyListeners();
  }
}