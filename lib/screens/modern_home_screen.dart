import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../animations/modern_match_animation.dart';
import '../utils/custom_page_route.dart';
import '../widgets/modern_swipe_card.dart';
import '../screens/nearby_users_screen.dart';
import 'modern_chat_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({Key? key}) : super(key: key);

  @override
  _ModernHomeScreenState createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
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
              return ModernMatchAnimation(
                currentUser: currentUser,
                matchedUser: matchedUser,
                onDismiss: () {
                  Navigator.of(context).pop();
                },
                onSendMessage: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ModernChatScreen(),
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
          children: [
            Icon(Icons.whatshot, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('SwipeMatch'),
          ],
        ),
        actions: [
          // Add nearby users button
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
          // Display swipe cards
          return Stack(
            children: [
              // Stack of swipe cards
              ...profiles.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;

                return Positioned.fill(
                  child: ModernSwipeCard(
                    user: user,
                    isTop: index == profiles.length - 1,
                    onSwipeLeft: () => _handleSwipeLeft(user.id),
                    onSwipeRight: () => _handleSwipeRight(user.id),
                    onSuperLike: () => _handleSuperLike(user.id),
                  ),
                );
              }).toList(),

              // Control buttons at the bottom - improved positioning
              if (profiles.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Dislike button
                        _buildActionButton(
                          Icons.close,
                          Colors.red,
                              () => _handleSwipeLeft(profiles.last.id),
                          size: 28,
                        ),

                        // Super like button
                        _buildActionButton(
                          Icons.star,
                          Colors.blue,
                              () => _handleSuperLike(profiles.last.id),
                          size: 32,
                          hasBorder: true,
                        ),

                        // Like button
                        _buildActionButton(
                          Icons.favorite,
                          Colors.green,
                              () => _handleSwipeRight(profiles.last.id),
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon,
      Color color,
      VoidCallback onTap, {
        double size = 24,
        bool hasBorder = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: hasBorder ? Border.all(color: color, width: 2) : null,
          ),
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        ),
      ),
    );
  }
}