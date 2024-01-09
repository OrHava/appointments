import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  bool isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    // Load the saved notification preference
    loadNotificationPreference();
  }

  Future<void> loadNotificationPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Set the state based on the saved preference
      isNotificationEnabled = prefs.getBool('notificationEnabled') ?? true;
    });
  }

  Future<void> saveNotificationPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Save the notification preference
    prefs.setBool('notificationEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text('Notification Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable Notifications',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Switch(
              value: isNotificationEnabled,
              onChanged: (value) {
                setState(() {
                  isNotificationEnabled = value;
                  // Save the notification preference when the user toggles the switch
                  saveNotificationPreference(value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
