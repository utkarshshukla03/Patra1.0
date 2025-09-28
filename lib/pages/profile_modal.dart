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
      // Request user (mock data)
      return [
        'https://images.unsplash.com/photo-1494790108755-2616b67fcec?w=400',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
      ];
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
      // Request user (mock data)
      return {
        'name': widget.requestUserData?['name'] ?? 'Emma',
        'age': widget.requestUserData?['age'] ?? 25,
        'bio': widget.requestUserData?['bio'] ??
            'Love hiking and coffee shops ☕️\n\nPassionate about photography and exploring new places. Always up for an adventure or a cozy night in with a good book.',
        'interests': widget.requestUserData?['interests'] ??
            ['Photography', 'Hiking', 'Coffee', 'Reading', 'Travel', 'Yoga'],
        'prompts': [
          {
            'question': 'My simple pleasures',
            'answer':
                'Sunday morning coffee, golden hour photography, and spontaneous road trips'
          },
          {
            'question': 'I\'m looking for',
            'answer':
                'Someone who can laugh at my terrible dad jokes and join me on weekend adventures'
          },
          {
            'question': 'You should leave a comment if',
            'answer':
                'You have any good book recommendations or know the best coffee spots in town'
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
                                image: DecorationImage(
                                  image: NetworkImage(_images[index]),
                                  fit: BoxFit.cover,
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
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
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

                  // Profile info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and age
                        Row(
                          children: [
                            Text(
                              _profileData['name'],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_profileData['age']}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey.shade600,
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
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Location and Gender (for homepage users)
                        if (widget.user != null) ...[
                          Row(
                            children: [
                              if (_profileData['location'] != null) ...[
                                Icon(Icons.location_on,
                                    color: Colors.grey.shade600, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  _profileData['location'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              if (_profileData['location'] != null &&
                                  _profileData['gender'] != null)
                                const SizedBox(width: 16),
                              if (_profileData['gender'] != null) ...[
                                Icon(Icons.person,
                                    color: Colors.grey.shade600, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  _profileData['gender'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Interests
                        if ((_profileData['interests'] as List).isNotEmpty) ...[
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_profileData['interests']
                                    as List<String>)
                                .map((interest) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.pink.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.pink.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        interest,
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
                        const Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(_profileData['prompts']
                                as List<Map<String, String>>)
                            .map((prompt) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prompt['question']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        prompt['answer']!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),

                        const SizedBox(height: 32),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
