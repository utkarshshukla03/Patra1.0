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
                      padding: const EdgeInsets.all(16),
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
            currentUser?.username ?? 'Username',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (currentUser?.age != null) ...[
            const SizedBox(height: 4),
            Text(
              '${currentUser!.age} years old',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
          if (currentUser?.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              currentUser!.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement share profile
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
      ],
    );
  }

  Widget _buildViewingInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos Gallery
        if (currentUser?.photoUrls?.isNotEmpty == true) ...[
          _buildPhotosGallery(),
          const SizedBox(height: 24),
        ],

        // Basic Info Cards
        _buildBasicInfoCards(),
        const SizedBox(height: 24),

        // Interests Section with Chips
        if (currentUser?.interests?.isNotEmpty == true) ...[
          _buildInterestsChips(),
          const SizedBox(height: 24),
        ],

        // Looking For Section with Chips
        if (currentUser?.orientation?.isNotEmpty == true) ...[
          _buildLookingForChips(),
          const SizedBox(height: 24),
        ],
      ],
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

  // Dating App Style Profile Methods for Viewing
  Widget _buildPhotosGallery() {
    final photos = currentUser?.photoUrls ?? [];
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
            'Photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(photos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCards() {
    return Row(
      children: [
        // Age and Location Card
        Expanded(
          child: Container(
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
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF6C5CE7), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentUser?.location ?? 'Location not set',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF636E72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (currentUser?.age != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.cake,
                          color: Color(0xFF6C5CE7), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${currentUser!.age} years old',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF636E72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Gender Card
        Expanded(
          child: Container(
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
                Row(
                  children: [
                    const Icon(Icons.person,
                        color: Color(0xFF6C5CE7), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentUser?.gender ?? 'Not specified',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF636E72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsChips() {
    final interests = currentUser?.interests ?? [];
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
            'My Interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLookingForChips() {
    final orientations = currentUser?.orientation ?? [];
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
            'Looking For',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: orientations.map((orientation) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B894), Color(0xFF81ECEC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  orientation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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

      // For now, just show success message
      // You'll need to implement the actual profile update method

      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
      // For now, just update local state and show success
      // You'll need to implement the actual profile update method

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
