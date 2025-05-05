import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import 'dart:ui';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fixed the _debugGoogleSignIn method to return a proper Map
  Future<Map<String, dynamic>> _debugGoogleSignIn() async {
    final Map<String, dynamic> debugInfo = {};

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      debugInfo['starting_debug'] = 'Attempting to debug Google Sign In';

      // This is a placeholder for actual debugging logic
      // In a real implementation, you would call methods on authProvider

      debugInfo['debug_completed'] = 'Debug info collected successfully';
      return debugInfo;
    } catch (e) {
      debugInfo['error'] = e.toString();
      return debugInfo;
    }
  }

  Future<void> _showDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the debug function and display results
      final Map<String, dynamic> debugInfo = await _debugGoogleSignIn();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show debug info in an alert dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Google Sign In Debug Info'),
            content: SingleChildScrollView(
              child: ListBody(
                children: debugInfo.entries.map((entry) =>
                    Text('${entry.key}: ${entry.value}')
                ).toList(),
              ),
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        // Navigate to main screen
        Navigator.of(context).pushReplacementNamed('/main');
      } else if (!success && mounted) {
        // Check if the error was the PigeonUserDetails issue but user is actually signed in
        if (authProvider.isLoggedIn) {
          // User is actually signed in, navigate to main
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          // Show error dialog
          _showErrorDialog('Google sign in failed. Please try again.');
        }
      }
    } catch (error) {
      print('Login screen error: $error');
      if (mounted) {
        _showErrorDialog('Failed to sign in with Google: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithFacebook();

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        _showErrorDialog('Facebook sign in failed. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('Failed to sign in with Facebook: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePhoneSignIn() async {
    if (mounted) {
      Navigator.of(context).pushNamed('/phone-login');
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithApple();

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        _showErrorDialog('Apple sign in failed. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('Failed to sign in with Apple: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oops!', style: TextStyle(color: Color(0xFFFF4458))),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF4458))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;



    return Scaffold(
      body: Stack(
        children: [
          // Beautiful background with gradient and pattern
          Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF4458), // Tinder red
                  Color(0xFFFF7854), // Orange gradient
                  Color(0xFFFF4458).withOpacity(0.9),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.1),

                        // Logo with flame animation
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.whatshot,
                            size: 60,
                            color: Color(0xFFFF4458),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // App name
                        Text(
                          'STILL',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 12.0,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 4),
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.25),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Swipe. Match. Chat.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.w300,
                          ),
                        ),

                        SizedBox(height: size.height * 0.08),

                        // Social login buttons with improved design
                        if (Platform.isIOS) ...[
                          _buildModernButton(
                            'Continue with Apple',
                            Icons.apple,
                            Colors.black,
                                () => _handleAppleSignIn(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildModernButton(
                          'Continue with Facebook',
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/1200px-Facebook_Logo_%282019%29.png',
                          const Color(0xFF1877F2),
                              () => _handleFacebookSignIn(),
                          isAsset: false,
                        ),

                        const SizedBox(height: 16),

                        _buildModernButton(
                          'Continue with Google',
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/800px-Google_%22G%22_logo.svg.png',
                          const Color(0xFF4285F4),
                              () => _handleGoogleSignIn(),
                          isAsset: false,
                        ),

                        const SizedBox(height: 16),

                        _buildModernButton(
                          'Continue with Phone',
                          Icons.phone_outlined,
                          const Color(0xFF25D366),
                              () => _handlePhoneSignIn(),
                        ),

                        const SizedBox(height: 32),

                        // Terms and conditions
                        Text(
                          'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign in link
                        TextButton(
                          onPressed: () {
                            // Handle manual email sign in if needed
                          },
                          child: Text(
                            'Sign in with Email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Debug button for development

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4458)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernButton(
      String text,
      dynamic icon,
      Color color,
      VoidCallback onTap, {
        bool isAsset = true,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          disabledBackgroundColor: Colors.white.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAsset && icon is IconData)
              Icon(icon, size: 22, color: color)
            else if (!isAsset && icon is String)
              Image.network(
                icon,
                width: 22,
                height: 22,
              ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}