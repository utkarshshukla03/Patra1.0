import 'package:flutter/material.dart';
import '../pages/homePage.dart';
import '../pages/discovery.dart';
import '../pages/profile.dart';
import '../widgets/simple_liquid_glass_navbar.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    HomePage(),
    DiscoveryPage(),
    ProfilePage(),
  ];

  final List<SimpleLiquidNavBarItem> _navItems = [
    SimpleLiquidNavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      activeColor: Colors.pink,
      label: 'Home',
    ),
    SimpleLiquidNavBarItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      activeColor: Colors.purple,
      label: 'Discover',
    ),
    SimpleLiquidNavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      activeColor: Colors.blue,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    // Add bounds checking
    if (index < 0 || index >= _pages.length) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // This allows the body to extend behind the navbar
      body: Stack(
        children: [
          // Page content
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(), // Disable swipe navigation
            onPageChanged: (index) {
              // Add bounds checking
              if (index >= 0 && index < _pages.length) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            children: _pages,
          ),

          // Simple Liquid Glass Navigation Bar
          SimpleLiquidGlassNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavItemTapped,
            items: _navItems,
          ),
        ],
      ),
    );
  }
}
