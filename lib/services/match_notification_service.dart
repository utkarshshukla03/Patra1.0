import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_notification.dart';

class MatchNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send match notification to both users
  static Future<void> sendMatchNotification(
    String matchId,
    String user1Id,
    String user2Id,
    Map<String, dynamic> user1Data,
    Map<String, dynamic> user2Data,
  ) async {
    try {
      print('🔔 Sending match notifications for match: $matchId');

      final batch = _firestore.batch();

      // Notification for user1 (the one who originally sent the like)
      final notification1Ref =
          _firestore.collection('match_notifications').doc();
      final notification1 = MatchNotification(
        id: notification1Ref.id,
        matchId: matchId,
        fromUserId: user2Id, // The person who accepted
        toUserId: user1Id, // The person who sent the original like
        createdAt: DateTime.now(),
        fromUserData: user2Data,
        toUserData: user1Data,
      );
      batch.set(notification1Ref, notification1.toFirestore());

      // Notification for user2 (the one who accepted the like)
      final notification2Ref =
          _firestore.collection('match_notifications').doc();
      final notification2 = MatchNotification(
        id: notification2Ref.id,
        matchId: matchId,
        fromUserId: user1Id, // The person who sent the original like
        toUserId: user2Id, // The person who accepted
        createdAt: DateTime.now(),
        fromUserData: user1Data,
        toUserData: user2Data,
      );
      batch.set(notification2Ref, notification2.toFirestore());

      await batch.commit();
      print('✅ Match notifications sent successfully');
    } catch (e) {
      print('❌ Error sending match notifications: $e');
    }
  }

  // Get unread match notifications for user
  static Stream<List<MatchNotification>> getUnreadNotifications(String userId) {
    return _firestore
        .collection('match_notifications')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => MatchNotification.fromFirestore(doc))
          .toList();

      // Sort by createdAt in memory to avoid index requirement
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('match_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Get all notifications for user
  static Stream<List<MatchNotification>> getAllNotifications(String userId) {
    return _firestore
        .collection('match_notifications')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => MatchNotification.fromFirestore(doc))
          .toList();

      // Sort by createdAt in memory and limit to 50
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(50).toList();
    });
  }
}
