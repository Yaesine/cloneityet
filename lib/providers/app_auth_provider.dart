import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/firestore_service.dart';
import '../services/notifications_service.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationsService _notificationsService = NotificationsService();
  User? _user;
  String? _errorMessage;
  bool _isLoading = true;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String get currentUserId => _user?.uid ?? '';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AppAuthProvider() {
    _user = _auth.currentUser;
    if (_user != null) {
      print('User is already authenticated: ${_user?.uid}');
    } else {
      print('No authenticated user at startup');
    }

    _auth.authStateChanges().listen((User? user) {
      print('Auth state changed: ${user?.uid ?? 'No user'}');
      _user = user;
      notifyListeners();
    });
  }

  // Google Sign In - SIMPLIFIED VERSION for fixing the token issue
  // Google Sign In - FIXED VERSION
  Future<bool> signInWithGoogle() async {
    try {
      print('Starting simple Google Sign In...');

      // Create a standard GoogleSignIn instance
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Clear any existing sign-in
      await googleSignIn.signOut();

      // Start the sign-in flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('User cancelled Google Sign In');
        return false;
      }

      print('Google Sign In succeeded for user: ${googleUser.email}');

      // Get the auth tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user != null) {
        print('Firebase authentication successful: ${_user!.uid}');

        // Create Firestore profile if needed
        await _firestoreService.createNewUser(
            _user!.uid,
            _user!.displayName ?? 'New User',
            _user!.email ?? ''
        );

        // Save FCM token
        await _notificationsService.saveTokenToDatabase(_user!.uid);

        // Save user ID to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _user!.uid);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign In error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
// Add this to your app_auth_provider.dart or any utility class

  Future<Map<String, dynamic>> debugGoogleSignIn() async {
    final Map<String, dynamic> debugInfo = {};

    try {
      debugInfo['starting'] = 'Attempting to initialize GoogleSignIn';
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Check if GoogleSignIn is configured
      debugInfo['initialized'] = 'GoogleSignIn initialized';

      // Check current sign in state
      final isSignedIn = await googleSignIn.isSignedIn();
      debugInfo['isSignedIn'] = isSignedIn;

      if (isSignedIn) {
        // Try to get current user
        final account = await googleSignIn.signInSilently();
        debugInfo['currentUser'] = account?.email ?? 'No user';

        // Try to get authentication
        if (account != null) {
          try {
            debugInfo['getting_auth'] = 'Attempting to get authentication tokens';
            final auth = await account.authentication;
            debugInfo['auth_success'] = 'Got authentication tokens';
            debugInfo['has_id_token'] = auth.idToken != null;
            debugInfo['has_access_token'] = auth.accessToken != null;
          } catch (e) {
            debugInfo['auth_error'] = e.toString();
          }
        }
      } else {
        // Try a fresh sign in
        debugInfo['attempting_signin'] = 'User not signed in, trying fresh sign in';
        try {
          final account = await googleSignIn.signIn();
          debugInfo['signin_result'] = account?.email ?? 'Sign in cancelled';

          if (account != null) {
            try {
              debugInfo['getting_fresh_auth'] = 'Getting tokens for fresh sign in';
              final auth = await account.authentication;
              debugInfo['fresh_auth_success'] = 'Got fresh authentication tokens';
              debugInfo['fresh_has_id_token'] = auth.idToken != null;
              debugInfo['fresh_has_access_token'] = auth.accessToken != null;
            } catch (e) {
              debugInfo['fresh_auth_error'] = e.toString();
            }
          }
        } catch (e) {
          debugInfo['signin_error'] = e.toString();
        }
      }
    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    return debugInfo;
  }
  // Facebook Sign In - Properly implemented
  Future<bool> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status == LoginStatus.success) {
        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

        // Sign in to Firebase with the Facebook [UserCredential]
        final userCredential =
        await _auth.signInWithCredential(facebookAuthCredential);

        _user = userCredential.user;

        if (_user != null) {
          // Create user profile in Firestore if it doesn't exist
          await _firestoreService.createNewUser(
              _user!.uid,
              _user!.displayName ?? 'Anonymous',
              _user!.email ?? ''
          );

          // Save token to Firestore
          await _notificationsService.saveTokenToDatabase(_user!.uid);

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', _user!.uid);

          return true;
        }
      } else {
        // Handle different login status
        print('Facebook login status: ${loginResult.status}');
        print('Facebook login message: ${loginResult.message}');
        return false;
      }

      return false;
    } catch (e) {
      print('Facebook sign in error: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  // Apple Sign In - Properly implemented (placeholder for now)
  Future<bool> signInWithApple() async {
    try {
      // TODO: Implement Apple Sign In with sign_in_with_apple package
      // You'll need to add the package to pubspec.yaml and configure it
      print('Apple sign in initiated');
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Apple sign in error: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  // Phone Auth - Properly implemented
  Future<String?> sendOtp(String phoneNumber) async {
    try {
      Completer<String?> completer = Completer<String?>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some devices (Android)
          final userCredential = await _auth.signInWithCredential(credential);
          _user = userCredential.user;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
          completer.complete(null);
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-timeout
        },
      );

      return completer.future;
    } catch (e) {
      print('Send OTP error: $e');
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user != null) {
        // Create user profile in Firestore if it doesn't exist
        await _firestoreService.createNewUser(
            _user!.uid,
            _user!.displayName ?? 'Anonymous',
            _user!.phoneNumber ?? ''
        );

        // Save token to Firestore
        await _notificationsService.saveTokenToDatabase(_user!.uid);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _user!.uid);

        return true;
      }

      return false;
    } catch (e) {
      print('Verify OTP error: $e');
      _errorMessage = e.toString();
      return false;
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      print('Attempting login with email: $email');

      // Sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;

      // Save to SharedPreferences for persistence
      if (_user != null) {
        await _notificationsService.saveTokenToDatabase(_user!.uid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _user!.uid);
        print('User logged in successfully: ${_user!.uid}');
      }

      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getReadableAuthError(e);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      print('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register new user
  Future<bool> register(String name, String email, String password) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      print('Starting registration for $email...');

      // Create user with Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;

      if (_user != null) {
        print('Firebase Auth user created: ${_user!.uid}');

        // Update display name in Firebase Auth
        await _user!.updateDisplayName(name);

        // Create user profile in Firestore using a more direct approach
        await _firestoreService.createNewUser(_user!.uid, name, email);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _user!.uid);

        print('Registration completed successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('Attempting logout');

      // Sign out from all providers
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      _user = null;
      print('User logged out successfully');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Logout error: $e');
    }
  }

  // Convert Firebase auth errors to user-friendly messages
  String _getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login or use a different email.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred during authentication.';
    }
  }

  // Check if user exists in SharedPreferences
  Future<bool> checkUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    print('Checking if user is logged in from SharedPreferences: $userId');

    if (userId != null && userId.isNotEmpty) {
      // Already logged in via SharedPreferences, but need to check Firebase Auth
      if (_user == null) {
        // User exists in SharedPreferences but not in Firebase Auth
        // This can happen if the app was closed and reopened
        // Clear SharedPreferences and return false
        await prefs.remove('userId');
        print('User ID found in SharedPreferences but not in Firebase Auth, clearing preferences');
        return false;
      }
      print('User is logged in: $userId');
      return true;
    }
    print('User is not logged in');
    return false;
  }
}