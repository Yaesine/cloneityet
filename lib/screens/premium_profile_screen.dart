// lib/screens/premium_profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../screens/modern_profile_edit_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/photo_manager_screen.dart';
import '../screens/profile_verification_screen.dart';
import '../widgets/components/blur_container.dart';
import '../widgets/components/animated_background.dart';
import '../widgets/components/glass_card.dart';
import '../widgets/components/neomorphic_container.dart';
import '../widgets/components/animated_progress_indicator.dart';

class PremiumProfileScreen extends StatefulWidget {
  const PremiumProfileScreen({Key? key}) : super(key: key);

  @override
  _PremiumProfileScreenState createState() => _PremiumProfileScreenState();
}

class _PremiumProfileScreenState extends State<PremiumProfileScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  int _profileCompletion = 0;
  bool _isScrolled = false;
  int _selectedPhotoIndex = 0;

  // Controllers for animations
  late AnimationController _profileCardController;
  late AnimationController _settingsCardController;
  late AnimationController _profileInfoController;
  late AnimationController _shimmerController;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Page controller for photos
  final PageController _photoPageController = PageController();

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _profileCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _settingsCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _profileInfoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Add scroll listener
    _scrollController.addListener(_onScroll);

    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _profileCardController.dispose();
    _settingsCardController.dispose();
    _profileInfoController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    _photoPageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser();

      if (mounted) {
        final user = userProvider.currentUser;

        // Calculate profile completion percentage
        if (user != null) {
          int completionScore = 0;

          // Check different profile elements and weight them
          if (user.imageUrls.isNotEmpty) completionScore += 15;  // Has profile picture
          if (user.imageUrls.length >= 3) completionScore += 15; // Has multiple pictures
          if (user.bio.isNotEmpty) completionScore += 10;        // Has some bio
          if (user.bio.length > 50) completionScore += 10;       // Has detailed bio
          if (user.interests.length >= 1) completionScore += 10; // Has some interests
          if (user.interests.length >= 3) completionScore += 10; // Has multiple interests
          if (user.location.isNotEmpty) completionScore += 10;   // Has location
          if (user.gender.isNotEmpty) completionScore += 10;     // Has gender
          if (user.lookingFor.isNotEmpty) completionScore += 10; // Has preferences

          setState(() {
            _profileCompletion = completionScore;
          });
        }

        setState(() {
          _isLoading = false;
        });

        // Start animations sequentially
        _profileCardController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          _profileInfoController.forward();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _settingsCardController.forward();
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: _isScrolled ? _buildScrolledAppBar() : null,
      body: _isLoading ? _buildLoadingView() :
      _errorMessage.isNotEmpty ? _buildErrorView() :
      _buildProfileContent(screenSize, statusBarHeight),
    );
  }

  PreferredSizeWidget _buildScrolledAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.currentUser;
          return user != null ? Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(
                  user.imageUrls.isNotEmpty ? user.imageUrls[0] : 'https://i.pravatar.cc/300?img=33',
                ),
              ),
              const SizedBox(width: 12),
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ) : const SizedBox();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pushNamed('/filters');
          },
        ),
      ],
    );
  }

  Widget _buildProfileContent(Size screenSize, double statusBarHeight) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        if (user == null) {
          return _buildNoUserView();
        }

        return Stack(
          children: [
            // Animated background
            AnimatedBackground(
              colors: const [
                Color(0xFFF8F9FA),
                Color(0xFFFEEBEF),
                Color(0xFFF8F9FA),
              ],
            ),

            // Main content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header section with profile images carousel
                SliverToBoxAdapter(
                  child: Container(
                    height: screenSize.height * 0.55,
                    width: screenSize.width,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Profile images carousel
                        _buildProfileImagesCarousel(user),

                        // Gradient overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Profile completion indicator
                        Positioned(
                          top: statusBarHeight + 16,
                          left: 16,
                          right: 16,
                          child: _buildProfileCompletionIndicator(),
                        ),

                        // User name and basic info
                        Positioned(
                          bottom: 24,
                          left: 24,
                          right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${user.name}, ${user.age}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black54,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.location,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black54,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Photo edit button
                        Positioned(
                          right: 24,
                          bottom: 24,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _profileCardController,
                              curve: Curves.easeOutBack,
                            )),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const PhotoManagerScreen(),
                                  ),
                                ).then((_) => _loadUserData());
                              },
                              child: NeomorphicContainer(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Page indicator
                        Positioned(
                          bottom: 80,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              user.imageUrls.isEmpty ? 1 : user.imageUrls.length,
                                  (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _selectedPhotoIndex == index ? 24 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _selectedPhotoIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile content cards
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Edit profile button
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _profileCardController,
                            curve: Curves.easeOutBack,
                          )),
                          child: _buildEditProfileButton(context),
                        ),

                        const SizedBox(height: 24),

                        // Bio section
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Curves.easeOut,
                            )),
                            child: _buildBioSection(user),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Interests section
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Interval(0.1, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Interval(0.1, 1.0, curve: Curves.easeOut),
                            )),
                            child: _buildInterestsSection(user),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Premium card
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Interval(0.2, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Interval(0.2, 1.0, curve: Curves.easeOut),
                            )),
                            child: _buildPremiumCard(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Verification card
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _profileInfoController,
                              curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                            )),
                            child: _buildVerificationCard(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Settings section
                        FadeTransition(
                          opacity: _settingsCardController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(_settingsCardController),
                            child: _buildSettingsSection(user),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImagesCarousel(User user) {
    return PageView.builder(
      controller: _photoPageController,
      onPageChanged: (index) {
        setState(() {
          _selectedPhotoIndex = index;
        });
      },
      itemCount: user.imageUrls.isEmpty ? 1 : user.imageUrls.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: user.imageUrls.isNotEmpty && index < user.imageUrls.length
              ? user.imageUrls[index]
              : 'https://i.pravatar.cc/300?img=33',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person, size: 60),
          ),
        );
      },
    );
  }

  Widget _buildProfileCompletionIndicator() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blur: 10,
      opacity: 0.7,
      borderRadius: 16,
      child: Row(
        children: [
          AnimatedProgressIndicator(
            value: _profileCompletion / 100,
            size: 36,
            color: _getCompletionColor(),
            backgroundColor: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Profile $_profileCompletion% Complete",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getCompletionMessage(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ModernProfileEditScreen(),
          ),
        ).then((_) => _loadUserData());
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        borderRadius: 24,
        blur: 15,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(User user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      blur: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 18,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModernProfileEditScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.bio.isNotEmpty ? user.bio : 'Add something about yourself...',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: user.bio.isNotEmpty ? Colors.black87 : Colors.black38,
            ),
          ),

          // Bio tip if needed
          if (user.bio.length < 50)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Profiles with detailed bios get up to 50% more matches!',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(User user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      blur: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.pink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Interests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 18,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModernProfileEditScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          user.interests.isNotEmpty
              ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          )
              : Center(
            child: Text(
              'Add your interests to help us find better matches',
              style: TextStyle(color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PremiumScreen()),
        );
      },
      child: Stack(
        children: [
          // Main card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade300,
                  Colors.amber.shade700,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Get Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'See who likes you & unlock premium features',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '5 Super Likes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '1 Boost',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Shine effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + 2.0 * _shimmerController.value, 0.0),
                      end: Alignment(1.0 + 2.0 * _shimmerController.value, 0.0),
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.4, 0.5, 0.6],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileVerificationScreen(),
          ),
        );
      },
      child: GlassCard(
        color: Colors.blue.withOpacity(0.05),
        blur: 5,
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verify Your Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get a blue checkmark and increase your matches',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            NeomorphicContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Verify',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildSettingsSection(User user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      blur: 15,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Discovery settings
          _buildSettingItem(
            title: 'Discovery Settings',
            subtitle: 'Distance, age range, looking for',
            icon: Icons.tune,
            color: Colors.purple,
            onTap: () {
              Navigator.of(context).pushNamed('/filters')
                  .then((_) => _loadUserData());
            },
          ),

          // Notifications
          _buildSettingItem(
            title: 'Notifications',
            subtitle: 'Manage your notifications',
            icon: Icons.notifications_none,
            color: Colors.orange,
            onTap: () {},
          ),

          // Privacy
          _buildSettingItem(
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            icon: Icons.lock_outline,
            color: Colors.green,
            onTap: () {},
          ),

          // Help & Support
          _buildSettingItem(
            title: 'Help & Support',
            subtitle: 'Contact us with any questions',
            icon: Icons.help_outline,
            color: Colors.blue,
            onTap: () {},
          ),

          // Logout
          _buildSettingItem(
            title: 'Logout',
            subtitle: 'Sign out of your account',
            icon: Icons.exit_to_app,
            color: AppColors.error,
            onTap: () async {
              try {
                await Provider.of<AppAuthProvider>(context, listen: false).logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging out: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: title == 'Logout' ? AppColors.error : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: title == 'Logout' ? AppColors.error.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: title == 'Logout' ? AppColors.error : Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F9FA),
                const Color(0xFFFEEBEF),
                const Color(0xFFF8F9FA),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading your profile...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F9FA),
                const Color(0xFFFEEBEF),
                const Color(0xFFF8F9FA),
              ],
            ),
          ),
        ),
        Center(
          child: GlassCard(
            blur: 20,
            padding: const EdgeInsets.all(24),
            borderRadius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                NeomorphicContainer(
                  child: InkWell(
                    onTap: _loadUserData,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Try Again',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoUserView() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F9FA),
                const Color(0xFFFEEBEF),
                const Color(0xFFF8F9FA),
              ],
            ),
          ),
        ),
        Center(
          child: GlassCard(
            blur: 20,
            padding: const EdgeInsets.all(32),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 80,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Profile Not Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your profile could not be loaded. Please create a profile to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                NeomorphicContainer(
                  child: InkWell(
                    onTap: () async {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      await userProvider.forceSyncCurrentUser();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Creating user profile...')),
                        );
                        _loadUserData();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Create Profile',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor() {
    if (_profileCompletion >= 80) return Colors.green;
    if (_profileCompletion >= 50) return Colors.amber;
    return AppColors.error;
  }

  String _getCompletionMessage() {
    if (_profileCompletion >= 80) return 'Your profile looks great!';
    if (_profileCompletion >= 50) return 'Keep improving your profile';
    return 'Complete your profile to get more matches';
  }
}