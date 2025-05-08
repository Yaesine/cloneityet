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

    // Setup animations
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

    // Listen for animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationCompleted = true;
        });
        _checkNavigationConditions();
      }
    });

    // Start animation and initialization in parallel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _initializeAppResources();
    });
  }

  // Initialize all resources in parallel
  Future<void> _initializeAppResources() async {
    try {
      // Load critical resources in parallel
      await Future.wait([
        _initializeAuthState(),
        _preloadCriticalData(),
        // Add minimum delay to ensure good user experience
        Future.delayed(const Duration(milliseconds: 800)),
      ]);

      // Mark initialization as complete
      if (mounted) {
        setState(() {
          _resourcesInitialized = true;
        });
        _checkNavigationConditions();
      }
    } catch (e) {
      debugPrint('Error initializing resources: $e');
      // Still mark as initialized to prevent getting stuck
      if (mounted) {
        setState(() {
          _resourcesInitialized = true;
        });
        _checkNavigationConditions();
      }
    }
  }

  // Initialize auth state
  Future<void> _initializeAuthState() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
    }
  }

  // Preload any critical app data
  Future<void> _preloadCriticalData() async {
    // For example, preload user profile or app configuration
    // You can add actual implementation here
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Check if we should navigate
  void _checkNavigationConditions() {
    // Only navigate when both animation is done and resources are loaded
    if (_resourcesInitialized && _animationCompleted && mounted) {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
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
                  // Optional loading indicator
                  if (!_resourcesInitialized)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
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