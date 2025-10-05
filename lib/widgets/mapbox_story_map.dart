import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/story_map.dart';

class MapboxStoryMap extends StatefulWidget {
  final List<HeatPoint> heatPoints;
  final Function(HeatPoint) onHeatPointTapped;

  const MapboxStoryMap({
    Key? key,
    required this.heatPoints,
    required this.onHeatPointTapped,
  }) : super(key: key);

  @override
  State<MapboxStoryMap> createState() => _MapboxStoryMapState();
}

class _MapboxStoryMapState extends State<MapboxStoryMap>
    with TickerProviderStateMixin {
  MapController _mapController = MapController();

  Position? _currentPosition;
  bool _serviceEnabled = false;
  LocationPermission _permissionGranted = LocationPermission.denied;

  // Thapar Institute coordinates
  static const LatLng _thaparCenter = LatLng(30.3540, 76.3636);

  List<Marker> _markers = [];
  List<CircleMarker> _heatCircles = [];

  // Map style URLs
  String _currentTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _addHeatPoints();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Check if location services are enabled
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      // Check location permission
      _permissionGranted = await Geolocator.checkPermission();
      if (_permissionGranted == LocationPermission.denied) {
        _permissionGranted = await Geolocator.requestPermission();
        if (_permissionGranted == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (_permissionGranted == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      // Get current location
      _currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting location: $e');
      // On web, if there's an error, just continue without location
      if (kIsWeb) {
        print('Web location error ignored, continuing...');
      }
    }
  }

  void _addHeatPoints() {
    _markers.clear();
    _heatCircles.clear();

    // Add heat circles and markers for each heat point
    for (int i = 0; i < widget.heatPoints.length; i++) {
      final heatPoint = widget.heatPoints[i];
      final position = LatLng(
        heatPoint.location.latitude,
        heatPoint.location.longitude,
      );

      // Add heat circle
      _heatCircles.add(
        CircleMarker(
          point: position,
          radius: heatPoint.heatRadius,
          color: heatPoint.heatColor.withOpacity(0.6),
          borderColor: heatPoint.heatColor.withOpacity(0.8),
          borderStrokeWidth: 2,
        ),
      );

      // Add marker at the center
      _markers.add(
        Marker(
          width: 40,
          height: 40,
          point: position,
          child: GestureDetector(
            onTap: () => widget.onHeatPointTapped(heatPoint),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${heatPoint.storyCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _moveToUserLocation() async {
    if (_currentPosition != null) {
      final userLatLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _mapController.move(userLatLng, 16.0);

      // Add user location marker
      setState(() {
        _markers.add(
          Marker(
            width: 30,
            height: 30,
            point: userLatLng,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      });
    }
  }

  Future<void> _moveToThapar() async {
    _mapController.move(_thaparCenter, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _thaparCenter,
              initialZoom: 14.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _currentTileUrl,
                userAgentPackageName: 'com.example.patra_initial',
                maxZoom: 18,
              ),
              CircleLayer(circles: _heatCircles),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Map style and location buttons
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.layers, color: Colors.white),
                        onPressed: _toggleMapStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.my_location, color: Colors.white),
                        onPressed: _moveToUserLocation,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Story count info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.heatPoints.fold(0, (sum, hp) => sum + hp.storyCount)} stories around campus',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _moveToThapar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              '🎓 Thapar Campus',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.black),
                            onPressed: () {
                              // TODO: Implement add story functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Add Story feature coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMapStyle() {
    setState(() {
      if (_isSatelliteView) {
        _currentTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        _isSatelliteView = false;
      } else {
        // Using a satellite-like tile provider
        _currentTileUrl =
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
        _isSatelliteView = true;
      }
      debugPrint(
          'Map style updated to: ${_isSatelliteView ? "Satellite" : "OpenStreetMap"}');
    });
  }
}
