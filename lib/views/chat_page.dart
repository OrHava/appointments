import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Message {
  final String text;
  final String sender;
  final String senderName;
  final int timestamp;

  Message({
    required this.text,
    required this.sender,
    required this.senderName,
    required this.timestamp,
  });

  factory Message.fromMap(Map<dynamic, dynamic> map) {
    return Message(
      text: map['text'] ?? '',
      sender: map['sender'] ?? '',
      senderName: map['senderName'] ?? '',
      timestamp: (map['timestamp'] ?? 0) is int
          ? map['timestamp']
          : (map['timestamp'] as Timestamp).seconds,
    );
  }
}

class ChatPage extends StatefulWidget {
  final String sendToId;
  final String senderId;
  final String sendToName;
  final String senderName;

  const ChatPage({
    Key? key,
    required this.sendToId,
    required this.senderId,
    required this.sendToName,
    required this.senderName,
  }) : super(key: key);

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _textEditingController = TextEditingController();
  late DatabaseReference reference;
  late StreamController<List<Message>> _streamController;
  List<Message> messages = [];
  String? mtoken = " ";
  late ScrollController _scrollController;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOsInitialize = const DarwinInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOsInitialize);
    flutterLocalNotificationsPlugin.initialize(
      initializationsSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          var payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            // Handle notification tap
          } else {
            // Handle notification tap when payload is empty
          }
        } catch (e) {
          // Handle exceptions
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("on message: ${message.notification?.title}");
      }
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('Appointments', 'Appointments',
              importance: Importance.high,
              styleInformation: bigTextStyleInformation,
              priority: Priority.high,
              playSound: true);
      NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
          iOS: const DarwinNotificationDetails());
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
          message.notification?.body, notificationDetails,
          payload: message.data['body']);
    });
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAAXZbqPbk:APA91bE7r68H2XUodI1ec_KV4Cl3dOwbKjefoE8pdoiX42FfYGFj5QhluMAK207PZQpEGqkm8svPVi95tsp0R6kHVDj1wnpLru4GySipQnm9vyOeqnqCcnCqwfJ8WZLA5BvwbEkpKPLd'
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            "notification": <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "GiseleHava4"
            },
            "to": token,
          }));
    } catch (e) {
      if (kDebugMode) {
        print("error push notification");
      }
    }
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) => {
          setState(() {
            mtoken = token;
          }),
          saveToken(token!),
        });
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection("UserTokens")
        .doc(widget.senderId)
        .set({
      'token': token,
    });
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      getToken();
      initInfo();
    }

    _scrollController = ScrollController();
    List<String> participants = [widget.sendToId, widget.senderId];
    participants.sort();

    String conversationId = "${participants[0]}_${participants[1]}";

    reference =
        FirebaseDatabase.instance.ref().child('messages').child(conversationId);

    _streamController = StreamController<List<Message>>.broadcast();

    reference.onChildAdded.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final message = Message.fromMap(data);

        setState(() {
          messages.add(message);
          FocusScope.of(context).unfocus();
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });

        _streamController.add(messages);
      }
    });
  }

  String getConversationId(String userId1, String userId2) {
    List<String> participants = [userId1, userId2];
    participants.sort();
    return "${participants[0]}_${participants[1]}";
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text('Chat Page',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _streamController.stream,
              initialData: messages,
              builder: (context, snapshot) {
                final updatedMessages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: updatedMessages.length,
                  itemBuilder: (context, index) {
                    final message = updatedMessages[index];
                    bool isMyMessage = message.sender == widget.senderId;

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: isMyMessage ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMyMessage ? 'You' : message.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              message.text,
                              style: const TextStyle(color: Colors.black),
                            ),
                            Text(
                              _formatDateTime(message.timestamp),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final message = Message(
                      text: _textEditingController.text,
                      sender: widget.senderId,
                      senderName: widget.senderName,
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                    );

                    reference.push().set({
                      'text': message.text,
                      'sender': message.sender,
                      'senderName': message.senderName,
                      'sendToName': widget.sendToName,
                      'timestamp': message.timestamp,
                    });

                    DocumentSnapshot snap = await FirebaseFirestore.instance
                        .collection("UserTokens")
                        .doc(widget.sendToId)
                        .get();

                    if (snap.exists && !kIsWeb) {
                      // Document exists
                      if (snap.data() != null && snap['token'] != null) {
                        // Token field exists and has a value
                        String token = snap['token'];
                        sendPushMessage(token, message.text,
                            "Message from ${message.senderName}");
                        // Now you can use the token for further processing
                      } else {
                        if (kDebugMode) {
                          print('Token field does not exist or is null.');
                        }
                      }
                    } else {
                      // Document does not exist
                      if (kDebugMode) {
                        print(
                            'Document does not exist for ID: ${widget.senderId}');
                      }
                    }

                    _textEditingController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    //_streamController.close();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut);
    } else {
      Timer(const Duration(milliseconds: 400), () => _scrollToBottom());
    }
  }

  String _formatDateTime(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String formattedDate = DateFormat('MMM d, yyyy, hh:mm a').format(dateTime);
    return formattedDate;
  }
}
