import 'dart:html';

import 'package:appointments/about_page.dart';
import 'package:appointments/account_settings_page.dart';
import 'package:appointments/block_page.dart';
import 'package:appointments/business_profile_page.dart';
import 'package:appointments/earnings_page.dart';
import 'package:appointments/help_center_page.dart';
import 'package:appointments/home_page_business.dart';
import 'package:appointments/notification_page.dart';
import 'package:appointments/premium_account_management.dart';
import 'package:appointments/settings_page.dart';
import 'package:appointments/sign_in_screen.dart';
import 'package:appointments/sign_up_screen.dart';
import 'package:appointments/splash_screen.dart';
import 'package:appointments/stats_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'first_time_sign_up_page.dart';
import 'home_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:url_strategy/url_strategy.dart';
import 'local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

//flutter build web
//firebase deploy

// Initialize FlutterLocalNotificationsPlugin at the top of your file or widget
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    final String nextExerciseName = inputData?['nextExerciseName'];
    LocalNotifications.initialize(flutterLocalNotificationsPlugin);
    LocalNotifications.showNotification(
        title: "Upcoming Appointmeant",
        body: nextExerciseName,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);
    return Future.value(true);
  });
}

Future<void> startBackgroundTask(
    int timerDurationInSeconds, String nextExerciseName) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isNotificationEnabled = prefs.getBool('notificationEnabled') ?? true;

  if (isNotificationEnabled) {
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
}

Future<void> initializeBackgroundTasks() async {
  Workmanager().initialize(callbackDispatcher);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String deepLinkUsed = "";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await initializeBackgroundTasks();
    await Firebase.initializeApp();
    // Initialize deep linking
    await initUniLinks();
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
  if (kIsWeb) {
    setPathUrlStrategy(); // Ensure that this is called before runApp
    // String? initialLink = await getInitialLink();
    // handleLink(initialLink!);
    Uri? initialUri = Uri.parse(window.location.href);
    handleLink(initialUri.toString());

    // Listen to changes in the URL
    window.onPopState.listen((PopStateEvent event) {
      Uri uri = Uri.parse(window.location.href);
      handleLink(uri.toString());
    });
  }

  runApp(MyApp(navigatorKey: navigatorKey, deepLinkUsed: deepLinkUsed));
}

Future<void> initUniLinks() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    String? initialLink = await getInitialLink();
    if (initialLink != null) {
      handleLink(initialLink);
    }
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        handleLink(uri.toString());
      }
    });
  } on PlatformException catch (e) {
    // ignore: avoid_print
    print("Error initializing deep links: $e");
    // Handle the error, show a message, or take appropriate action.
  }
}

void handleLink(String link) {
  // Example: Open a specific page based on the deep link
  if (link.contains('/settings')) {
    // Navigate to the home page using the stored context
    navigatorKey.currentState?.pushNamed('/settings');
    deepLinkUsed = 'settings';
  }

  if (link.contains('/businessProfile/')) {
    // Extract business ID from the deep link
    String businessId = link.split('/businessProfile/')[1];
    // Navigate to the business profile page using the stored context
    navigatorKey.currentState?.pushNamed('/businessProfile', arguments: {
      'businessId': businessId,
      // Additional parameters if needed
    });
    deepLinkUsed = 'businessProfile';
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Did push: ${route.settings.name}');
  }

  // Other navigation lifecycle methods...
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String deepLinkUsed;
  const MyApp(
      {super.key, required this.navigatorKey, required this.deepLinkUsed});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorObservers: [MyNavigatorObserver()],
        navigatorKey: navigatorKey,
        title: 'Appointments',
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => const HomePage(pageNumber: 0),
          '/businessHome': (context) => const HomePageBusiness(pageNumber: 0),
          '/firstTimeSignUp': (context) => const FirstTimeSignUpPage(),
          '/settings': (context) => const SettingsPage(),
          '/about': (context) {
            final Map<String, String>? arguments = ModalRoute.of(context)
                ?.settings
                .arguments as Map<String, String>?;

            return AboutPage(source: arguments?['source'] ?? '');
          },
          '/accountSettings': (context) {
            final Map<String, String>? arguments = ModalRoute.of(context)
                ?.settings
                .arguments as Map<String, String>?;

            return AccountSettingsPage(source: arguments?['source'] ?? '');
          },
          '/blockPage': (context) => const BlockPage(),
          '/helpCenter': (context) => HelpCenterPage(),
          '/signIn': (context) => const SignInScreen(),
          '/signUp': (context) => SignUpScreen(),
          '/stats': (context) => const StatsPage(),
          '/notification': (context) => const NotificationPage(),
          '/premiumAccountManagement': (context) {
            final Map<String, String>? arguments = ModalRoute.of(context)
                ?.settings
                .arguments as Map<String, String>?;

            return PremiumAccountManagement(source: arguments?['source'] ?? '');
          },
          '/authenticationWrapper': (context) {
            return const AuthenticationWrapper(deepLinkUsed: "");
          },
          '/earnings': (context) => Builder(
                builder: (context) {
                  // Extract userId from ModalRoute
                  final String? userId =
                      ModalRoute.of(context)?.settings.arguments as String?;
                  return EarningsPage(userId: userId!);
                },
              ),
          '/businessProfile${RoutePaths.businessId}': (context) {
            final Map<String, dynamic>? arguments = ModalRoute.of(context)
                ?.settings
                .arguments as Map<String, dynamic>?;
            final String businessId = arguments?['businessId'] ?? '';
            final String? userName = arguments?['userName'];
            final String? userPhone = arguments?['userPhone'];
            return BusinessProfilePage(
              businessId,
              userName,
              userPhone,
            );
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/businessProfile${RoutePaths.businessId}') {
            final Map<String, dynamic>? arguments =
                settings.arguments as Map<String, dynamic>?;
            final String businessId = arguments?['businessId'] ?? '';
            final String? userName = arguments?['userName'];
            final String? userPhone = arguments?['userPhone'];

            // Customize the route name as needed
            final String customRouteName = '/businessProfile/$businessId';

            return MaterialPageRoute(
              builder: (context) => BusinessProfilePage(
                businessId,
                userName,
                userPhone,
              ),
              settings: RouteSettings(
                name: customRouteName,
              ),
            );
          } else if (settings.name?.startsWith('/businessProfile/') == true) {
            final List<String> pathSegments =
                Uri.parse(settings.name!).pathSegments;
            final String businessId = pathSegments.last;

            return MaterialPageRoute(
              builder: (context) => BusinessProfilePage(
                businessId,
                "", // Add other parameters if needed
                "",
              ),
            );
          }
          return null;
          // Handle other routes as needed
          // ...
        },
        theme: ThemeData(
            primaryColor: Colors.white,
            inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.black),
                hintStyle: TextStyle(color: Colors.grey),
                focusColor: Colors.black)),
        home: Builder(
          builder: (context) {
            // Continue with the rest of the AuthenticationWrapper logic
            return AuthenticationWrapper(deepLinkUsed: deepLinkUsed);
          },
        ));
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final String deepLinkUsed;
  const AuthenticationWrapper(
      {super.key, Key? keys, required this.deepLinkUsed});

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
                return const SplashScreen();
              }

              String? userType = userTypeSnapshot.data;

              // Handle deep links here
              if (deepLinkUsed != "") {
                return Container(); // Return an empty container to avoid rendering anything
              }

              if (userType == 'user' && !isCurrentRoute('/home', context)) {
                navigateTo('/home', context);
              } else if (userType == 'business' &&
                  !isCurrentRoute('/businessHome', context)) {
                navigateTo('/businessHome', context);
              } else if (!isCurrentRoute('/firstTimeSignUp', context)) {
                navigateTo('/firstTimeSignUp', context);
              }

              return Container();
            },
          );
        }

        if (!isCurrentRoute('/signIn', context)) {
          navigateTo('/signIn', context);
        }
        return Container();
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

  bool isCurrentRoute(String routeName, BuildContext context) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  bool isCurrentRoute2(String routeName, BuildContext context) {
    return ModalRoute.of(context)!.settings.name!.startsWith(routeName);
  }

  void navigateTo(String routeName, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(routeName);
    });
  }
}

class RoutePaths {
  static var businessId = '/';
}
