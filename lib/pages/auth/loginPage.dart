import 'package:flutter/material.dart';
import '../../resources/auth_method.dart';
import '../../widgets/main_navigation_wrapper.dart';
import 'loginPages/forgotPasswordPage.dart';
import 'multiStepSignUpFlow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isloading = false;
  bool _isPasswordVisible = false;

  // Error states
  bool _hasEmailError = false;
  bool _hasPasswordError = false;
  String _emailErrorText = '';
  String _passwordErrorText = '';

  // Animation controllers
  late AnimationController _emailShakeController;
  late AnimationController _passwordShakeController;
  late Animation<double> _emailShakeAnimation;
  late Animation<double> _passwordShakeAnimation;

  void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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

    // Initialize shake animations
    _emailShakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _emailShakeController, curve: Curves.elasticIn),
    );
    _passwordShakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
          parent: _passwordShakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailShakeController.dispose();
    _passwordShakeController.dispose();
  }

  void _shakeEmailField(String errorMessage) {
    setState(() {
      _hasEmailError = true;
      // Make error messages more user-friendly
      if (errorMessage.contains("No user found with this email")) {
        _emailErrorText = "Email not found. Please check or sign up.";
      } else if (errorMessage.contains("Please use your thapar.edu")) {
        _emailErrorText = "Use your @thapar.edu email address";
      } else if (errorMessage.contains("Please enter a valid email")) {
        _emailErrorText = "Enter a valid email address";
      } else if (errorMessage.contains("User profile not found")) {
        _emailErrorText = "Account not found. Please sign up.";
      } else if (errorMessage == "Email is required") {
        _emailErrorText = "Email is required";
      } else if (errorMessage.contains("valid @thapar.edu email")) {
        _emailErrorText = "Use your @thapar.edu email address";
      } else {
        _emailErrorText =
            errorMessage.length > 50 ? "Invalid email address" : errorMessage;
      }
    });
    _emailShakeController.forward().then((_) {
      _emailShakeController.reverse();
    });

    // Clear error after 4 seconds
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
      // Make error messages more user-friendly
      if (errorMessage.contains("Incorrect password")) {
        _passwordErrorText = "Wrong password. Try again.";
      } else if (errorMessage == "Password is required") {
        _passwordErrorText = "Password is required";
      } else if (errorMessage
          .contains("Incorrect password. Please try again.")) {
        _passwordErrorText = "Wrong password. Try again.";
      } else {
        _passwordErrorText =
            errorMessage.length > 50 ? "Invalid password" : errorMessage;
      }
    });
    _passwordShakeController.forward().then((_) {
      _passwordShakeController.reverse();
    });

    // Clear error after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasPasswordError = false;
          _passwordErrorText = '';
        });
      }
    });
  }

  void loginUser() async {
    // Clear any existing errors
    setState(() {
      _hasEmailError = false;
      _hasPasswordError = false;
      _emailErrorText = '';
      _passwordErrorText = '';
      _isloading = true;
    });

    String res = await AuthMethods().loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text);

    setState(() {
      _isloading = false;
    });

    if (res == "Success") {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => MainNavigationWrapper(),
      ));
    } else {
      // Handle specific error types with precise field animations
      if (res.contains("No user found with this email") ||
          res.contains("Please enter a valid email address") ||
          res.contains("Please use your thapar.edu") ||
          res.contains("invalid-email") ||
          res.contains("User profile not found")) {
        // Email-specific errors
        _shakeEmailField(res);
      } else if (res.contains("Incorrect password") ||
          res.contains("wrong-password")) {
        // Password-specific errors
        _shakePasswordField(res);
      } else if (res.contains("Invalid email or password") ||
          res.contains("invalid-credential")) {
        // This error means either email or password is wrong, but we can't tell which
        // Let's check if the email format is valid first
        String email = _emailController.text.trim();
        if (email.isEmpty ||
            !email.contains('@') ||
            (!email.endsWith('@thapar.edu') && !email.endsWith('@thapr.edu'))) {
          // Email format is wrong
          _shakeEmailField("Please enter a valid @thapar.edu email address");
        } else {
          // Email format is correct, so password is likely wrong
          _shakePasswordField("Incorrect password. Please try again.");
        }
      } else if (res.contains("Please fill in all fields")) {
        // Handle empty fields
        if (_emailController.text.trim().isEmpty) {
          _shakeEmailField("Email is required");
        }
        if (_passwordController.text.isEmpty) {
          Future.delayed(Duration(milliseconds: 100), () {
            _shakePasswordField("Password is required");
          });
        }
      } else {
        // For any other unknown errors, show in email field as it's usually the primary identifier
        _shakeEmailField(res);
      }
    }
  }

  void forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _shakeEmailField("Please enter your email address");
      return;
    }

    if (!_emailController.text.trim().endsWith('@thapar.edu')) {
      _shakeEmailField("Please use your @thapar.edu email address");
      return;
    }

    try {
      // Send reset email and navigate to verification page
      await AuthMethods().resetPassword(email: _emailController.text.trim());

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ForgotPasswordPage(email: _emailController.text.trim()),
        ),
      );
    } catch (e) {
      _shakeEmailField("Error sending reset email. Please try again.");
    }
  }

  void navigateToSignUp() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MultiStepSignUpFlow(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // You can add this to your login page for testing
    AuthMethods().testFirebaseConnection().then((result) {
      print(result);
    });

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
              child: Center(
                  child: Column(
            children: [
              // Name
              SizedBox(
                height: 80,
              ),
              Text(
                'Patra',
                style: TextStyle(
                    fontSize: 50.0,
                    fontFamily: 'Ginger',
                    fontWeight: FontWeight.bold),
              ),
              // SizedBox(height: 10),

              // image
              Container(
                height: 300,
                child: Image.asset(
                  'assets/Talk.webp',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Asset loading error: $error');
                    return Container(
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 80,
                            color: Colors.pink,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Patra',
                            style: TextStyle(
                              fontFamily: 'Ginger',
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              //email/username
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _emailShakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_emailShakeAnimation.value, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: _hasEmailError
                                  ? Border.all(color: Colors.red, width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: _hasEmailError
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Email or username',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: _hasEmailError
                                        ? Colors.red
                                        : Colors.grey[600]),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_hasEmailError && _emailErrorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 15, top: 5),
                        child: Text(
                          _emailErrorText,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              // password

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _passwordShakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_passwordShakeAnimation.value, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: _hasPasswordError
                                  ? Border.all(color: Colors.red, width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: _hasPasswordError
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: _hasPasswordError
                                        ? Colors.red
                                        : Colors.grey[600]),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: _hasPasswordError
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_hasPasswordError && _passwordErrorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 15, top: 5),
                        child: Text(
                          _passwordErrorText,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Forgot Password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: forgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 15),

              // Sign In button
              GestureDetector(
                onTap: loginUser,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    padding: EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink, Colors.pink.shade700],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
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
                      child: _isloading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sign In',
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

              SizedBox(height: 150),
              // Not a member?SignUp
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Dont have an account?',
                      style: TextStyle(
                          // color: Colors.blue,
                          // fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  GestureDetector(
                    onTap: navigateToSignUp,
                    child: Text(' Sign Up',
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  )
                ],
              )
            ],
          ))),
        ));
  }
}
