import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart' as UserModel;
import '../models/story.dart';
import '../resources/auth_method.dart';
import '../services/cloudinary_service.dart';
import '../services/story_service.dart';
import '../pages/story_viewer_page.dart';
import '../pages/settings_page.dart';
import '../pages/story_camera_page.dart';
import '../pages/services/share.dart';
import '../utils/text_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel.User? currentUser;
  bool isEditing = false;
  bool _isUploading = false;

  // Text controllers for editing
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Image data for photo editing
  List<dynamic> imageData = List.filled(6, null);

  // Selection data for editing
  List<String> selectedInterests = [];
  List<String> selectedOrientations = [];
  String? selectedGender;

  // Story-related variables
  List<Story> userStories = [];

  final List<String> availableInterests = [
    'Photography',
    'Travel',
    'Music',
    'Movies',
    'Sports',
    'Reading',
    'Gaming',
    'Cooking',
    'Dancing',
    'Art',
    'Fitness',
    'Technology',
    'Fashion',
    'Food',
    'Nature',
    'Pets',
    'Coffee',
    'Books',
    'Hiking',
    'Swimming',
  ];

  final List<String> availableOrientations = [
    'Relationship',
    'Friendship',
    'Networking',
    'Dating',
    'Activity Partner',
  ];

  final List<String> genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStories();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userProfile = await AuthMethods().getUserProfile();
      if (mounted && userProfile != null) {
        setState(() {
          currentUser = UserModel.User(
            uid: userProfile['uid'] ?? '',
            username: userProfile['username'] ?? '',
            email: userProfile['email'] ?? '',
            photoUrl: userProfile['photoUrls']?.isNotEmpty == true
                ? userProfile['photoUrls'][0]
                : '',
            bio: userProfile['bio'],
            photoUrls: List<String>.from(userProfile['photoUrls'] ?? []),
            interests: List<String>.from(userProfile['interests'] ?? []),
            orientation: List<String>.from(userProfile['orientation'] ?? []),
            age: userProfile['age'],
            gender: userProfile['gender'],
            location: userProfile['location'],
          );
          if (currentUser != null) {
            _bioController.text = currentUser!.bio ?? '';
            _locationController.text = currentUser!.location ?? '';
            _ageController.text =
                currentUser!.age != null ? currentUser!.age.toString() : '';
            selectedInterests = List.from(currentUser!.interests ?? []);
            selectedOrientations = List.from(currentUser!.orientation ?? []);
            selectedGender = currentUser!.gender;

            // Load existing photos
            if (currentUser!.photoUrls != null) {
              for (int i = 0;
                  i < currentUser!.photoUrls!.length && i < 6;
                  i++) {
                imageData[i] = currentUser!.photoUrls![i];
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadUserStories() async {
    if (!mounted) return;

    try {
      final currentAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (currentAuthUser != null) {
        StoryService.getStoriesByUser(currentAuthUser.uid).listen((stories) {
          if (mounted) {
            setState(() {
              userStories = stories;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading user stories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 100), // Extra bottom padding for navbar
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          _buildProfileContent(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            isEditing ? 'Edit Profile' : 'Profile',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          if (isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  isEditing = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.menu, color: Colors.black87),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with Instagram-like story ring
          GestureDetector(
            onTap: () {
              if (userStories.isNotEmpty) {
                _openStoryViewer();
              } else {
                // Open camera directly if no stories (Instagram behavior)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoryCameraPage(),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: userStories.isNotEmpty
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFE91E63),
                                Color(0xFFFF5722),
                                Color(0xFFFF9800),
                                Color(0xFFFFC107),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: userStories.isEmpty
                          ? Border.all(color: Colors.grey[300]!, width: 3)
                          : null,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: currentUser?.photoUrls?.isNotEmpty == true
                            ? Image.network(
                                currentUser!.photoUrls!.first,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                // Add story button (Instagram style)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      // Open camera directly (Instagram behavior)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StoryCameraPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User info
          Text(
            TextUtils.formatUsername(currentUser?.username),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    backgroundColor: Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShareProfile(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Share Profile',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    if (isEditing) {
      return _buildEditingInterface();
    } else {
      return _buildViewingInterface();
    }
  }

  Widget _buildEditingInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos editing section
        _buildPhotosEditSection(),
        const SizedBox(height: 24),

        // Bio Section
        _buildEditSection(
          'About Me',
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell others about yourself...',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Interests Section
        _buildEditSection(
          'My Interests',
          _buildInterestsSelector(),
        ),
        const SizedBox(height: 24),

        // Looking For Section
        _buildEditSection(
          'Looking For',
          _buildOrientationsSelector(),
        ),
        const SizedBox(height: 24),

        // Location Section
        _buildEditSection(
          'Location',
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'Enter your location...',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Age Section
        _buildEditSection(
          'Age',
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter your age...',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gender Section
        _buildEditSection(
          'Gender',
          _buildGenderSelector(),
        ),
        const SizedBox(height: 32),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40), // Extra space for navbar
      ],
    );
  }

  Widget _buildViewingInterface() {
    final photos = currentUser?.photoUrls ?? [];
    int photoIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Me Section
        if (currentUser?.bio?.isNotEmpty == true) ...[
          _buildSectionWithTitle(
            'About Me',
            _buildBioSection(),
            Icons.person_outline,
          ),
          const SizedBox(height: 24),
        ],

        // Photo 1
        if (photos.length > photoIndex) ...[
          _buildPhotoSection(photos[photoIndex++]),
          const SizedBox(height: 24),
        ],

        // My Interests Section
        if (currentUser?.interests?.isNotEmpty == true) ...[
          _buildSectionWithTitle(
            'My Interests',
            _buildInterestsDisplay(),
            Icons.favorite_outline,
          ),
          const SizedBox(height: 24),
        ],

        // Photo 2
        if (photos.length > photoIndex) ...[
          _buildPhotoSection(photos[photoIndex++]),
          const SizedBox(height: 24),
        ],

        // Looking For Section
        if (currentUser?.orientation?.isNotEmpty == true) ...[
          _buildSectionWithTitle(
            'Looking For',
            _buildLookingForDisplay(),
            Icons.search,
          ),
          const SizedBox(height: 24),
        ],

        // Photo 3
        if (photos.length > photoIndex) ...[
          _buildPhotoSection(photos[photoIndex++]),
          const SizedBox(height: 24),
        ],

        // Personal Details Section
        _buildSectionWithTitle(
          'Personal Details',
          _buildPersonalDetailsSection(),
          Icons.info_outline,
        ),
        const SizedBox(height: 24),

        // Photo 4
        if (photos.length > photoIndex) ...[
          _buildPhotoSection(photos[photoIndex++]),
          const SizedBox(height: 24),
        ],

        // Lifestyle Section (if we have more data)
        if (currentUser?.location?.isNotEmpty == true) ...[
          _buildSectionWithTitle(
            'Lifestyle',
            _buildLifestyleSection(),
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 24),
        ],

        // Remaining Photos Gallery
        if (photos.length > photoIndex) ...[
          _buildSectionWithTitle(
            'More Photos',
            _buildRemainingPhotosGallery(photos.skip(photoIndex).toList()),
            Icons.photo_library_outlined,
          ),
          const SizedBox(height: 24),
        ],

        // Extra space for bottom navigation bar
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionWithTitle(String title, Widget content, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7).withOpacity(0.1),
                  const Color(0xFF74B9FF).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Text(
      currentUser?.bio ?? '',
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF636E72),
        height: 1.6,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInterestsDisplay() {
    final interests = currentUser?.interests ?? [];
    final interestColors = [
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)], // Red gradient
      [const Color(0xFF4ECDC4), const Color(0xFF6BCCC7)], // Teal gradient
      [const Color(0xFF45B7D1), const Color(0xFF5BC5E8)], // Blue gradient
      [const Color(0xFF96CEB4), const Color(0xFFA8D8C1)], // Green gradient
      [const Color(0xFFFECA57), const Color(0xFFFFD35A)], // Yellow gradient
      [const Color(0xFFFF9FF3), const Color(0xFFFFB3F6)], // Pink gradient
      [const Color(0xFFBB6BD9), const Color(0xFFC77DDB)], // Purple gradient
      [const Color(0xFFFF7675), const Color(0xFFFF8787)], // Coral gradient
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: interests.asMap().entries.map((entry) {
        int index = entry.key;
        String interest = entry.value;
        final colors = interestColors[index % interestColors.length];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            interest,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLookingForDisplay() {
    final orientations = currentUser?.orientation ?? [];
    final orientationColors = [
      [const Color(0xFF6C5CE7), const Color(0xFF74B9FF)], // Primary gradient
      [const Color(0xFF00B894), const Color(0xFF81ECEC)], // Green gradient
      [const Color(0xFFE17055), const Color(0xFFFF7675)], // Orange gradient
      [const Color(0xFD79A8), const Color(0xFFE84393)], // Pink gradient
      [const Color(0xFF00CEC9), const Color(0xFF55A3FF)], // Cyan gradient
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: orientations.asMap().entries.map((entry) {
        int index = entry.key;
        String orientation = entry.value;
        final colors = orientationColors[index % orientationColors.length];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            orientation,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Column(
      children: [
        if (currentUser?.age != null) ...[
          _buildDetailRow(
            Icons.cake_outlined,
            'Age',
            '${currentUser!.age} years old',
            const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 16),
        ],
        if (currentUser?.gender != null) ...[
          _buildDetailRow(
            Icons.person_outline,
            'Gender',
            currentUser!.gender!,
            const Color(0xFF00B894),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildLifestyleSection() {
    return Column(
      children: [
        if (currentUser?.location != null) ...[
          _buildDetailRow(
            Icons.location_on_outlined,
            'Location',
            currentUser!.location!,
            const Color(0xFFE17055),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String photoUrl) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.photo,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRemainingPhotosGallery(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              photos[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.photo,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditSection(String title, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildPhotosEditSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Your Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          _buildImageGrid(),
          const SizedBox(height: 16),
          if (imageData.any((data) => data != null && data is XFile)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadAllImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Uploading...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text('Upload Images',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _pickImage(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: imageData[index] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageData[index] is XFile
                        ? Image.file(
                            File((imageData[index] as XFile).path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          )
                        : Image.network(
                            imageData[index] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          ),
                  )
                : const Icon(
                    Icons.add_a_photo,
                    color: Colors.grey,
                    size: 32,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInterestsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableInterests.map((interest) {
        final isSelected = selectedInterests.contains(interest);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedInterests.remove(interest);
              } else if (selectedInterests.length < 6) {
                selectedInterests.add(interest);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrientationsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableOrientations.map((orientation) {
        final isSelected = selectedOrientations.contains(orientation);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedOrientations.remove(orientation);
              } else if (selectedOrientations.length < 3) {
                selectedOrientations.add(orientation);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00B894) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF00B894) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              orientation,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genderOptions.map((gender) {
        final isSelected = selectedGender == gender;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedGender = isSelected ? null : gender;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openStoryViewer() {
    if (userStories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewerPage(
            story: userStories.first,
            onStoryDeleted: () {
              _loadUserStories();
            },
          ),
        ),
      );
    }
  }

  // Image management methods
  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageData[index] = pickedFile;
      });
    }
  }

  Future<void> _uploadAllImages() async {
    setState(() {
      _isUploading = true;
    });

    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < imageData.length; i++) {
        if (imageData[i] != null) {
          if (imageData[i] is XFile) {
            // Upload new image using File instead of XFile
            File imageFile = File((imageData[i] as XFile).path);
            String? url = await CloudinaryService().uploadImage(imageFile);
            if (url != null) {
              uploadedUrls.add(url);
            }
          } else if (imageData[i] is String) {
            // Keep existing URL
            uploadedUrls.add(imageData[i] as String);
          }
        }
      }

      // Update user profile with new photo URLs
      String result = await AuthMethods().updateUserProfile(
        photoUrls: uploadedUrls,
      );

      if (result == "Success") {
        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload any new images first
      List<String> finalPhotoUrls = [];
      for (int i = 0; i < imageData.length; i++) {
        if (imageData[i] != null) {
          if (imageData[i] is XFile) {
            // Upload new image
            File imageFile = File((imageData[i] as XFile).path);
            String? url = await CloudinaryService().uploadImage(imageFile);
            if (url != null) {
              finalPhotoUrls.add(url);
            }
          } else if (imageData[i] is String) {
            // Keep existing URL
            finalPhotoUrls.add(imageData[i] as String);
          }
        }
      }

      // Update user profile in database
      String result = await AuthMethods().updateUserProfile(
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        gender: selectedGender,
        interests: selectedInterests,
        orientation: selectedOrientations,
        photoUrls: finalPhotoUrls.isNotEmpty ? finalPhotoUrls : null,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (result == "Success") {
        // Reload user data to reflect changes
        await _loadUserData();

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
