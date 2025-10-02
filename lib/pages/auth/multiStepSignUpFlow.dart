import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'steps/usernameStepPage.dart';
import 'steps/emailPasswordStepPage.dart';
import 'steps/genderStepPage.dart';
import 'steps/dobStepPage.dart';
import 'steps/lookingForStepPage.dart';
import 'steps/hobbiesStepPage.dart';
import 'steps/photosStepPage.dart';
import 'steps/bioLocationStepPage.dart';
import '../../resources/auth_method.dart';
import '../../widgets/main_navigation_wrapper.dart';
import '../../services/cloudinary_service.dart';

class MultiStepSignUpFlow extends StatefulWidget {
  const MultiStepSignUpFlow({Key? key}) : super(key: key);

  @override
  State<MultiStepSignUpFlow> createState() => _MultiStepSignUpFlowState();
}

class _MultiStepSignUpFlowState extends State<MultiStepSignUpFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps =
      8; // Updated to include gender, DOB, and looking for steps

  // Data collection variables
  String username = '';
  String email = '';
  String password = '';
  String selectedGender = '';
  DateTime? dateOfBirth;
  List<String> lookingFor = [];
  List<String> selectedHobbies = [];
  List<XFile> selectedPhotos = [];
  String bio = '';
  String location = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToHome() {
    _showSkipConfirmationDialog();
  }

  void _showSkipConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights,
                    size: 50,
                    color: Colors.pink,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Complete Your Story',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Profiles with complete details get matches faster. Do you want to finish now?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainNavigationWrapper(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Maybe Later',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.pink, Colors.pink.shade700],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Complete Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeSignup() async {
    try {
      // Create account with collected data
      String result = await AuthMethods().signUpUser(
        email: email,
        password: password,
        username: username,
      );

      if (result == "Success") {
        final CloudinaryService cloudinaryService = CloudinaryService();
        List<String> imageUrls = [];

        // Upload photos if any were selected
        if (selectedPhotos.isNotEmpty) {
          try {
            imageUrls = await cloudinaryService
                .uploadMultipleImagesFromXFiles(selectedPhotos);
            print('Successfully uploaded ${imageUrls.length} photos');
          } catch (e) {
            print('Error uploading photos: $e');
            // Continue even if photo upload fails
          }
        }

        // Complete profile setup with all collected data
        try {
          bool profileUpdateSuccess =
              await cloudinaryService.completeProfileSetup(
            interests: selectedHobbies,
            bio: bio.isNotEmpty ? bio : null,
            location: location.isNotEmpty ? location : null,
            photoUrls: imageUrls.isNotEmpty ? imageUrls : null,
            gender: selectedGender.isNotEmpty ? selectedGender : null,
            orientation: lookingFor.isNotEmpty ? lookingFor : null,
            dateOfBirth: dateOfBirth,
          );

          if (profileUpdateSuccess) {
            print('Profile setup completed successfully');
          } else {
            print('Profile setup failed but continuing...');
          }
        } catch (e) {
          print('Error completing profile setup: $e');
          // Continue even if profile update fails
        }

        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationWrapper(),
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating account: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(_totalSteps, (index) {
              bool isActive = index <= _currentStep;
              bool isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isCurrent
                            ? Colors.pink
                            : Colors.pink.withOpacity(0.7))
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: 15),

          // Step counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _skipToHome,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // Step 1: Email & Password
                  EmailPasswordStepPage(
                    onNext: (emailValue, passwordValue) {
                      email = emailValue;
                      password = passwordValue;
                      _nextStep();
                    },
                    onBack: _previousStep,
                    showBackButton: false,
                  ),

                  // Step 2: Username
                  UsernameStepPage(
                    onNext: (usernameValue) {
                      username = usernameValue;
                      _nextStep();
                    },
                    onBack: _previousStep,
                  ),

                  // Step 3: Gender
                  GenderStepPage(
                    onNext: (genderValue) {
                      selectedGender = genderValue;
                      _nextStep();
                    },
                    onBack: _previousStep,
                  ),

                  // Step 4: Date of Birth
                  DobStepPage(
                    onNext: (dobValue) {
                      dateOfBirth = dobValue;
                      _nextStep();
                    },
                    onBack: _previousStep,
                  ),

                  // Step 5: Looking For
                  LookingForStepPage(
                    onNext: (lookingForValue) {
                      lookingFor = lookingForValue;
                      _nextStep();
                    },
                    onBack: _previousStep,
                  ),

                  // Step 6: Hobbies
                  HobbiesStepPage(
                    onNext: (hobbies) {
                      selectedHobbies = hobbies;
                      _nextStep();
                    },
                    onBack: _previousStep,
                  ),

                  // Step 7: Photos
                  PhotosStepPage(
                    onNext: (photos) {
                      selectedPhotos = photos;
                      _nextStep();
                    },
                    onBack: _previousStep,
                  ),

                  // Step 8: Bio & Location
                  BioLocationStepPage(
                    onComplete: (bioValue, locationValue) async {
                      bio = bioValue;
                      location = locationValue;
                      await _completeSignup();
                    },
                    onBack: _previousStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
