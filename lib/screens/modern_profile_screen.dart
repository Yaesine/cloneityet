// lib/screens/modern_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/profile_edit_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({Key? key}) : super(key: key);

  @override
  _ModernProfileScreenState createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;

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

          return CustomScrollView(
            slivers: [
              // Animated header with curved bottom edge
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () {
                      // Navigate to settings
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
                          SnackBar(content: Text('Error logging out: $e')),
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
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
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
                                user.name,
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
                      // Bio section
                      _buildSectionCard(
                        title: 'About Me',
                        icon: Icons.person_outline,
                        iconColor: AppColors.primary,
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
                      _buildSectionCard(
                        title: 'My Interests',
                        icon: Icons.favorite_border,
                        iconColor: AppColors.error,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: user.interests.isNotEmpty
                              ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.interests.map((interest) => Chip(
                              label: Text(interest),
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              labelStyle: const TextStyle(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                      _buildSectionCard(
                        title: 'My Photos',
                        icon: Icons.photo_library_outlined,
                        iconColor: AppColors.secondary,
                        action: IconButton(
                          icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/photoManager')
                                .then((_) => _loadUserData());
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
                      _buildSectionCard(
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

                      const SizedBox(height: 20),

                      // Debug info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Debug Tools',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('User ID: ${user.id}',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('App Version: 1.0.0',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () async {
                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                await userProvider.forceSyncCurrentUser();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Forced user sync attempted')),
                                  );
                                  _loadUserData();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black54,
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: const Text('Force Sync User Profile'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/debug');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black54,
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: const Text('Open Debug Screen'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileEditScreen(),
            ),
          ).then((_) => _loadUserData());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color iconColor = Colors.grey,
    Widget? action,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                if (action != null) action,
              ],
            ),
          ),

          // Section content
          child,
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
          ElevatedButton.icon(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
            Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No profile data available',
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
            ElevatedButton.icon(
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
              icon: const Icon(Icons.person_add),
              label: const Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom clipper for wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 10);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 20);
    var secondEndPoint = Offset(size.width, size.height);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}