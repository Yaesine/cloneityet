// lib/screens/enhanced_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../widgets/components/section_card.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/interest_chip.dart';
import '../widgets/components/profile_avatar.dart';
import '../screens/modern_profile_edit_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/photo_manager_screen.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({Key? key}) : super(key: key);

  @override
  _EnhancedProfileScreenState createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
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
    return Scaffold(
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

          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _loadUserData,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Animated header with curved bottom edge
                SliverAppBar(
                  expandedHeight: 280.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  leading: const SizedBox.shrink(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: () {
                        // Navigate to settings
                        Navigator.of(context).pushNamed('/filters');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      onPressed: () async {
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
                    ),
                  ],
                  flexibleSpace: FadeTransition(
                    opacity: _headerAnimation,
                    child: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gradient background
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),

                          // Wave pattern at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipPath(
                              clipper: WaveClipper(),
                              child: Container(
                                height: 50,
                                color: AppColors.background,
                              ),
                            ),
                          ),

                          // Profile image and name
                          Positioned(
                            bottom: 70,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'profile_image',
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: AppDecorations.profileImageAvatar,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: CachedNetworkImage(
                                        imageUrl: user.imageUrls.isNotEmpty
                                            ? user.imageUrls[0]
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
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${user.name}, ${user.age}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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
                  ),
                ),

                // Profile content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Premium card
                        _buildPremiumCard(context),
                        const SizedBox(height: 20),

                        // Verification card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.blue.withOpacity(0.1),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user, color: Colors.blue),
                            ),
                            title: const Text(
                              'Verify Your Profile',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            subtitle: const Text('Get a blue checkmark and increase your matches'),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
                            onTap: () {
                              Navigator.of(context).pushNamed('/verification');
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bio section
                        SectionCard(
                          title: 'About Me',
                          icon: Icons.person_outline,
                          iconColor: AppColors.primary,
                          action: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ModernProfileEditScreen(),
                                ),
                              ).then((_) => _loadUserData());
                            },
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              user.bio.isNotEmpty ? user.bio : 'Add something about yourself...',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: user.bio.isNotEmpty ? Colors.black87 : Colors.black38,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Interests section
                        SectionCard(
                          title: 'My Interests',
                          icon: Icons.favorite_border,
                          iconColor: AppColors.error,
                          action: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ModernProfileEditScreen(),
                                ),
                              ).then((_) => _loadUserData());
                            },
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: user.interests.isNotEmpty
                                ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.interests.map((interest) => InterestChip(
                                label: interest,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                textColor: AppColors.primary,
                              )).toList(),
                            )
                                : Center(
                              child: Text(
                                'Add your interests to help us find better matches',
                                style: TextStyle(color: Colors.grey.shade400),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Photos section
                        SectionCard(
                          title: 'My Photos',
                          icon: Icons.photo_library_outlined,
                          iconColor: AppColors.secondary,
                          action: IconButton(
                            icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PhotoManagerScreen(),
                                ),
                              ).then((_) => _loadUserData());
                            },
                          ),
                          child: Container(
                            height: 160,
                            padding: const EdgeInsets.all(16),
                            child: user.imageUrls.length > 1
                                ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: user.imageUrls.length,
                              itemBuilder: (context, index) {
                                if (index == 0) return const SizedBox.shrink(); // Skip the first image (already shown in the header)

                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: user.imageUrls[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                                : Center(
                              child: Text(
                                'Add more photos to your profile',
                                style: TextStyle(color: Colors.grey.shade400),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Discovery preferences section
                        SectionCard(
                          title: 'Discovery Settings',
                          icon: Icons.tune,
                          iconColor: Colors.purple,
                          action: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/filters')
                                  .then((_) => _loadUserData());
                            },
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSettingRow(
                                  'Age Range',
                                  '${user.ageRangeStart} - ${user.ageRangeEnd}',
                                  Icons.calendar_today,
                                ),
                                const Divider(),
                                _buildSettingRow(
                                  'Distance',
                                  '${user.distance} km',
                                  Icons.place,
                                ),
                                const Divider(),
                                _buildSettingRow(
                                  'Looking For',
                                  user.lookingFor.isNotEmpty ? user.lookingFor : 'Everyone',
                                  Icons.person_search,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernProfileEditScreen(),
            ),
          ).then((_) => _loadUserData());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        elevation: 4,
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Card(
        elevation: 4,
        shadowColor: Colors.amber.withOpacity(0.3),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
    Colors.amber.shade300,
    Colors.amber.shade700,
    ],
    ),
    ),
    child: Material(
    color: Colors.transparent,
    child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
    Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => PremiumScreen()),
    );
    },
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
    children: [
    Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    shape: BoxShape.circle,
    ),
    child: const Icon(
    Icons.workspace_premium,
    color: Colors.white,
    size: 32,
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
    fontSize: 18,
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
    const SizedBox(height: 4),
    const Text(
    'See who likes you & more premium features',
    style: TextStyle(
    color: Colors.white,
    fontSize: 14,
    ),
    ),
    ],
    ),
    ),
    const Icon(
    Icons.arrow_forward_ios,
    color: Colors.white,
    size: 16,
    ),
    ],
    ),
    ),
    ),
    ),
    ),
    );
  }

  Widget _buildSettingRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: LoadingIndicator(
        type: LoadingIndicatorType.pulse,
        size: LoadingIndicatorSize.large,
        message: 'Loading your profile...',
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage),
          const SizedBox(height: 24),
          AppButton(
            text: 'Try Again',
            icon: Icons.refresh,
            onPressed: _loadUserData,
            type: AppButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNoUserView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            AppButton(
              text: 'Create Profile',
              icon: Icons.person_add,
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.forceSyncCurrentUser();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Creating user profile...')),
                  );
                  _loadUserData();
                }
              },
              type: AppButtonType.primary,
              size: AppButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}