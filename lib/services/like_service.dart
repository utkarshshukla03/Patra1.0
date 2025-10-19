import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as UserModel;

class LikeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a like to another user
  static Future<bool> sendLike(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return false;
      }

      final String currentUserId = currentUser.uid;

      print('💖 Sending like from $currentUserId to $targetUserId');

      // Check if already liked
      final existingLike = await _firestore
          .collection('likes')
          .doc('${currentUserId}_$targetUserId')
          .get();

      if (existingLike.exists) {
        print('⚠️ Already liked this user');
        return true; // Already liked, consider it successful
      }

      // Get current user data for the like record
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (!currentUserDoc.exists) {
        print('❌ Current user document not found');
        return false;
      }

      final currentUserData = currentUserDoc.data()!;

      // Create the like document
      final likeData = {
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'fromUserData': {
          'username': currentUserData['username'] ?? 'Unknown',
          'photoUrl': currentUserData['photoUrl'] ??
              (currentUserData['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': currentUserData['age'] ??
              _calculateAge(currentUserData['dateOfBirth']),
          'bio': currentUserData['bio'] ?? '',
          'location': currentUserData['location'] ?? '',
        },
      };

      // Save the like
      await _firestore
          .collection('likes')
          .doc('${currentUserId}_$targetUserId')
          .set(likeData);

      print('✅ Like sent successfully');

      // Check if it's a mutual like (match)
      final mutualLike = await _firestore
          .collection('likes')
          .doc('${targetUserId}_$currentUserId')
          .get();

      if (mutualLike.exists) {
        print('🎉 Mutual like detected! Creating match...');
        await _createMatch(currentUserId, targetUserId);
      }

      return true;
    } catch (e) {
      print('❌ Error sending like: $e');
      return false;
    }
  }

  // Create a match when mutual likes are detected
  static Future<void> _createMatch(String userId1, String userId2) async {
    try {
      // Get both user documents
      final user1Doc = await _firestore.collection('users').doc(userId1).get();
      final user2Doc = await _firestore.collection('users').doc(userId2).get();

      if (!user1Doc.exists || !user2Doc.exists) {
        print('❌ One or both user documents not found');
        return;
      }

      final user1Data = user1Doc.data()!;
      final user2Data = user2Doc.data()!;

      // Create match document
      final matchData = {
        'user1Id': userId1,
        'user2Id': userId2,
        'matchedAt': FieldValue.serverTimestamp(),
        'user1Data': {
          'username': user1Data['username'] ?? 'Unknown',
          'photoUrl': user1Data['photoUrl'] ??
              (user1Data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': user1Data['age'] ?? _calculateAge(user1Data['dateOfBirth']),
          'bio': user1Data['bio'] ?? '',
          'location': user1Data['location'] ?? '',
        },
        'user2Data': {
          'username': user2Data['username'] ?? 'Unknown',
          'photoUrl': user2Data['photoUrl'] ??
              (user2Data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': user2Data['age'] ?? _calculateAge(user2Data['dateOfBirth']),
          'bio': user2Data['bio'] ?? '',
          'location': user2Data['location'] ?? '',
        },
        'isActive': true,
        'lastMessage': null,
        'lastMessageAt': null,
      };

      // Create the match
      final matchRef = _firestore.collection('matches').doc();
      await matchRef.set(matchData);

      // Send match notifications to both users
      await _sendMatchNotifications(
          matchRef.id, userId1, userId2, user1Data, user2Data);

      print('✅ Match created successfully with ID: ${matchRef.id}');
    } catch (e) {
      print('❌ Error creating match: $e');
    }
  }

  // Send match notifications to both users
  static Future<void> _sendMatchNotifications(
    String matchId,
    String userId1,
    String userId2,
    Map<String, dynamic> user1Data,
    Map<String, dynamic> user2Data,
  ) async {
    try {
      final batch = _firestore.batch();

      // Notification for user1
      final notification1Ref =
          _firestore.collection('match_notifications').doc();
      final notification1Data = {
        'id': notification1Ref.id,
        'matchId': matchId,
        'fromUserId': userId2,
        'toUserId': userId1,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'fromUserData': {
          'username': user2Data['username'] ?? 'Unknown',
          'photoUrl': user2Data['photoUrl'] ??
              (user2Data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': user2Data['age'] ?? _calculateAge(user2Data['dateOfBirth']),
        },
        'toUserData': {
          'username': user1Data['username'] ?? 'Unknown',
          'photoUrl': user1Data['photoUrl'] ??
              (user1Data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': user1Data['age'] ?? _calculateAge(user1Data['dateOfBirth']),
        },
      };
      batch.set(notification1Ref, notification1Data);

      // Notification for user2
      final notification2Ref =
          _firestore.collection('match_notifications').doc();
      final notification2Data = {
        'id': notification2Ref.id,
        'matchId': matchId,
        'fromUserId': userId1,
        'toUserId': userId2,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'fromUserData': {
          'username': user1Data['username'] ?? 'Unknown',
          'photoUrl': user1Data['photoUrl'] ??
              (user1Data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': user1Data['age'] ?? _calculateAge(user1Data['dateOfBirth']),
        },
        'toUserData': {
          'username': user2Data['username'] ?? 'Unknown',
          'photoUrl': user2Data['photoUrl'] ??
              (user2Data['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': user2Data['age'] ?? _calculateAge(user2Data['dateOfBirth']),
        },
      };
      batch.set(notification2Ref, notification2Data);

      await batch.commit();
      print('✅ Match notifications sent successfully');
    } catch (e) {
      print('❌ Error sending match notifications: $e');
    }
  }

  // Send a super like
  static Future<bool> sendSuperLike(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return false;
      }

      final String currentUserId = currentUser.uid;

      print('⭐ Sending super like from $currentUserId to $targetUserId');

      // Check if already super liked
      final existingSuperLike = await _firestore
          .collection('super_likes')
          .doc('${currentUserId}_$targetUserId')
          .get();

      if (existingSuperLike.exists) {
        print('⚠️ Already super liked this user');
        return true;
      }

      // Get current user data
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (!currentUserDoc.exists) {
        print('❌ Current user document not found');
        return false;
      }

      final currentUserData = currentUserDoc.data()!;

      // Create the super like document
      final superLikeData = {
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'fromUserData': {
          'username': currentUserData['username'] ?? 'Unknown',
          'photoUrl': currentUserData['photoUrl'] ??
              (currentUserData['photoUrls'] as List?)?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'age': currentUserData['age'] ??
              _calculateAge(currentUserData['dateOfBirth']),
          'bio': currentUserData['bio'] ?? '',
          'location': currentUserData['location'] ?? '',
        },
      };

      // Save the super like
      await _firestore
          .collection('super_likes')
          .doc('${currentUserId}_$targetUserId')
          .set(superLikeData);

      // Super likes automatically create matches
      await _createMatch(currentUserId, targetUserId);

      print('✅ Super like sent and match created');
      return true;
    } catch (e) {
      print('❌ Error sending super like: $e');
      return false;
    }
  }

  // Get likes received by current user (for requests tab)
  static Stream<List<Map<String, dynamic>>> getLikesReceived() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final likes = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'fromUserId': data['fromUserId'],
          'fromUserData': data['fromUserData'],
          'timestamp': data['timestamp'],
        };
      }).toList();

      // Sort by timestamp in memory to avoid index requirement
      likes.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return likes;
    });
  }

  // Check if user has already swiped on target user
  static Future<bool> hasAlreadySwiped(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final String currentUserId = currentUser.uid;

      // Check likes
      final likeDoc = await _firestore
          .collection('likes')
          .doc('${currentUserId}_$targetUserId')
          .get();

      // Check super likes
      final superLikeDoc = await _firestore
          .collection('super_likes')
          .doc('${currentUserId}_$targetUserId')
          .get();

      // Check dislikes
      final dislikeDoc = await _firestore
          .collection('dislikes')
          .doc('${currentUserId}_$targetUserId')
          .get();

      return likeDoc.exists || superLikeDoc.exists || dislikeDoc.exists;
    } catch (e) {
      print('❌ Error checking swipe status: $e');
      return false;
    }
  }

  // Save dislike action
  static Future<bool> sendDislike(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final String currentUserId = currentUser.uid;

      await _firestore
          .collection('dislikes')
          .doc('${currentUserId}_$targetUserId')
          .set({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('👎 Dislike saved for $targetUserId');
      return true;
    } catch (e) {
      print('❌ Error sending dislike: $e');
      return false;
    }
  }

  // Helper method to calculate age
  static int? _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return null;

    DateTime? dob;
    if (dateOfBirth is Timestamp) {
      dob = dateOfBirth.toDate();
    } else if (dateOfBirth is String) {
      dob = DateTime.tryParse(dateOfBirth);
    }

    if (dob == null) return null;

    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
