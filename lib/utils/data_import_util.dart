import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';
import '../models/user.dart' as app_user;

class DataImportUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    CloudinaryConfig.cloudName,
    CloudinaryConfig.uploadPreset,
    cache: false,
  );

  /// Check if platform supports file operations
  static bool get isPlatformSupported {
    return !kIsWeb; // File operations not supported on web
  }

  /// Import all dummy data from the data_ folder
  static Future<void> importAllDummyData() async {
    if (!isPlatformSupported) {
      throw UnsupportedError(
          'File import is not supported on web platform. Please run on Windows, Android, or iOS.');
    }

    const String basePath = 'data_';
    const String csvFilePath = '$basePath/profiles/users.csv';
    const String biosFolder = '$basePath/text/bios';
    const String imagesFolder = '$basePath/assigned';

    await importDummyData(
      csvFilePath: csvFilePath,
      biosFolder: biosFolder,
      imagesFolder: imagesFolder,
    );
  }

  /// Import dummy data from files
  /// [csvFilePath] - Path to CSV file with user data
  /// [biosFolder] - Path to folder containing bio text files
  /// [imagesFolder] - Path to folder containing user images
  static Future<void> importDummyData({
    required String csvFilePath,
    required String biosFolder,
    required String imagesFolder,
  }) async {
    if (!isPlatformSupported) {
      throw UnsupportedError(
          'File import is not supported on web platform. Please run on Windows, Android, or iOS.');
    }

    try {
      print('Starting data import...');

      // Read CSV data
      List<Map<String, dynamic>> userData = await _readCSVFile(csvFilePath);
      print('Read ${userData.length} user records from CSV');

      // Import each user with progress tracking
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < userData.length; i++) {
        try {
          final userNumber = _extractUserNumber(userData[i]['user_id'] ?? '');
          final bioFilePath =
              '$biosFolder/user_${userNumber.toString().padLeft(4, '0')}.txt';
          final imageFilePath =
              '$imagesFolder/user_${userNumber.toString().padLeft(4, '0')}.jpg';

          await _importSingleUser(
            userData[i],
            bioFilePath,
            imageFilePath,
          );

          successCount++;
          print(
              '✅ Imported user ${i + 1}/${userData.length} - ${userData[i]['name']}');

          // Add delay to avoid rate limits
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          errorCount++;
          print('❌ Error importing user ${i + 1}: $e');
        }
      }

      print('\n🎉 Data import completed!');
      print('✅ Successfully imported: $successCount users');
      print('❌ Failed: $errorCount users');
    } catch (e) {
      print('💥 Critical error during data import: $e');
      rethrow;
    }
  }

  /// Extract user number from user_id (e.g., user_0001@thapar.edu -> 1)
  static int _extractUserNumber(String userId) {
    final regex = RegExp(r'user_(\d+)');
    final match = regex.firstMatch(userId);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 1; // Default fallback
  }

  /// Read CSV file and parse user data
  static Future<List<Map<String, dynamic>>> _readCSVFile(
      String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('CSV file not found: $filePath');
    }

    final contents = await file.readAsString();
    final lines = contents.split('\n');

    if (lines.isEmpty) {
      throw Exception('CSV file is empty');
    }

    // Parse header
    final headers = lines[0].split(',').map((h) => h.trim()).toList();
    final userDataList = <Map<String, dynamic>>[];

    // Parse data rows
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final values = _parseCSVLine(lines[i]);
      if (values.length >= headers.length) {
        final userData = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          userData[headers[j]] = values[j];
        }
        userDataList.add(userData);
      }
    }

    return userDataList;
  }

  /// Parse CSV line handling commas within quotes
  static List<String> _parseCSVLine(String line) {
    final values = <String>[];
    bool inQuotes = false;
    String currentValue = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(currentValue.trim());
        currentValue = '';
      } else {
        currentValue += char;
      }
    }

    // Add the last value
    values.add(currentValue.trim());

    return values;
  }

  /// Read bio from individual text file
  static Future<String> _readBioFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print('Bio file not found: $filePath, using default bio');
      return 'Looking for meaningful connections and new adventures!';
    }

    final contents = await file.readAsString();
    return contents.trim();
  }

  /// Import a single user with image upload
  static Future<void> _importSingleUser(
    Map<String, dynamic> userData,
    String bioFilePath,
    String imageFilePath,
  ) async {
    // Read bio from file
    final bio = await _readBioFile(bioFilePath);

    // Generate unique email and password for Firebase Auth
    final userNumber = _extractUserNumber(userData['user_id'] ?? '');
    final email = userData['user_id'] ?? 'test${userNumber}@patra.app';
    final password = userData['password'] ?? 'TestPass123!';

    // Create Firebase Auth user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;
    String photoUrl = '';
    List<String> photoUrls = [];

    // Upload image to Cloudinary if available
    final imageFile = File(imageFilePath);
    if (await imageFile.exists()) {
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFilePath,
            folder: CloudinaryConfig.profileImagesFolder,
            publicId: 'user_$uid',
          ),
        );
        photoUrl = response.secureUrl;
        photoUrls = [photoUrl];
        print('📸 Image uploaded: ${response.publicId}');
      } catch (e) {
        print('⚠️  Error uploading image for user $uid: $e');
      }
    } else {
      print('⚠️  Image file not found: $imageFilePath');
    }

    // Create user document
    final user = app_user.User(
      email: email,
      uid: uid,
      photoUrl: photoUrl,
      username: userData['name'] ?? 'User$userNumber',
      bio: bio,
      age: _parseAge(userData),
      gender: _parseGender(userData),
      orientation: _parseOrientation(userData) != null
          ? [_parseOrientation(userData)!]
          : null,
      interests: _parseInterests(userData),
      location:
          '${userData['city'] ?? 'Unknown'}, ${userData['state'] ?? 'India'}',
      photoUrls: photoUrls,
      dateOfBirth: _parseDateOfBirth(userData),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore
    await _firestore.collection('users').doc(uid).set(user.toJson());

    print(
        '👤 Created user: ${user.username} (${user.age}) from ${user.location}');
  }

  /// Parse age from user data
  static int? _parseAge(Map<String, dynamic> userData) {
    final ageStr = userData['age']?.toString();
    if (ageStr != null && ageStr.isNotEmpty) {
      return int.tryParse(ageStr);
    }
    return null;
  }

  /// Parse gender from user data
  static String? _parseGender(Map<String, dynamic> userData) {
    final gender = userData['gender']?.toString().toLowerCase();
    if (gender != null) {
      if (gender.contains('male') && !gender.contains('female')) return 'male';
      if (gender.contains('female')) return 'female';
      if (gender.contains('other') || gender.contains('non-binary'))
        return 'other';
    }
    return 'male'; // Default
  }

  /// Parse sexual orientation from looking_for field
  static String? _parseOrientation(Map<String, dynamic> userData) {
    final lookingFor = userData['looking_for']?.toString().toLowerCase();
    if (lookingFor != null && lookingFor.contains('relationship')) {
      return 'straight'; // Default for relationship seekers
    }

    // Default random orientation
    final orientations = ['straight', 'gay', 'lesbian', 'bisexual'];
    return orientations[Random().nextInt(orientations.length)];
  }

  /// Parse interests/hobbies from user data
  static List<String>? _parseInterests(Map<String, dynamic> userData) {
    final hobbiesStr = userData['hobbies']?.toString();
    if (hobbiesStr != null && hobbiesStr.isNotEmpty) {
      return hobbiesStr
          .split(',')
          .map((hobby) => _capitalizeFirst(hobby.trim()))
          .where((hobby) => hobby.isNotEmpty)
          .toList();
    }

    return ['Travel', 'Movies', 'Music']; // Default interests
  }

  /// Capitalize first letter of a string
  static String _capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  /// Parse date of birth from user data
  static DateTime? _parseDateOfBirth(Map<String, dynamic> userData) {
    final dobStr = userData['dob']?.toString();
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        // Parse DD-MM-YYYY format
        final parts = dobStr.split('-');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (e) {
        print('Error parsing date of birth: $dobStr');
      }
    }

    return null;
  }

  /// Delete all test users (for cleanup)
  static Future<void> deleteAllTestUsers() async {
    try {
      print('🗑️  Deleting all test users...');

      // Get all users
      final querySnapshot = await _firestore.collection('users').get();

      // Delete from Firestore
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Deleted ${querySnapshot.docs.length} users from Firestore');
      print(
          '⚠️  Note: Firebase Auth users need to be deleted manually or via admin SDK');
    } catch (e) {
      print('❌ Error deleting test users: $e');
      rethrow;
    }
  }

  /// Import a limited number of users for testing
  static Future<void> importLimitedUsers({int limit = 10}) async {
    if (!isPlatformSupported) {
      throw UnsupportedError(
          'File import is not supported on web platform. Please run on Windows, Android, or iOS.');
    }

    const String basePath = 'data_';
    const String csvFilePath = '$basePath/profiles/users.csv';
    const String biosFolder = '$basePath/text/bios';
    const String imagesFolder = '$basePath/assigned';

    try {
      print('Starting limited import of $limit users...');

      // Read CSV data
      List<Map<String, dynamic>> userData = await _readCSVFile(csvFilePath);
      final limitedData = userData.take(limit).toList();

      print('Processing ${limitedData.length} users...');

      // Import limited users
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < limitedData.length; i++) {
        try {
          final userNumber =
              _extractUserNumber(limitedData[i]['user_id'] ?? '');
          final bioFilePath =
              '$biosFolder/user_${userNumber.toString().padLeft(4, '0')}.txt';
          final imageFilePath =
              '$imagesFolder/user_${userNumber.toString().padLeft(4, '0')}.jpg';

          await _importSingleUser(
            limitedData[i],
            bioFilePath,
            imageFilePath,
          );

          successCount++;
          print('✅ Imported user ${i + 1}/$limit - ${limitedData[i]['name']}');

          // Add delay to avoid rate limits
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          errorCount++;
          print('❌ Error importing user ${i + 1}: $e');
        }
      }

      print('\n🎉 Limited import completed!');
      print('✅ Successfully imported: $successCount users');
      print('❌ Failed: $errorCount users');
    } catch (e) {
      print('💥 Critical error during limited import: $e');
      rethrow;
    }
  }
}
