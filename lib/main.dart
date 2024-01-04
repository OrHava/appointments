import 'package:appointments/home_page_business.dart';
import 'package:appointments/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'first_time_sign_up_page.dart';
import 'home_page.dart';
import 'package:firebase_database/firebase_database.dart';

import 'local_notifications.dart';

// Initialize FlutterLocalNotificationsPlugin at the top of your file or widget
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    final String nextExerciseName = inputData?['nextExerciseName'];
    LocalNotifications.initialize(flutterLocalNotificationsPlugin);
    LocalNotifications.showNotification(
        title: "Workout",
        body: nextExerciseName,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);
    return Future.value(true);
  });
}

void startBackgroundTask(int timerDurationInSeconds, String nextExerciseName) {
  // Calculate the delay time based on the timer duration
  final delayMilliseconds = timerDurationInSeconds * 1000;
  // print('Background task Start');
  Workmanager().registerOneOffTask(
    'notificationTask', // Task name
    'simpleTask', // Task tag
    initialDelay: Duration(milliseconds: delayMilliseconds),
    inputData: {'nextExerciseName': nextExerciseName},
  );
}

Future<void> initializeBackgroundTasks() async {
  Workmanager().initialize(callbackDispatcher);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await initializeBackgroundTasks();
    await Firebase.initializeApp();
  }

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyAljIr4zwJ8-ap9fwPS7arXTcoDgoy1A-8",
            authDomain: "appointments-5b541.firebaseapp.com",
            databaseURL:
                "https://appointments-5b541-default-rtdb.firebaseio.com",
            projectId: "appointments-5b541",
            storageBucket: "appointments-5b541.appspot.com",
            messagingSenderId: "401963892153",
            appId: "1:401963892153:web:8a071c430723d2ad978a68",
            measurementId: "G-1ZKDTLWNEW"));
  }

  //await FirebaseAppCheck.instance.activate();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appointments',
      debugShowCheckedModeBanner: false,
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
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.red,
                  ),
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
