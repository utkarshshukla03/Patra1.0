import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story.dart';
import '../models/user.dart' as custom_models;
import 'cloudinary_service.dart';

class StoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference for stories
  static CollectionReference get _storiesCollection => 
      _firestore.collection('stories');

  /// Create and upload a new story
  static Future<Story> createStory({
    required XFile imageFile,
    required custom_models.User currentUser,
    required String caption,
    required String locationName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Generate unique story ID
      final storyId = _storiesCollection.doc().id;
      
      // Upload image to Cloudinary with organized folder structure
      final imageUrl = await _uploadStoryImage(
        imageFile, 
        userId: currentUser.uid,
        storyId: storyId,
      );

      // Create story location
      final location = StoryLocation(
        latitude: latitude ?? 30.3540, // Default to Thapar coordinates
        longitude: longitude ?? 76.3636,
        locationName: locationName.isNotEmpty 
            ? locationName 
            : 'Thapar Institute of Engineering & Technology',
      );

      // Create story object
      final story = Story(
        id: storyId,
        userId: currentUser.uid,
        username: currentUser.username,
        userPhoto: currentUser.photoUrls?.isNotEmpty == true 
            ? currentUser.photoUrls!.first 
            : currentUser.photoUrl,
        storyImage: imageUrl,
        storyText: caption,
        timestamp: DateTime.now(),
        location: location,
        isViewed: false,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        viewedBy: [],
      );

      // Save to Firestore
      await _storiesCollection.doc(storyId).set(story.toMap());

      return story;
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  /// Upload story image with organized folder structure
  static Future<String> _uploadStoryImage(
    XFile imageFile, {
    required String userId,
    required String storyId,
  }) async {
    try {
      // Create organized folder structure: stories/userId/timestamp_storyId
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderPath = 'stories/$userId';
      final fileName = '${timestamp}_$storyId';
      
      return await CloudinaryService.uploadStoryImage(
        File(imageFile.path),
        folder: folderPath,
        fileName: fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload story image: $e');
    }
  }

  /// Get all active stories (not expired) - simplified version
  static Stream<List<Story>> getActiveStories() {
    // Simple query without orderBy to avoid index requirements
    return _storiesCollection
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map((doc) => Story.fromFirestore(doc))
              .where((story) => story.isActive && !story.isExpired)
              .toList();
          
          // Sort client-side by timestamp descending
          stories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return stories;
        });
  }

  /// Get stories by user ID - simplified version (no index required)
  static Stream<List<Story>> getStoriesByUser(String userId) {
    // Simple query without orderBy to avoid composite index requirement
    return _storiesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map((doc) => Story.fromFirestore(doc))
              .where((story) => story.isActive && !story.isExpired)
              .toList();
          
          // Sort client-side by timestamp descending
          stories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return stories;
        });
  }

  /// Get stories for map display (with location data) - simplified version
  static Stream<List<Story>> getStoriesForMap() {
    // Simple query without orderBy to avoid index requirements
    return _storiesCollection
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map((doc) => Story.fromFirestore(doc))
              .where((story) => story.isActive && !story.isExpired)
              .toList();
          
          // Sort client-side by timestamp descending
          stories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return stories;
        });
  }

  /// Mark story as viewed by current user
  static Future<void> markStoryAsViewed(String storyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _storiesCollection.doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([currentUserId]),
        'isViewed': true,
      });
    } catch (e) {
      print('Error marking story as viewed: $e');
    }
  }

  /// Delete a story (only by owner) with proper validation
  static Future<bool> deleteStory(String storyId, String userId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != userId) {
        throw Exception('Unauthorized: Cannot delete other user\'s story');
      }

      // Get story data before deletion
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (storyDoc.exists) {
        // Delete from Firestore
        await _storiesCollection.doc(storyId).delete();
        print('Story deleted successfully: $storyId');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting story: $e');
      return false;
    }
  }

  /// Initialize automatic cleanup service (call this when app starts)
  static void initializeAutoCleanup() {
    // Run cleanup every hour
    Timer.periodic(const Duration(hours: 1), (timer) {
      cleanupExpiredStories();
    });
    
    // Also run cleanup immediately
    cleanupExpiredStories();
  }

  /// Clean up expired stories (call this periodically)
  static Future<void> cleanupExpiredStories() async {
    try {
      final expiredStoriesQuery = await _storiesCollection
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredStoriesQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleaned up ${expiredStoriesQuery.docs.length} expired stories');
    } catch (e) {
      print('Error cleaning up expired stories: $e');
    }
  }

  /// Get story analytics for a user
  static Future<Map<String, dynamic>> getStoryAnalytics(String userId) async {
    try {
      final userStoriesQuery = await _storiesCollection
          .where('userId', isEqualTo: userId)
          .get();

      int totalStories = userStoriesQuery.docs.length;
      int totalViews = 0;
      int activeStories = 0;

      for (final doc in userStoriesQuery.docs) {
        final story = Story.fromFirestore(doc);
        totalViews += story.viewedBy.length;
        if (story.isActive) activeStories++;
      }

      return {
        'totalStories': totalStories,
        'totalViews': totalViews,
        'activeStories': activeStories,
        'averageViewsPerStory': totalStories > 0 ? totalViews / totalStories : 0,
      };
    } catch (e) {
      print('Error getting story analytics: $e');
      return {
        'totalStories': 0,
        'totalViews': 0,
        'activeStories': 0,
        'averageViewsPerStory': 0,
      };
    }
  }
}