import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, dynamic> user1Data;
  final Map<String, dynamic> user2Data;
  final bool isActive;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageAt,
    required this.user1Data,
    required this.user2Data,
    this.isActive = true,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      user1Id: data['user1Id'],
      user2Id: data['user2Id'],
      matchedAt: (data['matchedAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      user1Data: data['user1Data'] ?? {},
      user2Data: data['user2Data'] ?? {},
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'lastMessage': lastMessage,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'user1Data': user1Data,
      'user2Data': user2Data,
      'isActive': isActive,
    };
  }

  // Get the other user's data relative to current user
  Map<String, dynamic> getOtherUserData(String currentUserId) {
    return currentUserId == user1Id ? user2Data : user1Data;
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  String getFormattedTime() {
    if (lastMessageAt == null) return 'Just matched';

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
