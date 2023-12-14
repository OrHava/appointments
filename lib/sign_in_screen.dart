import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:firebase_database/firebase_database.dart';
import 'first_time_sign_up_page.dart';
import 'home_page.dart';
import 'home_page_business.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'images/background_image.jpg'), // Replace with your image asset path
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60.0),
                  ElevatedButton(
                    onPressed: () {
                      signInWithGoogle(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            30.0), // Adjust the value for curviness
                      ),
                      minimumSize: const Size(
                          double.infinity, 50.0), // Adjust the width and height
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.blue,
                        ), // Your desired icon
                        SizedBox(
                            width:
                                14.0), // Adjust the spacing between the icon and text
                        Text(
                          'Sign In with Google',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Text(
                    "Or",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(2,
                              2), // Adjust the offset based on your preference
                          blurRadius:
                              2, // Adjust the blur radius based on your preference
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          30.0), // Adjust the radius as needed
                      border: Border.all(), // Add additional styling if needed
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        suffixIcon: Icon(
                          Icons.email,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          30.0), // Adjust the radius as needed
                      border: Border.all(), // Add additional styling if needed
                    ),
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !isPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          sendPasswordResetEmail(
                              emailController.text.trim(), context);
                        },
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Validate that email and password are not empty
                      FocusScope.of(context).unfocus();
                      if (emailController.text.trim().isEmpty ||
                          passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please enter both email and password.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        // Proceed with sign-in if fields are not empty
                        signInWithEmailPassword(emailController.text.trim(),
                            passwordController.text.trim(), context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            30.0), // Adjust the value for curviness
                      ),
                      minimumSize: const Size(
                          double.infinity, 50.0), // Adjust the width and height
                    ),
                    child: const Text(
                      'Log in',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendPasswordResetEmail(
      String email, BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Show a message to the user that the password reset email has been sent
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email has been sent to $email.'),
          ),
        );
      }
    } catch (e) {
      // Handle errors, e.g., email not found
      // ignore: avoid_print
      print(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> signInWithEmailPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Get user type
      String? userType = await getUserType(userCredential.user!.uid);

      // Check if the user is signing in for the first time
      if (userCredential.additionalUserInfo!.isNewUser && context.mounted) {
        // Redirect the user to a different page for the first-time sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FirstTimeSignUpPage()),
        );
      } else {
        // Redirect based on user type
        redirectToHomePage(context, userType);
      }
    } catch (e) {
      // Handle sign-in errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    await GoogleSignIn().signOut();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Get user type
      String? userType = await getUserType(userCredential.user!.uid);

      // Check if the user is signing in for the first time
      if (userCredential.additionalUserInfo!.isNewUser && context.mounted) {
        // Redirect the user to a different page for the first-time sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FirstTimeSignUpPage()),
        );
      } else {
        // Redirect based on user type
        redirectToHomePage(context, userType);
      }
    } catch (e) {
      // Handle Google sign-in errors
      // ignore: avoid_print
      print(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void redirectToHomePage(BuildContext context, String? userType) {
    if (userType == 'user') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage(pageNumber: 0)),
      );
    } else if (userType == 'business') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const HomePageBusiness(pageNumber: 0)),
      );
    } else {
      // Handle the case where user type is not recognized
      // ignore: avoid_print
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FirstTimeSignUpPage()),
      );
      //  print("Unknown user type");
    }
  }

  Future<String?> getUserType(String uid) async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('users/$uid/userType').get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      } else {
        return null;
      }
    } catch (error) {
      // Handle errors here
      // ignore: avoid_print
      print("Error retrieving user type: $error");
      return null;
    }
  }
}
