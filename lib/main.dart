import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:new_tinder_clone/providers/message_provider.dart';
import 'package:new_tinder_clone/screens/achievements_screen.dart';
import 'package:new_tinder_clone/screens/boost_screen.dart';
import 'package:new_tinder_clone/screens/debug_screen.dart';
import 'package:new_tinder_clone/screens/modern_chat_screen.dart';
import 'package:new_tinder_clone/screens/modern_profile_screen.dart';
import 'package:new_tinder_clone/screens/nearby_users_screen.dart';
import 'package:new_tinder_clone/screens/phone_login_screen.dart';
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

// Remove this top-level function completely - we'll handle it differently
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Firebase.initializeApp();
//   print('Handling a background message: ${message.messageId}');
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Facebook SDK
  await FacebookAuth.instance.webAndDesktopInitialize(
    appId: "YOUR_FACEBOOK_APP_ID", // Replace with your Facebook App ID
    cookie: true,
    xfbml: true,
    version: "v15.0",
  );

  // Initialize notification manager after Firebase is initialized
  final notificationManager = NotificationManager();
  await notificationManager.initialize();

  // Initialize Firebase services
  final firestoreService = FirestoreService();
  await firestoreService.verifyFirestoreConnection();
  await firestoreService.createTestUsersIfNeeded();

  print('Firebase initialized successfully');

  final notificationsService = NotificationsService();
  await notificationsService.initialize();

  // Initialize location services
  final locationService = LocationService();

  // Ensure user authenticated
  void ensureUserAuthenticated() async {
    try {
      final authProvider = FirebaseAuth.instance;
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        print('No user authenticated, attempting anonymous sign-in for testing');
        final userCredential = await authProvider.signInAnonymously();
        print('Anonymous sign-in successful: ${userCredential.user?.uid}');

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

  ensureUserAuthenticated();

  runApp(const MyApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, _) {
        // Always show splash screen first, then navigate based on auth state
        return const SplashScreen();
      },
    );
  }
}

// In your main.dart file, update the MyApp widget:

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: NotificationHandler(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter Tinder Clone',
          theme: AppTheme.lightTheme.copyWith(
            scaffoldBackgroundColor: const Color(0xFFFF4458), // Add this
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/phone-login': (context) => const PhoneLoginScreen(),
            '/main': (context) => const MainScreen(),
            '/chat': (context) => const ModernChatScreen(),
            '/photoManager': (context) => const PhotoManagerScreen(),
            '/filters': (context) => const FiltersScreen(),
            '/debug': (context) => const DebugScreen(),
            '/boost': (context) => BoostScreen(),
            '/premium': (context) => PremiumScreen(),
            '/achievements': (context) => AchievementsScreen(
              unlockedBadges: [],
              availableBadges: [],
            ),
            '/streak': (context) => StreakScreen(
              streakCount: 0,
              rewindCount: 1,
              superLikeCount: 1,
            ),
            '/verification': (context) => ProfileVerificationScreen(),
          },
        ),
      ),
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
    const ModernHomeScreen(),
    const MatchesScreen(),
    const ModernProfileScreen(),
  ];

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeNotificationHandler();

      final notificationManager = NotificationManager();
      await notificationManager.initialize();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.forceSyncCurrentUser();
      await userProvider.loadCurrentUser();

      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final userId = authProvider.currentUserId;

      if (userId.isNotEmpty) {
        final locationService = LocationService();
        await locationService.updateUserLocation(userId);
      }

      await userProvider.loadPotentialMatches();
      await userProvider.loadMatches();
      userProvider.startMatchesStream();
    });
  }

  void _initializeNotificationHandler() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('FCM Token: $token');
      _saveTokenToFirestore(token);
    });

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