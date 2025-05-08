import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _resourcesInitialized = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller and animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Begin animation
    _animationController.forward();

    // Setup simplified navigation
    Future.delayed(Duration(milliseconds: 1500), () {
      _navigateToNextScreen();
    });

    // Initialize resources in background
    _loadResourcesInBackground();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadResourcesInBackground() async {
    try {
      // Initialize auth in background
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      authProvider.initializeAuth();

      // Make sure not to load any location or geocoding services here
    } catch (e) {
      debugPrint('Background resource loading error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF4458),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF4458), // Tinder red
              Color(0xFFFF7854), // Orange gradient
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Animation
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.whatshot,
                          color: Color(0xFFFF4458),
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Text(
                      'STILL',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tagline with fade-in effect
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Text(
                      'Swipe. Match. Chat.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}