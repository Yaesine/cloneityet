// lib/widgets/modern_swipe_card.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../services/profile_view_tracker.dart';
import '../theme/app_theme.dart';

class ModernSwipeCard extends StatefulWidget {
  final User user;
  final bool isTop;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSuperLike;

  const ModernSwipeCard({
    Key? key,
    required this.user,
    required this.isTop,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSuperLike,
  }) : super(key: key);

  @override
  _ModernSwipeCardState createState() => _ModernSwipeCardState();
}

class _ModernSwipeCardState extends State<ModernSwipeCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragAngle = 0;
  int _currentImageIndex = 0;
  bool _showInfo = false;

  // Animation controller for bounce back
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(() {
      setState(() {
        _dragOffset = _slideAnimation.value;
        _dragAngle = _rotationAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on drag offset (fades when dragging away)
    final opacity = widget.isTop
        ? max(0.5, min(1.0, 1.0 - _dragOffset.abs() / 500))
        : 1.0;

    return GestureDetector(
      onHorizontalDragUpdate: widget.isTop ? _handleDragUpdate : null,
      onHorizontalDragEnd: widget.isTop ? _handleDragEnd : null,
      onTap: () {
        if (widget.isTop) {
          setState(() {
            _showInfo = !_showInfo;
          });
          final tracker = ProfileViewTracker();
          tracker.trackProfileView(widget.user.id);
        }
      },
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(widget.isTop ? _dragOffset : 0, 0),
          child: Transform.rotate(
            angle: widget.isTop ? (_dragOffset / 1000) : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Profile Image
                    Hero(
                      tag: 'profile_image_${widget.user.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              widget.user.imageUrls.isNotEmpty
                                  ? widget.user.imageUrls[_currentImageIndex]
                                  : 'https://i.pravatar.cc/300?img=33',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // Image pagination dots
                    if (widget.user.imageUrls.length > 1)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.user.imageUrls.length,
                                (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Swipe indicators
                    if (widget.isTop && _dragOffset != 0)
                      Positioned(
                        top: 24,
                        left: _dragOffset > 0 ? 24 : null,
                        right: _dragOffset < 0 ? 24 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _dragOffset > 0 ? AppColors.secondary : AppColors.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: (_dragOffset.abs() > 50)
                                ? (_dragOffset > 0 ? AppColors.secondary.withOpacity(0.2) : AppColors.primary.withOpacity(0.2))
                                : Colors.transparent,
                          ),
                          child: Text(
                            _dragOffset > 0 ? 'LIKE' : 'NOPE',
                            style: TextStyle(
                              color: _dragOffset > 0 ? AppColors.secondary : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),

                    // User info with gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _showInfo ? 280 : 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.9],
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${widget.user.name}, ${widget.user.age}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.user.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_showInfo) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'About',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.user.bio,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Interests',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.user.interests.map((interest) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        interest,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                                if (!_showInfo)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                if (_showInfo)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Left/Right image navigation
                    if (widget.isTop && widget.user.imageUrls.length > 1)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _previousImage,
                              behavior: HitTestBehavior.translucent,
                              child: Container(),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _nextImage,
                              behavior: HitTestBehavior.translucent,
                              child: Container(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Action button elements moved to parent widget

  void _handleSuperLike() {
    // Show a star animation
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 2.0 * value,
              child: Opacity(
                opacity: value > 0.8 ? 2.0 - value * 2 : value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 100,
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            Navigator.of(ctx).pop();
            widget.onSuperLike();
          },
        ),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // Cancel any running animations
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    setState(() {
      _dragOffset += details.delta.dx;
      _dragAngle = _dragOffset / 1000; // Update rotation angle
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final swipeThreshold = MediaQuery.of(context).size.width / 4;

    if (_dragOffset.abs() > swipeThreshold || velocity.abs() > 800) {
      // Swipe completed - animate card off screen
      final screenWidth = MediaQuery.of(context).size.width;
      final endPosition = _dragOffset > 0 ? screenWidth * 1.5 : -screenWidth * 1.5;

      _slideAnimation = Tween<double>(
        begin: _dragOffset,
        end: endPosition,
      ).animate(_animationController);

      _rotationAnimation = Tween<double>(
        begin: _dragAngle,
        end: _dragOffset > 0 ? pi / 8 : -pi / 8,
      ).animate(_animationController);

      _animationController.forward().then((_) {
        if (_dragOffset > 0) {
          widget.onSwipeRight();
        } else {
          widget.onSwipeLeft();
        }
      });
    } else {
      // Not enough to trigger swipe - animate back to center
      _slideAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(_animationController);

      _rotationAnimation = Tween<double>(
        begin: _dragAngle,
        end: 0,
      ).animate(_animationController);

      _animationController.forward().then((_) {
        // Reset controller for next use
        _animationController.reset();
      });
    }
  }

  // Button-initiated swipes
  void handleSwipe(bool isRight) {
    // Set up the same animations as drag end
    final screenWidth = MediaQuery.of(context).size.width;
    final endPosition = isRight ? screenWidth * 1.5 : -screenWidth * 1.5;

    setState(() {
      // Instantly update to slight offset for visual feedback
      _dragOffset = isRight ? 50 : -50;
      _dragAngle = _dragOffset / 1000;
    });

    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: endPosition,
    ).animate(_animationController);

    _rotationAnimation = Tween<double>(
      begin: _dragAngle,
      end: isRight ? pi / 8 : -pi / 8,
    ).animate(_animationController);

    _animationController.forward().then((_) {
      if (isRight) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    });
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.user.imageUrls.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }
}