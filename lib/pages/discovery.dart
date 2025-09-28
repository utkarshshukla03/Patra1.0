import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/story_map.dart';
import '../widgets/real_snapchat_map.dart';
import '../widgets/web_fallback_map.dart';
import '../widgets/story_viewer.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with TickerProviderStateMixin {
  late AnimationController _mapController;
  late Animation<double> _mapAnimation;

  List<UserStory> _allStories = [];
  List<HeatPoint> _heatPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _mapController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _mapAnimation = CurvedAnimation(
      parent: _mapController,
      curve: Curves.easeOutCubic,
    );

    _loadMapData();
  }

  void _loadMapData() async {
    // Simulate loading time
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _allStories = StoryMapData.getMockStories();
      _heatPoints = StoryMapData.generateHeatPoints(_allStories);
      _isLoading = false;
    });

    _mapController.forward();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onHeatPointTapped(HeatPoint heatPoint) {
    HapticFeedback.mediumImpact();

    // Show story viewer with stories from this heat point
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StoryViewer(
          stories: heatPoint.stories,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main map view
          if (!_isLoading)
            AnimatedBuilder(
              animation: _mapAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _mapAnimation.value,
                  child: Opacity(
                    opacity: _mapAnimation.value,
                    child: kIsWeb
                        ? WebFallbackMap(
                            heatPoints: _heatPoints,
                            onHeatPointTapped: _onHeatPointTapped,
                          )
                        : RealSnapchatMap(
                            heatPoints: _heatPoints,
                            onHeatPointTapped: _onHeatPointTapped,
                          ),
                  ),
                );
              },
            ),

          // Loading state
          if (_isLoading) _buildLoadingState(),

          // Top app bar with Snapchat-style design
          _buildTopAppBar(),

          // Bottom navigation for map modes
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.map,
                color: Colors.black,
                size: 30,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Loading Story Map...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Discovering stories around Thapar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 10,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Snapchat-style title
            Expanded(
              child: Text(
                'Snap Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Map mode toggle
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showMapModeOptions();
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.layers,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Heat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.explore, 'Explore', true),
            _buildNavItem(Icons.group, 'Friends', false),
            _buildNavItem(Icons.add_location, 'Add Story', false),
            _buildNavItem(Icons.person, 'Me', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Handle navigation
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.yellow : Colors.white70,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.yellow : Colors.white70,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showMapModeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Map Display Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildModeOption(
                'Heat Map', 'Show story density with colors', true),
            _buildModeOption('Pin Mode', 'Individual story pins', false),
            _buildModeOption('Satellite', 'Satellite view overlay', false),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String title, String subtitle, bool isSelected) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.yellow.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.yellow : Colors.white70,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
