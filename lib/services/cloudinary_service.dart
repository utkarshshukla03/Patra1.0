import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './ml_service.dart';

class CloudinaryService {
  // Replace with your Cloudinary credentials
  static const String _cloudName = 'dugh2jryo';
  static const String _uploadPreset = 'patra_dating_app';

  final CloudinaryPublic _cloudinary =
      CloudinaryPublic(_cloudName, _uploadPreset);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload a single image to Cloudinary from XFile (web compatible)
  Future<String?> uploadImageFromXFile(XFile imageFile) async {
    try {
      if (kIsWeb) {
        // For web, use bytes
        final Uint8List bytes = await imageFile.readAsBytes();
        final CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: imageFile.name,
            folder: 'patra_dating_app/profile_images',
          ),
        );
        return response.secureUrl;
      } else {
        // For mobile, use file path
        final CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            folder: 'patra_dating_app/profile_images',
          ),
        );
        return response.secureUrl;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  // Static method for uploading images (used by story creation)
  static Future<String> uploadStoryImage(
    File imageFile, {
    String folder = 'stories',
    String? fileName,
  }) async {
    try {
      final CloudinaryPublic cloudinary =
          CloudinaryPublic(_cloudName, _uploadPreset);

      // Create unique filename if not provided
      final uniqueFileName = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      final CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'patra_dating_app/$folder',
          publicId: uniqueFileName,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload a single image to Cloudinary
  Future<String?> uploadImage(File imageFile) async {
    try {
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'patra_dating_app/profile_images',
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  // Upload multiple images to Cloudinary from XFile objects
  Future<List<String>> uploadMultipleImagesFromXFiles(
      List<XFile> imageFiles) async {
    List<String> uploadedUrls = [];

    for (XFile imageFile in imageFiles) {
      final String? url = await uploadImageFromXFile(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];

    for (File imageFile in imageFiles) {
      final String? url = await uploadImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Update user profile images in Firestore
  Future<bool> updateUserProfileImages(List<String> imageUrls) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating profile images: $e');
      return false;
    }
  }

  // Update user profile data in Firestore
  Future<bool> updateUserProfile({
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? orientation,
    List<String>? interests,
    String? location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (bio != null) updateData['bio'] = bio;
      if (dateOfBirth != null)
        updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (gender != null) updateData['gender'] = gender;
      if (orientation != null) updateData['orientation'] = orientation;
      if (interests != null) updateData['interests'] = interests;
      if (location != null) updateData['location'] = location;

      await _firestore.collection('users').doc(user.uid).update(updateData);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get ML-powered user recommendations
  Future<List<Map<String, dynamic>>> getMLPoweredMatches(
      {int count = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('🤖 ML Matching: No authenticated user');
        return [];
      }

      print(
          '🚀 ML Matching: Getting ML-powered recommendations for user ${user.uid}');

      // Check if ML service is available
      print('🔍 ML Matching: Checking ML service availability...');
      final isMLAvailable = await MLService.isMLServiceAvailable();

      if (!isMLAvailable) {
        print(
            '❌ ML Matching: ML service unavailable, falling back to regular matching');
        return await getUsersForMatching();
      }

      print(
          '✅ ML Matching: ML service is available, proceeding with ML recommendations');

      // Get ML recommendations
      final mlRecommendations = await MLService.getRecommendations(
        user.uid,
        count: count * 2, // Get more recommendations to account for filtering
      );

      if (mlRecommendations.isEmpty) {
        print(
            '⚠️  ML Matching: No ML recommendations received, falling back to regular matching');
        return await getUsersForMatching();
      }

      print(
          '🎯 ML Matching: Received ${mlRecommendations.length} ML recommendations from backend');
      print(
          '📋 ML Matching: Processing recommendations and fetching full user data...');

      // Get full user data for recommended users
      final List<Map<String, dynamic>> enrichedUsers = [];

      // Get all swipes to filter out already swiped users
      final QuerySnapshot swipeSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: user.uid)
          .get();

      final swipeMap = <String, bool>{};
      for (var doc in swipeSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        swipeMap[data['targetUserId']] = true;
      }

      for (var recommendation in mlRecommendations) {
        final recommendedUserId = recommendation['user_id'];

        // Skip if already swiped
        if (swipeMap[recommendedUserId] == true) {
          continue;
        }

        try {
          print(
              '🔍 Processing ML recommendation ${enrichedUsers.length + 1}: User $recommendedUserId (Score: ${recommendation['compatibility_score']?.toStringAsFixed(3)})');

          // Get full user data from Firestore
          final userDoc = await _firestore
              .collection('users')
              .where('uid', isEqualTo: recommendedUserId)
              .limit(1)
              .get();

          if (userDoc.docs.isNotEmpty) {
            final userData = userDoc.docs.first.data();
            print(
                '   ✅ Found user data: ${userData['name']} (${userData['age']}) from ${userData['location']}');

            // Enrich with ML data
            final enrichedUser = MLService.convertMLRecommendationToUser(
              recommendation,
              userData,
            );

            enrichedUsers.add(enrichedUser);
            print(
                '   ➕ Added to final matches list (${enrichedUsers.length}/${count})');

            // Stop when we have enough users
            if (enrichedUsers.length >= count) {
              print(
                  '🎯 Reached target count of $count users, stopping processing');
              break;
            }
          } else {
            print('   ⚠️ User data not found for $recommendedUserId');
          }
        } catch (e) {
          print(
              '❌ ML Matching: Error getting user data for $recommendedUserId: $e');
          continue;
        }
      }

      print(
          '✅ ML Matching: Successfully processed ${enrichedUsers.length} ML-powered matches');
      print('🔥 FINAL RECOMMENDED USERS FOR DISPLAY:');

      // Print comprehensive final user details
      for (int i = 0; i < enrichedUsers.length && i < 10; i++) {
        final user = enrichedUsers[i];
        print('   🏆 MATCH #${i + 1}:');
        print(
            '      👤 Name: ${user['name'] ?? 'N/A'} (${user['age'] ?? 'N/A'} years old)');
        print('      📍 Location: ${user['location'] ?? 'N/A'}');
        print(
            '      💯 ML Score: ${user['ml_score']?.toStringAsFixed(4) ?? 'N/A'}');
        print(
            '      💝 Interests: ${user['interests']?.join(', ') ?? 'None listed'}');
        print('      📱 Gender: ${user['gender'] ?? 'N/A'}');
        print(
            '      💌 Bio: ${user['bio']?.substring(0, user['bio']?.length > 50 ? 50 : user['bio']?.length)?.trim() ?? 'No bio'}${user['bio']?.length > 50 ? '...' : ''}');
        if (i < 3) print('      ═══════════════════════════════');
      }

      // If we don't have enough ML matches, supplement with regular matches
      if (enrichedUsers.length < count) {
        final regularMatches = await getUsersForMatching();
        final needed = count - enrichedUsers.length;

        // Add regular matches that aren't already in ML results
        final mlUserIds = enrichedUsers.map((u) => u['uid']).toSet();
        final supplementalMatches = regularMatches
            .where((u) => !mlUserIds.contains(u['uid']))
            .take(needed)
            .toList();

        enrichedUsers.addAll(supplementalMatches);

        print(
            '🤖 ML Matching: Added ${supplementalMatches.length} regular matches to supplement');
      }

      return enrichedUsers;
    } catch (e) {
      print('🤖 ML Matching: Error getting ML-powered matches: $e');
      // Fallback to regular matching
      return await getUsersForMatching();
    }
  }

  // Get all users for matching (excluding current user) with optimized swipe checking
  Future<List<Map<String, dynamic>>> getUsersForMatching() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      print('🔄 Loading data from Firestore...');

      // Get all users
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: user.uid)
          .get();

      final users = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Get all swipes in a single batch query instead of individual queries
      final QuerySnapshot swipeSnapshot = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Create a map of swiped users for O(1) lookup
      final swipeMap = <String, bool>{};
      for (var doc in swipeSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        swipeMap[data['targetUserId']] = true;
      }

      // Filter out already swiped users using the map (O(1) lookup instead of O(n) queries)
      final filteredUsers = users
          .where((userData) => !(swipeMap[userData['uid']] ?? false))
          .toList();

      print(
          '📊 Loaded ${filteredUsers.length} available users out of ${users.length} total');

      return filteredUsers;
    } catch (e) {
      print('Error getting users for matching: $e');
      return [];
    }
  }

  // Original method kept for compatibility (now deprecated)
  @deprecated
  Future<List<Map<String, dynamic>>> getUsersForMatchingLegacy() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: user.uid)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting users for matching: $e');
      return [];
    }
  }

  // Save swipe action (like or dislike) with cache update
  Future<bool> saveSwipeAction(String targetUserId, bool isLike) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('swipes')
          .doc('${user.uid}_$targetUserId')
          .set({
        'userId': user.uid,
        'targetUserId': targetUserId,
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // If it's a like, check for mutual like (match)
      if (isLike) {
        final QuerySnapshot mutualLike = await _firestore
            .collection('swipes')
            .where('userId', isEqualTo: targetUserId)
            .where('targetUserId', isEqualTo: user.uid)
            .where('isLike', isEqualTo: true)
            .get();

        if (mutualLike.docs.isNotEmpty) {
          // Create a match
          await _createMatch(user.uid, targetUserId);
        }
      }

      return true;
    } catch (e) {
      print('Error saving swipe action: $e');
      return false;
    }
  }

  // Create a match between two users
  Future<void> _createMatch(String userId1, String userId2) async {
    try {
      final matchId = userId1.compareTo(userId2) < 0
          ? '${userId1}_$userId2'
          : '${userId2}_$userId1';

      await _firestore.collection('matches').doc(matchId).set({
        'users': [userId1, userId2],
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
    } catch (e) {
      print('Error creating match: $e');
    }
  }

  // Check if user has already swiped on target user
  Future<bool> hasUserSwiped(String targetUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final DocumentSnapshot swipeDoc = await _firestore
          .collection('swipes')
          .doc('${user.uid}_$targetUserId')
          .get();

      return swipeDoc.exists;
    } catch (e) {
      print('Error checking swipe status: $e');
      return false;
    }
  }

  // Calculate age from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Complete profile setup with all collected data from multi-step signup
  Future<bool> completeProfileSetup({
    required List<String> interests,
    String? bio,
    String? location,
    List<String>? photoUrls,
    String? gender,
    List<String>? orientation,
    DateTime? dateOfBirth,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      Map<String, dynamic> updateData = {
        'interests': interests, // Can be empty array, that's fine
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (bio != null && bio.isNotEmpty) updateData['bio'] = bio;
      if (location != null && location.isNotEmpty)
        updateData['location'] = location;
      if (gender != null && gender.isNotEmpty) updateData['gender'] = gender;
      if (orientation != null && orientation.isNotEmpty)
        updateData['orientation'] = orientation;
      if (dateOfBirth != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
        // Calculate and store age
        int age = _calculateAge(dateOfBirth);
        updateData['age'] = age;
      }
      if (photoUrls != null && photoUrls.isNotEmpty) {
        updateData['photoUrls'] = photoUrls;
        updateData['photoUrl'] = photoUrls[0]; // Set primary photo
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      print('Profile setup completed successfully for user: ${user.uid}');
      print(
          'Data saved: interests=${interests.length}, bio=${bio != null}, location=${location != null}, gender=${gender != null}, orientation=${orientation?.length ?? 0}, photos=${photoUrls?.length ?? 0}, dob=${dateOfBirth != null}');
      return true;
    } catch (e) {
      print('Error completing profile setup: $e');
      return false;
    }
  }

  // Helper method to calculate age from date of birth
  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
