import 'package:flutter/material.dart';
import '../../resources/auth_method.dart';
import '../../widgets/main_navigation_wrapper.dart';
import '../../pages/auth/signUpPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isloading = false;

  void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void loginUser() async {
    setState(() {
      _isloading = true;
    });
    String res = await AuthMethods().loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text);

    if (res == "Success") {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => MainNavigationWrapper(),
      ));
    } else {
      showSnackBar(res, context);
    }

    setState(() {
      _isloading = false;
    });
  }

  void navigateToSignUp() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SignUp(),
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
                height: 20,
              ),
              Text(
                'PremPatra',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50.0,
                    fontFamily: 'StyleScript'),
              ),
              // SizedBox(height: 10),

              // image
              Container(
                height: 200,
                child: Image.asset(
                  'assets/Talk.webp',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Asset loading error: $error');
                    return Container(
                      height: 200,
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
                            'Patra Dating',
                            style: TextStyle(
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Email or username'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // password

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Passowrd'),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),

              // Sign In button
              GestureDetector(
                onTap: loginUser,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                      padding: EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: _isloading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                      )),
                ),
              ),

              SizedBox(height: 100),
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
