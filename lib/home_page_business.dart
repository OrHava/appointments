import 'dart:io';

import 'package:appointments/settings_page.dart';
import 'package:appointments/stats_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'appointments_list.dart';
import 'chat_page.dart';
import 'first_time_sign_up_page.dart';
import 'helpers.dart';

class HomePageBusiness extends StatefulWidget {
  final int pageNumber;
  final String? userId;

  const HomePageBusiness({Key? key, required this.pageNumber, this.userId})
      : super(key: key);

  @override
  HomePageBusinessState createState() => HomePageBusinessState();
}

enum AppointmentFilter {
  // ignore: constant_identifier_names
  Upcoming,
  // ignore: constant_identifier_names
  Completed,
  // ignore: constant_identifier_names
  Cancelled,
}

class HomePageBusinessState extends State<HomePageBusiness> {
  int _currentIndex = 0;
  static const String defaultProfileImageAsset = 'images/background_image.jpg';

  bool isScheduleExpanded = false;

// Declare the class-level variable for all chats
  List<Map<dynamic, dynamic>> allChats = [];
// Declare the class-level variable for displayed chats
  List<Map<dynamic, dynamic>> displayedChats = [];
  TextEditingController searchControllerForChats =
      TextEditingController(); //new1

  @override
  void initState() {
    super.initState();
    // Set the initial page based on the provided pageNumber
    _currentIndex = widget.pageNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: _getBody(),
      ),
      backgroundColor: const Color(0xFF161229),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedIconTheme: const IconThemeData(
            color: Color(0xFF7B86E2)), // Set the color for selected icon
        unselectedIconTheme: const IconThemeData(
            color: Colors.grey), // Set the color for unselected icon
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _getAppointmentsContent();
      case 2:
        return _getChatContent();
      case 3:
        return _buildProfile();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getAppointmentsContent() {
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      // Get the user ID
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50, // Background color of the tabs bar
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: TabBar(
                  tabs: [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                      color: Color(0xFF7B86E2), // Color of the curvy container
                      borderRadius: BorderRadius.all(Radius.circular(10))),

                  indicatorWeight:
                      0, // Set indicatorWeight to 0 to hide the default indicator
                  indicatorColor:
                      Colors.white, // Color of the selection indicator

                  indicatorPadding: EdgeInsets.symmetric(
                      horizontal: 16.0), // Spacing around the indicator
                  labelColor: Colors.white, // Color of the selected tab label
                  unselectedLabelColor:
                      Colors.black, // Color of the unselected tab label
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _getAppointmentsContent2(filter: AppointmentFilter.Upcoming),
                  _getAppointmentsContent2(filter: AppointmentFilter.Completed),
                  _getAppointmentsContent2(filter: AppointmentFilter.Cancelled),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text('User not signed in'),
      );
    }
  }

  Widget _getAppointmentsContent2({required AppointmentFilter filter}) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;
      return FutureBuilder<List<Appointment>>(
        future: getAppointmentsForUser(userId, filter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Appointment> appointments = snapshot.data ?? [];
            return AppointmentsList(
              type: filter,
              appointments: appointments,
              userType: 2,
              onCancel: () {
                // Callback function to refresh the list when an appointment is cancelled
                setState(() {});
              },
            );
          }
        },
      );
    } else {
      return const Center(
        child: Text('User not signed in'),
      );
    }
  }

  Future<List<Appointment>> getAppointmentsForUser(
      String userUid, AppointmentFilter filter) async {
    try {
      final DatabaseReference appointmentsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userUid)
          .child('appointmentsByDate');

      final dataSnapshot = await appointmentsRef.get();

      if (dataSnapshot.exists) {
        Map<dynamic, dynamic> appointmentsData =
            dataSnapshot.value as Map<dynamic, dynamic>;

        List<Appointment> appointments = appointmentsData.entries
            .map((entry) => Appointment.fromJson({
                  'userId': entry.value['userId'],
                  'name': entry.value['name'],
                  'phone': entry.value['phone'],
                  'cancelled': entry.value['cancelled'],
                  'startTime': entry.value['startTime'],
                  'endTime': entry.value['endTime'],
                  'pushId': entry.value['pushId'],
                }))
            .where((appointment) {
          DateTime now = DateTime.now();
          DateTime appointmentDate = appointment.startTime;
          bool cancelled = appointment.cancelled;

          switch (filter) {
            case AppointmentFilter.Upcoming:
              return appointmentDate.isAfter(now) && !cancelled;
            case AppointmentFilter.Completed:
              return appointmentDate.isBefore(now) && !cancelled;
            case AppointmentFilter.Cancelled:
              // You need to determine how to identify cancelled appointments in your data
              // For example, if you have a 'cancelled' field in your data, you can use:
              return cancelled;
            // Adjust the condition based on your data structure.
            // return false; // Placeholder, update as needed
          }
        }).toList();
        // appointments.sort((a, b) => a.startTime.compareTo(b.startTime));

        return appointments;
      } else {
        return [];
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error fetching appointments: $error');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExistingChats(
      String userId, String searchQuery) async {
    try {
      DatabaseReference chatsRef =
          FirebaseDatabase.instance.ref().child('messages');
      DatabaseEvent snapshot = await chatsRef.once();

      List<Map<String, dynamic>> chats = [];
      Map<dynamic, dynamic>? data =
          snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        for (var entry in data.entries) {
          List<String> participants = entry.key.toString().split('_');

          // Check if userId is one of the participants
          if (participants.contains(userId)) {
            // Find the other participant's ID
            String otherUserId = participants.firstWhere(
              (participantId) => participantId != userId,
              orElse: () => '',
            );

            if (otherUserId.isNotEmpty) {
              // Access the nested messages map under the entry.value
              Map<dynamic, dynamic> messagesMap = entry.value;

              // Get the last message for the current chat
              DatabaseReference chatRef = FirebaseDatabase.instance
                  .ref()
                  .child('messages')
                  .child(entry.key.toString()); // Use the current chat's key

              DatabaseEvent snapshot =
                  await chatRef.orderByChild('timestamp').limitToLast(1).once();

              Map<dynamic, dynamic>? data =
                  snapshot.snapshot.value as Map<dynamic, dynamic>?;

              if (data != null && data.isNotEmpty) {
                // Assuming you have a 'text' field in the message
                String lastMessageText =
                    data.values.first['text'] as String? ?? '';
                int lastMessageTimestamp =
                    data.values.first['timestamp'] as int? ?? 0;

                // Use the correct field for the user name (e.g., 'senderName')
                // Find the other user's name
                String otherUserName = messagesMap.entries
                    .where((entry) => entry.key != userId)
                    .map((entry) => entry.value['senderName'] as String? ?? '')
                    .firstWhere((name) => name.isNotEmpty, orElse: () => '');

                // Check if the other user's name contains the search query
                if (otherUserName
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) {
                  Map<String, dynamic> chatMap = {
                    'userId': otherUserId,
                    'userName': otherUserName,
                    'lastMessage': lastMessageText,
                    'lastMessageTimestamp': lastMessageTimestamp,
                    'chatId': entry.key.toString(),
                    // Add other properties you want to include in the chatMap
                  };

                  chats.add(chatMap);
                }
              }
            }
          }
        }
      }

      return chats;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching existing chats: $e');
      return [];
    }
  }

  String formatTimestamp(int timestamp) {
    // Create a DateTime object from the timestamp
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    // Format the DateTime object to a string in HH:mm format
    String formattedTime = DateFormat('HH:mm').format(dateTime);

    return formattedTime;
  }

  Widget _getChatContent() {
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      // Get the user ID
      String userId = user.uid;

      return FutureBuilder<Map<dynamic, dynamic>?>(
        future: getUserProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Text('User profile not found');
          } else {
            // User profile data is available, display it
            UserProfile userProfile = UserProfile.fromJson(snapshot.data!);
            String userName = userProfile.businessName;
            String userId = user.uid;
            String senderId = widget.userId ?? "0";

            if (senderId == "0") {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      height: 15,
                    ),
                    const Text(
                      "Messages",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      height: 15,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Gray background color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchControllerForChats,
                              style: const TextStyle(
                                color: Colors.black, // Set the text color
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search for client name...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.black),
                            onPressed: () {
                              // Call the function to filter chats based on the search query
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Map<dynamic, dynamic>>>(
                        future: getExistingChats(
                            userId, searchControllerForChats.text),
                        builder: (context, chatsSnapshot) {
                          if (chatsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (chatsSnapshot.hasError) {
                            return Text('Error: ${chatsSnapshot.error}');
                          } else if (!chatsSnapshot.hasData ||
                              chatsSnapshot.data == null) {
                            return const Text('Chats not found');
                          } else {
                            // Store all chats to a variable for filtering
                            displayedChats = chatsSnapshot.data!;

                            if (displayedChats.isEmpty) {
                              return const Center(
                                  child: Text('No conversations yet'));
                            }
                            return ListView.separated(
                              itemCount: displayedChats.length,
                              separatorBuilder: (context, index) => Container(
                                height: 10,
                                color: Colors
                                    .black, // Set the separator color to black
                              ),
                              itemBuilder: (context, index) {
                                String chatSenderId =
                                    displayedChats[index]['userId'];
                                String chatSenderName =
                                    displayedChats[index]['userName'];
                                String lastMessage =
                                    displayedChats[index]['lastMessage'];
                                String formattedTime = formatTimestamp(
                                    displayedChats[index]
                                        ['lastMessageTimestamp']);

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF7B86E2),
                                    child: Text(
                                      chatSenderName[0],
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  trailing: Text(formattedTime,
                                      style: const TextStyle(
                                          color: Color(0xFF878493))),
                                  title: Text(chatSenderName,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  subtitle: Text(lastMessage,
                                      style: const TextStyle(
                                          color: Color(0xFF878493))),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          sendToId: chatSenderId,
                                          senderId: userId,
                                          sendToName: chatSenderName,
                                          senderName: userName,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            // Return the ChatPage wrapped with another FutureBuilder
            return FutureBuilder<Map<dynamic, dynamic>?>(
              future: getUserProfile(
                  senderId), // Replace with your function to fetch chat content
              builder: (context, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (chatSnapshot.hasError) {
                  return Text('Error: ${chatSnapshot.error}');
                } else if (!chatSnapshot.hasData || chatSnapshot.data == null) {
                  return const Text('Chat content not found');
                } else {
                  UserProfile userProfile2 =
                      UserProfile.fromJson(chatSnapshot.data!);
                  String userName2 = userProfile2.fullName;
                  return ChatPage(
                    sendToId: senderId,
                    senderId: userId,
                    sendToName: userName2,
                    senderName: userName,
                    // Adjust this based on your chat content structure
                  );
                }
              },
            );
          }
        },
      );
    } else {
      return const Center(
        child: Text('User not signed in'),
      );
    }
  }

//_buildHome
  Widget _buildHome() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      return Container(
        color: const Color(0xFF161229),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0xFF7B86E2), Color(0xFFA796D1)],
                        center: Alignment.center,
                        radius: 1.5,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          spreadRadius: 10,
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    children: [
                      SizedBox(height: 40),
                      Text(
                        'Welcome to Home Business!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: FutureBuilder<List<Appointment>>(
                        future: getAppointmentsForUser(
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                          AppointmentFilter.Upcoming,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                  'Uh-oh! The cosmic planner encountered a supernova.'),
                            );
                          } else {
                            List<Appointment> appointments =
                                snapshot.data ?? [];
                            int upcomingAppointmentsCount = appointments.length;

                            if (appointments.isEmpty) {
                              return const Center(
                                child: Image(
                                  fit: BoxFit.contain,
                                  image: AssetImage(
                                      'images/no_upcoming_appointments.png'),
                                ),
                              );
                            }
                            appointments.sort(
                                (a, b) => a.startTime.compareTo(b.startTime));

                            return Column(
                              children: [
                                Center(
                                  child: Text(
                                    'Upcoming Appointments Count: $upcomingAppointmentsCount',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF878493),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // Adjust as needed

                                    children: [
                                      for (int i = 0;
                                          i < appointments.length;
                                          i++)
                                        Container(
                                          width: MediaQuery.of(context)
                                              .size
                                              .width, // Set a width constraint

                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Column(
                                            children: [
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 30,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        Container(
                                                          width: 70,
                                                          height: 30,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFF7B86E2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        const Positioned(
                                                          top: 5,
                                                          left: 5,
                                                          child: Icon(
                                                            Icons.date_range,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 5,
                                                          left: 25,
                                                          child: Text(
                                                            DateFormat('MMM d')
                                                                .format(
                                                              appointments[i]
                                                                  .startTime,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                        ),
                                                        color: const Color(
                                                            0xFF7B86E2),
                                                        elevation: 8,
                                                        child: ListTile(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .all(20),
                                                          title: Text(
                                                            appointments[i]
                                                                .name,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                height: 5,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons.phone,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 16,
                                                                  ),
                                                                  Container(
                                                                    width: 5,
                                                                  ),
                                                                  Text(
                                                                    appointments[
                                                                            i]
                                                                        .phone,
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .access_time,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 16,
                                                                  ),
                                                                  Container(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    DateFormat(
                                                                            'HH:mm')
                                                                        .format(
                                                                            appointments[i].startTime),
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          onTap: () {
                                                            // print(appointments[i]
                                                            //     .startTime
                                                            //     .toString());
                                                          },
                                                        ),
                                                      ),
                                                    ),

                                                    const SizedBox(width: 10),
                                                    // Vertical timeline line
                                                    Column(
                                                      children: [
                                                        Container(
                                                          width: 2,
                                                          height:
                                                              50, // Adjust the height as needed
                                                          color: Colors.white,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(3.0),
                                                          child: _getTimelineIcon(
                                                              appointments[i]
                                                                  .startTime),
                                                        ),
                                                        Container(
                                                          width: 2,
                                                          height:
                                                              50, // Adjust the height as needed
                                                          color: Colors.white,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Watch how many view your business Page',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF878493),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatsPage(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B86E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'stats_icon',
                            child: Icon(
                              Icons.insert_chart,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Stats',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _getTimelineIcon(DateTime startTime) {
    // Determine the time of day (morning, afternoon, evening) based on the appointment time
    int hour = startTime.hour;
    if (hour < 12) {
      // Morning
      return const Icon(
        Icons.wb_sunny,
        color: Colors.white,
        size: 16,
      );
    } else if (hour < 17) {
      // Afternoon
      return const Icon(
        Icons.brightness_5,
        color: Colors.white,
        size: 16,
      );
    } else {
      // Evening
      return const Icon(
        Icons.brightness_3,
        color: Colors.white,
        size: 16,
      );
    }
  }

  Widget _buildProfile() {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      // Get the user ID
      String userId = user.uid;

      return SingleChildScrollView(
        child: Center(
          child: FutureBuilder<Map<dynamic, dynamic>?>(
            future: getUserProfile(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Container(
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Text('User profile not found');
              } else {
                // User profile data is available, display it
                UserProfile userProfile = UserProfile.fromJson(snapshot.data!);

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7B86E2),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(100),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Row(
                                children: [
                                  Container(
                                    margin:
                                        const EdgeInsets.only(left: 10, top: 0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            userProfile.businessName,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          const Icon(
                                            Icons.star,
                                            size: 25,
                                            color: Colors.yellow,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            userProfile.businessRating
                                                .toStringAsFixed(1),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: IconButton(
                                      icon: const FaIcon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (context.mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FirstTimeSignUpPage(),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 10, bottom: 80),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      getBusinessIcon(userProfile.businessType),
                                      Container(
                                        width: 10,
                                      ),
                                      Text(
                                        userProfile.businessType,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 10, bottom: 40),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.map,
                                        size: 15, // Adjust the size as needed
                                        color: Colors.white,
                                      ),
                                      Container(
                                        width: 10,
                                      ),
                                      Text(
                                        userProfile.businessLocation,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 10, bottom: 0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user,
                                        size: 15, // Adjust the size as needed
                                        color: Colors.white,
                                      ),
                                      Container(
                                        width: 10,
                                      ),
                                      Text(
                                        userProfile.ownerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 10, top: 40),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 15, // Adjust the size as needed
                                        color: Colors.white,
                                      ),
                                      Container(
                                        width: 10,
                                      ),
                                      Text(
                                        userProfile.phoneNumber,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 10, top: 80),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_city,
                                        size: 15, // Adjust the size as needed
                                        color: Colors.white,
                                      ),
                                      Container(
                                        width: 10,
                                      ),
                                      Text(
                                        userProfile.businessFullAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 10, top: 140),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const FaIcon(
                                          FontAwesomeIcons.waze,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          LatLng? coordinates =
                                              await getAddressCoordinates(
                                                  userProfile
                                                      .businessFullAddress);

                                          if (coordinates != null) {
                                            // print(
                                            //     'Latitude: ${coordinates.latitude}, Longitude: ${coordinates.longitude}');

                                            launchWazeRoute(
                                                coordinates.latitude,
                                                coordinates.longitude);
                                          }
                                        },
                                      ),
                                      Container(
                                        width: 10,
                                      ),
                                      IconButton(
                                          icon: const FaIcon(
                                            FontAwesomeIcons.mapLocation,
                                            color: Colors.white,
                                          ),
                                          onPressed: () async {
                                            LatLng? coordinates =
                                                await getAddressCoordinates(
                                                    userProfile
                                                        .businessFullAddress);

                                            if (coordinates != null) {
                                              // print(
                                              //     'Latitude: ${coordinates.latitude}, Longitude: ${coordinates.longitude}');

                                              launchGoogleMaps(
                                                  coordinates.latitude,
                                                  coordinates.longitude);
                                            }
                                          }),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.policy,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          showPopup(
                                              context,
                                              userProfile
                                                  .businessAppointmentPolicies);
                                        },
                                      ),
                                      IconButton(
                                        icon: const FaIcon(
                                          Icons.settings,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          if (context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const SettingsPage(),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 20, right: 20),
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF161229).withOpacity(0.2),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 10, right: 10),
                                height: 140,
                                width: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF161229).withOpacity(0.4),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(bottom: 0, right: 0),
                                height: 160,
                                width: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF161229).withOpacity(0.6),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 30,
                              right: 30,
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                      userProfile.photoUrl ??
                                          'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=150&d=mp&r=pg',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: const Color(0xFF161229),
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userProfile.businessInfo,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF878493)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: const Color(0xFF161229),
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Services',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              if (userProfile.services.isNotEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: userProfile.services.length,
                                    itemBuilder: (context, index) {
                                      Service service =
                                          userProfile.services[index];
                                      String currencySymbol = getCurrencySymbol(
                                          service.paymentType);
                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          side: const BorderSide(
                                              color: Color(0xFF878493),
                                              width: 2.0),
                                        ),
                                        color: const Color(0xFF161229),
                                        elevation: 8,
                                        child: ListTile(
                                          trailing: Text(
                                              '$currencySymbol${service.amount}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white)),
                                          title: Text(service.name,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),

                                          // You can customize the ListTile as needed
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              if (userProfile.services.isEmpty)
                                const Text(
                                  'No services available.',
                                  style: TextStyle(color: Color(0xFF878493)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pictures',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: _getImagesWidgets(userProfile.businessPhotos),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        color: const Color(0xFF161229),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hours',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              _buildBusinessSchedule(
                                  userProfile.businessSchedule),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      );
    } else {
      // If the user is not signed in, you might want to redirect to the sign-in page.
      return const Center(
        child: Text('User not signed in'),
      );
    }
  }

  String getCurrencySymbol(String currencyType) {
    switch (currencyType) {
      case 'Shekels':
        return '₪'; // Replace with the actual symbol for Shekels
      case 'Dollars':
        return '\$';
      case 'Euros':
        return '€';
      default:
        return '';
    }
  }

  void showPopup(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info,
                color: Color(0xFF7B86E2),
              ),
              SizedBox(width: 10),
              Text(
                'Policy',
                style: TextStyle(color: Color(0xFF7B86E2)),
              ),
            ],
          ),
          content: Text(
            text,
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B86E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Icon getBusinessIcon(String businessType) {
    IconData iconData;

    switch (businessType.toLowerCase()) {
      case 'salon':
        iconData = FontAwesomeIcons.scissors;
      case 'spa':
        iconData = Icons.spa;
      case 'dentist':
        iconData = FontAwesomeIcons.tooth;
      case 'doctor':
        iconData = Icons.local_hospital;
      case 'fitness center':
        iconData = Icons.fitness_center;
      case 'photographer':
        iconData = Icons.camera_alt;
      case 'consulting':
        iconData = FontAwesomeIcons.handshake;
      case 'repair service':
        iconData = Icons.build;
      case 'restaurant':
        iconData = Icons.restaurant;
      case 'other':
        iconData = Icons.category;
      default:
        iconData = Icons.category; // Default icon for unknown options
    }

    return Icon(
      iconData,
      size: 15, // Adjust the size as needed
      color: Colors.white,
    );
  }

  Widget _buildBusinessSchedule(
    Map<String, Map<String, dynamic>> businessSchedule,
  ) {
    // Define the order of days starting from Sunday
    final daysOrder = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    // Sort the days based on their order
    final sortedDays = daysOrder.where(businessSchedule.containsKey);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: sortedDays.map((day) {
        Map<String, dynamic> schedule = businessSchedule[day]!;
        bool isAvailable = schedule['available'] ?? true;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFF878493), width: 2.0),
          ),
          color: const Color(0xFF161229),
          elevation: 8,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildDayName(day),
                _buildTimeText('Opening', schedule['opening'], isAvailable),
                _buildTimeText('Closing', schedule['closing'], isAvailable),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayName(String day) {
    return SizedBox(
      width: 80, // Adjust the width based on your needs
      child: Text('$day:',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
    );
  }

  Widget _buildTimeText(String label, TimeOfDay? time, bool isAvailable) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$label:',
              style: const TextStyle(fontSize: 14, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            isAvailable
                ? (time != null ? _formatTimeOfDay(time) : 'Closed')
                : 'Not Available',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    return '${timeOfDay.hourOfPeriod}:${timeOfDay.minute.toString().padLeft(2, '0')} ${timeOfDay.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  List<Widget> _getImagesWidgets(List<dynamic> images) {
    return images.map((image) {
      return GestureDetector(
        onTap: () {
          _showImageDialog(images, images.indexOf(image));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: _getImagesProvider(image),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }).toList();
  }

  void _showImageDialog(List<dynamic> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.7,
            child: PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _getImagesProvider(images[index]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  ImageProvider<Object> _getImagesProvider(dynamic image) {
    if (image is File) {
      return FileImage(image);
    } else if (image is String) {
      if (image.startsWith('http')) {
        return NetworkImage(image);
      } else {
        // If it's a local file path, use FileImage
        return FileImage(File(image));
      }
    } else {
      // Handle other cases if needed
      return const AssetImage(defaultProfileImageAsset);
    }
  }

  Future<void> launchWazeRoute(double lat, double lng) async {
    var url = 'waze://?ll=${lat.toString()},${lng.toString()}';
    var fallbackUrl =
        'https://waze.com/ul?ll=${lat.toString()},${lng.toString()}&navigate=yes';
    try {
      bool launched = false;

      launched = await url_launcher.launchUrl(Uri.parse(url));

      if (!launched) {
        await url_launcher.launchUrl(Uri.parse(fallbackUrl));
      }
    } catch (e) {
      await url_launcher.launchUrl(Uri.parse(fallbackUrl));
    }
  }

  Future<void> launchGoogleMaps(double lat, double lng) async {
    var url = 'google.navigation:q=${lat.toString()},${lng.toString()}';
    var fallbackUrl =
        'https://www.google.com/maps/search/?api=1&query=${lat.toString()},${lng.toString()}';
    try {
      bool launched = false;

      launched = await url_launcher.launchUrl(Uri.parse(url));

      if (!launched) {
        await url_launcher.launchUrl(Uri.parse(fallbackUrl));
      }
    } catch (e) {
      await url_launcher.launchUrl(Uri.parse(fallbackUrl));
    }
  }

  Future<Map<dynamic, dynamic>?> getUserProfile(String userId) async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref();
      final snapshot = await reference.child('users/$userId').get();

      if (snapshot.exists) {
        // Print the structure of the received data
        // ignore: avoid_print
        //print("Received user data: ${snapshot.value}");

        // User profile found, convert the data to a Map<String, dynamic>
        if (snapshot.value is Map<dynamic, dynamic>) {
          Map<dynamic, dynamic> values =
              snapshot.value as Map<dynamic, dynamic>;
          return values;
        } else {
          // Handle the case where userData is not a Map<String, dynamic>
          // ignore: avoid_print
          print("Error: User data is not in the expected format");
          return null;
        }
      } else {
        // User profile not found
        // ignore: avoid_print
        print("Error: User profile not found");
        return null;
      }
    } catch (error) {
      // Handle errors here
      // ignore: avoid_print
      print("Error retrieving user profile for user $userId: $error");
      return null;
    }
  }
}
