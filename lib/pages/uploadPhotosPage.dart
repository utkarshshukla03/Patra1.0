import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';
import '../services/cloudinary_service.dart';
import '../widgets/main_navigation_wrapper.dart';

class UploadPhotosPage extends StatefulWidget {
  @override
  State<UploadPhotosPage> createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  List<XFile?> imageFiles = List.filled(6, null);
  String bio = '';
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;

  Future<void> pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageFiles[index] = image;
      });
    }
  }

  Future<void> _uploadPhotosAndFinish() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Filter out null images and get the actual files
      List<XFile> actualImages =
          imageFiles.where((file) => file != null).cast<XFile>().toList();

      if (actualImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one photo')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload images to Cloudinary using XFile-compatible method
      List<String> imageUrls =
          await _cloudinaryService.uploadMultipleImagesFromXFiles(actualImages);

      if (imageUrls.isNotEmpty) {
        // Update user profile with image URLs and bio
        bool success =
            await _cloudinaryService.updateUserProfileImages(imageUrls);

        if (bio.isNotEmpty) {
          await _cloudinaryService.updateUserProfile(bio: bio);
        }

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photos uploaded successfully!')),
          );

          // Navigate to home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigationWrapper()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile data')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload images')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Your Photos'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add up to 6 photos of yourself',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ReorderableWrap(
                spacing: 8,
                runSpacing: 8,
                maxMainAxisCount: 3,
                needsLongPressDraggable: true,
                children: List.generate(6, (index) {
                  return GestureDetector(
                    key: ValueKey(index),
                    onTap: () => pickImage(index),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pinkAccent),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.pinkAccent.withValues(alpha: 0.1),
                      ),
                      child: imageFiles[index] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: imageFiles[index]!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(snapshot.data!,
                                              fit: BoxFit.cover);
                                        } else {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }
                                      },
                                    )
                                  : Image.file(File(imageFiles[index]!.path),
                                      fit: BoxFit.cover),
                            )
                          : Center(
                              child: Icon(Icons.add_a_photo,
                                  color: Colors.pinkAccent, size: 32),
                            ),
                    ),
                  );
                }),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final temp = imageFiles.removeAt(oldIndex);
                    imageFiles.insert(newIndex, temp);
                  });
                },
              ),
              SizedBox(height: 24),
              Text('Your Bio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    bio = val;
                  });
                },
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _isUploading ? null : _uploadPhotosAndFinish,
                  child: _isUploading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Uploading...',
                                style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : Text('Finish',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
