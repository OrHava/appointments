import 'package:appointments/first_time_sign_up_page.dart';
import 'package:appointments/home_page_business.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserProfilePage extends StatefulWidget {
  final String businessId;
  final String userName;
  final String userPhone;

  const UserProfilePage(this.businessId, this.userName, this.userPhone,
      {Key? key})
      : super(key: key);

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  bool isScheduleExpanded = false;
  static const String defaultProfileImageAsset = 'images/background_image.jpg';
  List<String> selectedTimeSlots = [];
  DateTime selectedDate = DateTime.now();
  String? selectedAppointmentTime;
  bool isBlocked = false; // Add this variable to track block status
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      String currentUserUid = user.uid;
      return Scaffold(
        backgroundColor: const Color(0xFF161229),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7B86E2),
          title: const Text('User Profile'),
        ),
        body: _buildProfile(widget.businessId, currentUserUid),
      );
    } else {
      return Container();
    }
  }

  // Update the initState method to check block status
  @override
  void initState() {
    super.initState();
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      String currentUserUid = user.uid;
      fetchBlockStatus(currentUserUid);
    }
  }

// Add this method to set the initial block status
  Future<void> fetchBlockStatus(String currentUserUid) async {
    try {
      bool blocked = await isUserBlocked(widget.businessId,
          currentUserUid); // Replace with the actual current user ID
      setState(() {
        isBlocked = blocked;
      });
    } catch (error) {
      // ignore: avoid_print
      print("Error fetching block status: $error");
    }
  }

  Future<bool> isUserBlocked(String businessId, String userId) async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref();
      final snapshot = await reference.child('users/$userId').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        UserProfile userProfile = UserProfile.fromJson(values);
        List<String> blockedUserIds =
            List<String>.from(userProfile.blockedUserIds);
        return blockedUserIds.contains(businessId);
      }

      return false;
    } catch (error) {
      // ignore: avoid_print
      print("Error checking block status: $error");
      return false;
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

  Future<void> toggleBlockUser(String businessId, String userId) async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref();
      final snapshot = await reference.child('users/$userId').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        UserProfile userProfile = UserProfile.fromJson(values);
        List<String> blockedUserIds =
            List<String>.from(userProfile.blockedUserIds);

        // Toggle block status
        if (blockedUserIds.contains(businessId)) {
          blockedUserIds.remove(businessId);
        } else {
          blockedUserIds.add(businessId);
        }

        // Use update to add or remove the blocked user ID
        await reference
            .child('users/$userId')
            .update({'blockedUserIds': blockedUserIds});

        // Update state to reflect the change
        setState(() {
          isBlocked = !isBlocked;
        });
      }
    } catch (error) {
      // Handle errors here
      // ignore: avoid_print
      print("Error toggling block status: $error");
    }
  }

  Widget _buildProfile(String userId, String personalID) {
    // Get the current user from FirebaseAuth

    return SingleChildScrollView(
      child: Center(
        child: FutureBuilder<Map<dynamic, dynamic>?>(
          future: getUserProfile(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                color: Colors.amber,
              ));
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
                            child: Container(
                              margin: const EdgeInsets.only(left: 10, top: 10),
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
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              margin:
                                  const EdgeInsets.only(left: 10, bottom: 60),
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
                              margin: const EdgeInsets.only(left: 10, top: 140),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const FaIcon(
                                        Icons.chat,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HomePageBusiness(
                                                      pageNumber: 2,
                                                      userId:
                                                          widget.businessId),
                                            ));
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        toggleBlockUser(
                                            widget.businessId, personalID);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .red, // Change color as needed
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isBlocked
                                                ? Icons.unarchive
                                                : Icons
                                                    .block, // Change icons as needed
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isBlocked ? 'Unblock' : 'Block',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
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
                              margin:
                                  const EdgeInsets.only(bottom: 20, right: 20),
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF161229).withOpacity(0.2),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10, right: 10),
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF161229).withOpacity(0.4),
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
                                color: const Color(0xFF161229).withOpacity(0.6),
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
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
