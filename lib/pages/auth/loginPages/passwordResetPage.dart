import 'package:flutter/material.dart';
import '../loginPage.dart';

class PasswordResetPage extends StatefulWidget {
  final String email;

  const PasswordResetPage({super.key, required this.email});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage>
    with TickerProviderStateMixin {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Error states
  bool _hasNewPasswordError = false;
  bool _hasConfirmPasswordError = false;
  String _newPasswordErrorText = '';
  String _confirmPasswordErrorText = '';

  // Animation controllers
  late AnimationController _newPasswordShakeController;
  late AnimationController _confirmPasswordShakeController;
  late Animation<double> _newPasswordShakeAnimation;
  late Animation<double> _confirmPasswordShakeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _newPasswordShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _confirmPasswordShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize shake animations
    _newPasswordShakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
          parent: _newPasswordShakeController, curve: Curves.elasticIn),
    );
    _confirmPasswordShakeAnimation =
        Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
          parent: _confirmPasswordShakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordShakeController.dispose();
    _confirmPasswordShakeController.dispose();
    super.dispose();
  }

  void _shakeNewPasswordField(String errorMessage) {
    setState(() {
      _hasNewPasswordError = true;
      _newPasswordErrorText = errorMessage;
    });
    _newPasswordShakeController.forward().then((_) {
      _newPasswordShakeController.reverse();
    });

    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasNewPasswordError = false;
          _newPasswordErrorText = '';
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
    if (password.length < 8) {
      return false;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return false;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return false;
    }
    return true;
  }

  void _resetPassword() async {
    // Clear previous errors
    setState(() {
      _hasNewPasswordError = false;
      _hasConfirmPasswordError = false;
      _newPasswordErrorText = '';
      _confirmPasswordErrorText = '';
    });

    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Validation
    bool hasError = false;

    if (newPassword.isEmpty) {
      _shakeNewPasswordField("Password is required");
      hasError = true;
    } else if (!_validatePassword(newPassword)) {
      _shakeNewPasswordField("Password must be 8+ chars with A-Z, a-z, 0-9");
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _shakeConfirmPasswordField("Please confirm your password");
      hasError = true;
    } else if (newPassword != confirmPassword) {
      _shakeConfirmPasswordField("Passwords don't match");
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would call your backend API to reset the password
      // For now, we'll simulate the process
      await Future.delayed(Duration(seconds: 2));

      // Show success message
      _showSuccessDialog();
    } catch (e) {
      _shakeNewPasswordField("Failed to reset password. Please try again.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green,
                ),
              ),

              SizedBox(height: 20),

              Text(
                'Password Reset Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 15),

              Text(
                'Your password has been successfully reset. You can now login with your new password.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 25),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade700],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // Icon and title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 25),
                    Text(
                      'Create New Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Your new password must be different from your previous password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // New Password Field
              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),

              SizedBox(height: 10),

              AnimatedBuilder(
                animation: _newPasswordShakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_newPasswordShakeAnimation.value, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: _hasNewPasswordError
                                ? Border.all(color: Colors.red, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: _hasNewPasswordError
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _newPasswordController,
                            obscureText: !_isNewPasswordVisible,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter new password',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: _hasNewPasswordError
                                      ? Colors.red
                                      : Colors.grey[600]),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isNewPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _hasNewPasswordError
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isNewPasswordVisible =
                                        !_isNewPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_hasNewPasswordError &&
                            _newPasswordErrorText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 15, top: 5),
                            child: Text(
                              _newPasswordErrorText,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 25),

              // Confirm Password Field
              Text(
                'Confirm New Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),

              SizedBox(height: 10),

              AnimatedBuilder(
                animation: _confirmPasswordShakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_confirmPasswordShakeAnimation.value, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: _hasConfirmPasswordError
                                ? Border.all(color: Colors.red, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: _hasConfirmPasswordError
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Confirm new password',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: _hasConfirmPasswordError
                                      ? Colors.red
                                      : Colors.grey[600]),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _hasConfirmPasswordError
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_hasConfirmPasswordError &&
                            _confirmPasswordErrorText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 15, top: 5),
                            child: Text(
                              _confirmPasswordErrorText,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 20),

              // Password requirements
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Password Requirements',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '• At least 8 characters long\n'
                      '• Contains uppercase letter (A-Z)\n'
                      '• Contains lowercase letter (a-z)\n'
                      '• Contains at least one number (0-9)',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Reset Password Button
              GestureDetector(
                onTap: _isLoading ? null : _resetPassword,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey[400]!, Colors.grey[500]!]
                          : [Colors.green, Colors.green.shade700],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoading ? Colors.grey : Colors.green)
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
                            'Reset Password',
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

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
