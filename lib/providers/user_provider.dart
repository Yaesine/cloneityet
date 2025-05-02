import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/user_model.dart';
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

  // Getters
  List<User> get potentialMatches => _potentialMatches;
  List<Match> get matches => _matches;
  List<User> get matchedUsers => _matchedUsers;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize and load current user data
  Future<void> initialize() async {
    await loadCurrentUser();
    await loadPotentialMatches();
  }

  // Load current user data
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getCurrentUserData();
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
      print('Attempting to load potential matches from Firestore...');
      _potentialMatches = await _firestoreService.getPotentialMatches();
      print('Loaded ${_potentialMatches.length} potential matches');

      // Only use dummy data if Firebase returned no results
      if (_potentialMatches.isEmpty) {
        print('No potential matches found in Firestore, using dummy data');
        _potentialMatches = DummyData.getDummyUsers();
      }
    } catch (e) {
      _errorMessage = 'Failed to load potential matches: $e';
      print('Error loading potential matches: $e');
      // Fall back to dummy data on error
      _potentialMatches = DummyData.getDummyUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      print('Error swiping left: $e');
    }
  }

  // Swipe right (like)
  Future<void> swipeRight(String userId) async {
    try {
      bool isMatch = await _firestoreService.recordSwipe(userId, true);

      if (isMatch) {
        // If it's a match, load the matched user
        final matchedUser = await _firestoreService.getUserData(userId);
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
        }
      }

      // Remove from potential matches regardless of match result
      _potentialMatches.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      print('Error swiping right: $e');
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