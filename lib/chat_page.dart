import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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

  late ScrollController _scrollController;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text('Chat Page'),
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
                  onPressed: () {
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
