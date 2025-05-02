import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/swipe_card.dart';
import '../models/user_model.dart';
import '../data/dummy_data.dart'; // Make sure this import exists

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

  void _handleSwipeRight(String userId) {
    Provider.of<UserProvider>(context, listen: false).swipeRight(userId);
  }

  @override
  Widget build(BuildContext context) {
    // In your HomeScreen build method
    print('Current user ID: ${Provider.of<AppAuthProvider>(context, listen: false).currentUserId}');
  //  print('Number of potential matches: ${userProvider.potentialMatches.length}');

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
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          // Get profiles from provider
          List<User> profiles = userProvider.potentialMatches;

          // If no profiles are available from the provider, use dummy data
          if (profiles.isEmpty) {
            profiles = DummyData.getDummyUsers();
          }

          // Now continue with your existing condition
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

          // Continue with the rest of your existing code for displaying the profiles
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
                ),
              );
            }).toList(),
          );
        },
      ),
    );

  }
}