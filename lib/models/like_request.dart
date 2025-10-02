enum RequestType {
  like,
  superlike,
}

class LikeRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserPhoto;
  final int fromUserAge;
  final String fromUserBio;
  final RequestType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? fullUserData; // Store complete Firebase user data

  LikeRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserPhoto,
    required this.fromUserAge,
    required this.fromUserBio,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.fullUserData,
  });

  // Mock data factory
  factory LikeRequest.mock(String id) {
    final mockNames = [
      'Emma',
      'Sophia',
      'Olivia',
      'Ava',
      'Isabella',
      'Mia',
      'Abigail',
      'Emily',
      'Harper',
      'Evelyn'
    ];
    final mockBios = [
      'Love hiking and coffee shops ☕️',
      'Yoga enthusiast & book lover 📚',
      'Adventure seeker, let\'s explore together! ✈️',
      'Foodie who loves trying new cuisines 🍜',
      'Artist by day, stargazer by night ✨',
      'Fitness lover & dog mom 🐕',
      'Music lover & concert goer 🎵',
      'Beach walks and sunset views 🌅',
      'Photography and travel enthusiast 📸',
      'Coffee addict & morning person ☀️',
    ];

    final photos = [
      'https://images.unsplash.com/photo-1494790108755-2616b67fcec?w=400',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400',
      'https://images.unsplash.com/photo-1521146764736-56c929d59c83?w=400',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400',
      'https://images.unsplash.com/photo-1504703395950-b89145a5425b?w=400',
    ];

    final index = int.parse(id) % mockNames.length;

    return LikeRequest(
      id: id,
      fromUserId: 'user_$id',
      fromUserName: mockNames[index],
      fromUserPhoto: photos[index],
      fromUserAge: 22 + (int.parse(id) % 8),
      fromUserBio: mockBios[index],
      type: int.parse(id) % 3 == 0 ? RequestType.superlike : RequestType.like,
      timestamp: DateTime.now().subtract(Duration(hours: int.parse(id) % 24)),
    );
  }

  static List<LikeRequest> getMockRequests() {
    return List.generate(
        8, (index) => LikeRequest.mock((index + 1).toString()));
  }
}
