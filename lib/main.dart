import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_tinder_clone/screens/debug_screen.dart';
import 'package:new_tinder_clone/screens/modern_chat_screen.dart';
import 'package:new_tinder_clone/screens/modern_profile_screen.dart';
import 'package:new_tinder_clone/screens/nearby_users_screen.dart';
import 'package:new_tinder_clone/services/firestore_service.dart';
import 'package:new_tinder_clone/services/location_service.dart';
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

// Add these imports
import 'screens/photo_manager_screen.dart';
import 'screens/filters_screen.dart';
import 'providers/user_provider.dart';
import 'providers/app_auth_provider.dart';
import 'package:flutter/cupertino.dart';

void main() async {
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



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Tinder Clone',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
          '/chat': (context) => const ModernChatScreen(),
          '/photoManager': (context) => const PhotoManagerScreen(),
          '/filters': (context) => const FiltersScreen(),
          '/debug': (context) => const DebugScreen(), // Add this line
        },
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