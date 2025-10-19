import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match.dart';
import '../models/like_request.dart';
import 'match_notification_service.dart';

class MatchesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a match when a user accepts a like request
  static Future<bool> createMatch(LikeRequest request) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return false;
      }

      print(
          '🔄 Creating match between ${request.fromUserId} and ${currentUser.uid}');

      // Get current user data
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) {
        print('❌ Current user document not found');
        return false;
      }

      final currentUserData = currentUserDoc.data()!;
      final currentUserInfo = {
        'name': currentUserData['username'] ?? 'Unknown User',
        'age': currentUserData['age'] ??
            _calculateAge(currentUserData['dateOfBirth']),
        'photo': currentUserData['photoUrl'] ??
            (currentUserData['photoUrls'] as List?)?.first ??
            'https://via.placeholder.com/400x600?text=No+Image',
        'bio': currentUserData['bio'] ?? 'No bio available',
        'email': currentUserData['email'] ?? '',
        'interests': currentUserData['interests'] ?? [],
        'location': currentUserData['location'] ?? 'Unknown location',
      };

      // Get user info from LikeRequest
      final requesterUserInfo = {
        'name': request.fromUserName,
        'age': request.fromUserAge,
        'photo': request.fromUserPhoto,
        'bio': request.fromUserBio,
        'email': request.fullUserData?['email'] ?? '',
        'interests': request.fullUserData?['interests'] ?? [],
        'location': request.fullUserData?['location'] ?? 'Unknown location',
      };

      // Create match document
      final matchData = {
        'user1Id': request.fromUserId, // Person who sent the like
        'user2Id': currentUser.uid, // Person who accepted
        'matchedAt': FieldValue.serverTimestamp(),
        'user1Data': requesterUserInfo,
        'user2Data': currentUserInfo,
        'isActive': true,
        'lastMessage': null,
        'lastMessageAt': null,
      };

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Create the match
      final matchRef = _firestore.collection('matches').doc();
      batch.set(matchRef, matchData);

      // Remove the like request
      final requestQuery = await _firestore
          .collection('like_requests')
          .where('fromUserId', isEqualTo: request.fromUserId)
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in requestQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ Match created successfully with ID: ${matchRef.id}');

      // Send match notifications to both users
      await MatchNotificationService.sendMatchNotification(
        matchRef.id,
        request.fromUserId,
        currentUser.uid,
        requesterUserInfo,
        currentUserInfo,
      );

      return true;
    } catch (e) {
      print('❌ Error creating match: $e');
      return false;
    }
  }

  // Get matches for current user
  static Stream<List<Match>> getUserMatches() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .where('user1Id', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot1) async {
      final matches1 =
          snapshot1.docs.map((doc) => Match.fromFirestore(doc)).toList();

      // Also get matches where current user is user2
      final snapshot2 = await _firestore
          .collection('matches')
          .where('isActive', isEqualTo: true)
          .where('user2Id', isEqualTo: currentUser.uid)
          .get();

      final matches2 =
          snapshot2.docs.map((doc) => Match.fromFirestore(doc)).toList();

      final allMatches = [...matches1, ...matches2];

      // Sort by last message time or match time
      allMatches.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.matchedAt;
        final bTime = b.lastMessageAt ?? b.matchedAt;
        return bTime.compareTo(aTime);
      });

      return allMatches;
    });
  }

  // Update last message in match
  static Future<void> updateLastMessage(String matchId, String message) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating last message: $e');
    }
  }

  // Delete/deactivate a match
  static Future<bool> deleteMatch(String matchId) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('❌ Error deleting match: $e');
      return false;
    }
  }

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
