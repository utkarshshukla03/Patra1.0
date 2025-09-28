import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/story_map.dart';

// For web platform, we'll use a simplified map until Google Maps is properly configured
class WebFallbackMap extends StatefulWidget {
  final List<HeatPoint> heatPoints;
  final Function(HeatPoint) onHeatPointTapped;

  const WebFallbackMap({
    Key? key,
    required this.heatPoints,
    required this.onHeatPointTapped,
  }) : super(key: key);

  @override
  State<WebFallbackMap> createState() => _WebFallbackMapState();
}

class _WebFallbackMapState extends State<WebFallbackMap>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Map viewport settings
  static const double _mapWidth = 2000.0;
  static const double _mapHeight = 2000.0;
  static const double _initialScale = 2.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // Set initial position to center on Thapar Institute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnThapar();
    });

    // Pulse animation for heat points
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _centerOnThapar() {
    const double centerX = _mapWidth / 2;
    const double centerY = _mapHeight / 2;

    final Size screenSize = MediaQuery.of(context).size;
    final double translateX =
        (screenSize.width / 2) - (centerX * _initialScale);
    final double translateY =
        (screenSize.height / 2) - (centerY * _initialScale);

    _transformationController.value = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(_initialScale);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Convert lat/lng to map coordinates
  Offset _locationToMapCoordinates(LocationPoint location) {
    // Convert relative to Thapar center
    const double thaparLat = 30.3540;
    const double thaparLng = 76.3636;

    // Scale factor for coordinate conversion (approximate)
    const double latScale = 100000.0;
    const double lngScale = 100000.0;

    final double x =
        _mapWidth / 2 + (location.longitude - thaparLng) * lngScale;
    final double y =
        _mapHeight / 2 - (location.latitude - thaparLat) * latScale;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map background with Snapchat-style design
        Container(
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
        ),

        // Interactive map with heat points
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          constrained: false,
          child: SizedBox(
            width: _mapWidth,
            height: _mapHeight,
            child: Stack(
              children: [
                // Campus background pattern
                _buildCampusBackground(),

                // Heat points and stories
                ...widget.heatPoints
                    .map((heatPoint) => _buildHeatPoint(heatPoint)),

                // Center marker for Thapar
                _buildCenterMarker(),
              ],
            ),
          ),
        ),

        // Map controls
        _buildMapControls(),

        // Location indicator
        _buildLocationIndicator(),

        // Web notice
        _buildWebNotice(),
      ],
    );
  }

  Widget _buildCampusBackground() {
    return Container(
      width: _mapWidth,
      height: _mapHeight,
      child: CustomPaint(
        painter: CampusBackgroundPainter(),
      ),
    );
  }

  Widget _buildHeatPoint(HeatPoint heatPoint) {
    final Offset position = _locationToMapCoordinates(heatPoint.location);

    return Positioned(
      left: position.dx - heatPoint.heatRadius,
      top: position.dy - heatPoint.heatRadius,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onHeatPointTapped(heatPoint);
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: heatPoint.heatRadius * 2,
                height: heatPoint.heatRadius * 2,
                decoration: BoxDecoration(
                  color: heatPoint.heatColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: heatPoint.heatColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${heatPoint.storyCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: heatPoint.heatRadius / 3,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCenterMarker() {
    final Offset position =
        _locationToMapCoordinates(StoryMapData.thaparCenter);

    return Positioned(
      left: position.dx - 15,
      top: position.dy - 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_pin,
            color: Colors.yellow,
            size: 30,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.87),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Thapar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 20,
      top: 100,
      child: Column(
        children: [
          // Recenter button
          _buildControlButton(
            icon: Icons.my_location,
            onTap: _centerOnThapar,
            tooltip: 'Center on Thapar',
          ),
          SizedBox(height: 10),

          // Zoom in button
          _buildControlButton(
            icon: Icons.zoom_in,
            onTap: _zoomIn,
            tooltip: 'Zoom In',
          ),
          SizedBox(height: 5),

          // Zoom out button
          _buildControlButton(
            icon: Icons.zoom_out,
            onTap: _zoomOut,
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIndicator() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.87),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.yellow,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thapar Institute',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Patiala, Punjab • ${widget.heatPoints.length} story zones',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebNotice() {
    if (!kIsWeb) return SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Web Demo Mode • Add Google Maps API key for full functionality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(1.2);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(0.8);
    _transformationController.value = matrix;
  }
}

class CampusBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint buildingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw campus roads/paths
    _drawCampusRoads(canvas, size, pathPaint);

    // Draw building outlines
    _drawBuildings(canvas, size, buildingPaint);
  }

  void _drawCampusRoads(Canvas canvas, Size size, Paint paint) {
    final Path path = Path();

    // Main road horizontal
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.9, size.height * 0.5);

    // Main road vertical
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.5, size.height * 0.9);

    // Cross roads
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.8);

    path.moveTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width * 0.3, size.height * 0.8);

    canvas.drawPath(path, paint);
  }

  void _drawBuildings(Canvas canvas, Size size, Paint paint) {
    // Academic blocks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.25, 120, 80),
        Radius.circular(8),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, size.height * 0.35, 100, 90),
        Radius.circular(8),
      ),
      paint,
    );

    // Hostels
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.6, 80, 120),
        Radius.circular(8),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.7, size.height * 0.6, 80, 100),
        Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
