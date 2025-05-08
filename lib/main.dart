// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:new_tinder_clone/screens/TinderStyleProfileScreen.dart';
import 'package:new_tinder_clone/screens/email_login_screen.dart';
import 'package:new_tinder_clone/screens/likes_screen.dart';
import 'package:new_tinder_clone/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Providers
import 'providers/message_provider.dart';
import 'providers/user_provider.dart';
import 'providers/app_auth_provider.dart';

// Services
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'services/notification_manager.dart';
import 'services/notifications_service.dart';

// Screens
import 'screens/enhanced_home_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/enhanced_profile_screen.dart';
import 'screens/enhanced_chat_screen.dart';
import 'screens/modern_login_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/photo_manager_screen.dart';
import 'screens/boost_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/nearby_users_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/profile_verification_screen.dart';

// Theme
import 'theme/app_theme.dart';

// Utils
import 'utils/navigation.dart';
import 'widgets/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notification manager after Firebase is initialized
  final notificationManager = NotificationManager();
  await notificationManager.initialize();

  // Initialize Firebase services
  final firestoreService = FirestoreService();
  await firestoreService.verifyFirestoreConnection();
  await firestoreService.createTestUsersIfNeeded();

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
        print('No user authenticated. Launching app without authentication.');
        return;
      } else {
        print('User already authenticated: ${currentUser.uid}');

        // Check if user exists in Firestore
        final firestoreService = FirestoreService();
        final existingUser = await firestoreService.getUserData(currentUser.uid);

        if (existingUser == null) {
          print('Creating user profile in Firestore');
          await firestoreService.createNewUser(
              currentUser.uid,
              currentUser.displayName ?? 'User',
              currentUser.email ?? ''
          );
        }
      }
    } catch (e) {
      print('ERROR during authentication check: $e');
      if (e.toString().contains('admin-restricted-operation')) {
        print('Anonymous authentication is disabled. Please enable it in Firebase Console.');
      }
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
          title: 'STILL - Dating App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const ModernLoginScreen(),
            '/phone-login': (context) => const PhoneLoginScreen(),
            '/main': (context) => const MainScreen(),
            '/chat': (context) => const EnhancedChatScreen(),
            '/photoManager': (context) => const PhotoManagerScreen(),
            '/filters': (context) => const FiltersScreen(),
            '/boost': (context) => BoostScreen(),
            '/premium': (context) => PremiumScreen(),
            '/modernProfile': (context) => TinderStyleProfileScreen(), // Add this new route
            '/email-login': (context) => const EmailLoginScreen(),
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
// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const EnhancedHomeScreen(),
    const LikesScreen(),  // Add the new LikesScreen here
    const MatchesScreen(),
    const TinderStyleProfileScreen(),
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

      // Load the new likes and visitors data
      await userProvider.loadUsersWhoLikedMe();
      await userProvider.loadProfileVisitors();

      // Start all streams
      userProvider.startMatchesStream();
      userProvider.startVisitorsAndLikesStreams();
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
            child: const Text('OK'),
          ),
          if (message.data['type'] != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleNotificationAction(message);
              },
              child: const Text('View', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  void _handleNotificationAction(RemoteMessage message) {
    final type = message.data['type'];

    // Navigate based on notification type
    switch (type) {
      case 'match':
        setState(() {
          _currentIndex = 2; // Switch to Matches tab
        });
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case 'super_like':
      case 'profile_view':
        setState(() {
          _currentIndex = 1; // Switch to Likes tab
        });
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case 'message':
      // Navigate to the chat screen if a specific user is referenced
        if (message.data['senderId'] != null) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);

          // Find the matched user by ID
          for (final user in userProvider.matchedUsers) {
            if (user.id == message.data['senderId']) {
              Navigator.of(context).pushNamed('/chat', arguments: user);
              return;
            }
          }
        } else {
          // Otherwise just go to matches tab
          setState(() {
            _currentIndex = 2; // Switch to Matches tab
          });
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        break;
      default:
      // Default to the home tab
        setState(() {
          _currentIndex = 0;
        });
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
    }
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
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
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          backgroundColor: Colors.white,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Likes',
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
      ),
    );
  }
}