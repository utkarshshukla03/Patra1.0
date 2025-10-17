import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateManager extends ChangeNotifier {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  User? _currentUser;
  bool _isLoading = true;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Initialize auth state listener
  void initialize() {
    if (_isInitialized) return;

    print('🔐 Initializing AuthStateManager...');

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isLoading = false;
      _isInitialized = true;

      if (user != null) {
        print('✅ User is logged in: ${user.email}');
      } else {
        print('❌ User is not logged in');
      }

      notifyListeners();
    });
  }

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('🎉 Login successful: ${credential.user!.email}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Login failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('👋 User logged out');
    } catch (e) {
      print('❌ Logout failed: $e');
    }
  }

  // Check if user session is valid
  bool hasValidSession() {
    return FirebaseAuth.instance.currentUser != null;
  }
}
