import 'package:flutter/material.dart';
import '../pages/auth/loginPage.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../services/auth_state_manager.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthStateManager _authManager = AuthStateManager();

  @override
  void initState() {
    super.initState();
    _authManager.initialize();
    _authManager.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authManager.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth state
    if (!_authManager.isInitialized || _authManager.isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 254, 254),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'PlayFairDisplay',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Return appropriate screen based on auth state
    return _authManager.isLoggedIn
        ? const MainNavigationWrapper()
        : const LoginPage();
  }
}
