import 'package:appointments/appointments_list.dart';
import 'package:appointments/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'first_time_sign_up_page.dart';
import 'helpers.dart';
import 'home_page_business.dart';

class HomePage extends StatefulWidget {
  final int pageNumber;
  final String? businessId;
  const HomePage({Key? key, required this.pageNumber, this.businessId})
      : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  TextEditingController searchControllerForGlobal = TextEditingController();
  List<UserProfile> searchResults = [];
  String userName = "";
  String userPhone = "";
  bool isNavigating = false; // Add this variable in your state

// Declare the class-level variable for all chats
  List<Map<dynamic, dynamic>> allChats = [];
// Declare the class-level variable for displayed chats
  List<Map<dynamic, dynamic>> displayedChats = [];
  TextEditingController searchControllerForChats =
      TextEditingController(); //new1
  @override
  void initState() {
    requestPermission();
    super.initState();
    getToken();
    if (!kIsWeb) {
      getToken();
      NotificationHandler.handleNotification(context);
    }
    // Set the initial page based on the provided pageNumber
    _currentIndex = widget.pageNumber;
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) => {
          saveToken(token!),
        });
  }

  void saveToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      // Get the user ID
      String userId = user.uid;
      await FirebaseFirestore.instance
          .collection("UserTokens")
          .doc(userId)
          .set({
        'token': token,
      });
    }
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // ignore: avoid_print
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // ignore: avoid_print
      print('User granted provisional permission');
    } else {
      // ignore: avoid_print
      print('User not granted permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: _getBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
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
    // Adjust the content for each tab
    switch (_currentIndex) {
      case 0:
        return _getHomeContent();
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

  Widget _getHomeContent() {
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      // Get the user ID
      String userId = user.uid;
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FutureBuilder<Map<dynamic, dynamic>?>(
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
                      UserProfile userProfile =
                          UserProfile.fromJson(snapshot.data!);
                      userName = userProfile.fullName;
                      userPhone = userProfile.phoneNumber;
                      return Row(
                        children: [
                          const Text(
                            'Appointments!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(child: Container()),
                          Column(
                            children: [
                              Text(
                                'Hello ${userProfile.fullName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                getGreeting(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 3,
                          ),
                          Container(
                            height: 45,
                            width: 45,
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
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchControllerForGlobal,
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          searchResults = [];

                          await performSearch(searchControllerForGlobal.text);

                          // Check if search results are not empty
                          if (searchResults.isNotEmpty && context.mounted) {
                            // Navigate to a new page with the search results
                            if (!isNavigating) {
                              // Handle the tap on a search result
                              isNavigating = true;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultPage(
                                    searchResults: searchResults,
                                    userName: userName,
                                    userPhone: userPhone,
                                  ),
                                ),
                              ).then((value) {
                                isNavigating =
                                    false; // Reset the flag when navigation is complete
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 20,
                ),
                const Row(
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 20,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: businessTypes.map((option) {
                      return GestureDetector(
                          onTap: () async {
                            // Your function or code to execute when the card is tapped
                            searchResults = [];

                            await performSearch(option);

                            // Check if search results are not empty
                            if (searchResults.isNotEmpty && context.mounted) {
                              // Navigate to a new page with the search results
                              if (!isNavigating) {
                                // Handle the tap on a search result
                                isNavigating = true;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultPage(
                                      searchResults: searchResults,
                                      userName: userName,
                                      userPhone: userPhone,
                                    ),
                                  ),
                                ).then((value) {
                                  isNavigating =
                                      false; // Reset the flag when navigation is complete
                                });
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "There is no business in this area yet."),
                                  ),
                                );
                              }
                            }
                          },
                          child: SizedBox(
                            width: 120, // Set the desired width
                            height: 130, // Set the desired height
                            child: Card(
                              color: const Color(0xFF7B86E2),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    getIconForOption(option),
                                    color: const Color(0xFF161229),
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    option,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ));
                    }).toList(),
                  ),
                ),
                Container(
                  height: 20,
                ),
                const Row(
                  children: [
                    Text(
                      'Recents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 20,
                ),
                FutureBuilder<List<Appointment>>(
                  future: getAppointmentsForUserRecents(
                    FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Uh-oh! The cosmic planner encountered a supernova.',
                        ),
                      );
                    } else {
                      List<Appointment> appointments = snapshot.data ?? [];

                      if (appointments.isEmpty) {
                        return const Text('No recents');
                      }

                      appointments
                          .sort((a, b) => a.startTime.compareTo(b.startTime));

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < appointments.length; i++)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildAppointmentCard(appointments[i]),
                              ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return const Center(
        child: Text('User not signed in'),
      );
    }
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return FutureBuilder<Map<dynamic, dynamic>?>(
      future: getUserProfile(appointment
          .userId), // Assuming getUserProfile returns a Future<UserProfile>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator while waiting for the result
          return Container();
        } else if (snapshot.hasError) {
          // Handle errors
          return Text('Error: ${snapshot.error}');
        } else {
          // If the Future is complete and successful, build the card with the business information
          UserProfile userProfile = UserProfile.fromJson(snapshot.data!);
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  RoutePaths.businessId = '/${appointment.userId}';

                  Navigator.of(context).pushNamed(
                    '/businessProfile${RoutePaths.businessId}',
                    arguments: {
                      'businessId': appointment.userId,
                      'userName': userName,
                      'userPhone': userPhone,
                    },
                  );
                },
                child: SizedBox(
                  width: 150, // Adjust the width as needed
                  height: 180, // Adjust the height as needed
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom:
                            0, // Adjust the bottom position to control the card visibility
                        child: SizedBox(
                          width: 150,
                          height: 160,
                          child: Card(
                            color: Colors.transparent,
                            elevation: 8,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15.0),
                                bottom: Radius.circular(
                                    35.0), // Set bottom border radius to 0
                              ),
                              side: BorderSide(
                                color: Color(0xFF7B86E2),
                                width: 2.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 50),
                                Text(
                                  userProfile.businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userProfile.businessFullAddress,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userProfile.businessType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top:
                            0, // Adjust the top position to control the image visibility
                        child: Card(
                          elevation: 8,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: const BorderSide(
                              color: Color(0xFF7B86E2),
                              width: 2.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Image.network(
                                userProfile.photoUrl ??
                                    'https://example.com/default_image.jpg',
                                height: 60, // Adjust the height as needed
                                width: 60, // Adjust the width as needed
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  IconData getIconForOption(String option) {
    switch (option.toLowerCase()) {
      case 'salon':
        return FontAwesomeIcons.scissors;
      case 'spa':
        return Icons.spa;
      case 'dentist':
        return FontAwesomeIcons.tooth;
      case 'doctor':
        return Icons.local_hospital;
      case 'fitness center':
        return Icons.fitness_center;
      case 'photographer':
        return Icons.camera_alt;
      case 'consulting':
        return FontAwesomeIcons.handshake;
      case 'repair service':
        return Icons.build;
      case 'restaurant':
        return Icons.restaurant;
      case 'other':
        return Icons.category;
      default:
        return Icons.category; // Default icon for unknown options
    }
  }

  List<String> businessTypes = [
    'Salon',
    'Spa',
    'Dentist',
    'Doctor',
    'Fitness Center',
    'Photographer',
    'Consulting',
    'Repair Service',
    'Restaurant',
    'Other',
  ];

  Future<void> performSearch(String searchText2) async {
    String searchText = searchText2.toLowerCase();
    List<UserProfile> results = [];

    final dataSnapshot = await databaseReference.child('users').get();

    if (dataSnapshot.exists) {
      Map<dynamic, dynamic> usersData =
          dataSnapshot.value as Map<dynamic, dynamic>;

      usersData.forEach((key, value) {
        UserProfile userProfile = UserProfile.fromJson(value);
        if (userProfile.userType == 'business' &&
            (userProfile.businessName.toLowerCase().contains(searchText) ||
                userProfile.businessLocation
                    .toLowerCase()
                    .contains(searchText) ||
                userProfile.businessType.toLowerCase().contains(searchText))) {
          results.add(userProfile);
        }
      });
    }

    setState(() {
      searchResults = results;
    });
  }

  String getGreeting() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
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
                  indicator: BoxDecoration(
                      color: Color(0xFF7B86E2), // Color of the curvy container
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  indicatorWeight:
                      0, // Set indicatorWeight to 0 to hide the default indicator
                  indicatorSize: TabBarIndicatorSize.tab,
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
              appointments: appointments,
              type: filter,
              userType: 1,
              username: userName,
              phoneNumber: userPhone,
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

  Future<List<Appointment>> getAppointmentsForUserRecents(
      String userUid) async {
    try {
      final DatabaseReference appointmentsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userUid)
          .child('appointmentsByDate');

      final dataSnapshot = await appointmentsRef.get();

      if (dataSnapshot.exists) {
        Map<String, Appointment> latestAppointments = {};

        Map<dynamic, dynamic> appointmentsData =
            dataSnapshot.value as Map<dynamic, dynamic>;

        for (var entry in appointmentsData.entries) {
          Appointment appointment = Appointment.fromJson({
            'userId': entry.value['userId'],
            'name': entry.value['name'],
            'phone': entry.value['phone'],
            'cancelled': entry.value['cancelled'],
            'approved': entry.value['approved'],
            'startTime': entry.value['startTime'],
            'endTime': entry.value['endTime'],
            'pushId': entry.value['pushId'],
          });

          String businessId = entry
              .value['userId']; // Assuming there's a businessId in your data

          if (!latestAppointments.containsKey(businessId) ||
              appointment.startTime
                      .compareTo(latestAppointments[businessId]!.startTime) >
                  0) {
            latestAppointments[businessId] = appointment;
          }
        }

        List<Appointment> appointments = latestAppointments.values.toList();

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
                  'approved': entry.value['approved'],
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
                    .map((entry) => entry.value['sendToName'] as String? ?? '')
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
            userName = userProfile.fullName;
            userPhone = userProfile.phoneNumber;
            String userId = user.uid;
            String senderId = widget.businessId ?? "0";

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
                                hintText: 'Search for business name..',
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
                  String userName2 = userProfile2.businessName;
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
                return const Center(child: CircularProgressIndicator());
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
                                    margin: const EdgeInsets.only(
                                        left: 10, top: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        userProfile.fullName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                          Navigator.of(context)
                                              .pushReplacementNamed(
                                                  '/firstTimeSignUp');
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
                                    const EdgeInsets.only(left: 10, bottom: 60),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
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
                                          Icons.settings,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          if (context.mounted) {
                                            Navigator.of(context)
                                                .pushReplacementNamed(
                                                    '/settings');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

Future<Map<dynamic, dynamic>?> getUserProfile(String userId) async {
  try {
    DatabaseReference reference = FirebaseDatabase.instance.ref();
    final snapshot = await reference.child('users/$userId').get();

    if (snapshot.exists) {
      // Print the structure of the received data
      // ignore: avoid_print
      // print("Received user data: ${snapshot.value}");

      // User profile found, convert the data to a Map<String, dynamic>
      if (snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
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

class SearchResultPage extends StatelessWidget {
  final List<UserProfile> searchResults;
  final String userName;
  final String userPhone;

  const SearchResultPage({
    super.key,
    required this.searchResults,
    required this.userName,
    required this.userPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              searchResults[index].businessName,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(searchResults[index].businessLocation,
                style: const TextStyle(color: Colors.white)),
            onTap: () {
              RoutePaths.businessId = '/${searchResults[index].uid}';

              Navigator.of(context).pushNamed(
                '/businessProfile${RoutePaths.businessId}',
                arguments: {
                  'businessId': searchResults[index].uid,
                  'userName': userName,
                  'userPhone': userPhone,
                },
              );
            },
          );
        },
      ),
    );
  }
}
