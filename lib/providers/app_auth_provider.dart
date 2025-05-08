// lib/providers/app_auth_provider.dart - Updated Version
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  // Facebook Sign In - Properly implemented
  Future<bool> signInWithFacebook() async {
    try {
      print('Starting Facebook login process...');

      // Clear any existing login state
      await FacebookAuth.instance.logOut();
      print('Previous Facebook sessions cleared');

      // Use a more flexible login behavior instead of webOnly
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback, // This tries native app first, then falls back to dialog/web
      );

      print('Facebook login status: ${loginResult.status}');
      print('Facebook login message: ${loginResult.message}');

      if (loginResult.status == LoginStatus.success) {
        // Get user data for better profile creation
        final userData = await FacebookAuth.instance.getUserData();
        print('Facebook user data retrieved: ${userData['name']}');

        if (loginResult.accessToken == null) {
          print('Error: Facebook login successful but no access token received');
          _errorMessage = 'Authentication error: No access token received';
          notifyListeners();
          return false;
        }

        print('Access token received, length: ${loginResult.accessToken!.token.length}');

        // Create Firebase credential
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

        // Sign in to Firebase
        final userCredential = await _auth.signInWithCredential(facebookAuthCredential);
        _user = userCredential.user;

        if (_user != null) {
          print('Firebase authenticated user: ${_user!.uid}');

          // Create user profile in Firestore
          await _firestoreService.createNewUser(
              _user!.uid,
              _user!.displayName ?? userData['name'] ?? 'New User',
              _user!.email ?? userData['email'] ?? ''
          );

          // Save token to Firestore
          await _notificationsService.saveTokenToDatabase(_user!.uid);

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', _user!.uid);

          notifyListeners();
          return true;
        }

        print('Firebase authentication failed after successful Facebook login');
        _errorMessage = 'Firebase authentication failed';
        notifyListeners();
        return false;

      } else if (loginResult.status == LoginStatus.cancelled) {
        print('User cancelled Facebook login');
        _errorMessage = 'Login cancelled';
        notifyListeners();
        return false;
      } else {
        print('Facebook login failed: ${loginResult.message}');
        _errorMessage = loginResult.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Facebook sign in error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Apple Sign In - Properly implemented (placeholder for now)
  Future<bool> signInWithApple() async {
    try {
      // TODO: Implement Apple Sign In with sign_in_with_apple package
      // You'll need to add the package to pubspec.yaml and configure it
      print('Apple sign in initiated');
      _errorMessage = "Apple Sign In is not yet fully implemented";
      notifyListeners();
      return false;
    } catch (e) {
      print('Apple sign in error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Phone Auth - Enhanced to support WhatsApp OTP
  Future<String?> sendOtp(String phoneNumber, {bool useWhatsApp = false}) async {
    try {
      _errorMessage = null;
      notifyListeners();

      // Log the phone verification attempt
      print('Sending OTP to $phoneNumber via ${useWhatsApp ? "WhatsApp" : "SMS"}');

      if (useWhatsApp) {
        // Note: This is a simulated WhatsApp OTP implementation
        // In a real app, you would need to use an actual WhatsApp Business API service
        // or a third-party provider like Twilio that supports WhatsApp

        // Simulate WhatsApp OTP for demonstration purposes
        // In reality, you would call your backend or a 3rd party API here
        final simulatedOtp = '123456';
        print('Simulated WhatsApp OTP: $simulatedOtp');

        // Return a dummy verification ID
        // In a real implementation, you would still use Firebase Auth or a similar verification system
        return 'whatsapp-verification-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Regular Firebase Phone Auth
        Completer<String?> completer = Completer<String?>();

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification on some devices (Android)
            try {
              final userCredential = await _auth.signInWithCredential(credential);
              _user = userCredential.user;

              if (_user != null && !completer.isCompleted) {
                completer.complete('auto-verified');
              }
              notifyListeners();
            } catch (e) {
              if (!completer.isCompleted) {
                completer.complete(null);
              }
              _errorMessage = e.toString();
              notifyListeners();
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            print('Phone verification failed: ${e.message}');
            _errorMessage = e.message;
            notifyListeners();
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            print('SMS code sent to $phoneNumber, verification ID: $verificationId');
            if (!completer.isCompleted) {
              completer.complete(verificationId);
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Auto-timeout
            print('Phone verification auto-retrieval timeout');
            if (!completer.isCompleted) {
              completer.complete(verificationId);
            }
          },
        );

        return completer.future;
      }
    } catch (e) {
      print('Send OTP error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      _errorMessage = null;
      notifyListeners();

      print('Verifying OTP: verification ID=$verificationId, OTP=$otp');

      // Check if it's a simulated WhatsApp verification
      if (verificationId.startsWith('whatsapp-verification-')) {
        // For our simulated WhatsApp implementation, accept any 6-digit code
        // In a real app, you would verify this with your backend or 3rd party service
        if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
          print('Simulated WhatsApp OTP verification successful');

          // Create a random anonymous user account in Firebase
          final userCredential = await _auth.signInAnonymously();
          _user = userCredential.user;

          if (_user != null) {
            // Update the user profile in Firestore
            await _firestoreService.createNewUser(
                _user!.uid,
                'WhatsApp User',
                ''
            );

            // Save FCM token
            await _notificationsService.saveTokenToDatabase(_user!.uid);

            // Save to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', _user!.uid);

            notifyListeners();
            return true;
          }
          return false;
        } else {
          print('Invalid OTP format for WhatsApp verification');
          _errorMessage = 'Invalid verification code';
          notifyListeners();
          return false;
        }
      } else {
        // Regular Firebase OTP verification
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
              _user!.displayName ?? 'Phone User',
              _user!.phoneNumber ?? ''
          );

          // Save token to Firestore
          await _notificationsService.saveTokenToDatabase(_user!.uid);

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', _user!.uid);

          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Verify OTP error: $e');
      _errorMessage = e.toString();
      notifyListeners();
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

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getReadableAuthError(e);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
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
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getReadableAuthError(e);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Registration error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
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
      notifyListeners();
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
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please request a new code.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
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