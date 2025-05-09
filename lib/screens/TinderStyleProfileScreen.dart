import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../screens/modern_profile_edit_screen.dart';
import '../screens/photo_manager_screen.dart';
import '../screens/profile_verification_screen.dart';
import '../screens/premium_screen.dart';

class TinderStyleProfileScreen extends StatefulWidget {
  const TinderStyleProfileScreen({Key? key}) : super(key: key);

  @override
  _TinderStyleProfileScreenState createState() => _TinderStyleProfileScreenState();
}

class _TinderStyleProfileScreenState extends State<TinderStyleProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  int _profileCompletion = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int calculateProfileCompletion(User user) {
    int completionScore = 0;

    // Only count imageUrls if the user has actually uploaded at least one
    if (user.imageUrls.isNotEmpty) {
      completionScore += 30; // Give more weight to having a profile picture
    }

    // Bio should be meaningful
    if (user.bio.length > 20) {
      completionScore += 20;
    } else if (user.bio.isNotEmpty) {
      completionScore += 5; // Some credit for starting a bio
    }

    // Interests are important for matching
    if (user.interests.length >= 3) {
      completionScore += 20;
    } else if (user.interests.isNotEmpty) {
      completionScore += (10 * user.interests.length / 3) as int; // Partial credit
    }

    // Location is required
    if (user.location.isNotEmpty) {
      completionScore += 15;
    }

    // Gender preferences
    if (user.gender.isNotEmpty && user.lookingFor.isNotEmpty) {
      completionScore += 15;
    } else if (user.gender.isNotEmpty || user.lookingFor.isNotEmpty) {
      completionScore += 7; // Partial credit
    }

    // Make sure we don't exceed 100%
    return min(completionScore.round(), 100);
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
          setState(() {
            _profileCompletion = calculateProfileCompletion(user);
            _isLoading = false;
          });

          _controller.forward();
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
    return Scaffold(
      backgroundColor: Colors.white,
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

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header with image
                  _buildProfileHeader(user),

                  // Profile details
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile completion
                        _buildProfileCompletionCard(),

                        const SizedBox(height: 24),

                        // Action buttons
                        _buildActionButtons(),

                        const SizedBox(height: 24),

                        // About me section
                        _buildAboutMeSection(user),

                        const SizedBox(height: 24),

                        // Interests section
                        _buildInterestsSection(user),

                        const SizedBox(height: 24),

                        // Settings section
                        _buildSettingsSection(user),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Stack(
      children: [
        // Profile image
        Container(
          height: 440,
          width: double.infinity,
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: user.imageUrls.isNotEmpty
                  ? user.imageUrls[0]
                  : 'https://i.pravatar.cc/300?img=33',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error_outline, size: 60),
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),

        // Settings button
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pushNamed('/filters');
              },
            ),
          ),
        ),

        // User info container
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and age
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${user.name}, ${user.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCompletionColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCompletionIcon(),
                  color: _getCompletionColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile $_profileCompletion% Complete",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCompletionMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _profileCompletion / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getCompletionColor()),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.edit,
          label: 'Edit Info',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModernProfileEditScreen(),
              ),
            ).then((_) => _loadUserData());
          },
        ),

        _buildActionButton(
          icon: Icons.photo_library,
          label: 'Add Media',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PhotoManagerScreen(),
              ),
            ).then((_) => _loadUserData());
          },
        ),

        _buildActionButton(
          icon: Icons.verified_user,
          label: 'Get Verified',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileVerificationScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection(User user) {
    return _buildSectionCard(
      title: 'About me',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.bio.isNotEmpty ? user.bio : 'Add something about yourself...',
            style: TextStyle(
              height: 1.4,
              color: user.bio.isNotEmpty ? Colors.black87 : Colors.grey,
            ),
          ),

          if(user.bio.length < 20)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[800], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Profiles with detailed bios get up to 50% more matches!',
                      style: TextStyle(color: Colors.amber[800], fontSize: 12),
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
    return _buildSectionCard(
      title: 'Interests',
      child: user.interests.isNotEmpty
          ? Wrap(
        spacing: 8,
        runSpacing: 8,
        children: user.interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      )
          : Center(
        child: Text(
          'Add your interests to help us find better matches',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // Upgrade to Tinder Premium
        _buildSettingCard(
          icon: Icons.workspace_premium,
          iconColor: Colors.amber,
          title: 'Tinder Premium',
          subtitle: 'See who likes you & more',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PremiumScreen()),
            );
          },
          showBadge: true,
          badgeText: 'UPGRADE',
        ),

        const SizedBox(height: 12),

        // Discovery Settings
        _buildSettingCard(
          icon: Icons.tune,
          iconColor: AppColors.primary,
          title: 'Discovery Settings',
          subtitle: 'Distance, age range, looking for',
          onTap: () {
            Navigator.of(context).pushNamed('/filters')
                .then((_) => _loadUserData());
          },
        ),

        const SizedBox(height: 12),

        // Notifications
        _buildSettingCard(
          icon: Icons.notifications_none,
          iconColor: Colors.blue,
          title: 'Notifications',
          subtitle: 'Manage your notifications',
          onTap: () {},
        ),

        const SizedBox(height: 12),

        // Privacy & Safety
        _buildSettingCard(
          icon: Icons.lock_outline,
          iconColor: Colors.green,
          title: 'Privacy & Safety',
          subtitle: 'Control your privacy settings',
          onTap: () {},
        ),

        const SizedBox(height: 16),

        // Logout button
        Center(
          child: TextButton(
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
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
    String badgeText = '',
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (showBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.primary,
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
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
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
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor() {
    if (_profileCompletion >= 80) return Colors.green;
    if (_profileCompletion >= 40) return Colors.amber;
    return AppColors.primary;
  }

  IconData _getCompletionIcon() {
    if (_profileCompletion >= 80) return Icons.check_circle;
    if (_profileCompletion >= 40) return Icons.star;
    return Icons.warning;
  }

  String _getCompletionMessage() {
    if (_profileCompletion >= 80) return 'Your profile looks great!';
    if (_profileCompletion >= 40) return 'You\'re on the right track!';
    return 'Complete your profile to get more matches';
  }
}