import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/story_service.dart';
import '../services/cloudinary_service.dart';
import '../resources/auth_method.dart';
import '../models/user.dart' as UserModel;
import '../widgets/glassmorphism_loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class StoryEditPage extends StatefulWidget {
  final String imagePath;
  final bool isFromCamera;

  const StoryEditPage({
    super.key,
    required this.imagePath,
    required this.isFromCamera,
  });

  @override
  State<StoryEditPage> createState() => _StoryEditPageState();
}

class _StoryEditPageState extends State<StoryEditPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isTextMode = false;
  bool _isLocationEnabled = false;
  Position? _currentPosition;
  String? _locationName;
  List<StorySticker> _stickers = [];
  int _selectedTextColor = 0;

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  final List<String> _stickerEmojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '🤧',
    '🥵',
    '🥶',
    '🥴',
    '😵',
    '🤯',
    '🤠',
    '🥳',
    '🥸',
    '😎',
    '🤓',
    '🧐',
    '😕',
    '😟',
    '🙁',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '🤎',
    '💔',
    '❣️',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '☮️',
    '✝️',
    '☪️',
    '🕉️',
    '☸️',
    '✡️',
    '🔯',
    '🕎',
    '☯️',
    '☦️',
    '🛐',
    '⛎',
    '♈',
    '♉',
    '♊',
    '♋',
    '♌',
    '♍',
    '♎',
    '♏',
    '♐',
    '🔥',
    '💯',
    '💢',
    '💨',
    '💫',
    '💦',
    '💤',
    '🌟'
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLocationEnabled = true;
        _locationName =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _addSticker(String emoji) {
    setState(() {
      _stickers.add(StorySticker(
        emoji: emoji,
        position: Offset(
          MediaQuery.of(context).size.width * 0.5,
          MediaQuery.of(context).size.height * 0.4,
        ),
        size: 50,
      ));
    });
  }

  void _removeSticker(int index) {
    setState(() {
      _stickers.removeAt(index);
    });
  }

  Future<void> _retakePhoto() async {
    Navigator.pop(context);
  }

  Future<void> _uploadStory() async {
    // Show glassmorphism loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GlassmorphismLoadingDialog(),
    );

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Upload image to Cloudinary
      String? imageUrl;
      if (kIsWeb) {
        // For web, we'll use the imagePath directly for now
        // In production, you'd want to upload to Cloudinary properly
        imageUrl = widget.imagePath;
      } else {
        File imageFileForUpload = File(widget.imagePath);
        imageUrl = await CloudinaryService().uploadImage(imageFileForUpload);
      }

      if (imageUrl == null) {
        throw Exception('Failed to process image');
      }

      // Upload story using StoryService createStory method
      final currentUserData = await AuthMethods().getUserProfile();
      if (currentUserData == null) {
        throw Exception('Failed to get user profile');
      }

      // Create User object
      final userModel = UserModel.User(
        uid: currentUser.uid,
        username: currentUserData['username'] ?? '',
        email: currentUserData['email'] ?? '',
        photoUrl: currentUserData['photoUrls']?.isNotEmpty == true
            ? currentUserData['photoUrls'][0]
            : '',
        bio: currentUserData['bio'],
        photoUrls: List<String>.from(currentUserData['photoUrls'] ?? []),
        interests: List<String>.from(currentUserData['interests'] ?? []),
        orientation: List<String>.from(currentUserData['orientation'] ?? []),
        age: currentUserData['age'],
        gender: currentUserData['gender'],
        location: currentUserData['location'],
      );

      // Create XFile from the image path
      final storyImageFile = XFile(widget.imagePath);

      await StoryService.createStory(
        imageFile: storyImageFile,
        currentUser: userModel,
        caption: _textController.text,
        locationName: _locationName ?? 'Unknown Location',
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Go back to profile
      Navigator.pop(context); // Close camera/edit flow

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error uploading story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload story: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: kIsWeb
                ? Image.network(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
          ),

          // Text Overlay
          if (_textController.text.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _textController.text,
                  style: TextStyle(
                    color: _textColors[_selectedTextColor],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Stickers
          ...(_stickers.asMap().entries.map((entry) {
            int index = entry.key;
            StorySticker sticker = entry.value;
            return Positioned(
              left: sticker.position.dx - sticker.size / 2,
              top: sticker.position.dy - sticker.size / 2,
              child: GestureDetector(
                onTap: () => _removeSticker(index),
                onPanUpdate: (details) {
                  setState(() {
                    _stickers[index] = StorySticker(
                      emoji: sticker.emoji,
                      position: Offset(
                        sticker.position.dx + details.delta.dx,
                        sticker.position.dy + details.delta.dy,
                      ),
                      size: sticker.size,
                    );
                  });
                },
                child: Container(
                  width: sticker.size,
                  height: sticker.size,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      sticker.emoji,
                      style: TextStyle(fontSize: sticker.size * 0.7),
                    ),
                  ),
                ),
              ),
            );
          }).toList()),

          // Location tag
          if (_isLocationEnabled && _locationName != null)
            Positioned(
              bottom: 150,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _locationName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top Controls
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Text button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTextMode = !_isTextMode;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Location button
                GestureDetector(
                  onTap: _getCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _isLocationEnabled ? Colors.blue : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stickers Panel
          Positioned(
            right: 20,
            top: 120,
            bottom: 200,
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ListView.builder(
                itemCount: _stickerEmojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _addSticker(_stickerEmojis[index]),
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Center(
                        child: Text(
                          _stickerEmojis[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Text Input Mode
          if (_isTextMode)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text Color Selector
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _textColors.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTextColor = index;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: _textColors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedTextColor == index
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Text Input
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(
                          color: _textColors[_selectedTextColor],
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                        autofocus: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Done button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isTextMode = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Retake button
                GestureDetector(
                  onTap: _retakePhoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Retake',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Upload button
                GestureDetector(
                  onTap: _uploadStory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StorySticker {
  final String emoji;
  final Offset position;
  final double size;

  StorySticker({
    required this.emoji,
    required this.position,
    required this.size,
  });
}
