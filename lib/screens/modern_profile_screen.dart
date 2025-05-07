import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:new_tinder_clone/widgets/components/blur_container.dart';
import 'package:new_tinder_clone/widgets/components/glass_card.dart';
import 'package:new_tinder_clone/widgets/components/neomorphic_container.dart';
import 'package:new_tinder_clone/widgets/components/animated_background.dart';
import 'package:new_tinder_clone/widgets/components/animated_progress_indicator.dart';
import 'package:new_tinder_clone/providers/user_provider.dart';
import 'package:new_tinder_clone/providers/app_auth_provider.dart';
import 'package:new_tinder_clone/theme/app_theme.dart';
import 'package:new_tinder_clone/models/user_model.dart';

class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({Key? key}) : super(key: key);

  @override
  _ModernProfileScreenState createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  int _profileCompletion = 0;
  int _selectedTabIndex = 0;
  int _currentPhotoIndex = 0;
  bool _showEditOptions = false;

  // Controllers for animations
  late TabController _tabController;
  late AnimationController _rippleController;
  late AnimationController _fadeController;
  late AnimationController _carouselController;
  late PageController _photoPageController;

  final List<String> _tabs = ['Profile', 'Photos', 'Settings'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _carouselController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _photoPageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );

    _photoPageController.addListener(() {
      final page = _photoPageController.page?.round() ?? 0;
      if (page != _currentPhotoIndex) {
        setState(() {
          _currentPhotoIndex = page;
        });
      }
    });

    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rippleController.dispose();
    _fadeController.dispose();
    _carouselController.dispose();
    _photoPageController.dispose();
    super.dispose();
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
          if (user.imageUrls.isNotEmpty) completionScore += 20;
          if (user.bio.length > 20) completionScore += 20;
          if (user.interests.length >= 3) completionScore += 20;
          if (user.location.isNotEmpty) completionScore += 20;
          if (user.gender.isNotEmpty && user.lookingFor.isNotEmpty) completionScore += 20;

          setState(() {
            _profileCompletion = completionScore;
            _isLoading = false;
          });

          // Start animations
          _fadeController.forward();
          _rippleController.forward();
        }
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
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showEditOptions ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showEditOptions = !_showEditOptions;
              });
              if (_showEditOptions) {
                _rippleController.forward(from: 0);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.currentUser;
          if (user == null) {
            return _buildNoUserView();
          }

          return Stack(
            children: [
              // Beautiful animated background
              AnimatedBackground(
                colors: const [
                  Color(0xFF6A11CB),
                  Color(0xFFFE4A97),
                  Color(0xFF006EFF),
                ],
                speed: 0.5,
              ),

              // Main content
              Column(
                children: [
                  // Top profile section
                  _buildProfileHeader(user, size, statusBarHeight),

                  // Custom tab bar
                  _buildTabBar(),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildProfileTab(user),
                        _buildPhotosTab(user),
                        _buildSettingsTab(user),
                      ],
                    ),
                  ),
                ],
              ),

              // Edit options overlay
              if (_showEditOptions)
                _buildEditOptions(size),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user, Size size, double statusBarHeight) {
    return Container(
      height: size.height * 0.35,
      width: size.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Profile background image
          Hero(
            tag: 'profile_image',
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    user.imageUrls.isNotEmpty
                        ? user.imageUrls[0]
                        : 'https://i.pravatar.cc/300?img=33',
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // User info overlay at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and age with verification badge
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
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
                          color: Colors.blue.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location info
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
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Profile completion indicator
                  Row(
                    children: [
                      AnimatedProgressIndicator(
                        value: _profileCompletion / 100,
                        size: 36,
                        color: _getCompletionColor(),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        strokeWidth: 3,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Profile $_profileCompletion% Complete",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getCompletionMessage(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Add premium badge if completion is high
          if (_profileCompletion >= 80)
            Positioned(
              top: statusBarHeight + 20,
              right: 20,
              child: FadeTransition(
                opacity: _fadeController,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade300,
                        Colors.amber.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.2),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: _tabs.map((tab) {
            final index = _tabs.indexOf(tab);
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    index == 0
                        ? Icons.person
                        : index == 1
                        ? Icons.photo_library
                        : Icons.settings,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(tab),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileTab(User user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio section
          FadeTransition(
            opacity: _fadeController,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.bio.isNotEmpty
                        ? user.bio
                        : 'Add something about yourself...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Interests section
          FadeTransition(
            opacity: _fadeController,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Interests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  user.interests.isNotEmpty
                      ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) {
                      return BlurContainer(
                        blurAmount: 5,
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                      : Center(
                    child: Text(
                      'Add your interests to help us find better matches',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Premium card
          FadeTransition(
            opacity: _fadeController,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber.shade300,
                        Colors.amber.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 16,
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
                          Icons.diamond,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Unlock all features and get more matches',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            NeomorphicContainer(
                              borderRadius: 24,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Get Premium',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Shimmer effect
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ShimmerPainter(
                          animation: _rippleController,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Verification card
          FadeTransition(
            opacity: _fadeController,
            child: GlassCard(
              color: Colors.blue.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.blue,
                      size: 24,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get a blue checkmark and increase your matches',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeomorphicContainer(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.blue,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verify',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhotosTab(User user) {
    return Column(
      children: [
        // Photo carousel
        Expanded(
          child: PageView.builder(
            controller: _photoPageController,
            itemCount: user.imageUrls.isEmpty ? 1 : user.imageUrls.length,
            itemBuilder: (context, index) {
              final isActive = _currentPhotoIndex == index;

              return AnimatedScale(
                scale: isActive ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 24,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: user.imageUrls.isNotEmpty && index < user.imageUrls.length
                            ? user.imageUrls[index]
                            : 'https://i.pravatar.cc/300?img=33',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pagination indicator
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              user.imageUrls.isEmpty ? 1 : user.imageUrls.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPhotoIndex == index ? 20 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _currentPhotoIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),

        // Photo management buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.add_a_photo,
                label: 'Add',
                onTap: () {
                  // Navigate to photo upload screen
                },
              ),
              _buildActionButton(
                icon: Icons.star_border_outlined,
                label: 'Set as Main',
                onTap: () {
                  // Set current photo as main photo
                },
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Remove',
                onTap: () {
                  // Remove current photo
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(User user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discovery settings section
          FadeTransition(
            opacity: _fadeController,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discovery Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingRow(
                    'Age Range',
                    '${user.ageRangeStart} - ${user.ageRangeEnd}',
                    Icons.calendar_today,
                    Colors.amber,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSettingRow(
                    'Distance',
                    '${user.distance} km',
                    Icons.place,
                    Colors.green,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSettingRow(
                    'Looking For',
                    user.lookingFor.isNotEmpty ? user.lookingFor : 'Everyone',
                    Icons.person_search,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Account settings
          FadeTransition(
            opacity: _fadeController,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingRow(
                    'Notifications',
                    'Manage notifications',
                    Icons.notifications_none,
                    Colors.orange,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSettingRow(
                    'Privacy',
                    'Privacy settings',
                    Icons.lock_outline,
                    Colors.blue,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSettingRow(
                    'App Settings',
                    'Theme, language and more',
                    Icons.settings,
                    Colors.grey,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSettingRow(
                    'Help & Support',
                    'Get help',
                    Icons.help_outline,
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Logout button
          FadeTransition(
            opacity: _fadeController,
            child: BlurContainer(
              blurAmount: 10,
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: InkWell(
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
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.exit_to_app,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () {
          // Navigate to edit setting screen
          Navigator.of(context).pushNamed('/filters');
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      blur: 5,
      borderRadius: 20,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOptions(Size size) {
    return Stack(
      children: [
        // Background animation with ripple effect
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return CustomPaint(
              painter: RipplePainter(
                animation: _rippleController,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10 * _rippleController.value,
                  sigmaY: 10 * _rippleController.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _rippleController.value),
                ),
              ),
            );
          },
        ),

        // Edit option buttons
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEditOptionButton(
                label: 'Edit Profile',
                icon: Icons.edit,
                color: Colors.blue,
                onTap: () {
                  // Navigate to profile edit screen
                  setState(() {
                    _showEditOptions = false;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildEditOptionButton(
                label: 'Manage Photos',
                icon: Icons.photo_library,
                color: Colors.purple,
                onTap: () {
                  // Navigate to photo manager
                  setState(() {
                    _tabController.animateTo(1);
                    _showEditOptions = false;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildEditOptionButton(
                label: 'Edit Settings',
                icon: Icons.settings,
                color: Colors.amber,
                onTap: () {
                  // Navigate to settings
                  setState(() {
                    _tabController.animateTo(2);
                    _showEditOptions = false;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildEditOptionButton(
                label: 'Get Verified',
                icon: Icons.verified,
                color: Colors.teal,
                onTap: () {
                  // Navigate to verification
                  setState(() {
                    _showEditOptions = false;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditOptionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _rippleController,
      child: FadeTransition(
        opacity: _rippleController,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.6),
                  color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated background
        AnimatedBackground(
          colors: const [
            Color(0xFF6A11CB),
            Color(0xFFFE4A97),
            Color(0xFF006EFF),
          ],
        ),

        // Loading animation
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading your profile...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
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
      fit: StackFit.expand,
      children: [
        // Animated background
        AnimatedBackground(
          colors: const [
            Color(0xFF6A11CB),
            Color(0xFFFE4A97),
            Color(0xFF006EFF),
          ],
        ),

        // Error message
        Center(
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            blur: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error Loading Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: _loadUserData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
      fit: StackFit.expand,
      children: [
        // Animated background
        AnimatedBackground(
          colors: const [
            Color(0xFF6A11CB),
            Color(0xFFFE4A97),
            Color(0xFF006EFF),
          ],
        ),

        // No user message
        Center(
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            blur: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off,
                    size: 50,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Profile Not Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your profile could not be loaded. Please create a profile to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
    return Colors.red;
  }

  String _getCompletionMessage() {
    if (_profileCompletion >= 80) return 'Your profile looks great!';
    if (_profileCompletion >= 50) return 'Keep improving your profile';
    return 'Complete your profile to get more matches';
  }
}

// Custom painter for shimmer effect
class ShimmerPainter extends CustomPainter {
  final Animation<double> animation;

  ShimmerPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment(-1.0 + 2.0 * animation.value, 0.0),
        end: Alignment(1.0 + 2.0 * animation.value, 0.0),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) => true;
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Animation<double> animation;

  RipplePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width < size.height ? size.width : size.height;

    // Draw multiple ripples
    for (var i = 0; i < 3; i++) {
      final rippleProgress = (animation.value - i * 0.2).clamp(0.0, 1.0);
      if (rippleProgress <= 0) continue;

      final radius = maxRadius * rippleProgress;
      final opacity = (1 - rippleProgress).clamp(0.0, 0.5);

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}