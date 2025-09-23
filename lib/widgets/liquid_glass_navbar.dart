import 'package:flutter/material.dart';
import 'dart:ui';

class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<LiquidNavBarItem> items;

  const LiquidGlassNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _liquidController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _liquidAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _liquidController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _liquidAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _liquidController,
      curve: Curves.elasticOut,
    ));

    _liquidController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _liquidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add bounds checking to prevent assertion errors
    if (widget.items.isEmpty) {
      return SizedBox.shrink();
    }

    // Ensure currentIndex is within bounds
    final safeCurrentIndex =
        widget.currentIndex.clamp(0, widget.items.length - 1);

    return Positioned(
      left: 20,
      right: 20,
      bottom: 30,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.items.length,
                  (index) => _buildNavItem(index, safeCurrentIndex),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, int currentIndex) {
    // Add bounds checking for index
    if (index < 0 || index >= widget.items.length) {
      return SizedBox.shrink();
    }

    final isSelected = index == currentIndex;
    final item = widget.items[index];

    return GestureDetector(
      onTap: () {
        widget.onTap(index);
        if (isSelected) {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        }
      },
      child: AnimatedBuilder(
        animation: _liquidAnimation,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Liquid background for selected item
                if (isSelected)
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 40 + (_liquidAnimation.value * 5),
                          height: 40 + (_liquidAnimation.value * 5),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                item.activeColor.withOpacity(0.3),
                                item.activeColor.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),

                // Icon with liquid effect
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected
                        ? item.activeColor
                        : Colors.white.withOpacity(0.6),
                    size: isSelected ? 28 : 24,
                  ),
                ),

                // Ripple effect on tap
                if (isSelected)
                  AnimatedBuilder(
                    animation: _liquidAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 20 + (_liquidAnimation.value * 30),
                        height: 20 + (_liquidAnimation.value * 30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.activeColor.withOpacity(
                              0.3 - (_liquidAnimation.value * 0.3),
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LiquidNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final Color activeColor;
  final String label;

  LiquidNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.activeColor,
    required this.label,
  });
}
