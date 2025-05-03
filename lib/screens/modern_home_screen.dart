// lib/screens/modern_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../animations/match_animation.dart';
import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/custom_page_route.dart';
import '../widgets/modern_swipe_card.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../screens/chat_screen.dart';
import '../screens/nearby_users_screen.dart';
import 'modern_chat_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({Key? key}) : super(key: key);

  @override
  _ModernHomeScreenState createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();

    // Animation controller for FAB menu
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Load potential matches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadPotentialMatches();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
      if (_isFabMenuOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
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
                      child: const ModernChatScreen(),
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
    // FAB animations
    final Animation<double> _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fabAnimationController);

    final Animation<double> _fabRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(_fabAnimationController);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://i.pravatar.cc/300?img=33', // Replace with your logo
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 8),
            const Text(
              'datemate',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          // Add nearby button in the app bar
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.location_on),
              color: AppColors.primary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NearbyUsersScreen(),
                  ),
                );
              },
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Finding your perfect matches...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Get profiles from provider
          List<User> profiles = userProvider.potentialMatches;

          // If no profiles are available, show empty state
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No more profiles to show',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Try adjusting your discovery preferences or check back later for new potential matches',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {
                      userProvider.loadPotentialMatches();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          // Display swipe cards
          return Stack(
            children: [
              // Swipe cards
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

              // Action buttons - positioned at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Dislike button
                        _buildActionButton(
                          Icons.close_rounded,
                          AppColors.primaryLight,
                          AppColors.primary,
                              () {
                            if (profiles.isNotEmpty) {
                              _handleSwipeLeft(profiles.last.id);
                            }
                          },
                          size: 28,
                        ),

                        // Super like button
                        _buildActionButton(
                          Icons.star_rounded,
                          AppColors.info,
                          const Color(0xFF1A76D2),
                              () {
                            if (profiles.isNotEmpty) {
                              _handleSuperLike(profiles.last.id);
                            }
                          },
                          size: 28,
                        ),

                        // Like button
                        _buildActionButton(
                          Icons.favorite_rounded,
                          AppColors.secondaryLight,
                          AppColors.secondary,
                              () {
                            if (profiles.isNotEmpty) {
                              _handleSwipeRight(profiles.last.id);
                            }
                          },
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // FAB menu
      floatingActionButton: _buildFabMenu(_fabScaleAnimation, _fabRotateAnimation),
    );
  }

  Widget _buildActionButton(
      IconData icon,
      Color bgColor,
      Color iconColor,
      VoidCallback onTap, {
        double size = 24,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size,
        ),
      ),
    );
  }

  Widget _buildFabMenu(Animation<double> scaleAnimation, Animation<double> rotateAnimation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subscription boost button
        ScaleTransition(
          scale: scaleAnimation,
          child: FloatingActionButton.small(
            heroTag: 'fab1',
            backgroundColor: Colors.purple,
            child: const Icon(Icons.bolt),
            onPressed: () {
              // Subscription prompt
              _showSubscriptionDialog();
            },
          ),
        ),
        const SizedBox(height: 12),

        // Rewind last swipe button
        ScaleTransition(
          scale: scaleAnimation,
          child: FloatingActionButton.small(
            heroTag: 'fab2',
            backgroundColor: Colors.amber,
            child: const Icon(Icons.replay),
            onPressed: () {
              // Show premium feature dialog
              _showPremiumFeatureDialog("Rewind", "Go back to profiles you accidentally passed on.");
            },
          ),
        ),
        const SizedBox(height: 12),

        // Main FAB
        FloatingActionButton(
          heroTag: 'mainFab',
          backgroundColor: AppColors.primary,
          child: AnimatedBuilder(
            animation: rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: rotateAnimation.value * 2 * 3.14159,
                child: Icon(
                  _isFabMenuOpen ? Icons.close : Icons.flash_on,
                  size: 28,
                ),
              );
            },
          ),
          onPressed: _toggleFabMenu,
        ),
      ],
    );
  }

  void _showSubscriptionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Get DateMate Plus',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Premium features cards
                    _buildFeatureCard(
                      'Unlimited Likes',
                      'Send as many likes as you want',
                      Icons.favorite_border,
                      Colors.pinkAccent,
                    ),
                    _buildFeatureCard(
                      'See Who Likes You',
                      'Match with them instantly',
                      Icons.visibility,
                      Colors.purpleAccent,
                    ),
                    _buildFeatureCard(
                      'Priority Likes',
                      'Get seen faster',
                      Icons.star_border,
                      Colors.amberAccent,
                    ),
                    _buildFeatureCard(
                      '5 Super Likes Per Day',
                      'You\'re 3x more likely to match',
                      Icons.bolt,
                      Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    // Plans
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildPlanOption('1 month', '\$19.99', false),
                          const Divider(),
                          _buildPlanOption('6 months', '\$59.99 (\$10/mo)', false),
                          const Divider(),
                          _buildPlanOption('12 months', '\$89.99 (\$7.50/mo)', true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'No Thanks',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String duration, String price, bool bestValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (bestValue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BEST VALUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          Radio(
            value: bestValue,
            groupValue: true,
            activeColor: AppColors.primary,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  void _showPremiumFeatureDialog(String feature, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock $feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(description),
            const SizedBox(height: 16),
            const Text(
              'This is a premium feature available with DateMate Plus subscription.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSubscriptionDialog();
            },
            child: const Text('See Plans'),
          ),
        ],
      ),
    );
  }
}