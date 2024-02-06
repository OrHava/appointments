import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}

Future<LatLng?> getAddressCoordinates(String address) async {
  try {
    // Use the 'geocoding' API to get the coordinates
    List<Location> locations = await locationFromAddress(address);

    // Check if locations list is not empty
    if (locations.isNotEmpty) {
      // Access the first location (you can handle multiple results if needed)
      Location location = locations.first;

      // Get the latitude and longitude
      double latitude = location.latitude;
      double longitude = location.longitude;

      return LatLng(latitude: latitude, longitude: longitude);
    } else {
      // ignore: avoid_print
      print('No coordinates found for the address: $address');
      return null;
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error: $e');
    return null;
  }
}

class Appointment {
  final String userId;
  final String name;
  final String phone;
  final bool cancelled;
  final DateTime startTime;
  final DateTime endTime;
  final bool approved;
  String? pushId;
  final Service service; // Include a Service property

  Appointment({
    required this.userId,
    required this.name,
    required this.phone,
    required this.cancelled,
    required this.approved,
    required this.startTime,
    required this.endTime,
    required this.service,
    this.pushId,
  });

  factory Appointment.fromJson(Map<dynamic, dynamic> json) {
    return Appointment(
      userId: json['userId'],
      name: json['name'],
      phone: json['phone'],
      cancelled: json['cancelled'],
      approved: json['approved'],
      pushId: json['pushId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      service: json['service'] != null
          ? _parseService(json['service'])
          : Service('', 0, ''),
    );
  }

  static Service _parseService(dynamic serviceData) {
    if (serviceData is Map<dynamic, dynamic>) {
      return Service.fromJson(serviceData);
    } else {
      // Handle the case where the service data is not in the expected format
      // You might want to log an error or return a default Service instance
      return Service('', 0, '');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'approved': approved,
      'cancelled': cancelled,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'pushId': pushId,
      'service': service.toJson(), // Serialize the 'service' property
    };
  }
}

class Service {
  String name;
  double amount;
  String paymentType; // New property for payment type

  Service(this.name, this.amount, this.paymentType);

  // Convert Service object to JSON format
  Map<dynamic, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'paymentType': paymentType,
    };
  }

  // Create a Service object from JSON data
  factory Service.fromJson(Map<dynamic, dynamic> json) {
    return Service(
      json['name'] ?? "",
      (json['amount'] ?? 0).toDouble(),
      json['paymentType'] ?? "",
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class ChatArguments {
  final RemoteMessage message;

  ChatArguments(this.message);
}

class NotificationHandler {
  static Future<bool> checkNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;
    return status == PermissionStatus.granted;
  }

  static Future<void> handleNotification(BuildContext context) async {
    bool notificationsEnabled = await checkNotificationPermission();

    if (notificationsEnabled) {
      // Your normal logic when notifications are enabled
    } else {
      // Show an alert indicating that notifications are disabled
      if (context.mounted) {
        await showDisabledNotificationsAlert(context);
      }
    }
  }

  static Future<void> showDisabledNotificationsAlert(
      BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool stopShowingAlert = prefs.getBool('stopShowingAlert') ?? false;

    if (stopShowingAlert) {
      return;
    }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Smaller border radius
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.5, // 80% of the screen width
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align children to the right
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const Text(
                    'Enable Notifications',
                    style: TextStyle(
                      fontSize: 16, // Smaller font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Lottie.asset(
                    'images/notification-bell.json',
                    height: 80, // Smaller height
                    width: 80, // Smaller width
                    repeat: true,
                  ),
                  const SizedBox(height: 8), // Smaller spacing
                  Text(
                    'Please enable notifications in your device settings.',
                    style: TextStyle(
                      fontSize: 14, // Smaller font size
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8), // Smaller spacing
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      AppSettings.openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B86E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Smaller font size
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Smaller spacing
                  ElevatedButton(
                    onPressed: () async {
                      prefs.setBool('stopShowingAlert', true);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(
                            color: Color(0xFF7B86E2), width: 2.0),
                      ),
                    ),
                    child: const Text(
                      'Stop Showing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Smaller font size
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

class ColorChangingCircularProgressIndicator extends StatefulWidget {
  final List<Color> colorList;
  final double strokeWidth;

  const ColorChangingCircularProgressIndicator({
    Key? key,
    required this.colorList,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  @override
  ColorChangingCircularProgressIndicatorState createState() =>
      ColorChangingCircularProgressIndicatorState();
}

class ColorChangingCircularProgressIndicatorState
    extends State<ColorChangingCircularProgressIndicator> {
  late int _currentColorIndex;
  late Timer _colorChangeTimer;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = 0;
    _colorChangeTimer =
        Timer.periodic(const Duration(seconds: 1), _changeColor);
  }

  @override
  void dispose() {
    _colorChangeTimer.cancel();
    super.dispose();
  }

  void _changeColor(Timer timer) {
    setState(() {
      _currentColorIndex = (_currentColorIndex + 1) % widget.colorList.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: widget.strokeWidth,
      valueColor:
          AlwaysStoppedAnimation<Color>(widget.colorList[_currentColorIndex]),
    );
  }
}
