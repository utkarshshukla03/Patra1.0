import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';

class UploadPhotosPage extends StatefulWidget {
  @override
  State<UploadPhotosPage> createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  List<Uint8List?> images = List.filled(6, null);
  String bio = '';

  Future<void> pickImage(int index) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        images[index] = bytes;
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
                        color: Colors.pinkAccent.withOpacity(0.1),
                      ),
                      child: images[index] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(images[index]!,
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
                    final temp = images.removeAt(oldIndex);
                    images.insert(newIndex, temp);
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
                  onPressed: () {
                    // TODO: Save images and bio to database
                    Navigator.of(context).pop();
                  },
                  child: Text('Finish',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
