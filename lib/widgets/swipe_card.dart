import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user_model.dart';

class SwipeCard extends StatefulWidget {
  final User user;
  final bool isTop;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const SwipeCard({
    Key? key,
    required this.user,
    required this.isTop,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  }) : super(key: key);

  @override
  _SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragAngle = 0;
  int _currentImageIndex = 0;

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
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(widget.isTop ? _dragOffset : 0, 0),
          child: Transform.rotate(
            angle: widget.isTop ? (_dragOffset / 1000) : 0,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: widget.isTop ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Profile Image
                          Hero(
                            tag: 'profile_image_${widget.user.id}',
                            child: Image.network(
                              widget.user.imageUrls[_currentImageIndex],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.error, size: 50),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Image pagination dots
                          if (widget.user.imageUrls.length > 1)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.user.imageUrls.length,
                                      (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Swipe indicators - more prominent now
                          if (widget.isTop && _dragOffset != 0)
                            Positioned(
                              top: 24,
                              left: _dragOffset > 0 ? 24 : null,
                              right: _dragOffset < 0 ? 24 : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _dragOffset > 0 ? Colors.green : Colors.red,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: (_dragOffset.abs() > 50)
                                      ? (_dragOffset > 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3))
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  _dragOffset > 0 ? 'LIKE' : 'NOPE',
                                  style: TextStyle(
                                    color: _dragOffset > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),

                          // User info gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.9),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${widget.user.name}, ${widget.user.age}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 20,
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
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.user.bio,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

                    // Action buttons with improved styling
                    if (widget.isTop)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              Icons.close,
                              Colors.red,
                                  () => _handleSwipe(false),
                            ),
                            _buildActionButton(
                              Icons.star,
                              Colors.blue,
                                  () {
                                // Super like functionality could be added here
                              },
                              size: 32,
                            ),
                            _buildActionButton(
                              Icons.favorite,
                              Colors.green,
                                  () => _handleSwipe(true),
                            ),
                          ],
                        ),
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

  Widget _buildActionButton(
      IconData icon,
      Color color,
      VoidCallback onTap, {
        double size = 24,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size,
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

  // New method to handle button-initiated swipes
  void _handleSwipe(bool isRight) {
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