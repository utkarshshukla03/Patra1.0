import 'package:flutter/material.dart';
import '../models/user.dart' as UserModel;
import '../utils/text_utils.dart';

class ProfileModal extends StatefulWidget {
  final String? userId; // For request users
  final UserModel.User? user; // For homepage users
  final Map<String, dynamic>? requestUserData; // For request user data

  const ProfileModal({
    super.key,
    this.userId,
    this.user,
    this.requestUserData,
  });

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Get images based on data source
  List<String> get _images {
    if (widget.user != null) {
      // HomePage user
      if (widget.user!.photoUrls != null &&
          widget.user!.photoUrls!.isNotEmpty) {
        return widget.user!.photoUrls!;
      } else {
        return [
          widget.user!.primaryPhotoUrl.isNotEmpty
              ? widget.user!.primaryPhotoUrl
              : 'https://via.placeholder.com/400x600?text=No+Image'
        ];
      }
    } else {
      // Request user - use real data from Firebase
      final photoUrls = widget.requestUserData?['photoUrls'] as List<dynamic>?;
      if (photoUrls != null && photoUrls.isNotEmpty) {
        final urlList = photoUrls.map((url) => url.toString()).toList();
        return urlList;
      } else {
        // Fallback to primary photo
        final primaryPhoto = widget.requestUserData?['photo'] as String?;
        return [
          primaryPhoto ?? 'https://via.placeholder.com/400x600?text=No+Image'
        ];
      }
    }
  }

  // Get profile data based on source
  Map<String, dynamic> get _profileData {
    if (widget.user != null) {
      // HomePage user
      return {
        'name': TextUtils.formatUsername(widget.user!.username),
        'age': widget.user!.calculatedAge,
        'bio': widget.user!.bio ?? 'No bio available',
        'interests': widget.user!.interests ?? [],
        'location': widget.user!.location,
        'gender': widget.user!.gender,
        'orientation': widget.user!.orientation ?? [],
      };
    } else {
      // Request user - use real Firebase data
      final interests =
          widget.requestUserData?['interests'] as List<dynamic>? ?? [];
      final orientation =
          widget.requestUserData?['orientation'] as List<dynamic>? ?? [];

      return {
        'name': widget.requestUserData?['name'] ?? 'Unknown User',
        'age': widget.requestUserData?['age'] ?? 'Unknown Age',
        'bio': widget.requestUserData?['bio'] ?? 'No bio available',
        'interests': interests.map((e) => e.toString()).toList(),
        'location': widget.requestUserData?['location'] ?? 'Unknown location',
        'gender': widget.requestUserData?['gender'] ?? 'Not specified',
        'orientation': orientation.map((e) => e.toString()).toList(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _images[index],
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        '🚨 Error loading image ${_images[index]}: $error');
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image,
                                              size: 50, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Image failed to load',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                          SizedBox(height: 4),
                                          Text('Index: $index',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        // Image indicators
                        Positioned(
                          top: 20,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: List.generate(_images.length, (index) {
                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Close button
                        Positioned(
                          top: 20,
                          right: 24,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Name and Age (Most Important)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _profileData['name'],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              child: Text(
                                '${_profileData['age']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 2. Location (Important for dating)
                        if (_profileData['location'] != null &&
                            _profileData['location'] != 'Unknown location' &&
                            _profileData['location'].toString().isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _profileData['location'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 3. Bio/About (Personal Description)
                        if (_profileData['bio'] != null &&
                            _profileData['bio'] != 'No bio available' &&
                            _profileData['bio'].toString().isNotEmpty) ...[
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              _profileData['bio'],
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 4. Looking For (What they want)
                        if (_profileData['orientation'] != null &&
                            (_profileData['orientation'] as List)
                                .isNotEmpty) ...[
                          const Text(
                            'Looking for',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            child: Text(
                              (_profileData['orientation'] as List).join(', '),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 5. Interests/Hobbies (Compatibility)
                        if ((_profileData['interests'] as List).isNotEmpty) ...[
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_profileData['interests']
                                    as List<dynamic>)
                                .map((interest) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.pink.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.pink.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        interest.toString(),
                                        style: TextStyle(
                                          color: Colors.pink.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 6. Additional Info (Gender, etc.)
                        if (_profileData['gender'] != null &&
                            _profileData['gender'] != 'Not specified' &&
                            _profileData['gender'].toString().isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getGenderIcon(_profileData['gender']),
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _profileData['gender'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String? value) {
    if (value == null ||
        value.isEmpty ||
        value == 'Unknown location' ||
        value == 'Not specified') {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get gender icon
  IconData _getGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'non-binary':
      case 'other':
        return Icons.transgender;
      default:
        return Icons.person;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
