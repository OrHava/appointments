import 'package:appointments/screens_general/first_time_sign_up_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BlockPage extends StatefulWidget {
  const BlockPage({Key? key}) : super(key: key);

  @override
  BlockPageState createState() => BlockPageState();
}

class BlockPageState extends State<BlockPage> {
  List<String> blockedUserIds = [];
  List<String> userNames = []; // Declare userNames as an instance variable

  @override
  void initState() {
    super.initState();
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    if (user != null) {
      String currentUserUid = user.uid;
      fetchBlockedUsers(currentUserUid);
    }
  }

  Future<void> fetchBlockedUsers(String businessId) async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref();
      final snapshot = await reference.child('users/$businessId').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        UserProfile userProfile = UserProfile.fromJson(values);
        List<String> userIds = List<String>.from(userProfile.blockedUserIds);

// Fetch user names for blocked user IDs
        userNames = await Future.wait(
          userIds.map((userId) async {
            Map<dynamic, dynamic>? userData = await getUserProfile(userId);
            return userData?['fullName'] ?? 'Unknown User';
          }),
        );

        setState(() {
          blockedUserIds = userIds;
        });
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error fetching blocked users: $error");
    }
  }

  Future<void> unblockUser(String userId, String businessId) async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref();
      final snapshot = await reference.child('users/$businessId').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        UserProfile userProfile = UserProfile.fromJson(values);

        List<String> updatedBlockedUserIds =
            List<String>.from(userProfile.blockedUserIds);
        updatedBlockedUserIds.remove(userId);

        await reference
            .child('users/$businessId')
            .update({'blockedUserIds': updatedBlockedUserIds});

        // Refresh the list after unblocking
        fetchBlockedUsers(businessId);
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error unblocking user: $error");
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

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      String currentUserUid = user.uid;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Blocked Users',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          backgroundColor: const Color(0xFF7B86E2), // Set theme color
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/settings');
            },
          ),
        ),
        body: Container(
          color: const Color(0xFF161229), // Set background color
          child: ListView.builder(
            itemCount: blockedUserIds.length,
            itemBuilder: (context, index) {
              String userId = blockedUserIds[index];

              String userName =
                  userNames.length > index ? userNames[index] : 'Unknown User';

              return ListTile(
                title: Text(
                  'Blocked User: $userName',
                  style: const TextStyle(color: Colors.white), // Set text color
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    unblockUser(userId, currentUserUid);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Change color as needed
                  ),
                  child: const Text(
                    'Unblock',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
