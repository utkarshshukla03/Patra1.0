import 'package:flutter/material.dart';
import 'uploadPhotosPage.dart';
import '../services/cloudinary_service.dart';

class HobbiesPage extends StatefulWidget {
  // final String email;
  // final String username;
  // final Uint8List image;
  // const HobbiesPage(
  //     {Key? key,
  //     required this.email,
  //     required this.username,
  //     required this.image})
  //     : super(key: key);

  @override
  State<HobbiesPage> createState() => _HobbiesPageState();
}

class _HobbiesPageState extends State<HobbiesPage> {
  // Example fields for hobbies, gender, dob, interests, relationship type
  List<String> selectedHobbies = [];
  String? gender;
  DateTime? dob;
  List<String> relationshipTypes = []; // Changed to List for multiple selection
  String aboutMe = '';
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isSaving = false;

  final List<String> hobbiesTags = [
    'Music',
    'Sports',
    'Reading',
    'Travel',
    'Art',
    'Gaming',
    'Cooking',
    'Dancing',
    'Movies',
    'Fitness',
    'Tech',
    'Pets',
    'Photography',
    'Fashion',
    'Outdoors',
    'Writing',
    'Yoga',
    'Meditation',
    'Volunteering',
    'Board Games'
  ];
  final List<String> interestTags = [
    'Friendship',
    'Fun',
    'Casual',
    'Relationship',
    'Serious',
    'Marriage',
    'Commitment'
  ];
  final List<String> genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Other',
    'Prefer not to say'
  ];
  final List<String> orientationOptions = [
    'Straight',
    'Gay',
    'Bisexual',
    'Other',
    'Prefer not to say'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tell Us About Yourself'),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.pinkAccent,
                        child:
                            Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text('Welcome!',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Let us know more about you',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700])),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.interests, color: Colors.pinkAccent),
                            SizedBox(width: 8),
                            Text('Hobbies',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: hobbiesTags.map((tag) {
                            final selected = selectedHobbies.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: selected,
                              selectedColor: Colors.pinkAccent.shade100,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    selectedHobbies.add(tag);
                                  } else {
                                    selectedHobbies.remove(tag);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wc, color: Colors.pinkAccent),
                            SizedBox(width: 8),
                            Text('Gender',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: genderOptions.map((g) {
                            return ChoiceChip(
                              label: Text(g),
                              selected: gender == g,
                              selectedColor: Colors.pinkAccent.shade100,
                              onSelected: (val) {
                                setState(() {
                                  gender = val ? g : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.pinkAccent),
                            SizedBox(width: 8),
                            Text('Sexual Orientation',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: orientationOptions.map((o) {
                            return ChoiceChip(
                              label: Text(o),
                              selected: relationshipTypes.contains(o),
                              selectedColor: Colors.pinkAccent.shade100,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    if (!relationshipTypes.contains(o)) {
                                      relationshipTypes.add(o);
                                    }
                                  } else {
                                    relationshipTypes.remove(o);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cake, color: Colors.pinkAccent),
                            SizedBox(width: 8),
                            Text('Date of Birth',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                                dob == null
                                    ? 'Select DOB'
                                    : dob!.toLocal().toString().split(' ')[0],
                                style: TextStyle(fontSize: 16)),
                            IconButton(
                              icon: Icon(Icons.calendar_today,
                                  color: Colors.pinkAccent),
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    dob = picked;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.search, color: Colors.pinkAccent),
                            SizedBox(width: 8),
                            Text('Looking For',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: interestTags.map((tag) {
                            return ChoiceChip(
                              label: Text(tag),
                              selected: relationshipTypes
                                  .contains(tag), // Check if tag is in the list
                              selectedColor: Colors.pinkAccent.shade100,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    // Add tag if not already selected
                                    if (!relationshipTypes.contains(tag)) {
                                      relationshipTypes.add(tag);
                                    }
                                  } else {
                                    // Remove tag if deselected
                                    relationshipTypes.remove(tag);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.pinkAccent),
                            SizedBox(width: 8),
                            Text('About Me',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Write a short bio about yourself...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              aboutMe = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      setState(() {
                        _isSaving = true;
                      });

                      try {
                        // Save user preferences to Firestore
                        bool success =
                            await _cloudinaryService.updateUserProfile(
                          dateOfBirth: dob,
                          gender: gender,
                          orientation: relationshipTypes,
                          interests: selectedHobbies,
                          bio: aboutMe,
                        );

                        if (success) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UploadPhotosPage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to save preferences')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      } finally {
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    },
                    child: _isSaving
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Saving...', style: TextStyle(fontSize: 18)),
                            ],
                          )
                        : Text('Next',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
