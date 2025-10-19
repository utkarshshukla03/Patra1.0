import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'swipe_analytics_service.dart';

class MLIntegrationService {
  static const String _mlBackendUrl =
      'http://localhost:5000'; // Updated to Flask server port
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// **🎯 Core Purpose: Feed real-time swipe data to ML recommendation engine**
  /// This integration allows your ML backend to:
  /// 1. Learn user preferences in real-time
  /// 2. Adjust recommendation weights based on user behavior
  /// 3. Improve match quality over time
  /// 4. Personalize the dating experience

  // Send swipe interaction to ML backend for learning
  static Future<bool> recordSwipeForML(
      String targetUserId, String actionType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Prepare data for ML backend (matching your swipe_log.csv format)
      final mlData = {
        'user_id': currentUser.uid,
        'target_user_id': targetUserId,
        'action': actionType, // like, superlike, reject
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('🤖 Sending swipe data to ML backend: ${mlData['action']} action');

      // Send to ML backend
      final response = await http.post(
        Uri.parse('$_mlBackendUrl/record_interaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mlData),
      );

      if (response.statusCode == 200) {
        print('✅ ML backend updated successfully');
        return true;
      } else {
        print('❌ ML backend update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending data to ML backend: $e');
      return false;
    }
  }

  // Get improved recommendations from ML backend
  static Future<List<String>?> getMLRecommendations({int topN = 10}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      print('🎯 Requesting ML recommendations for user: ${currentUser.uid}');

      final response = await http.get(
        Uri.parse('$_mlBackendUrl/recommend/${currentUser.uid}?top_n=$topN'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> recommendations = data['recommendations'] ?? [];

        print('✅ Received ${recommendations.length} ML recommendations');

        return recommendations.map((rec) => rec['user_id'].toString()).toList();
      } else {
        print('❌ Failed to get ML recommendations: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting ML recommendations: $e');
      return null;
    }
  }

  // Export Firebase swipe data to ML backend format
  static Future<bool> syncSwipeDataToML() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      print('🔄 Syncing swipe data to ML backend...');

      // Get user's swipe history
      final swipeHistory = await SwipeAnalyticsService.getUserSwipeHistory(
          currentUser.uid,
          limit: 1000);

      // Convert to ML backend format
      final mlSwipeData = swipeHistory
          .map((swipe) => {
                'user_id': swipe['userId'],
                'target_user_id': swipe['targetUserId'],
                'action': swipe['actionType'],
                'timestamp':
                    swipe['timestamp']?.toDate()?.toIso8601String() ?? '',
              })
          .toList();

      // Send batch data to ML backend
      final response = await http.post(
        Uri.parse('$_mlBackendUrl/sync_swipe_data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': currentUser.uid,
          'swipe_data': mlSwipeData,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Swipe data synced successfully');
        return true;
      } else {
        print('❌ Failed to sync swipe data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error syncing swipe data: $e');
      return false;
    }
  }

  // Get user's ML-calculated statistics
  static Future<Map<String, dynamic>?> getMLUserStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final response = await http.get(
        Uri.parse('$_mlBackendUrl/user_stats/${currentUser.uid}'),
      );

      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        print('📊 Retrieved ML user stats: ${stats.keys.toList()}');
        return stats;
      }

      return null;
    } catch (e) {
      print('Error getting ML user stats: $e');
      return null;
    }
  }

  // Update user Elo rating based on match success
  static Future<bool> updateEloRating(
      String targetUserId, bool wasMatch) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final response = await http.post(
        Uri.parse('$_mlBackendUrl/update_elo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': currentUser.uid,
          'target_id': targetUserId,
          'result': wasMatch ? 'match' : 'no_match',
        }),
      );

      if (response.statusCode == 200) {
        print('🏆 Elo rating updated for match result: $wasMatch');
        return true;
      }

      return false;
    } catch (e) {
      print('Error updating Elo rating: $e');
      return false;
    }
  }

  // Check if ML backend is available
  static Future<bool> isMLBackendAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_mlBackendUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('ML backend not available: $e');
      return false;
    }
  }

  /// **🧠 AI-Powered Insights for User**
  /// These methods provide intelligent insights back to the user

  // Get personalized dating insights
  static Future<Map<String, dynamic>?> getPersonalizedInsights() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Combine Firebase analytics with ML insights
      final firebaseStats =
          await SwipeAnalyticsService.getUserSwipeStats(currentUser.uid);
      final mlStats = await getMLUserStats();

      if (firebaseStats == null) return null;

      final totalSwipes = firebaseStats['totalSwipes'] ?? 0;
      final likeCount = firebaseStats['likeCount'] ?? 0;
      final superlikeCount = firebaseStats['superlikeCount'] ?? 0;
      final rejectCount = firebaseStats['rejectCount'] ?? 0;

      // Calculate insights
      final insights = <String, dynamic>{
        'swipe_selectivity':
            totalSwipes > 0 ? (likeCount + superlikeCount) / totalSwipes : 0,
        'superlike_usage': totalSwipes > 0 ? superlikeCount / totalSwipes : 0,
        'activity_level': _categorizeActivityLevel(totalSwipes),
        'dating_style':
            _analyzeDatingStyle(likeCount, superlikeCount, rejectCount),
        'ml_elo_rating': mlStats?['elo_rating'] ?? 1000,
        'recommendation_score': mlStats?['recommendation_score'] ?? 0,
        'suggested_improvements': _generateSuggestions(firebaseStats, mlStats),
      };

      return insights;
    } catch (e) {
      print('Error getting personalized insights: $e');
      return null;
    }
  }

  static String _categorizeActivityLevel(int totalSwipes) {
    if (totalSwipes < 50) return 'Casual';
    if (totalSwipes < 200) return 'Active';
    if (totalSwipes < 500) return 'Very Active';
    return 'Power User';
  }

  static String _analyzeDatingStyle(int likes, int superlikes, int rejects) {
    final total = likes + superlikes + rejects;
    if (total == 0) return 'New User';

    final likeRate = (likes + superlikes) / total;
    final superlikeRate = superlikes / total;

    if (likeRate > 0.7) return 'Open & Friendly';
    if (likeRate < 0.3) return 'Selective';
    if (superlikeRate > 0.1) return 'Enthusiastic';
    return 'Balanced';
  }

  static List<String> _generateSuggestions(
      Map<String, dynamic>? fbStats, Map<String, dynamic>? mlStats) {
    final suggestions = <String>[];

    if (fbStats != null) {
      final matchRate = mlStats?['match_rate'] ?? 0;
      final totalSwipes = fbStats['totalSwipes'] ?? 0;

      if (matchRate < 0.1 && totalSwipes > 50) {
        suggestions.add('Try being more selective - quality over quantity!');
      }

      if (fbStats['superlikeCount'] == 0 && totalSwipes > 20) {
        suggestions
            .add('Consider using Super Likes for profiles you really like!');
      }

      if (totalSwipes < 10) {
        suggestions.add('Keep swiping to find great matches!');
      }
    }

    return suggestions;
  }
}

/// **📈 Benefits for Your Dating App:**
/// 
/// 1. **Personalized Recommendations**: ML learns individual preferences
/// 2. **Improved Match Quality**: Algorithm adapts to user behavior
/// 3. **Better User Experience**: More relevant profiles shown first
/// 4. **Data-Driven Insights**: Users understand their dating patterns
/// 5. **Continuous Learning**: System gets smarter with more data
/// 
/// **🔧 Integration Points:**
/// - Real-time swipe tracking feeds ML backend
/// - Recommendation engine provides better profile ordering
/// - Elo ratings create competitive matching
/// - Analytics help users improve their approach
/// - A/B testing capabilities for feature improvements