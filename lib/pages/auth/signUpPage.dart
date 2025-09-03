import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patra_initial/pages/auth/loginPage.dart';

import '../../resources/auth_method.dart';
import '../hobbiesPage.dart';
// import '../homePage.dart';
// import 'package:prem_patra1/resources/auth_method.dart';
// import 'package:prem_patra1/resources/auth_methods.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:prem_patra1/screens/login.dart';

// import '../responsive/mobile_screen_layout.dart';
// import '../responsive/responsive_layout.dart';
// import '../responsive/web_screen_layout.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  Uint8List? _image;
  bool _isloading = false;
  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
  }

  void selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    setState(() {
      _image = im;
    });
  }

  Future<Uint8List> pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      return await image.readAsBytes();
    }
    throw Exception('No image selected');
  }

  void signUpUser() async {
    String email = _emailController.text.trim();
    if (!email.endsWith('@thapar.edu')) {
      showSnackBar('Please use your thapar.edu email ID to sign up.', context);
      return;
    }
    setState(() {
      _isloading = true;
    });
    String res = await AuthMethods().signUpUser(
        email: email,
        password: _passwordController.text,
        username: _usernameController.text,
        file: _image!);
    setState(() {
      _isloading = false;
    });

    if (res != 'success') {
      showSnackBar(res, context);
    } else {
      // Go to next page for more questions
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HobbiesPage(
              // email: email,
              // username: _usernameController.text,
              // image: _image!,
              ),
        ),
      );
    }
  }

  void navigateToLogIn() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => LoginPage(),
    ));
  }

  void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Image.asset(
              //   'assets/hug.png',
              //   height: 300,
              //   width: 300,
              // ),

              // circular widget to accept and show our selected file
              // Stack(
              //   children: [
              //     _image != null
              //         ? CircleAvatar(
              //             radius: 64,
              //             backgroundImage: MemoryImage(_image!),
              //           )
              //         : const CircleAvatar(
              //             radius: 64,
              //             backgroundImage: NetworkImage(
              //                 'https://as2.ftcdn.net/v2/jpg/02/15/84/43/1000_F_215844325_ttX9YiIIyeaR7Ne6EaLLjMAmy4GvPC69.jpg'),
              //           ),
              //     Positioned(
              //         bottom: -10,
              //         left: 80,
              //         child: IconButton(
              //           onPressed: selectImage,
              //           icon: const Icon(Icons.add_a_photo),
              //         ))
              //   ],
              // ),
              SizedBox(height: 20),

              ///username

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Username'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Email'),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),
              // password
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                            border: InputBorder.none, hintText: 'Password'),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // confirm password
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Confirm Password'),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Next button
              GestureDetector(
                onTap: signUpUser,
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
                                'Next',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                      )),
                ),
              ),
              SizedBox(height: 100),

              // have an account?Login in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Have an account?',
                      style: TextStyle(
                          // color: Colors.blue,
                          // fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  GestureDetector(
                    onTap: navigateToLogIn,
                    child: Text(' Log In',
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
