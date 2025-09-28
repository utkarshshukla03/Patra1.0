import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import '../models/story_map.dart';

class RealSnapchatMap extends StatefulWidget {
  final List<HeatPoint> heatPoints;
  final Function(HeatPoint) onHeatPointTapped;

  const RealSnapchatMap({
    Key? key,
    required this.heatPoints,
    required this.onHeatPointTapped,
  }) : super(key: key);

  @override
  State<RealSnapchatMap> createState() => _RealSnapchatMapState();
}

class _RealSnapchatMapState extends State<RealSnapchatMap>
    with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Location location = Location();
  LocationData? _currentLocation;
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;

  // Thapar Institute coordinates
  static const LatLng _thaparCenter = LatLng(30.3540, 76.3636);

  Set<Marker> _markers = {};
  Set<Circle> _heatCircles = {};

  @override
  void initState() {
    super.initState();

    // Pulse animation for heat circles
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

    _checkLocationPermission();
    _createMapElements();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();
  }

  void _createMapElements() {
    _markers.clear();
    _heatCircles.clear();

    // Create heat circles and markers for each heat point
    for (int i = 0; i < widget.heatPoints.length; i++) {
      final heatPoint = widget.heatPoints[i];
      final position = LatLng(
        heatPoint.location.latitude,
        heatPoint.location.longitude,
      );

      // Create marker for the center of heat zone
      _markers.add(
        Marker(
          markerId: MarkerId('heat_$i'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(heatPoint.intensity),
          ),
          infoWindow: InfoWindow(
            title: heatPoint.location.locationName,
            snippet: '${heatPoint.storyCount} stories • Tap to view',
          ),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onHeatPointTapped(heatPoint);
          },
        ),
      );

      // Create heat circle around the marker
      _heatCircles.add(
        Circle(
          circleId: CircleId('heat_circle_$i'),
          center: position,
          radius: heatPoint.heatRadius * 5, // Scale up for map
          fillColor: heatPoint.heatColor.withValues(alpha: 0.3),
          strokeColor: heatPoint.heatColor.withValues(alpha: 0.8),
          strokeWidth: 2,
        ),
      );
    }

    // Add Thapar center marker
    _markers.add(
      Marker(
        markerId: const MarkerId('thapar_center'),
        position: _thaparCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(
          title: 'Thapar Institute of Engineering & Technology',
          snippet: 'Campus Center',
        ),
      ),
    );

    setState(() {});
  }

  double _getMarkerColor(double intensity) {
    if (intensity < 0.2) return BitmapDescriptor.hueBlue;
    if (intensity < 0.4) return BitmapDescriptor.hueGreen;
    if (intensity < 0.6) return BitmapDescriptor.hueYellow;
    if (intensity < 0.8) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    // Dark theme map style for Snapchat look
    String mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#1d2c4d"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8ec3b9"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1a3646"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#4b6878"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#64779e"
          }
        ]
      },
      {
        "featureType": "administrative.province",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#4b6878"
          }
        ]
      },
      {
        "featureType": "landscape.man_made",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#334e87"
          }
        ]
      },
      {
        "featureType": "landscape.natural",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#023e58"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#283d6a"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#6f9ba5"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1d2c4d"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#023e58"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3C7680"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#304a7d"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#98a5be"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1d2c4d"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#2c6675"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#255763"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#b0d5ce"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#023e58"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#98a5be"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1d2c4d"
          }
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#283d6a"
          }
        ]
      },
      {
        "featureType": "transit.station",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3a4762"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#0e1626"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#4e6d70"
          }
        ]
      }
    ]
    ''';

    await _mapController.setMapStyle(mapStyle);
  }

  Future<void> _centerOnThapar() async {
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _thaparCenter,
          zoom: 16.0,
          tilt: 0,
        ),
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    if (_currentLocation != null) {
      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 16.0,
            tilt: 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: const CameraPosition(
            target: _thaparCenter,
            zoom: 15.0,
          ),
          markers: _markers,
          circles: _heatCircles,
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          buildingsEnabled: true,
          trafficEnabled: false,
          onTap: (LatLng position) {
            // Handle map tap if needed
          },
        ),

        // Custom controls overlay
        _buildMapControls(),

        // Location indicator
        _buildLocationIndicator(),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 20,
      top: 100,
      child: Column(
        children: [
          // Center on Thapar button
          _buildControlButton(
            icon: Icons.school,
            onTap: _centerOnThapar,
            tooltip: 'Center on Thapar',
            color: Colors.yellow,
          ),
          const SizedBox(height: 10),

          // My location button
          _buildControlButton(
            icon: Icons.my_location,
            onTap: _centerOnUserLocation,
            tooltip: 'My Location',
            color: Colors.blue,
          ),
          const SizedBox(height: 10),

          // Map type toggle
          _buildControlButton(
            icon: Icons.layers,
            onTap: _showMapTypeOptions,
            tooltip: 'Map Type',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required Color color,
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color == Colors.white ? Colors.black87 : color,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.87),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.yellow,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'LIVE',
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

  void _showMapTypeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Map Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMapTypeOption('Normal', MapType.normal),
            _buildMapTypeOption('Satellite', MapType.satellite),
            _buildMapTypeOption('Hybrid', MapType.hybrid),
            _buildMapTypeOption('Terrain', MapType.terrain),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String title, MapType mapType) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        // Note: You would need to add state management for map type
        // For now, we'll just close the modal
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.map,
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
