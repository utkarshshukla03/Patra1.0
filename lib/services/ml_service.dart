import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MLService {
  static const String _baseUrl = kDebugMode 
      ? 'http://localhost:5000/api'  // Development
      : 'https://your-ml-api-url.com/api';  // Production

  static const Duration _timeout = Duration(seconds: 30);

  /// Get ML-powered user recommendations
  static Future<List<Map<String, dynamic>>> getRecommendations(
    String userId, {
    int count = 10,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/recommendations/$userId?count=$count');
      
      print('🤖 ML Service: Fetching recommendations for user $userId (count: $count)');
      print('🌐 ML Service: API URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      print('🤖 ML Service: Response status ${response.statusCode}');
      print('🤖 ML Service: Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final recommendations = List<Map<String, dynamic>>.from(
            data['recommendations'] ?? []
          );
          
          print('✅ ML Service: Got ${recommendations.length} ML recommendations');
          print('📊 ML ALGORITHM DETAILS:');
          
          // Print detailed recommendation list with all available data
          for (int i = 0; i < recommendations.length && i < 15; i++) {
            final rec = recommendations[i];
            print('   🎯 Rank #${i + 1}:');
            print('      👤 User ID: ${rec['user_id']}');
            print('      💯 Compatibility Score: ${rec['compatibility_score']?.toStringAsFixed(4) ?? 'N/A'}');
            print('      🎪 Age Score: ${rec['age_score']?.toStringAsFixed(3) ?? 'N/A'}');
            print('      📍 Location Score: ${rec['location_score']?.toStringAsFixed(3) ?? 'N/A'}');
            print('      💝 Interest Score: ${rec['interest_score']?.toStringAsFixed(3) ?? 'N/A'}');
            print('      ⭐ Elo Rating: ${rec['elo_score'] ?? 'N/A'}');
            if (i < 5) print('      ═══════════════════════════════');
          }
          
          return recommendations;
        } else {
          throw Exception('ML API returned error: ${data['message']}');
        }
      } else if (response.statusCode == 404) {
        print('🤖 ML Service: User not found in ML system, falling back to regular matching');
        return [];
      } else {
        throw Exception('ML API request failed with status ${response.statusCode}');
      }
    } on SocketException {
      print('🤖 ML Service: Network error - ML service unavailable');
      return [];
    } on http.ClientException {
      print('🤖 ML Service: HTTP client error - ML service unavailable');
      return [];
    } catch (e) {
      print('🤖 ML Service: Error getting recommendations: $e');
      return [];
    }
  }

  /// Record user interaction for ML learning
  static Future<bool> recordInteraction(
    String userId,
    String targetId,
    String action, // 'like', 'dislike', 'superlike'
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/interaction');
      
      print('🤖 ML Service: Recording interaction $userId -> $targetId ($action)');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'target_id': targetId,
          'action': action,
        }),
      ).timeout(_timeout);

      print('🤖 ML Service: Interaction response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('🤖 ML Service: Interaction recorded successfully');
          return true;
        }
      }
      
      print('🤖 ML Service: Failed to record interaction');
      return false;
    } catch (e) {
      print('🤖 ML Service: Error recording interaction: $e');
      return false;
    }
  }

  /// Check if ML service is available
  static Future<bool> isMLServiceAvailable() async {
    try {
      print('🔍 ML Service: Checking health at $_baseUrl/health');
      final url = Uri.parse('$_baseUrl/health');
      
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isHealthy = data['status'] == 'healthy';
        
        if (isHealthy) {
          print('✅ ML Service: Backend is healthy! Users in DB: ${data['users_in_database']}');
          print('🚀 ML Service: ML recommendations ENABLED (v${data['version']})');
        } else {
          print('⚠️  ML Service: Backend responded but not healthy: ${data['status']}');
        }
        
        return isHealthy;
      }
      print('❌ ML Service: Health check failed with status ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ ML Service: Health check failed: $e');
      return false;
    }
  }

  /// Get user statistics from ML system
  static Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/stats');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['stats'];
        }
      }
      return null;
    } catch (e) {
      print('🤖 ML Service: Error getting user stats: $e');
      return null;
    }
  }

  /// Convert ML recommendation to user data format
  static Map<String, dynamic> convertMLRecommendationToUser(
    Map<String, dynamic> recommendation,
    Map<String, dynamic> fullUserData,
  ) {
    // Merge ML recommendation data with full user profile data
    return {
      ...fullUserData,
      'ml_score': recommendation['score'],
      'ml_rank': recommendation['rank'],
      'recommended_by_ml': true,
    };
  }
}