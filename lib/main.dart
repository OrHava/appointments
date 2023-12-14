import 'package:appointments/home_page_business.dart';
import 'package:appointments/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'first_time_sign_up_page.dart';
import 'home_page.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appointments',
      theme: ThemeData(
          primaryColor: Colors.white,
          inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: Colors.black),
              hintStyle: TextStyle(color: Colors.grey),
              focusColor: Colors.black)),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key, Key? keys});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // You can show a loading indicator here
        }

        if (snapshot.hasData) {
          // Check the user type in the Realtime Database
          return FutureBuilder<String?>(
            future: getUserType(snapshot.data!.uid),
            builder: (context, userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(
                  color: Colors.red,
                );
              }

              String? userType = userTypeSnapshot.data;

              if (userType == 'user') {
                return const HomePage(pageNumber: 0);
              } else if (userType == 'business') {
                return const HomePageBusiness(pageNumber: 0);
              } else {
                // Handle the case where user type is not recognized
                return const FirstTimeSignUpPage();
              }
            },
          );
        }

        return const SignInScreen();
      },
    );
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
