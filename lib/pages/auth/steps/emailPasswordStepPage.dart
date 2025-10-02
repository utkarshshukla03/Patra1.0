import 'package:flutter/material.dart';
import 'dart:async';

class EmailPasswordStepPage extends StatefulWidget {
  final Function(String, String) onNext;
  final VoidCallback onBack;
  final bool showBackButton;

  const EmailPasswordStepPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  State<EmailPasswordStepPage> createState() => _EmailPasswordStepPageState();
}

class _EmailPasswordStepPageState extends State<EmailPasswordStepPage>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes for better focus management
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Debounce timer to reduce rapid state changes
  Timer? _debounceTimer;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Error states
  bool _hasEmailError = false;
  bool _hasPasswordError = false;
  bool _hasConfirmPasswordError = false;
  String _emailErrorText = '';
  String _passwordErrorText = '';
  String _confirmPasswordErrorText = '';

  // Animation controllers
  late AnimationController _emailShakeController;
  late AnimationController _passwordShakeController;
  late AnimationController _confirmPasswordShakeController;
  late AnimationController _fadeController;

  late Animation<double> _emailShakeAnimation;
  late Animation<double> _passwordShakeAnimation;
  late Animation<double> _confirmPasswordShakeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _emailShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _passwordShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _confirmPasswordShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    _emailShakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _emailShakeController, curve: Curves.elasticIn),
    );
    _passwordShakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
          parent: _passwordShakeController, curve: Curves.elasticIn),
    );
    _confirmPasswordShakeAnimation =
        Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
          parent: _confirmPasswordShakeController, curve: Curves.elasticIn),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start fade in animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailShakeController.dispose();
    _passwordShakeController.dispose();
    _confirmPasswordShakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _shakeEmailField(String errorMessage) {
    setState(() {
      _hasEmailError = true;
      _emailErrorText = errorMessage;
    });
    _emailShakeController.forward().then((_) {
      _emailShakeController.reverse();
    });

    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasEmailError = false;
          _emailErrorText = '';
        });
      }
    });
  }

  void _shakePasswordField(String errorMessage) {
    setState(() {
      _hasPasswordError = true;
      _passwordErrorText = errorMessage;
    });
    _passwordShakeController.forward().then((_) {
      _passwordShakeController.reverse();
    });

    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasPasswordError = false;
          _passwordErrorText = '';
        });
      }
    });
  }

  void _shakeConfirmPasswordField(String errorMessage) {
    setState(() {
      _hasConfirmPasswordError = true;
      _confirmPasswordErrorText = errorMessage;
    });
    _confirmPasswordShakeController.forward().then((_) {
      _confirmPasswordShakeController.reverse();
    });

    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasConfirmPasswordError = false;
          _confirmPasswordErrorText = '';
        });
      }
    });
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  void _debouncedSetState(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(callback);
      }
    });
  }

  void _showPasswordRequirementsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent dialog from closing when tapping inside
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
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
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Password Requirements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRequirementItem('At least 8 characters long'),
                            SizedBox(height: 8),
                            _buildRequirementItem(
                                'Contains uppercase letter (A-Z)'),
                            SizedBox(height: 8),
                            _buildRequirementItem(
                                'Contains lowercase letter (a-z)'),
                            SizedBox(height: 8),
                            _buildRequirementItem(
                                'Contains at least one number (0-9)'),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Tap anywhere to dismiss',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Auto dismiss after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildRequirementItem(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  void _validateAndProceed() {
    setState(() {
      _hasEmailError = false;
      _hasPasswordError = false;
      _hasConfirmPasswordError = false;
      _emailErrorText = '';
      _passwordErrorText = '';
      _confirmPasswordErrorText = '';
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    // Email validation
    if (email.isEmpty) {
      _shakeEmailField("Please enter your email address");
      hasError = true;
    } else if (!email.endsWith('@thapar.edu')) {
      _shakeEmailField("Please use your @thapar.edu email address");
      hasError = true;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _shakeEmailField("Please enter a valid email address");
      hasError = true;
    }

    // Password validation
    if (password.isEmpty) {
      _shakePasswordField("Please enter a password");
      hasError = true;
    } else if (!_validatePassword(password)) {
      _showPasswordRequirementsDialog();
      hasError = true;
    }

    // Confirm password validation
    if (confirmPassword.isEmpty) {
      _shakeConfirmPasswordField("Please confirm your password");
      hasError = true;
    } else if (password != confirmPassword) {
      _shakeConfirmPasswordField("Passwords don't match");
      hasError = true;
    }

    if (!hasError) {
      widget.onNext(email, password);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool hasError,
    required String errorText,
    required Animation<double> shakeAnimation,
    FocusNode? focusNode,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? togglePasswordVisibility,
  }) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: hasError
                      ? Border.all(color: Colors.red, width: 2)
                      : Border.all(
                          color: Colors.grey.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: hasError
                          ? Colors.red.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isPassword && !(isPasswordVisible ?? false),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      icon,
                      color: hasError ? Colors.red : Colors.grey[600],
                      size: 24,
                    ),
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              (isPasswordVisible ?? false)
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: hasError ? Colors.red : Colors.grey[600],
                            ),
                            onPressed: togglePasswordVisibility,
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  onChanged: (value) {
                    if (hasError) {
                      setState(() {
                        if (controller == _emailController) {
                          _hasEmailError = false;
                          _emailErrorText = '';
                        } else if (controller == _passwordController) {
                          _hasPasswordError = false;
                          _passwordErrorText = '';
                        } else if (controller == _confirmPasswordController) {
                          _hasConfirmPasswordError = false;
                          _confirmPasswordErrorText = '';
                        }
                      });
                    }
                  },
                ),
              ),

              // Error message
              if (hasError && errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8),
                  child: Text(
                    errorText,
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

                  // Back button (conditional)
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

                  SizedBox(height: widget.showBackButton ? 40 : 80),

                  // Heading
                  Text(
                    'Your Credentials',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 15),

                  Text(
                    'We\'ll use your Thapar email to keep your account secure',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter your @thapar.edu email',
                    icon: Icons.email_outlined,
                    hasError: _hasEmailError,
                    errorText: _emailErrorText,
                    shakeAnimation: _emailShakeAnimation,
                    focusNode: _emailFocusNode,
                  ),

                  SizedBox(height: 25),

                  // Password field
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Create a strong password',
                    icon: Icons.lock_outline,
                    hasError: _hasPasswordError,
                    errorText: _passwordErrorText,
                    shakeAnimation: _passwordShakeAnimation,
                    focusNode: _passwordFocusNode,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    togglePasswordVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),

                  SizedBox(height: 25),

                  // Confirm password field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm your password',
                    icon: Icons.lock_outline,
                    hasError: _hasConfirmPasswordError,
                    errorText: _confirmPasswordErrorText,
                    shakeAnimation: _confirmPasswordShakeAnimation,
                    focusNode: _confirmPasswordFocusNode,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    togglePasswordVisibility: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),

                  SizedBox(height: 20),

                  // Continue button
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 30),
                    child: GestureDetector(
                      onTap: _isLoading ? null : _validateAndProceed,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isLoading
                                ? [Colors.grey[400]!, Colors.grey[500]!]
                                : [Colors.pink, Colors.pink.shade700],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (_isLoading ? Colors.grey : Colors.pink)
                                  .withOpacity(0.3),
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
                              : Text(
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
