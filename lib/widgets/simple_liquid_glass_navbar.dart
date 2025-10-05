import 'package:flutter/material.dart';
import 'dart:ui';

class SimpleLiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<SimpleLiquidNavBarItem> items;

  const SimpleLiquidGlassNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<SimpleLiquidGlassNavBar> createState() =>
      _SimpleLiquidGlassNavBarState();
}

class _SimpleLiquidGlassNavBarState extends State<SimpleLiquidGlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safety checks
    if (widget.items.isEmpty) {
      return SizedBox.shrink();
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: 30,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
            // Additional shadow for better visibility
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 25,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.2),
                    Colors.grey.shade100.withOpacity(0.3),
                    Colors.grey.shade200.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.items.length,
                  (index) => _buildNavItem(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    // Bounds checking
    if (index < 0 || index >= widget.items.length) {
      return SizedBox.shrink();
    }

    final isSelected = index == widget.currentIndex;
    final item = widget.items[index];

    return GestureDetector(
      onTap: () {
        widget.onTap(index);
        // Simple animation trigger
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      },
      child: Container(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle for selected item
            if (isSelected)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      item.activeColor.withOpacity(0.3),
                      item.activeColor.withOpacity(0.1),
                    ],
                  ),
                ),
              ),

            // Icon
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected
                    ? item.activeColor
                    : Colors.black.withOpacity(
                        0.6), // Changed from white to black for better visibility
                size: isSelected ? 28 : 24,
              ),
            ),

            // Subtle ring effect for selected item
            if (isSelected)
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.activeColor.withOpacity(0.4),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SimpleLiquidNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final Color activeColor;
  final String label;

  SimpleLiquidNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.activeColor,
    required this.label,
  });
}
