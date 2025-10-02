import 'package:flutter/material.dart';

class BioLocationStepPage extends StatefulWidget {
  final Function(String, String) onComplete;
  final VoidCallback onBack;

  const BioLocationStepPage({
    Key? key,
    required this.onComplete,
    required this.onBack,
  }) : super(key: key);

  @override
  State<BioLocationStepPage> createState() => _BioLocationStepPageState();
}

class _BioLocationStepPageState extends State<BioLocationStepPage>
    with TickerProviderStateMixin {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

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
    _bioController.dispose();
    _locationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _completeSignup() async {
    setState(() {
      _isLoading = true;
    });

    // Add a small delay for better UX
    await Future.delayed(Duration(milliseconds: 500));

    widget.onComplete(
      _bioController.text.trim(),
      _locationController.text.trim(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          helperText: helperText,
          helperStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 24,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: maxLines > 1 ? 20 : 18,
          ),
          counterStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ),
    );
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

                  SizedBox(height: 40),

                  // Heading
                  Text(
                    'Tell us a little about yourself',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 15),

                  Text(
                    'Share what makes you unique. This helps others connect with the real you.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Bio field
                  Text(
                    'About You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),

                  SizedBox(height: 12),

                  _buildTextField(
                    controller: _bioController,
                    hintText:
                        'What\'s your story? What do you love? What makes you laugh?',
                    icon: Icons.person_outline,
                    maxLines: 5,
                    maxLength: 500,
                    helperText:
                        'Share your personality, interests, or what you\'re looking for',
                  ),

                  SizedBox(height: 30),

                  // Location field
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),

                  SizedBox(height: 12),

                  _buildTextField(
                    controller: _locationController,
                    hintText: 'Where are you based?',
                    icon: Icons.location_on_outlined,
                    helperText:
                        'City, state, or area (helps with local connections)',
                  ),

                  SizedBox(height: 30),

                  // Tips container
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates,
                                color: Colors.green, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Profile Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Be authentic and genuine\n'
                          '• Mention your passions and goals\n'
                          '• Keep it positive and engaging\n'
                          '• Both fields are optional but recommended',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      // Skip button
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => widget.onComplete('', ''),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 15),

                      // Complete button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _completeSignup,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading
                                    ? [Colors.grey[400]!, Colors.grey[500]!]
                                    : [Colors.green, Colors.green.shade700],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Complete Setup',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
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
