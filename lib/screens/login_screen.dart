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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement Google Sign In
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (error) {
      _showErrorDialog('Failed to sign in with Google');
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
      // TODO: Implement Facebook Sign In
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithFacebook();

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (error) {
      _showErrorDialog('Failed to sign in with Facebook');
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
    // Apple Sign In is not available yet - show appropriate message
    _showErrorDialog('Apple Sign In will be available in future updates');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Tinder-like gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.pink.withOpacity(0.1),
                  Colors.red.withOpacity(0.1),
                ],
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.15),

                      // Logo
                      const Icon(
                        Icons.whatshot,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),

                      // App name (Tinder-style)
                      const Text(
                        'STILL',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      SizedBox(height: size.height * 0.1),

                      // Terms text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            children: [
                              const TextSpan(text: 'By tapping Create Account or Sign In, you agree to our '),
                              TextSpan(
                                text: 'Terms',
                                style: const TextStyle(
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: '. Learn how we process your data in our '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Cookie Policy',
                                style: const TextStyle(
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign In with Apple (only on iOS)
                      if (Platform.isIOS) ...[
                        _buildSocialButton(
                          'SIGN IN WITH APPLE',
                          Icons.apple,
                          Colors.black,
                              () => _handleAppleSignIn(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Sign In with Facebook
                      _buildSocialButton(
                        'SIGN IN WITH FACEBOOK',
                        Icons.facebook,
                        const Color(0xFF1877F2),
                            () => _handleFacebookSignIn(),
                      ),

                      const SizedBox(height: 16),

                      // Sign In with Google
                      _buildSocialButton(
                        'SIGN IN WITH GOOGLE',
                        Icons.g_translate,
                        Colors.red,
                            () => _handleGoogleSignIn(),
                      ),

                      const SizedBox(height: 16),

                      // Sign In with Phone Number
                      _buildSocialButton(
                        'SIGN IN WITH PHONE NUMBER',
                        Icons.phone,
                        Colors.green,
                            () => _handlePhoneSignIn(),
                      ),

                      const SizedBox(height: 48),

                      // Trouble signing in
                      TextButton(
                        onPressed: () {
                          // TODO: Handle trouble signing in
                        },
                        child: const Text(
                          'Trouble Signing In?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      String text,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
          disabledBackgroundColor: color.withOpacity(0.5),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}