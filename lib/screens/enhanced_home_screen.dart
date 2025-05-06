// lib/screens/enhanced_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../animations/modern_match_animation.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../widgets/enhanced_swipe_card.dart';
import '../widgets/components/loading_indicator.dart';
import '../screens/modern_chat_screen.dart';
import 'nearby_users_screen.dart';
import 'premium_screen.dart';
import 'boost_screen.dart';
import 'streak_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  _EnhancedHomeScreenState createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Load potential matches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<UserProvider>(context, listen: false).loadPotentialMatches();
    } catch (e) {
      print('Error loading matches: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSwipeLeft(String userId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      await Provider.of<UserProvider>(context, listen: false).swipeLeft(userId);
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _handleSuperLike(String userId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      await Provider.of<UserProvider>(context, listen: false).superLike(userId);

      // Show a star animation
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (ctx) => Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 2.0 * value,
                child: Opacity(
                  opacity: value > 0.8 ? 2.0 - value * 2 : value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              Navigator.of(ctx).pop();
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _handleSwipeRight(String userId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
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
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.whatshot,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'STILL',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          // Premium button
          IconButton(
            icon: const Icon(
              Icons.workspace_premium,
              color: Colors.amber,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PremiumScreen()),
              );
            },
            tooltip: 'Premium',
          ),

          // Nearby users button
          IconButton(
            icon: const Icon(
              Icons.location_on,
              color: AppColors.primary,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NearbyUsersScreen(),
                ),
              );
            },
            tooltip: 'Nearby',
          ),
        ],
        leading: IconButton(
          icon: const Icon(
            Icons.bolt,
            color: Colors.orange,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => BoostScreen()),
            );
          },
          tooltip: 'Boost',
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: LoadingIndicator(
          type: LoadingIndicatorType.pulse,
          size: LoadingIndicatorSize.large,
          color: AppColors.primary,
          message: 'Finding your matches...',
        ),
      )
          : Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          // Get profiles from provider
          List<User> profiles = userProvider.potentialMatches;

          // If no profiles are available, show empty state
          if (profiles.isEmpty) {
            return _buildEmptyState();
          }

          // Display swipe cards
          return Stack(
            children: [
              // Background decoration
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Swipe cards stack
              ...profiles.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;

                return Positioned.fill(
                  child: EnhancedSwipeCard(
                    user: user,
                    isTop: index == profiles.length - 1,
                    onSwipeLeft: () => _handleSwipeLeft(user.id),
                    onSwipeRight: () => _handleSwipeRight(user.id),
                    onSuperLike: () => _handleSuperLike(user.id),
                  ),
                );
              }).toList(),

              // Control buttons at the bottom for the top card
              if (profiles.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Dislike button
                        SwipeActionButton(
                          icon: Icons.close,
                          color: AppColors.error,
                          onTap: () => _handleSwipeLeft(profiles.last.id),
                          size: 64,
                        ),

                        // Super like button
                        SwipeActionButton(
                          icon: Icons.star,
                          color: Colors.blue,
                          onTap: () => _handleSuperLike(profiles.last.id),
                          isSuper: true,
                          size: 54,
                        ),

                        // Like button
                        SwipeActionButton(
                          icon: Icons.favorite,
                          color: AppColors.primary,
                          onTap: () => _handleSwipeRight(profiles.last.id),
                          size: 64,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
        onPressed: _loadMatches,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh matches',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No more profiles to show',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We\'re working on finding more matches for you. Check back later or adjust your preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                GradientButton(
                  text: 'Boost Your Profile',
                  icon: Icons.bolt,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => BoostScreen()),
                    );
                  },
                  isFullWidth: true,
                  gradientColors: [Colors.orange, AppColors.primary],
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Adjust Preferences',
                  icon: Icons.tune,
                  onPressed: () {
                    Navigator.of(context).pushNamed('/filters');
                  },
                  type: AppButtonType.outline,
                  isFullWidth: true,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: _loadMatches,
                  type: AppButtonType.text,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}