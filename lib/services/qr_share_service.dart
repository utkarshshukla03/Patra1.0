import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRShareService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a like request to a user via QR code scan
  static Future<bool> sendLikeRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return false;
      }

      print('🔄 Sending QR like request to user: $targetUserId');

      // Check if target user exists
      final targetUserDoc =
          await _firestore.collection('users').doc(targetUserId).get();

      if (!targetUserDoc.exists) {
        print('❌ Target user not found');
        return false;
      }

      // Check if request already exists
      final existingRequest = await _firestore
          .collection('like_requests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: targetUserId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        print('⚠️ Like request already sent to this user');
        return false; // Request already exists
      }

      // Check if they're already matched
      final existingMatch1 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUser.uid)
          .where('user2Id', isEqualTo: targetUserId)
          .where('isActive', isEqualTo: true)
          .get();

      final existingMatch2 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: targetUserId)
          .where('user2Id', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingMatch1.docs.isNotEmpty || existingMatch2.docs.isNotEmpty) {
        print('⚠️ Already matched with this user');
        return false;
      }

      // Get current user data
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) {
        print('❌ Current user data not found');
        return false;
      }

      final currentUserData = currentUserDoc.data()!;

      // Create the like request
      final requestData = {
        'fromUserId': currentUser.uid,
        'toUserId': targetUserId,
        'type': 'like',
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'qr_scan', // Track that this came from QR scan
        'fromUserName': currentUserData['username'] ?? 'Unknown User',
        'fromUserPhoto': currentUserData['photoUrl'] ??
            (currentUserData['photoUrls'] as List?)?.first ??
            'https://via.placeholder.com/400x600?text=No+Image',
        'fromUserAge': currentUserData['age'] ?? 22,
        'fromUserBio': currentUserData['bio'] ?? 'No bio available',
        'fullUserData': {
          'name': currentUserData['username'] ?? 'Unknown User',
          'age': currentUserData['age'] ?? 22,
          'photo': currentUserData['photoUrl'] ??
              (currentUserData['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'bio': currentUserData['bio'] ?? 'No bio available',
          'email': currentUserData['email'] ?? '',
          'interests': currentUserData['interests'] ?? [],
          'location': currentUserData['location'] ?? 'Unknown location',
          'photoUrls': currentUserData['photoUrls'] ?? [],
        },
      };

      // Save to Firestore
      await _firestore.collection('like_requests').add(requestData);

      print('✅ QR like request sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending QR like request: $e');
      return false;
    }
  }

  /// Get user info for QR code generation
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'uid': userId,
          'name': data['username'] ?? 'Unknown User',
          'photo': data['photoUrl'] ??
              (data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': data['age'] ?? 22,
          'bio': data['bio'] ?? 'No bio available',
        };
      }
    } catch (e) {
      print('❌ Error getting user info: $e');
    }
    return null;
  }

  /// Check if current user can send request to target user
  static Future<bool> canSendRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if request already exists
      final existingRequest = await _firestore
          .collection('like_requests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: targetUserId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return false; // Request already sent
      }

      // Check if already matched
      final existingMatch1 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUser.uid)
          .where('user2Id', isEqualTo: targetUserId)
          .where('isActive', isEqualTo: true)
          .get();

      final existingMatch2 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: targetUserId)
          .where('user2Id', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .get();

      return existingMatch1.docs.isEmpty && existingMatch2.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking request eligibility: $e');
      return false;
    }
  }

  /// Get QR statistics for analytics
  static Future<Map<String, int>> getQRStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      // Count QR-based requests sent
      final sentQRRequests = await _firestore
          .collection('like_requests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('source', isEqualTo: 'qr_scan')
          .get();

      // Count QR-based requests received
      final receivedQRRequests = await _firestore
          .collection('like_requests')
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('source', isEqualTo: 'qr_scan')
          .get();

      return {
        'qr_requests_sent': sentQRRequests.docs.length,
        'qr_requests_received': receivedQRRequests.docs.length,
      };
    } catch (e) {
      print('❌ Error getting QR stats: $e');
      return {};
    }
  }
}
