import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../animations/match_animation.dart';
import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/custom_page_route.dart';
import '../widgets/swipe_card.dart';
import '../models/user_model.dart';
import '../data/dummy_data.dart';
import '../screens/nearby_users_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load potential matches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadPotentialMatches();
    });
  }

  void _handleSwipeLeft(String userId) {
    Provider.of<UserProvider>(context, listen: false).swipeLeft(userId);
  }

  void _handleSuperLike(String userId) {
    Provider.of<UserProvider>(context, listen: false).superLike(userId);
  }

  void _handleSwipeRight(String userId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final User? matchedUser = await userProvider.swipeRight(userId);

    // Show match animation if there's a match
    if (matchedUser != null && mounted) {
      // Get current user
      final currentUser = userProvider.currentUser;

      if (currentUser != null) {
        // Show match animation
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return MatchAnimation(
                currentUser: currentUser,
                matchedUser: matchedUser,
                onDismiss: () {
                  Navigator.of(context).pop();
                },
                onSendMessage: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    CustomPageRoute(
                      child: const ChatScreen(),
                      settings: RouteSettings(arguments: matchedUser),
                    ),
                  );
                },
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.whatshot, color: Colors.red),
            SizedBox(width: 8),
            Text('Tinder Clone'),
          ],
        ),
        actions: [
          // Add nearby button in the app bar
          IconButton(
            icon: const Icon(Icons.location_on),
            color: Colors.red,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NearbyUsersScreen(),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get profiles from provider
          List<User> profiles = userProvider.potentialMatches;

          print('Current user ID: ${Provider.of<AppAuthProvider>(context, listen: false).currentUserId}');
          print('Number of potential matches: ${profiles.length}');

          // If no profiles are available, show empty state
          if (profiles.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No more profiles to show',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new matches',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Display swipe cards
          return Stack(
            children: profiles.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;

              return Positioned.fill(
                child: SwipeCard(
                  user: user,
                  isTop: index == profiles.length - 1,
                  onSwipeLeft: () => _handleSwipeLeft(user.id),
                  onSwipeRight: () => _handleSwipeRight(user.id),
                  onSuperLike: () => _handleSuperLike(user.id),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}