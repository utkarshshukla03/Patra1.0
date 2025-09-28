import 'dart:math';
import 'package:flutter/material.dart';

class UserStory {
  final String id;
  final String userId;
  final String username;
  final String userPhoto;
  final String storyImage;
  final String? storyText;
  final DateTime timestamp;
  final LocationPoint location;
  final bool isViewed;

  UserStory({
    required this.id,
    required this.userId,
    required this.username,
    required this.userPhoto,
    required this.storyImage,
    this.storyText,
    required this.timestamp,
    required this.location,
    this.isViewed = false,
  });

  // Check if story is recent (within 24 hours)
  bool get isRecent => DateTime.now().difference(timestamp).inHours < 24;
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final String locationName;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  // Calculate distance between two points in kilometers
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    double lat1Rad = latitude * pi / 180;
    double lat2Rad = other.latitude * pi / 180;
    double deltaLatRad = (other.latitude - latitude) * pi / 180;
    double deltaLngRad = (other.longitude - longitude) * pi / 180;

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}

class HeatPoint {
  final LocationPoint location;
  final int storyCount;
  final List<UserStory> stories;

  HeatPoint({
    required this.location,
    required this.storyCount,
    required this.stories,
  });

  // Get heat intensity (0.0 to 1.0)
  double get intensity {
    if (storyCount == 0) return 0.0;
    // Normalize based on max expected stories in an area (let's say 50)
    return (storyCount / 50.0).clamp(0.0, 1.0);
  }

  // Get heat color based on intensity
  Color get heatColor {
    if (intensity < 0.2) return Colors.blue.withValues(alpha: 0.6);
    if (intensity < 0.4) return Colors.green.withValues(alpha: 0.7);
    if (intensity < 0.6) return Colors.yellow.withValues(alpha: 0.8);
    if (intensity < 0.8) return Colors.orange.withValues(alpha: 0.9);
    return Colors.red.withValues(alpha: 1.0);
  }

  // Get heat radius for display
  double get heatRadius {
    return 20.0 + (intensity * 40.0); // 20-60 radius based on intensity
  }
}

// Mock data generator for Thapar Institute area
class StoryMapData {
  // Thapar Institute coordinates
  static const LocationPoint thaparCenter = LocationPoint(
    latitude: 30.3540,
    longitude: 76.3636,
    locationName: "Thapar Institute of Engineering & Technology",
  );

  // Generate mock stories around Thapar campus
  static List<UserStory> getMockStories() {
    final Random random = Random();
    final List<UserStory> stories = [];

    // Mock locations around Thapar campus
    final List<Map<String, dynamic>> campusLocations = [
      {
        'name': 'Central Library',
        'lat': 30.3545,
        'lng': 76.3630,
        'stories': 12,
      },
      {
        'name': 'Academic Block A',
        'lat': 30.3535,
        'lng': 76.3640,
        'stories': 8,
      },
      {
        'name': 'Hostel Block',
        'lat': 30.3550,
        'lng': 76.3625,
        'stories': 15,
      },
      {
        'name': 'Sports Complex',
        'lat': 30.3525,
        'lng': 76.3645,
        'stories': 6,
      },
      {
        'name': 'Food Court',
        'lat': 30.3540,
        'lng': 76.3630,
        'stories': 20,
      },
      {
        'name': 'Main Gate',
        'lat': 30.3530,
        'lng': 76.3650,
        'stories': 10,
      },
      {
        'name': 'Auditorium',
        'lat': 30.3548,
        'lng': 76.3635,
        'stories': 7,
      },
      {
        'name': 'Engineering Block',
        'lat': 30.3542,
        'lng': 76.3642,
        'stories': 9,
      },
    ];

    final List<String> mockUsernames = [
      'Arjun',
      'Priya',
      'Rohit',
      'Sneha',
      'Vikram',
      'Ananya',
      'Karan',
      'Divya',
      'Aditya',
      'Riya',
      'Harsh',
      'Pooja'
    ];

    final List<String> mockPhotos = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'https://images.unsplash.com/photo-1494790108755-2616b67fcec?w=150',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150',
    ];

    final List<String> storyTexts = [
      'Having a great time at campus! 🎓',
      'Library sessions with friends 📚',
      'Amazing food at the cafeteria! 🍕',
      'Sports day vibes 🏃‍♂️',
      'Study group session 💻',
      'Campus life is awesome! 🌟',
      'Late night coding 👨‍💻',
      'Beautiful sunset from hostel 🌅',
    ];

    int storyId = 1;

    // Generate stories for each location
    for (var location in campusLocations) {
      for (int i = 0; i < location['stories']; i++) {
        final username = mockUsernames[random.nextInt(mockUsernames.length)];
        final photo = mockPhotos[random.nextInt(mockPhotos.length)];
        final storyText = storyTexts[random.nextInt(storyTexts.length)];

        // Add small random offset to coordinates for variety
        final latOffset = (random.nextDouble() - 0.5) * 0.001;
        final lngOffset = (random.nextDouble() - 0.5) * 0.001;

        stories.add(UserStory(
          id: 'story_$storyId',
          userId: 'user_${random.nextInt(1000)}',
          username: username,
          userPhoto: photo,
          storyImage: 'https://picsum.photos/400/600?random=$storyId',
          storyText: storyText,
          timestamp: DateTime.now().subtract(
            Duration(hours: random.nextInt(24)),
          ),
          location: LocationPoint(
            latitude: location['lat'] + latOffset,
            longitude: location['lng'] + lngOffset,
            locationName: location['name'],
          ),
        ));

        storyId++;
      }
    }

    return stories;
  }

  // Generate heat points from stories
  static List<HeatPoint> generateHeatPoints(List<UserStory> stories) {
    final Map<String, List<UserStory>> locationGroups = {};

    // Group stories by approximate location (within 50m radius)
    for (var story in stories) {
      String locationKey = _getLocationKey(story.location);
      if (!locationGroups.containsKey(locationKey)) {
        locationGroups[locationKey] = [];
      }
      locationGroups[locationKey]!.add(story);
    }

    // Create heat points from grouped stories
    return locationGroups.entries.map((entry) {
      final stories = entry.value;
      final avgLat =
          stories.map((s) => s.location.latitude).reduce((a, b) => a + b) /
              stories.length;
      final avgLng =
          stories.map((s) => s.location.longitude).reduce((a, b) => a + b) /
              stories.length;

      return HeatPoint(
        location: LocationPoint(
          latitude: avgLat,
          longitude: avgLng,
          locationName: stories.first.location.locationName,
        ),
        storyCount: stories.length,
        stories: stories,
      );
    }).toList();
  }

  static String _getLocationKey(LocationPoint location) {
    // Round to 4 decimal places for grouping (approximately 10m precision)
    final lat = (location.latitude * 10000).round() / 10000;
    final lng = (location.longitude * 10000).round() / 10000;
    return '${lat}_$lng';
  }
}
