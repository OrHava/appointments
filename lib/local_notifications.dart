import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  static Future initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('ic_launcher');

    DarwinInitializationSettings iosInitializationSettings =
        const DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    var id = 0,
    required String title,
    required String body,
    var payload,
    required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  }) async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      "GiseleHava11",
      'channelName',
      playSound: true,
      icon: 'ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(presentSound: false);
    var not = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, not);
  }
}
