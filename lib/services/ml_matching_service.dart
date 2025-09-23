import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class MLMatchingService {
  static const String _baseUrl = 'http://localhost:5000';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get ML-powered recommendations for the current user
  Future<List<Map<String, dynamic>>> getMLRecommendations(
      {int count = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/recommendations/${user.uid}?count=$count'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ ML Recommendations loaded: ${data['count']} matches');
          return List<Map<String, dynamic>>.from(data['recommendations']);
        } else {
          print('❌ ML API error: ${data['error']}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting ML recommendations: $e');
      return [];
    }
  }

  // Check if ML service is available
  Future<bool> isMLServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '✅ ML Service healthy: ${data['users_count']} users, ${data['swipes_count']} swipes');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ ML Service unavailable: $e');
      return false;
    }
  }

  // Refresh ML data (trigger ML service to reload from Firebase)
  Future<bool> refreshMLData() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh-data'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print(
              '✅ ML Data refreshed: ${data['users_count']} users, ${data['swipes_count']} swipes');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error refreshing ML data: $e');
      return false;
    }
  }
}
