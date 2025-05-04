import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:new_tinder_clone/providers/message_provider.dart';
import 'package:new_tinder_clone/screens/achievements_screen.dart';
import 'package:new_tinder_clone/screens/boost_screen.dart';
import 'package:new_tinder_clone/screens/debug_screen.dart';
import 'package:new_tinder_clone/screens/modern_chat_screen.dart';
import 'package:new_tinder_clone/screens/modern_profile_screen.dart';
import 'package:new_tinder_clone/screens/nearby_users_screen.dart';
import 'package:new_tinder_clone/screens/premium_screen.dart';
import 'package:new_tinder_clone/screens/profile_verification_screen.dart';
import 'package:new_tinder_clone/screens/streak_screen.dart';
import 'package:new_tinder_clone/services/background_notification_handler.dart';
import 'package:new_tinder_clone/services/firestore_service.dart';
import 'package:new_tinder_clone/services/location_service.dart';
import 'package:new_tinder_clone/services/notification_manager.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notifications_service.dart';
import 'theme/app_theme.dart';
import 'screens/modern_home_screen.dart';
import 'screens/modern_profile_screen.dart';
import './widgets/notification_handler.dart';
import './utils/navigation.dart'; // Add this import

// Add these imports
import 'screens/photo_manager_screen.dart';
import 'screens/filters_screen.dart';
import 'providers/user_provider.dart';
import 'providers/app_auth_provider.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final notificationManager = NotificationManager();
  await notificationManager.initialize();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
// In main.dart after Firebase.initializeApp()
  final firestoreService = FirestoreService();
  await firestoreService.verifyFirestoreConnection();
  await firestoreService.createTestUsersIfNeeded();

  // Add debug print to confirm Firebase initialization
  print('Firebase initialized successfully');

  final notificationsService = NotificationsService();
  await notificationsService.initialize();

  // Initialize location services
  final locationService = LocationService();
// In main.dart

  // In main.dart, after Firebase initialization
  void ensureUserAuthenticated() async {
    try {
      final authProvider = FirebaseAuth.instance;
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        print('No user authenticated, attempting anonymous sign-in for testing');

        // For testing purposes, sign in anonymously
        final userCredential = await authProvider.signInAnonymously();
        print('Anonymous sign-in successful: ${userCredential.user?.uid}');

        // Create a basic profile for this anonymous user
        if (userCredential.user != null) {
          final firestoreService = FirestoreService();
          await firestoreService.createNewUser(
              userCredential.user!.uid,
              'Anonymous User',
              'anonymous@example.com'
          );
        }
      } else {
        print('User already authenticated: ${currentUser.uid}');
      }
    } catch (e) {
      print('ERROR during authentication check: $e');
    }
  }

// Call this function after Firebase initialization
  ensureUserAuthenticated();

  runApp(const MyApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const SplashScreen(); // Show splash while checking auth
        }

        if (authProvider.isLoggedIn) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// In your main.dart
// In your main.dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(  // Wrap with MultiProvider
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
    child: NotificationHandler(  // Wrap with NotificationHandler
      child: MaterialApp(
        navigatorKey: navigatorKey, // This will now work
        title: 'Flutter Tinder Clone',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),  // Changed from SplashScreen
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
          '/chat': (context) => const ModernChatScreen(),
          '/photoManager': (context) => const PhotoManagerScreen(),
          '/filters': (context) => const FiltersScreen(),
          '/debug': (context) => const DebugScreen(),

          // Add these new routes
          '/boost': (context) => BoostScreen(),
          '/premium': (context) => PremiumScreen(),
          '/achievements': (context) => AchievementsScreen(
            unlockedBadges: [], // You'll need to fetch these
            availableBadges: [], // You'll need to fetch these
          ),
          '/streak': (context) => StreakScreen(
            streakCount: 0, // You'll need to fetch this
            rewindCount: 1, // Daily rewind count
            superLikeCount: 1, // Daily super likes
          ),
          '/verification': (context) => ProfileVerificationScreen(),
        },
    ),
    ), // This closing parenthesis was missing
    );
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ModernHomeScreen(), // Replace HomeScreen with ModernHomeScreen
    const MatchesScreen(),
    const ModernProfileScreen(),
  ];

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Load user data and update location when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeNotificationHandler();

      final notificationManager = NotificationManager();
      await notificationManager.initialize();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.forceSyncCurrentUser();
      await userProvider.loadCurrentUser();

      // Get current user ID
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final userId = authProvider.currentUserId;

      if (userId.isNotEmpty) {
        // Update user location
        final locationService = LocationService();
        await locationService.updateUserLocation(userId);
      }

      // Load potential matches and matches
      await userProvider.loadPotentialMatches();
      await userProvider.loadMatches();

      // Start listening to match updates
      userProvider.startMatchesStream();
    });
  }

  void _initializeNotificationHandler() {
    // FCM token handling
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('FCM Token: $token');
      _saveTokenToFirestore(token);
    });

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showInAppNotification(message);
    });
  }

  void _showInAppNotification(RemoteMessage message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
            label: 'Swipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}