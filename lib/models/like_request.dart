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

  // Factory from Firestore document
  factory LikeRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return LikeRequest(
      id: id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserData']?['username'] ?? 'Unknown',
      fromUserPhoto: data['fromUserData']?['photoUrl'] ?? 
                    'https://via.placeholder.com/400x600?text=No+Image',
      fromUserAge: data['fromUserData']?['age'] ?? 18,
      fromUserBio: data['fromUserData']?['bio'] ?? '',
      type: data['type'] == 'superlike' ? RequestType.superlike : RequestType.like,
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      fullUserData: data['fromUserData'],
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserData': {
        'username': fromUserName,
        'photoUrl': fromUserPhoto,
        'age': fromUserAge,
        'bio': fromUserBio,
      },
      'type': type == RequestType.superlike ? 'superlike' : 'like',
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}
