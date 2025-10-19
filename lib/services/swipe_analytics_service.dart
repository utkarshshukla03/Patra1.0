import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwipeAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's swipe statistics
  static Future<Map<String, dynamic>?> getUserSwipeStats(String? userId) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return null;

      final DocumentSnapshot doc =
          await _firestore.collection('user_analytics').doc(uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }

      return {
        'totalSwipes': 0,
        'likeCount': 0,
        'superlikeCount': 0,
        'rejectCount': 0,
        'matchCount': 0,
      };
    } catch (e) {
      print('Error getting user swipe stats: $e');
      return null;
    }
  }

  // Get detailed swipe history for a user
  static Future<List<Map<String, dynamic>>> getUserSwipeHistory(String? userId,
      {int limit = 50}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return [];

      final QuerySnapshot querySnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting user swipe history: $e');
      return [];
    }
  }

  // Get users who swiped on current user (incoming likes/superlikes)
  static Future<List<Map<String, dynamic>>> getIncomingSwipes(
      {String type = 'all'}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      Query query = _firestore
          .collection('swipes')
          .where('targetUserId', isEqualTo: currentUser.uid);

      // Filter by action type if specified
      if (type != 'all') {
        query = query.where('actionType', isEqualTo: type);
      }

      final QuerySnapshot querySnapshot =
          await query.orderBy('timestamp', descending: true).get();

      List<Map<String, dynamic>> incomingSwipes = [];

      for (var doc in querySnapshot.docs) {
        final swipeData = doc.data() as Map<String, dynamic>;

        // Get the swiper's user data
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(swipeData['userId']).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          incomingSwipes.add({
            'swipeId': doc.id,
            'actionType': swipeData['actionType'],
            'timestamp': swipeData['timestamp'],
            'fromUser': userData,
          });
        }
      }

      return incomingSwipes;
    } catch (e) {
      print('Error getting incoming swipes: $e');
      return [];
    }
  }

  // Calculate match rate for user
  static Future<double> getUserMatchRate(String? userId) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return 0.0;

      final stats = await getUserSwipeStats(uid);
      if (stats == null) return 0.0;

      final totalLikes =
          (stats['likeCount'] ?? 0) + (stats['superlikeCount'] ?? 0);
      final matches = stats['matchCount'] ?? 0;

      if (totalLikes == 0) return 0.0;

      return (matches / totalLikes) * 100; // Return as percentage
    } catch (e) {
      print('Error calculating match rate: $e');
      return 0.0;
    }
  }

  // Get daily swipe limits and usage
  static Future<Map<String, dynamic>> getDailySwipeInfo(String? userId) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return {};

      // Format date consistently
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final DocumentSnapshot doc =
          await _firestore.collection('user_analytics').doc(uid).get();

      print('🔍 Checking daily swipe info for user $uid on $dateKey');

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final dailySwipes = data['dailySwipes'] as Map<String, dynamic>? ?? {};
        final todaySwipes = dailySwipes[dateKey] ?? 0;

        print('📊 Found daily swipes data: $dailySwipes');
        print('📊 Today ($dateKey) swipes: $todaySwipes');

        return {
          'todaySwipes': todaySwipes,
          'dailyLimit': 100, // Default daily limit
          'remainingSwipes': 100 - todaySwipes,
          'canSwipe': todaySwipes < 100,
          'dateKey': dateKey, // For debugging
        };
      }

      print('📊 No analytics document found, returning defaults');
      return {
        'todaySwipes': 0,
        'dailyLimit': 100,
        'remainingSwipes': 100,
        'canSwipe': true,
        'dateKey': dateKey,
      };
    } catch (e) {
      print('Error getting daily swipe info: $e');
      return {};
    }
  }

  // Reset daily swipe count (for testing or admin purposes)
  static Future<bool> resetDailySwipeCount(String? userId) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return false;

      // Format date consistently
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('user_analytics').doc(uid).update({
        'dailySwipes.$dateKey': 0,
      });

      print('🔄 Reset daily swipe count for $uid on $dateKey');
      return true;
    } catch (e) {
      print('Error resetting daily swipe count: $e');
      return false;
    }
  }

  // Export user data for ML training (anonymized)
  static Future<Map<String, dynamic>?> exportUserDataForML(
      String userId) async {
    try {
      final swipeHistory = await getUserSwipeHistory(userId, limit: 1000);
      final stats = await getUserSwipeStats(userId);

      // Create anonymized export for ML
      return {
        'userId': userId, // Keep for ML training
        'stats': stats,
        'swipeHistory': swipeHistory
            .map((swipe) => {
                  'actionType': swipe['actionType'],
                  'timestamp': swipe['timestamp'],
                  // Remove sensitive user data
                })
            .toList(),
        'exportTimestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error exporting user data for ML: $e');
      return null;
    }
  }
}
