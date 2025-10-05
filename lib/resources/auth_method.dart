import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login user with email and password
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return "Please fill in all fields";
      }

      // Debug: Log the email being used
      print('Attempting login with email: $email');

      // Check if email is from thapar.edu or thapr.edu domain
      if (!email.endsWith('@thapar.edu') && !email.endsWith('@thapr.edu')) {
        return "Please use your thapar.edu or thapr.edu email ID to login";
      }

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Firebase Auth successful for UID: ${userCredential.user?.uid}');

      // Check if user document exists in Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (!userDoc.exists) {
        print(
            'User document does not exist in Firestore for UID: ${userCredential.user?.uid}');
        return "User profile not found. Please sign up first.";
      }

      print('Login successful for user: ${userCredential.user?.email}');
      return "Success"; // Login successful
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return "No user found with this email. Please sign up first.";
        case 'wrong-password':
          return "Incorrect password. Please try again.";
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'user-disabled':
          return "This account has been disabled. Contact support.";
        case 'too-many-requests':
          return "Too many failed attempts. Please try again later.";
        case 'invalid-credential':
          return "Invalid email or password. Please check your credentials.";
        default:
          return "Login failed: ${e.message}";
      }
    } catch (e) {
      print('Unexpected login error: $e');
      return "An unexpected error occurred: $e";
    }
  }

  // Sign up user with email, password, and username
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        return "Please fill in all fields";
      }

      // Check if email is from thapar.edu or thapr.edu domain
      if (!email.endsWith('@thapar.edu') && !email.endsWith('@thapr.edu')) {
        return "Please use your thapar.edu or thapr.edu email ID to sign up";
      }

      // Validate email format
      if (!RegExp(r'^[\w-\.]+@(thapar|thapr)\.edu$').hasMatch(email)) {
        return "Please enter a valid @thapar.edu or @thapr.edu email address";
      }

      // Validate password strength
      if (password.length < 6) {
        return "Password must be at least 6 characters long";
      }

      // Validate username
      if (username.length < 2) {
        return "Username must be at least 2 characters long";
      }

      // Check if username already exists
      QuerySnapshot usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return "Username already taken. Please choose a different one.";
      }

      // Create user account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(username);

      // Wait a moment for auth state to propagate
      await Future.delayed(Duration(milliseconds: 500));

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'username': username.toLowerCase(),
        'name': username,
        'email': email,
        'photoUrl': '', // Single photo URL for backwards compatibility
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrls': <String>[], // Will store Cloudinary URLs
        'bio': '',
        'dateOfBirth': null, // Will be set in hobbies page
        'gender': '',
        'orientation': '',
        'interests': <String>[], // Will be set in hobbies page
        'location': '',
        'isProfileComplete': false,
        'isEmailVerified': userCredential.user?.emailVerified ?? false,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return "Success"; // Sign up successful
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return "Password is too weak. Please choose a stronger password.";
        case 'email-already-in-use':
          return "An account already exists with this email. Please login instead.";
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'operation-not-allowed':
          return "Email/password accounts are not enabled. Contact support.";
        default:
          return "Sign up failed: ${e.message}";
      }
    } catch (e) {
      // Log the actual error for debugging
      print('Sign up error: $e');
      return "An unexpected error occurred: $e";
    }
  }

  // Verify email
  Future<String> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return "Verification email sent successfully";
      } else if (user?.emailVerified == true) {
        return "Email is already verified";
      } else {
        return "No user logged in";
      }
    } catch (e) {
      return "Error sending verification email: $e";
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data
      return user.emailVerified;
    }
    return false;
  }

  // Update user profile completion status
  Future<String> updateProfileCompletionStatus(
      {required bool isComplete}) async {
    try {
      String? uid = getCurrentUserId();
      if (uid == null) return "No user logged in";

      await _firestore.collection('users').doc(uid).update({
        'isProfileComplete': isComplete,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      return "Success";
    } catch (e) {
      return "Error updating profile: $e";
    }
  }

  // Sign out user
  Future<String> signOut() async {
    try {
      await _auth.signOut();
      return "Success";
    } catch (e) {
      return "Error signing out: $e";
    }
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Reset password
  Future<String> resetPassword({required String email}) async {
    try {
      if (email.isEmpty) {
        return "Please enter your email address";
      }

      if (!email.endsWith('@thapar.edu')) {
        return "Please use your thapar.edu email ID";
      }

      await _auth.sendPasswordResetEmail(email: email);
      return "Password reset email sent successfully";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "No user found with this email address";
        case 'invalid-email':
          return "Please enter a valid email address";
        default:
          return "Error: ${e.message}";
      }
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String? uid = getCurrentUserId();
      if (uid == null) return null;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile with new information
  Future<String> updateUserProfile({
    String? bio,
    String? location,
    String? gender,
    int? age,
    List<String>? interests,
    List<String>? orientation,
    List<String>? photoUrls,
  }) async {
    try {
      String? uid = getCurrentUserId();
      if (uid == null) return "No user logged in";

      Map<String, dynamic> updateData = {
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      // Only update fields that are provided
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (gender != null) updateData['gender'] = gender;
      if (age != null) updateData['age'] = age;
      if (interests != null) updateData['interests'] = interests;
      if (orientation != null) updateData['orientation'] = orientation;
      if (photoUrls != null) updateData['photoUrls'] = photoUrls;

      await _firestore.collection('users').doc(uid).update(updateData);

      return "Success";
    } catch (e) {
      print('Error updating user profile: $e');
      return "Error updating profile: $e";
    }
  }

  // Test Firebase connection
  Future<String> testFirebaseConnection() async {
    try {
      // Test Firestore connection
      await _firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test'
      });

      return "Firebase connection successful!";
    } catch (e) {
      return "Firebase connection failed: $e";
    }
  }
}
