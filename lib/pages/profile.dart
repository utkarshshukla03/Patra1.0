import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:reorderables/reorderables.dart';
import '../models/user.dart' as custom_models;
import '../models/story.dart';
import '../services/cloudinary_service.dart';
import '../services/story_service.dart';
import '../pages/story_viewer_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  custom_models.User? currentUser;
  bool isLoading = true;
  bool isEditing = false;

  // Controllers for editing
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Combined image handling - supports both URLs and local files
  List<dynamic> imageData =
      List.filled(6, null); // Can hold String (URL) or XFile (local file)
  bool _isUploading = false;

  List<String> selectedInterests = [];
  List<String> selectedOrientations = [];
  String? selectedGender;

  // Story-related variables
  List<Story> userStories = [];
  bool _isLoadingStories = false;

  final List<String> availableInterests = [
    'Photography',
    'Travel',
    'Music',
    'Movies',
    'Sports',
    'Reading',
    'Cooking',
    'Gaming',
    'Art',
    'Dancing',
    'Fitness',
    'Technology',
    'Fashion',
    'Food',
    'Adventure',
    'Nature',
    'Writing',
    'Coffee'
  ];

  final List<String> availableOrientations = [
    'Serious Dating',
    'Casual Dating',
    'Friendship',
    'Networking'
  ];

  final List<String> genderOptions = ['Male', 'Female', 'Non-binary', 'Other'];

  void _initializeImageData() {
    // Initialize imageData with existing user photos
    if (currentUser?.photoUrls != null) {
      for (int i = 0; i < 6; i++) {
        if (i < currentUser!.photoUrls!.length) {
          imageData[i] = currentUser!.photoUrls![i]; // Existing URL
        } else {
          imageData[i] = null; // Empty slot
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeImageData();
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
      final currentAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (currentAuthUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentAuthUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUser = custom_models.User.fromSnap(userDoc);
            _bioController.text = currentUser?.bio ?? '';
            _locationController.text = currentUser?.location ?? '';
            selectedInterests = currentUser?.interests ?? [];
            selectedOrientations = currentUser?.orientation ?? [];
            selectedGender = currentUser?.gender;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      final currentAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (currentAuthUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentAuthUser.uid)
            .update({
          'bio': _bioController.text,
          'location': _locationController.text,
          'interests': selectedInterests,
          'orientation': selectedOrientations,
          'gender': selectedGender,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Reload user data
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageData[index] = image; // Store the new XFile
      });
    }
  }

  Future<void> _uploadAllImages() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Separate new files from existing URLs
      List<XFile> newImages = [];
      List<String> finalImageUrls = [];

      for (int i = 0; i < imageData.length; i++) {
        if (imageData[i] != null) {
          if (imageData[i] is String) {
            // Existing URL - keep it
            finalImageUrls.add(imageData[i] as String);
          } else if (imageData[i] is XFile) {
            // New file - needs to be uploaded
            newImages.add(imageData[i] as XFile);
          }
        }
      }

      // Upload new images if any
      List<String> newImageUrls = [];
      if (newImages.isNotEmpty) {
        final CloudinaryService cloudinaryService = CloudinaryService();
        newImageUrls =
            await cloudinaryService.uploadMultipleImagesFromXFiles(newImages);
      }

      // Combine existing URLs with new URLs in the correct order
      List<String> allImageUrls = [];
      int newImageIndex = 0;

      for (int i = 0; i < imageData.length; i++) {
        if (imageData[i] != null) {
          if (imageData[i] is String) {
            // Existing URL
            allImageUrls.add(imageData[i] as String);
          } else if (imageData[i] is XFile) {
            // New uploaded image
            if (newImageIndex < newImageUrls.length) {
              allImageUrls.add(newImageUrls[newImageIndex]);
              newImageIndex++;
            }
          }
        }
      }

      if (allImageUrls.isNotEmpty) {
        // Update user profile with all image URLs (existing + new)
        final CloudinaryService cloudinaryService = CloudinaryService();
        bool success =
            await cloudinaryService.updateUserProfileImages(allImageUrls);

        if (success) {
          // Update imageData to reflect the new state (all URLs now)
          setState(() {
            for (int i = 0; i < 6; i++) {
              if (i < allImageUrls.length) {
                imageData[i] = allImageUrls[i];
              } else {
                imageData[i] = null;
              }
            }
          });

          // Reload user data to reflect changes
          await _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Images updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save images'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload images'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C5CE7),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(),
                    const SizedBox(height: 30),
                    _buildProfileContent(),
                    const SizedBox(height: 100), // Space for bottom padding
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
          ),
          TextButton(
            onPressed: () {
              if (isEditing) {
                _updateProfile();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
            style: TextButton.styleFrom(
              backgroundColor:
                  isEditing ? const Color(0xFF00B894) : const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              isEditing ? 'Save' : 'Edit Profile',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final photos = currentUser?.photoUrls ?? [];

    return Column(
      children: [
        // 6 Image Grid (shown in edit mode) or Profile Image
        if (isEditing) ...[
          Text(
            'Edit Your Photos',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          _buildImageGrid(),
          const SizedBox(height: 16),
          if (imageData.any((data) => data != null && data is XFile)) ...[
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadAllImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isUploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
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
            const SizedBox(height: 16),
          ],
        ] else ...[
          // Profile Image (view mode)
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photos.isNotEmpty
                      ? Image.network(
                          photos.first,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Name and Age
        Text(
          '${currentUser?.username ?? 'Unknown'}, ${currentUser?.calculatedAge ?? 0}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3436),
          ),
        ),

        const SizedBox(height: 4),

        // Email
        Text(
          currentUser?.email ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    final photos = currentUser?.photoUrls ?? [];

    return ReorderableWrap(
      spacing: 8,
      runSpacing: 8,
      maxMainAxisCount: 3,
      needsLongPressDraggable: true,
      children: List.generate(6, (index) {
        return GestureDetector(
          key: ValueKey(index),
          onTap: () => _pickImage(index),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6C5CE7)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            ),
            child: imageData[index] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageData[index] is String
                        ? Image.network(
                            imageData[index] as String,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          )
                        : kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future:
                                    (imageData[index] as XFile).readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              )
                            : Image.file(
                                File((imageData[index] as XFile).path),
                                fit: BoxFit.cover,
                              ),
                  )
                : (photos.length > index && photos[index].isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              color: Color(0xFF6C5CE7),
                              size: 32,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          color: Color(0xFF6C5CE7),
                          size: 32,
                        ),
                      ),
          ),
        );
      }),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final temp = imageData.removeAt(oldIndex);
          imageData.insert(newIndex, temp);
        });
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withValues(alpha: 0.8),
            const Color(0xFFA29BFE).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileContent() {
    final photos = currentUser?.photoUrls ?? [];
    int photoIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stories Section
        _buildMyStoriesSection(),

        const SizedBox(height: 24),

        // Bio Section
        _buildSection(
          'About Me',
          isEditing ? _buildEditableBio() : _buildDisplayBio(),
          showPhoto: photos.length > photoIndex,
          photoUrl: photos.length > photoIndex ? photos[photoIndex++] : null,
        ),

        const SizedBox(height: 24),

        // Interests Section
        _buildSection(
          'My Interests',
          isEditing ? _buildEditableInterests() : _buildDisplayInterests(),
          showPhoto: photos.length > photoIndex,
          photoUrl: photos.length > photoIndex ? photos[photoIndex++] : null,
        ),

        const SizedBox(height: 24),

        // Looking For Section
        _buildSection(
          'Looking For',
          isEditing ? _buildEditableLookingFor() : _buildDisplayLookingFor(),
          showPhoto: photos.length > photoIndex,
          photoUrl: photos.length > photoIndex ? photos[photoIndex++] : null,
        ),

        const SizedBox(height: 24),

        // Location Section
        _buildSection(
          'Location',
          isEditing ? _buildEditableLocation() : _buildDisplayLocation(),
          showPhoto: photos.length > photoIndex,
          photoUrl: photos.length > photoIndex ? photos[photoIndex++] : null,
        ),

        const SizedBox(height: 24),

        // Gender Section
        _buildSection(
          'Gender',
          isEditing ? _buildEditableGender() : _buildDisplayGender(),
          showPhoto: photos.length > photoIndex,
          photoUrl: photos.length > photoIndex ? photos[photoIndex++] : null,
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content,
      {bool showPhoto = false, String? photoUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 12),

        // Content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE9ECEF),
              width: 1,
            ),
          ),
          child: content,
        ),

        // Photo after content if available
        if (showPhoto && photoUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              photoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFE9ECEF),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Bio Section Widgets
  Widget _buildEditableBio() {
    return TextField(
      controller: _bioController,
      maxLines: 4,
      maxLength: 500,
      decoration: const InputDecoration(
        hintText: 'Tell us about yourself...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF2D3436),
        height: 1.4,
      ),
    );
  }

  Widget _buildDisplayBio() {
    final bio = currentUser?.bio;
    return Text(
      bio?.isNotEmpty == true ? bio! : 'No bio added yet',
      style: TextStyle(
        fontSize: 16,
        color: bio?.isNotEmpty == true ? const Color(0xFF2D3436) : Colors.grey,
        height: 1.4,
      ),
    );
  }

  // Interests Section Widgets
  Widget _buildEditableInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your interests:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF636E72),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : const Color(0xFFDDD6FE),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedInterests.length}/6 selected',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF636E72),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayInterests() {
    final interests = currentUser?.interests ?? [];
    if (interests.isEmpty) {
      return const Text(
        'No interests added yet',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDDD6FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            interest,
            style: const TextStyle(
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Looking For Section Widgets
  Widget _buildEditableLookingFor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you looking for?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF636E72),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00B894) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00B894)
                        : const Color(0xFF81ECEC),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  orientation,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF00B894),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDisplayLookingFor() {
    final orientations = currentUser?.orientation ?? [];
    if (orientations.isEmpty) {
      return const Text(
        'Not specified',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: orientations.map((orientation) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF81ECEC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            orientation,
            style: const TextStyle(
              color: Color(0xFF00B894),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Location Section Widgets
  Widget _buildEditableLocation() {
    return TextField(
      controller: _locationController,
      decoration: const InputDecoration(
        hintText: 'Enter your location...',
        border: InputBorder.none,
        prefixIcon: Icon(Icons.location_on, color: Color(0xFF636E72)),
        hintStyle: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF2D3436),
      ),
    );
  }

  Widget _buildDisplayLocation() {
    final location = currentUser?.location;
    return Row(
      children: [
        const Icon(Icons.location_on, color: Color(0xFF636E72), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location?.isNotEmpty == true ? location! : 'Location not specified',
            style: TextStyle(
              fontSize: 16,
              color: location?.isNotEmpty == true
                  ? const Color(0xFF2D3436)
                  : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // Gender Section Widgets
  Widget _buildEditableGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your gender:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF636E72),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE17055) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE17055)
                        : const Color(0xFFFFAB91),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  gender,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFE17055),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDisplayGender() {
    final gender = currentUser?.gender;
    return Row(
      children: [
        const Icon(Icons.person_outline, color: Color(0xFF636E72), size: 20),
        const SizedBox(width: 8),
        Text(
          gender?.isNotEmpty == true ? gender! : 'Not specified',
          style: TextStyle(
            fontSize: 16,
            color: gender?.isNotEmpty == true
                ? const Color(0xFF2D3436)
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  // Story-related methods
  Future<void> _loadUserStories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingStories = true;
    });

    try {
      final currentAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (currentAuthUser != null) {
        StoryService.getStoriesByUser(currentAuthUser.uid).listen((stories) {
          if (mounted) {
            setState(() {
              userStories = stories;
              _isLoadingStories = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading user stories: $e');
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
        });
      }
    }
  }

  void _showAddStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Story',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Color(0xFF6C5CE7),
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickStoryImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF6C5CE7),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickStoryImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStoryImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        await _createStory(image);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createStory(XFile imageFile) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final currentAuthUser = auth.FirebaseAuth.instance.currentUser;
      if (currentAuthUser == null || currentUser == null) {
        Navigator.pop(context);
        return;
      }

      await StoryService.createStory(
        imageFile: imageFile,
        currentUser: currentUser!,
        caption: '',
        locationName: currentUser?.location ?? 'Unknown',
      );

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh stories
      _loadUserStories();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error creating story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create story: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewStory(Story story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerPage(
          story: story,
          onStoryDeleted: () {
            // Refresh stories after deletion
            _loadUserStories();
          },
        ),
      ),
    );
  }

  Widget _buildMyStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Stories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
            if (userStories.isNotEmpty)
              Text(
                '${userStories.length} active',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingStories)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFF6C5CE7),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userStories.length + 1, // +1 for the "Add Story" card
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add Story Card (Snapchat style) - Always show first
                  return GestureDetector(
                    onTap: _showAddStoryOptions,
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6C5CE7),
                                width: 2,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF6C5CE7).withOpacity(0.1),
                                  const Color(0xFF6C5CE7).withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF6C5CE7),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add Story',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6C5CE7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Existing story cards
                  final story = userStories[index - 1];
                  return GestureDetector(
                    onTap: () => _viewStory(story),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: story.isExpired 
                                    ? Colors.grey.shade300 
                                    : const Color(0xFF6C5CE7),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Image.network(
                                    story.storyImage,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (story.isExpired)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.black54,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.access_time,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            story.formattedTimeRemaining,
                            style: TextStyle(
                              fontSize: 10,
                              color: story.isExpired 
                                  ? Colors.grey.shade500
                                  : const Color(0xFF6C5CE7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
