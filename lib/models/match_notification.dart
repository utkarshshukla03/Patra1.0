import 'package:cloud_firestore/cloud_firestore.dart';

class MatchNotification {
  final String id;
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> fromUserData;
  final Map<String, dynamic> toUserData;

  MatchNotification({
    required this.id,
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
    this.isRead = false,
    required this.fromUserData,
    required this.toUserData,
  });

  factory MatchNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchNotification(
      id: doc.id,
      matchId: data['matchId'],
      fromUserId: data['fromUserId'],
      toUserId: data['toUserId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      fromUserData: data['fromUserData'] ?? {},
      toUserData: data['toUserData'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'fromUserData': fromUserData,
      'toUserData': toUserData,
    };
  }
}
