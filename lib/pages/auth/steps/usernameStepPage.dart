import 'package:flutter/material.dart';
import 'dart:math';

class UsernameStepPage extends StatefulWidget {
  final Function(String) onNext;
  final VoidCallback onBack;
  final bool showBackButton;

  const UsernameStepPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  State<UsernameStepPage> createState() => _UsernameStepPageState();
}

class _UsernameStepPageState extends State<UsernameStepPage>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  late String _randomPrompt;
  bool _hasError = false;
  String _errorText = '';

  // Animation controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _psychologicalPrompts = [
    "What should we call you while you're here?",
    "How do your friends usually introduce you?",
    "If someone wants to grab your attention, what name do they shout?",
    "The name that feels most you is…?",
    "What do you want your matches to see first?",
    "How do people who love you call you?",
    "The vibe you want to give people with your name is…?",
    "What's your 'go-to' name in social circles?",
    "What name feels most natural when you hear it?",
    "If this app became your favorite story, what name would you use as the main character?",
  ];

  @override
  void initState() {
    super.initState();
    _randomPrompt =
        _psychologicalPrompts[Random().nextInt(_psychologicalPrompts.length)];

    // Initialize animations
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

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
    _usernameController.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorText = message;
    });

    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });

    // Clear error after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorText = '';
        });
      }
    });
  }

  void _validateAndProceed() {
    String username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showError("Please enter a username");
      return;
    }

    if (username.length < 2) {
      _showError("Username should be at least 2 characters");
      return;
    }

    if (username.length > 20) {
      _showError("Username should be less than 20 characters");
      return;
    }

    // Check for inappropriate characters
    if (!RegExp(r'^[a-zA-Z0-9_\s]+$').hasMatch(username)) {
      _showError("Username can only contain letters, numbers, and underscores");
      return;
    }

    widget.onNext(username);
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

                  // Back button (if needed)
                  if (widget.showBackButton)
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

                  SizedBox(height: widget.showBackButton ? 20 : 60),

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
                            Icons.person_add,
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

                  SizedBox(height: 60),

                  // Psychological prompt heading
                  Text(
                    _randomPrompt,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Username input field with animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: _hasError
                                    ? Border.all(color: Colors.red, width: 2)
                                    : Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: _hasError
                                        ? Colors.red.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _usernameController,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter your username',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 18,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: _hasError
                                        ? Colors.red
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (_hasError) {
                                    setState(() {
                                      _hasError = false;
                                      _errorText = '';
                                    });
                                  }
                                },
                                onSubmitted: (value) => _validateAndProceed(),
                              ),
                            ),

                            // Error message
                            if (_hasError && _errorText.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, top: 8),
                                child: Text(
                                  _errorText,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30),

                  // Helpful tip
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.pink.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.pink,
                          size: 24,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Choose something that represents you authentically. This is how your matches will know you.',
                            style: TextStyle(
                              color: Colors.pink[700],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  // Continue button
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 30),
                    child: GestureDetector(
                      onTap: _validateAndProceed,
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
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
            ),
          ),
        ),
      ),
    );
  }
}
