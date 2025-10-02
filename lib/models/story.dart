import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String userId;
  final String username;
  final String? userPhoto;
  final String storyImage;
  final String storyText;
  final DateTime timestamp;
  final StoryLocation location;
  final bool isViewed;
  final DateTime expiresAt;
  final List<String> viewedBy;

  const Story({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhoto,
    required this.storyImage,
    required this.storyText,
    required this.timestamp,
    required this.location,
    required this.isViewed,
    required this.expiresAt,
    this.viewedBy = const [],
  });

  // Convert Story to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhoto': userPhoto,
      'storyImage': storyImage,
      'storyText': storyText,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location.toMap(),
      'isViewed': isViewed,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
    };
  }

  // Create Story from Firestore document
  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userPhoto: map['userPhoto'],
      storyImage: map['storyImage'] ?? '',
      storyText: map['storyText'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: StoryLocation.fromMap(map['location'] ?? {}),
      isViewed: map['isViewed'] ?? false,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? 
          DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
    );
  }

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story.fromMap(data);
  }

  // Check if story is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Check if story is active (not expired)
  bool get isActive => !isExpired;

  // Get remaining time before expiration
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  // Get formatted time remaining (e.g., "2h", "30m", "expired")
  String get formattedTimeRemaining {
    if (isExpired) return "expired";
    
    final remaining = timeRemaining;
    if (remaining.inHours > 0) {
      return "${remaining.inHours}h";
    } else if (remaining.inMinutes > 0) {
      return "${remaining.inMinutes}m";
    } else {
      return "<1m";
    }
  }

  // Copy with updated fields
  Story copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhoto,
    String? storyImage,
    String? storyText,
    DateTime? timestamp,
    StoryLocation? location,
    bool? isViewed,
    DateTime? expiresAt,
    List<String>? viewedBy,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhoto: userPhoto ?? this.userPhoto,
      storyImage: storyImage ?? this.storyImage,
      storyText: storyText ?? this.storyText,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      isViewed: isViewed ?? this.isViewed,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }

  @override
  String toString() {
    return 'Story(id: $id, userId: $userId, username: $username, storyText: $storyText, timestamp: $timestamp)';
  }
}

class StoryLocation {
  final double latitude;
  final double longitude;
  final String locationName;

  const StoryLocation({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  factory StoryLocation.fromMap(Map<String, dynamic> map) {
    return StoryLocation(
      latitude: (map['latitude'] ?? 30.3540).toDouble(),
      longitude: (map['longitude'] ?? 76.3636).toDouble(),
      locationName: map['locationName'] ?? 'Unknown Location',
    );
  }

  @override
  String toString() {
    return 'StoryLocation(latitude: $latitude, longitude: $longitude, locationName: $locationName)';
  }
}