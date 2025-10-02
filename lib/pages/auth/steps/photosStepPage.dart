import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';

class PhotosStepPage extends StatefulWidget {
  final Function(List<XFile>) onNext;
  final VoidCallback onBack;

  const PhotosStepPage({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PhotosStepPage> createState() => _PhotosStepPageState();
}

class _PhotosStepPageState extends State<PhotosStepPage>
    with TickerProviderStateMixin {
  List<XFile?> imageFiles = List.filled(6, null);
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start fade in animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageFiles[index] = image;
      });
    }
  }

  void _proceedToNext() {
    // Filter out null images and get the actual files
    List<XFile> actualImages =
        imageFiles.where((file) => file != null).cast<XFile>().toList();

    // Photos are optional - user can proceed without any photos
    widget.onNext(actualImages);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),

                  // Back button
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // App name/branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink, Colors.pink.shade300],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.photo_camera,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'PremPatra',
                          style: TextStyle(
                            fontFamily: 'StyleScript',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Photos heading
                  Text(
                    'Add up to 6 photos of yourself',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 15),

                  // Optional subtitle
                  Text(
                    'Photos help others connect with you (optional)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 30),

                  // Photo grid using ReorderableWrap
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
                            color: Colors.pinkAccent.withOpacity(0.1),
                          ),
                          child: imageFiles[index] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? FutureBuilder<Uint8List>(
                                          future:
                                              imageFiles[index]!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover);
                                            } else {
                                              return Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }
                                          },
                                        )
                                      : Image.file(
                                          File(imageFiles[index]!.path),
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

                  Spacer(),

                  // Buttons row
                  Row(
                    children: [
                      // Skip button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNext([]), // Skip with no photos
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 15),

                      // Continue button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _proceedToNext,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.pink, Colors.pink.shade700],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                imageFiles.any((file) => file != null)
                                    ? 'Continue'
                                    : 'Continue without photos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
