// lib/screens/likes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/loading_indicator.dart';
import '../utils/custom_page_route.dart';
import '../animations/modern_match_animation.dart';
import '../screens/modern_chat_screen.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({Key? key}) : super(key: key);

  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<User> _likedByUsers = [];
  List<Map<String, dynamic>> _profileVisitors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Load users who liked the current user
      await userProvider.loadUsersWhoLikedMe();
      _likedByUsers = userProvider.usersWhoLikedMe;

      // Load profile visitors
      await userProvider.loadProfileVisitors();
      _profileVisitors = userProvider.profileVisitors;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading likes data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes & Visitors'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Likes'),
            Tab(text: 'Visitors'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: LoadingIndicator(
          type: LoadingIndicatorType.pulse,
          size: LoadingIndicatorSize.large,
          message: 'Loading...',
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          // Likes Tab
          _buildLikesTab(),

          // Visitors Tab
          _buildVisitorsTab(),
        ],
      ),
    );
  }

  Widget _buildLikesTab() {
    if (_likedByUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No likes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When someone likes you, they will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _likedByUsers.length,
      itemBuilder: (context, index) {
        final user = _likedByUsers[index];
        return _buildLikeCard(user);
      },
    );
  }

  Widget _buildVisitorsTab() {
    if (_profileVisitors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_outlined,
                size: 50,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No profile visitors yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When someone views your profile, they will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _profileVisitors.length,
      itemBuilder: (context, index) {
        final visitor = _profileVisitors[index];
        final user = visitor['user'] as User;
        final timestamp = visitor['timestamp'] as DateTime;
        return _buildVisitorCard(user, timestamp);
      },
    );
  }

  Widget _buildLikeCard(User user) {
    return GestureDetector(
      onTap: () {
        _showUserProfile(user);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Profile Image
              Hero(
                tag: 'profile_${user.id}',
                child: Image.network(
                  user.imageUrls.isNotEmpty ? user.imageUrls[0] : 'https://i.pravatar.cc/300?img=33',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 50),
                    );
                  },
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // User info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.location,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Match button
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _matchWithUser(user),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(User user, DateTime timestamp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Hero(
          tag: 'visitor_${user.id}',
          child: CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
              user.imageUrls.isNotEmpty ? user.imageUrls[0] : 'https://i.pravatar.cc/300?img=33',
            ),
            onBackgroundImageError: (_, __) {},
          ),
        ),
        title: Text(
          '${user.name}, ${user.age}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.location),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Visited ${timeago.format(timestamp)}'),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _matchWithUser(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Like Back'),
        ),
        onTap: () => _showUserProfile(user),
      ),
    );
  }

  void _showUserProfile(User user) {
    // Navigate to user detail screen
    Navigator.of(context).push(
      CustomPageRoute(
        child: UserProfileDetail(user: user),
        settings: RouteSettings(arguments: user),
      ),
    );
  }

  Future<void> _matchWithUser(User user) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final matchedUser = await userProvider.swipeRight(user.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show match animation if there's a match
      if (matchedUser != null && mounted) {
        final currentUser = userProvider.currentUser;
        if (currentUser != null) {
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

      // Refresh likes data after matching
      _loadData();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// User Profile Detail Screen (copy from nearby_users_screen.dart)
class UserProfileDetail extends StatelessWidget {
  final User user;

  const UserProfileDetail({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                user.imageUrls.isNotEmpty ? user.imageUrls[0] : 'https://i.pravatar.cc/300?img=33',
                fit: BoxFit.cover,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(user.location),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user.bio),
                  const SizedBox(height: 24),
                  const Text(
                    'Interests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) => Chip(
                      label: Text(interest),
                      backgroundColor: Colors.red.shade100,
                      labelStyle: TextStyle(color: Colors.red.shade800),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (user.imageUrls.length > 1)
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (user.imageUrls.length > 1)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.imageUrls.length - 1, // Skip the first one (already shown in app bar)
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                user.imageUrls[index + 1],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Dislike user
                  Provider.of<UserProvider>(context, listen: false).swipeLeft(user.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.close, size: 32),
              ),
              ElevatedButton(
                onPressed: () {
                  // Super like user
                  Provider.of<UserProvider>(context, listen: false).superLike(user.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.star, size: 32),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Like user
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final matchedUser = await userProvider.swipeRight(user.id);
                  Navigator.of(context).pop();

                  // Show match animation if there's a match
                  if (matchedUser != null && context.mounted) {
                    final currentUser = userProvider.currentUser;
                    if (currentUser != null) {
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.favorite, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}