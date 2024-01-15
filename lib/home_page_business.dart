import 'dart:io';

import 'package:appointments/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _feedbackController = TextEditingController();
// Declare the class-level variable for all chats
  List<Map<dynamic, dynamic>> allChats = [];
// Declare the class-level variable for displayed chats
  List<Map<dynamic, dynamic>> displayedChats = [];
  TextEditingController searchControllerForChats =
      TextEditingController(); //new1
  DateTime? _selectedDate;
  final List<String> pageTitles = ['Home', 'Appointments', 'Chat', 'Profile'];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  late Map<DateTime, List<Appointment>> appointmentEvents =
      {}; // Initialize here;
  @override
  void initState() {
    super.initState();
    // Set the initial page based on the provided pageNumber
    _currentIndex = widget.pageNumber;
    _selectedDate = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _fetchAppointments();
  }

  void _fetchAppointments() {
    Future.wait([
      getAppointmentsForUser(user!.uid, AppointmentFilter.Upcoming),
      getAppointmentsForUser(user!.uid, AppointmentFilter.Completed),
    ]).then((List<List<Appointment>> results) {
      final upcomingAppointments = results[0];
      final completedAppointments = results[1];

      final upcomingAppointmentsEvents =
          getAppointmeantEvents(upcomingAppointments);
      final completedAppointmentsEvents =
          getAppointmeantEvents(completedAppointments);

      final combinedEvents = {
        ...upcomingAppointmentsEvents,
        ...completedAppointmentsEvents,
      };

      setState(() {
        appointmentEvents = combinedEvents;
      });
    }).catchError((error) {
      // Handle the error appropriately, e.g., show an error message
      // ignore: avoid_print
      print('Error fetching appointments: $error');
    });
  }

  Map<DateTime, List<Appointment>> getAppointmeantEvents(
      List<Appointment> appointments) {
    final appointmentEvents = <DateTime, List<Appointment>>{};

    for (var appointment in appointments) {
      // Use UTC date for consistency
      final date = DateTime.utc(appointment.startTime.year,
          appointment.startTime.month, appointment.startTime.day);

      if (appointmentEvents.containsKey(date)) {
        appointmentEvents[date]!.add(appointment);
      } else {
        appointmentEvents[date] = [appointment];
      }
    }

    return appointmentEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: Text(
          pageTitles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Add an IconButton to open the drawer
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                // Open the drawer on button click
                _scaffoldKey.currentState?.openDrawer();
              },
            );
          },
        ),
        actions: [
          _currentIndex == 0
              ? IconButton(
                  icon: const Icon(
                    Icons.today,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Handle logic for returning to today
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                  },
                )
              : Container(),
          _currentIndex == 0
              ? PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.tune,
                    color: Colors.white,
                  ),
                  onSelected: (String result) {
                    setState(() {
                      if (result == 'month') {
                        _calendarFormat = CalendarFormat.month;
                      } else if (result == 'twoWeeks') {
                        _calendarFormat = CalendarFormat.twoWeeks;
                      } else if (result == 'week') {
                        _calendarFormat = CalendarFormat.week;
                      }
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'month',
                      child: Text('Month'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'twoWeeks',
                      child: Text('Two Weeks'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'week',
                      child: Text('Week'),
                    ),
                  ],
                )
              : Container(),
        ],
      ),
      // Add a Drawer widget to the Scaffold
      drawer: Drawer(
        backgroundColor: const Color(0xFF161229),
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ListTile(
                title: const Text(
                  'Appointments Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.asset(
                    'images/icon_app_cute_bigger.png',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                onTap: () {
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/about',
                        arguments: {'source': 'businessHome'});
                  }
                },
              ),
              const Divider(
                color: Color(0xFF878493),
              ),
              ListTile(
                title: const Text(
                  'Reports',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.insert_chart,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/stats');
                  }
                },
              ),
              ListTile(
                title: const Text(
                  'Earnings',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.money,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamed('/earnings', arguments: user!.uid);
                  }
                },
              ),
              ListTile(
                title: const Text(
                  'Customization',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                leading:
                    const Icon(Icons.contact_page, color: Color(0xFF878493)),
                onTap: () {
                  Navigator.of(context)
                      .pushReplacementNamed('/firstTimeSignUp');
                },
              ),
              ListTile(
                title: const Text(
                  'Share',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                leading: const Icon(Icons.share, color: Color(0xFF878493)),
                onTap: () async {
                  User? user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    // String userId = user.uid;

                    // Handle the tap on a search result using Fluro router
                    String baseUrl =
                        'https://orhava.web.app/businessProfile/${user.uid}'; // Replace with your actual base URL

                    if (kIsWeb) {
                      var url = baseUrl;
                      final Uri uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        throw 'Could not launch $url';
                      }
                    } else {
                      // For mobile, use Share package
                      Share.share(
                        baseUrl,
                        subject: 'Business Link',
                      );
                    }
                  }
                  // Handle the tap on a search result using Fluro router
                },
              ),
              const Divider(
                color: Color(0xFF878493),
              ),
              ListTile(
                title: Text(
                  user!.displayName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user!.email ?? '',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  FontAwesomeIcons.person,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/accountSettings',
                      arguments: {'source': 'businessHome'});
                },
              ),
              ListTile(
                title: const Text(
                  'Settings',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.settings,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/settings');
                },
              ),
              ListTile(
                title: const Text(
                  'Premium Account',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.store,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  if (kIsWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please connect with the app to manage your premium account.'),
                        duration: Duration(
                            seconds:
                                4), // You can adjust the duration as needed
                      ),
                    );
                  } else {
                    // Navigate to premium account management page for mobile platforms

                    Navigator.of(context).pushReplacementNamed(
                        '/premiumAccountManagement',
                        arguments: {'source': 'businessHome'});
                  }
                },
              ),
              ListTile(
                title: const Text(
                  'Send feedback',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.send,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  _showFeedbackForm(context);
                },
              ),
              ListTile(
                title: const Text(
                  'Help Center',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.help_center,
                  color: Color(0xFF878493),
                ),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/helpCenter');
                },
              ),
              ListTile(
                title: const Text(
                  'Log out',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.logout,
                  color: Color(0xFF878493),
                ),
                onTap: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();

                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/signIn');
                    }
                  } catch (e) {
                    // ignore: avoid_print
                    print("Error during sign out: $e");
                  }
                },
              ),
            ],
          ),
        ),
      ),

      body: _getBody(),

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
        selectedLabelStyle: const TextStyle(
          color: Color(0xFF7B86E2), // Set the color for selected label
        ),
        unselectedLabelStyle: const TextStyle(
          color: Colors.grey, // Set the color for unselected label
        ),
        selectedItemColor: const Color(0xFF7B86E2),
        unselectedItemColor: Colors.grey,
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
                  'service': entry.value['service'],
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
      return Column(
        children: [
          TableCalendar(
            onFormatChanged: (format) {
              // Dummy callback to satisfy the assertion
              null;
            },
            availableCalendarFormats: const {
              CalendarFormat.week: 'Week',
              CalendarFormat.month: 'Month',
              CalendarFormat.twoWeeks: 'TwoWeeks',
            },
            firstDay: DateTime.utc(2010, 10, 16),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            lastDay: DateTime.utc(2030, 3, 14),
            headerStyle: const HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                color: Colors.transparent, // Change this to the color you want
              ),
              leftChevronIcon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white, // Change this to the color you want
              ),
              titleTextStyle: TextStyle(
                color: Colors.white, // Change this to the color you want
                fontSize: 20, // Adjust the font size if needed
                fontWeight: FontWeight.bold, // Adjust the font weight if needed
              ),
              rightChevronIcon: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white, // Change this to the color you want
              ),
              // ... other header style properties ...
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF878493), // Change this to the color you want
              ),
              weekendTextStyle:
                  TextStyle(color: Colors.white), // Set the weekend days color
            ),
            focusedDay: _selectedDate ?? DateTime.now(),
            onDaySelected: (selectedDate, focusedDate) {
              setState(() {
                _selectedDate = selectedDate;
              });
            },
            onPageChanged: (focusedDate) {
              setState(() {
                _selectedDate = focusedDate;
              });
            },
            calendarFormat: _calendarFormat,
            eventLoader: (date) => appointmentEvents[date] ?? [],
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // Swiped right
                  setState(() {
                    _selectedDate =
                        _selectedDate!.subtract(const Duration(days: 1));
                  });
                } else if (details.primaryVelocity! < 0) {
                  // Swiped left
                  setState(() {
                    _selectedDate = _selectedDate!.add(const Duration(days: 1));
                  });
                }
              },
              child: (appointmentEvents[_selectedDate]?.isEmpty ?? true)
                  ? const Center(
                      child: Image(
                        fit: BoxFit.contain,
                        image:
                            AssetImage('images/no_upcoming_appointments.png'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: appointmentEvents[_selectedDate]!.length,
                      itemBuilder: (context, index) {
                        final List<Appointment> appointmentsForDate =
                            appointmentEvents[_selectedDate] ?? [];

                        // Sort appointments by start time
                        appointmentsForDate
                            .sort((a, b) => a.startTime.compareTo(b.startTime));

                        final Appointment appointment =
                            appointmentsForDate[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.all(8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: const BorderSide(
                                color: Color(0xFF7B86E2), width: 2.0),
                          ),
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left side for time range
                                Column(
                                  children: [
                                    Text(
                                      DateFormat('HH:mm')
                                          .format(appointment.startTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      width: 2.0, // Adjust the width as needed
                                      height:
                                          50.0, // Adjust the height as needed
                                      color: Colors.white,
                                    ),
                                    Text(
                                      DateFormat('HH:mm')
                                          .format(appointment.endTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16), // Add spacing
                                Expanded(
                                  // Right side for appointment details
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Name: ${appointment.name}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8), // Add spacing
                                      Text(
                                        'Phone: ${appointment.phone}\n',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),

                                      Text(
                                        '${appointment.service.name} - ${getCurrencySymbol(appointment.service.paymentType)}${appointment.service.amount}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    } else {
      return Container();
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
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: userProfile.primaryColor.isNotEmpty
                              ? Color(int.parse(
                                  userProfile.primaryColor.substring(2),
                                  radix: 16))
                              : const Color(
                                  0xFF7B86E2), // Default color if primaryColor is not available
                          borderRadius: const BorderRadius.only(
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
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: Container(
                                          height:
                                              300, // Adjust the height as needed
                                          width:
                                              300, // Adjust the width as needed
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(
                                                userProfile.photoUrl ??
                                                    'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=150&d=mp&r=pg',
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              onPressed: () async {
                                if (userProfile.facebookLink.isNotEmpty) {
                                  var url = userProfile.facebookLink;
                                  final Uri uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("There is no link yet."),
                                      ),
                                    );
                                  }
                                }
                              },
                              // ignore: prefer_const_constructors
                              icon: Icon(
                                FontAwesomeIcons.facebook,
                                size: 50,
                                color: Colors.blue,
                              )

                              // Wrap Icons.facebook with Icon widget
                              ),
                          Container(
                            width: 5,
                          ),
                          IconButton(
                            onPressed: () async {
                              if (userProfile.instagramLink.isNotEmpty) {
                                var url = userProfile.instagramLink;
                                final Uri uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("There is no link yet."),
                                    ),
                                  );
                                }
                              }
                            },
                            // ignore: prefer_const_constructors
                            icon: Icon(
                              FontAwesomeIcons.instagram,
                              size: 50, // Adjust the icon size
                              color: Colors.purple, // Set a suitable color
                            ), // Wrap Icons.facebook with Icon widget
                          ),
                          Container(
                            width: 5,
                          ),
                          IconButton(
                            onPressed: () async {
                              if (userProfile.websiteLink.isNotEmpty) {
                                var url = userProfile.websiteLink;
                                final Uri uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("There is no link yet."),
                                    ),
                                  );
                                }
                              }
                            },
                            // ignore: prefer_const_constructors
                            icon: Icon(
                              Icons.web,
                              size: 50,
                              color: Colors.teal,
                            ), // Wrap Icons.facebook with Icon widget
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
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

  void _showFeedbackForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Provide Feedback & Support',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Your Feedback',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B86E2)),
                      onPressed: () {
                        _sendFeedback(context);
                      },
                      child: const Text('Send Feedback'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendFeedback(BuildContext context) {
    String feedbackText = _feedbackController.text.trim();

    // Get the current user's ID
    String currentUserUid = _auth.currentUser!.uid;

    // Reference to the feedback node in the database
    DatabaseReference feedbackRef =
        FirebaseDatabase.instance.ref().child('feedback');

    // Generate a unique key for each feedback entry
    String feedbackKey = feedbackRef.push().key!;

    // Create a map to represent the feedback entry
    Map<String, dynamic> feedbackData = {
      'userId': currentUserUid,
      'text': feedbackText,
      'timestamp':
          ServerValue.timestamp, // Use server timestamp for accurate timing
    };

    // Update the database with the feedback
    feedbackRef.child(feedbackKey).set(feedbackData);

    // Close the feedback form
    Navigator.pop(context);
    // Show a SnackBar to indicate successful feedback submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback sent successfully!'),
        duration: Duration(seconds: 4), // You can adjust the duration as needed
      ),
    );
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
