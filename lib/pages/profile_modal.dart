import 'package:flutter/material.dart';
import '../models/user.dart' as UserModel;

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
        'name': widget.user!.username,
        'age': widget.user!.calculatedAge,
        'bio': widget.user!.bio ?? 'No bio available',
        'interests': widget.user!.interests ?? [],
        'location': widget.user!.location,
        'gender': widget.user!.gender,
        'prompts': [
          {
            'question': 'About me',
            'answer': widget.user!.bio ?? 'Getting to know me better...'
          },
          if (widget.user!.interests != null &&
              widget.user!.interests!.isNotEmpty)
            {
              'question': 'My interests',
              'answer': widget.user!.interests!.join(', ')
            },
          if (widget.user!.location != null)
            {'question': 'Location', 'answer': widget.user!.location!},
        ],
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
        'prompts': [
          // Only include bio, no duplicate info sections
          {
            'question': 'About me',
            'answer':
                widget.requestUserData?['bio'] ?? 'Getting to know me better...'
          },
        ],
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
                        // Name and Age
                        Row(
                          children: [
                            Text(
                              _profileData['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_profileData['age']}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bio
                        Text(
                          _profileData['bio'],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Location and Gender
                        if (widget.user != null) ...[
                          // Home page user
                          if (_profileData['location'] != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _profileData['location'],
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_profileData['location'] != null &&
                              _profileData['gender'] != null)
                            const SizedBox(height: 8),
                          if (_profileData['gender'] != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _profileData['gender'],
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          // Request user - show more detailed info sections
                          _buildInfoSection(
                              'Location', _profileData['location']),
                          _buildInfoSection('Gender', _profileData['gender']),
                          if (_profileData['orientation'] != null &&
                              (_profileData['orientation'] as List).isNotEmpty)
                            _buildInfoSection(
                                'Looking for',
                                (_profileData['orientation'] as List)
                                    .join(', ')),
                        ],

                        const SizedBox(height: 24),

                        // Interests/Hobbies
                        if ((_profileData['interests'] as List).isNotEmpty) ...[
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                                          horizontal: 12, vertical: 6),
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
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Prompts
                        ...(_profileData['prompts']
                                as List<Map<String, dynamic>>)
                            .map((prompt) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prompt['question']?.toString() ??
                                          'Question',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
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
                                        prompt['answer']?.toString() ??
                                            'No answer provided',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                )),

                        const SizedBox(height: 20),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
