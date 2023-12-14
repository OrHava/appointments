import 'package:appointments/user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:appointments/business_profile_page.dart';

import 'first_time_sign_up_page.dart';

class AppointmentsList extends StatefulWidget {
  final List<Appointment> appointments;
  final VoidCallback? onCancel;
  final int? userType;
  final String? username;
  final String? phoneNumber;

  const AppointmentsList({
    Key? key,
    required this.appointments,
    this.onCancel,
    this.userType,
    this.username,
    this.phoneNumber,
  }) : super(key: key);
  @override
  AppointmentsListState createState() => AppointmentsListState();
}

class AppointmentsListState extends State<AppointmentsList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.appointments.length,
      itemBuilder: (context, index) {
        Appointment appointment = widget.appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return FutureBuilder<Map<dynamic, dynamic>?>(
      future: getUserProfile(appointment.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          Map<dynamic, dynamic>? userProfile = snapshot.data;
          return Card(
            color: const Color(0xFF161229),
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userProfile != null) ...[
                    // Display user profile information
                    Row(
                      children: [
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                userProfile['photoUrl'] ??
                                    'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=150&d=mp&r=pg',
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 20,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Container(
                              height: 5,
                            ),
                            if (userProfile['businessType'] !=
                                null) // Check if businessType exists
                              Text(
                                '${userProfile['userType'] == "user" ? userProfile['phoneNumber'] : userProfile['businessType']}',
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF878493)),
                              ),
                          ],
                        )
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        color:
                            Colors.blue.shade50, // Color of the curvy container
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  color: Colors.grey),
                              Container(
                                width: 10,
                              ),
                              Text(
                                _formatDate(appointment.startTime),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Expanded(child: Container()),
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.grey),
                              Container(
                                width: 10,
                              ),
                              Text(
                                '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 16), // Adding some space between text and buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 3,
                        child: ElevatedButton(
                          onPressed: () {
                            cancelAppointment(appointment.pushId, context,
                                appointment.userId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Adjust the value for more or less curve
                              side: const BorderSide(
                                  color: Color(0xFF7B86E2), width: 2.0),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF7B86E2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 3,
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (widget.userType == 1) {
                              // Navigate to BusinessProfilePage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessProfilePage(
                                    appointment.userId,
                                    widget.username,
                                    widget.phoneNumber, //here is the problem
                                  ),
                                ),
                              );
                            } else if (widget.userType == 2) {
                              // Navigate to UserProfilePage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                    appointment.userId,
                                    appointment.name,
                                    appointment.phone,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B86E2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Adjust the value for more or less curve
                            ),
                          ),
                          child: const Text('Reschedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month}-${dateTime.day}";
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
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

  Future<void> cancelAppointment(
      String? appointmentId, BuildContext context, String userId) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      try {
        // Reference to the appointment node in the Realtime Database

        final DatabaseReference appointmentRef2 = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .child('appointmentsByDate')
            .child(appointmentId!);

        final DatabaseReference appointmentRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(user.uid)
            .child('appointmentsByDate')
            .child(appointmentId);

        // Fetch the existing appointment data
        DatabaseEvent appointmentSnapshot = await appointmentRef.once();
        DatabaseEvent appointmentSnapshot2 = await appointmentRef2.once();
        if (appointmentSnapshot.snapshot.value != null &&
            appointmentSnapshot2.snapshot.value != null) {
          // Update the 'cancelled' field to true
          Map<String, dynamic> appointmentData;

          // Check if the data is of type Map<String, dynamic>
          if (appointmentSnapshot.snapshot.value is Map<String, dynamic> &&
              appointmentSnapshot2.snapshot.value is Map<String, dynamic>) {
            appointmentData = Map<String, dynamic>.from(
                appointmentSnapshot.snapshot.value as Map<String, dynamic>);
            appointmentData = Map<String, dynamic>.from(
                appointmentSnapshot2.snapshot.value as Map<String, dynamic>);
          } else {
            // Handle the case when the data is of type Object?
            appointmentData = {
              'cancelled': true
            }; // Assuming 'cancelled' is the only field you want to update
          }

          // Save the updated appointment back to the database
          await appointmentRef.update(appointmentData);
          await appointmentRef2.update(appointmentData);
          // Optionally, you can show a success message or trigger any other necessary actions
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Appointment cancelled successfully!')),
            );

            // Refresh the list by calling setState
            widget.onCancel!();
          }
        } else {
          // Handle the case when the appointment with the given ID doesn't exist
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment not found.')),
            );
          }
        }
      } catch (error) {
        // Handle errors
        // ignore: avoid_print
        print("Error: $error");

        // Optionally, you can show an error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Failed to cancel appointment. Please try again.')),
          );
        }
      }
    }
  }
}
