import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatchAnimationOverlay extends StatefulWidget {
  final Map<String, dynamic> currentUserData;
  final Map<String, dynamic> matchedUserData;
  final VoidCallback onComplete;

  const MatchAnimationOverlay({
    super.key,
    required this.currentUserData,
    required this.matchedUserData,
    required this.onComplete,
  });

  @override
  State<MatchAnimationOverlay> createState() => _MatchAnimationOverlayState();
}

class _MatchAnimationOverlayState extends State<MatchAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _heartController;
  late AnimationController _textController;
  late AnimationController _backgroundController;

  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Setup animations
    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: const Offset(-0.15, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _rightSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(0.15, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeInOut,
      ),
    );

    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Start background fade
    _backgroundController.forward();

    await Future.delayed(const Duration(milliseconds: 200));

    // Start slide animations
    _slideController.forward();

    await Future.delayed(const Duration(milliseconds: 600));

    // Start heart animation
    _heartController.forward();
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 300));

    // Start text animation
    _textController.forward();

    // Auto close after 3 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    widget.onComplete();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _heartController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete,
      child: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            color:
                Colors.black.withOpacity(0.9 * _backgroundFadeAnimation.value),
            child: Stack(
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.pink
                            .withOpacity(0.3 * _backgroundFadeAnimation.value),
                        Colors.purple
                            .withOpacity(0.3 * _backgroundFadeAnimation.value),
                        Colors.deepPurple
                            .withOpacity(0.3 * _backgroundFadeAnimation.value),
                      ],
                    ),
                  ),
                ),

                // Floating hearts background
                ...List.generate(12, (index) => _buildFloatingHeart(index)),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile images
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left profile (current user)
                          AnimatedBuilder(
                            animation: _leftSlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  _leftSlideAnimation.value.dx *
                                      MediaQuery.of(context).size.width,
                                  _leftSlideAnimation.value.dy *
                                      MediaQuery.of(context).size.height,
                                ),
                                child: _buildProfileImage(
                                  widget.currentUserData['photo'] ?? '',
                                  widget.currentUserData['name'] ?? 'You',
                                  isLeft: true,
                                ),
                              );
                            },
                          ),

                          // Right profile (matched user)
                          AnimatedBuilder(
                            animation: _rightSlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  _rightSlideAnimation.value.dx *
                                      MediaQuery.of(context).size.width,
                                  _rightSlideAnimation.value.dy *
                                      MediaQuery.of(context).size.height,
                                ),
                                child: _buildProfileImage(
                                  widget.matchedUserData['photo'] ?? '',
                                  widget.matchedUserData['name'] ?? 'Unknown',
                                  isLeft: false,
                                ),
                              );
                            },
                          ),

                          // Center heart
                          AnimatedBuilder(
                            animation: _heartScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _heartScaleAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.pink,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // Match text
                      AnimatedBuilder(
                        animation: _textFadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFadeAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  "It's a Match!",
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "You and ${widget.matchedUserData['name']} liked each other",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  "Tap anywhere to continue",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl, String name,
      {required bool isLeft}) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingHeart(int index) {
    final random = (index * 37) % 100;
    final size = 20.0 + (random % 15);
    final left = (random * 3.7) % 100;
    final animationDelay = (random * 47) % 2000;

    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * left / 100,
          top: MediaQuery.of(context).size.height * 0.2 +
              (MediaQuery.of(context).size.height *
                  0.6 *
                  (1 - _heartController.value)),
          child: Opacity(
            opacity: _heartController.value * 0.6,
            child: Icon(
              Icons.favorite,
              color: Colors.pink.shade200,
              size: size,
            ),
          ),
        );
      },
    );
  }
}
