// Backend placeholder functions for Like/Superlike requests feature
// TODO: Implement with actual backend/Firebase integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsService {
  // Placeholder function to accept a like request
  static Future<bool> onAccept(String requestId) async {
    print('🎉 Accepting request: $requestId');

    // TODO: Implement actual logic:
    // 1. Create a match record in database
    // 2. Remove the request from pending requests
    // 3. Create a chat thread between users
    // 4. Send push notification to both users
    // 5. Update user match count/statistics

    await Future.delayed(const Duration(milliseconds: 500)); // Mock API delay

    return true; // Mock success response
  }

  // Placeholder function to dismiss a like request
  static Future<bool> onDismiss(String requestId) async {
    print('❌ Dismissing request: $requestId');

    // TODO: Implement actual logic:
    // 1. Remove the request from pending requests
    // 2. Add the user to dismissed list (to avoid showing again)
    // 3. Update analytics/statistics
    // 4. Possibly send feedback to recommendation algorithm

    await Future.delayed(const Duration(milliseconds: 300)); // Mock API delay

    return true; // Mock success response
  }

  // Placeholder function to fetch detailed user profile
  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    print('👤 Fetching profile for user: $userId');

    // TODO: Implement actual logic:
    // 1. Fetch user profile from database
    // 2. Get user's photos from cloud storage
    // 3. Load user's interests, prompts, and preferences
    // 4. Check privacy settings and what can be shown
    // 5. Track profile views for analytics

    await Future.delayed(const Duration(milliseconds: 800)); // Mock API delay

    // Mock profile data
    return {
      'id': userId,
      'name': 'Emma',
      'age': 25,
      'bio':
          'Love hiking and coffee shops ☕️\n\nPassionate about photography and exploring new places.',
      'photos': [
        'https://images.unsplash.com/photo-1494790108755-2616b67fcec?w=400',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
      ],
      'interests': ['Photography', 'Hiking', 'Coffee', 'Reading', 'Travel'],
      'prompts': [
        {
          'question': 'My simple pleasures',
          'answer':
              'Sunday morning coffee, golden hour photography, and spontaneous road trips'
        },
        {
          'question': 'I\'m looking for',
          'answer':
              'Someone who can laugh at my terrible dad jokes and join me on weekend adventures'
        },
      ],
      'location': 'San Francisco, CA',
      'distance': 5, // km away
    };
  }

  // Placeholder function to load incoming requests
  static Future<List<Map<String, dynamic>>> loadIncomingRequests() async {
    print('📥 Loading incoming requests...');

    // TODO: Implement actual logic:
    // 1. Fetch pending like/superlike requests from database
    // 2. Sort by timestamp (newest first) or priority (superlike first)
    // 3. Load basic profile info for each requester
    // 4. Apply any filters or privacy settings
    // 5. Mark requests as "seen" when loaded

    await Future.delayed(const Duration(milliseconds: 600)); // Mock API delay

    // For testing: Get the test request using current user's UID
    final currentUser = FirebaseAuth.instance.currentUser;
    final testRequests = await getTestRequestsForUser(currentUser?.uid ?? '');

    return testRequests;
  }

  // Test function to create a like from one UID to another
  static Future<List<Map<String, dynamic>>> getTestRequestsForUser(
      String userUID) async {
    List<Map<String, dynamic>> requests = [];

    // For testing: Create a like from yThH7GJ068MiTokfbrQyQ5rSwDj1 to HfdoBOlYEBO54oUpaSqPTf5ML452
    if (userUID == 'HfdoBOlYEBO54oUpaSqPTf5ML452') {
      // Fetch the actual user data for the person who liked
      final likerUserData =
          await _fetchUserDataByUID('yThH7GJ068MiTokfbrQyQ5rSwDj1');

      if (likerUserData != null) {
        requests.add({
          'id': 'like_${DateTime.now().millisecondsSinceEpoch}',
          'fromUserId': 'yThH7GJ068MiTokfbrQyQ5rSwDj1',
          'type': 'like',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'userInfo': likerUserData,
        });
      }
    }

    return requests;
  }

  // Helper function to fetch user data by UID from Firestore
  static Future<Map<String, dynamic>?> _fetchUserDataByUID(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Extract and format user data
        return {
          'name': data['username'] ?? 'Unknown User',
          'age': data['age'] ?? _calculateAgeFromDOB(data['dateOfBirth']),
          'photo': data['photoUrl'] ??
              data['photoUrls']?.first ??
              'https://via.placeholder.com/400x600?text=No+Image',
          'bio': data['bio'] ?? 'No bio available',
          'email': data['email'] ?? '',
          'interests': data['interests'] ?? [],
          'location': data['location'] ?? 'Unknown location',
          'gender': data['gender'] ?? '',
          'orientation': data['orientation'] ?? [],
          'photoUrls': data['photoUrls'] ?? [],
        };
      }
    } catch (e) {
      print('Error fetching user data for UID $uid: $e');
    }
    return null;
  }

  // Helper function to calculate age from date of birth
  static int? _calculateAgeFromDOB(dynamic dateOfBirth) {
    if (dateOfBirth == null) return null;

    try {
      DateTime dob;
      if (dateOfBirth is Timestamp) {
        dob = dateOfBirth.toDate();
      } else if (dateOfBirth is DateTime) {
        dob = dateOfBirth;
      } else {
        return null;
      }

      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      print('Error calculating age: $e');
      return null;
    }
  }

  // Placeholder function to send a like/superlike
  static Future<bool> sendLikeRequest(
      String targetUserId, String requestType) async {
    print('💕 Sending $requestType to user: $targetUserId');

    // TODO: Implement actual logic:
    // 1. Check if user has remaining likes for today
    // 2. Check if already liked this user before
    // 3. Create like/superlike record in database
    // 4. Send push notification to target user
    // 5. Update user's daily like count
    // 6. Check for immediate match (if target user already liked back)

    await Future.delayed(const Duration(milliseconds: 400)); // Mock API delay

    return true; // Mock success response
  }

  // Placeholder function to create a chat thread
  static Future<String?> createChatThread(
      String userId1, String userId2) async {
    print('💬 Creating chat thread between $userId1 and $userId2');

    // TODO: Implement actual logic:
    // 1. Create chat thread record in database
    // 2. Set up real-time messaging listeners
    // 3. Send initial system message (optional)
    // 4. Update both users' match lists
    // 5. Send match notification to both users

    await Future.delayed(const Duration(milliseconds: 500)); // Mock API delay

    return 'chat_${DateTime.now().millisecondsSinceEpoch}'; // Mock chat ID
  }

  // Test function to simulate creating a like from one user to another
  static Future<bool> createTestLike({
    required String fromUserEmail,
    required String toUserEmail,
    String type = 'like',
  }) async {
    print('💕 Creating test $type from $fromUserEmail to $toUserEmail');

    // Simulate database operation
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real app, this would:
    // 1. Create a record in the likes/requests table
    // 2. Send a push notification to the target user
    // 3. Update analytics
    // 4. Check for a match if the target user already liked back

    print('✅ Test $type created successfully!');
    return true;
  }

  // Test function to simulate the Unnati -> Utkarsh like scenario
  static Future<bool> createUnnatiLikesUtkarshTest() async {
    return await createTestLike(
      fromUserEmail: 'unnati_ma24@thapar.edu',
      toUserEmail: 'utkarsh_mca24@thapar.edu',
      type: 'like',
    );
  }
}

// Additional utility functions
class RequestsUtils {
  // Calculate time ago string for timestamps
  static String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  // Validate if user can send more likes today
  static bool canSendLike(int dailyLikeCount, bool isPremium) {
    final maxLikes = isPremium ? 100 : 10; // Premium users get more likes
    return dailyLikeCount < maxLikes;
  }

  // Check if request type is valid
  static bool isValidRequestType(String type) {
    return ['like', 'superlike'].contains(type.toLowerCase());
  }
}
