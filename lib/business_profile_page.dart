import 'dart:io';

import 'package:appointments/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'appointment_confirmation_popup.dart';
// import 'package:timezone/timezone.dart' as tz;

import 'first_time_sign_up_page.dart';
import 'helpers.dart';
import 'main.dart';

class BusinessProfilePage extends StatefulWidget {
  final String businessId;
  final String? userName;
  final String? userPhone;
  const BusinessProfilePage(this.businessId, this.userName, this.userPhone,
      {Key? key})
      : super(key: key);

  @override
  BusinessProfilePageState createState() => BusinessProfilePageState();
}

class BusinessProfilePageState extends State<BusinessProfilePage> {
  bool isScheduleExpanded = false;
  static const String defaultProfileImageAsset = 'images/background_image.jpg';
  List<String> selectedTimeSlots = [];
  ValueNotifier<List<String>> selectedTimeSlotsNotifier =
      ValueNotifier<List<String>>([]);

  DateTime selectedDate = DateTime.now();
  String? selectedAppointmentTime;

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
          title: const Text('Business Profile'),
        ),
        body: _buildProfile(widget.businessId, currentUserUid),
      );
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();

    recordPageView(widget.businessId);
  }

  Future<void> recordPageView(String currentUserUid) async {
    DatabaseReference viewsRef = FirebaseDatabase.instance
        .ref()
        .child('statistics')
        .child(currentUserUid)
        .child('views');
    String currentDate = _getCurrentDate();
    String currentMonth = _getCurrentMonth();
    String currentYear = _getCurrentYear();

    try {
      await viewsRef.child('daily').child(currentDate).push().set({'count': 1});
      await viewsRef
          .child('monthly')
          .child(currentMonth)
          .push()
          .set({'count': 1});
      await viewsRef
          .child('yearly')
          .child(currentYear)
          .push()
          .set({'count': 1});
      await viewsRef.child('total').push().set({'count': 1});

      // ignore: avoid_print
      print('Page view recorded successfully.');
    } catch (error) {
      // ignore: avoid_print
      print('Error recording page view: $error');
    }
  }

  // Function to get the current date as a string
  String _getCurrentDate() {
    return DateTime.now().toUtc().toIso8601String().split('T').first;
  }

  // Function to get the current month as a string
  String _getCurrentMonth() {
    return '${DateTime.now().year}-${DateTime.now().month}';
  }

  // Function to get the current year as a string
  String _getCurrentYear() {
    return DateTime.now().year.toString();
  }

  Future<void> bookAppointment(
      String businessName, String businessPhone) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      if (selectedAppointmentTime != null) {
        // Combine selectedDate and selectedAppointmentTime into a single DateTime
        String cleanedTime =
            selectedAppointmentTime!.replaceAll(RegExp('[^0-9:]'), '');

// Extracting hours and minutes from the cleaned time
        int hours = int.parse(cleanedTime.split(':')[0]);
        int minutes = int.parse(cleanedTime.split(':')[1]);

// Check if the cleaned time contains "PM" and adjust the hours accordingly
        if (selectedAppointmentTime!.toLowerCase().contains('pm') &&
            hours != 12) {
          // Adding 12 hours to convert from 12-hour to 24-hour format
          hours += 12;
        }

// Combine selectedDate and cleanedTime into a single DateTime
        DateTime combinedDateTime = DateTime(
          DateTime.now().year,
          selectedDate.month,
          selectedDate.day,
          hours,
          minutes,
        );

        // Now, combinedDateTime holds the selected date and time

        try {
          // Assuming you have selected values for appointment
          DateTime startTime = combinedDateTime;
          DateTime endTime = combinedDateTime.add(const Duration(minutes: 30));

          Appointment newAppointmentForUser = Appointment(
              userId: widget.businessId,
              startTime: startTime,
              endTime: endTime,
              cancelled: false,
              name: businessName,
              phone: businessPhone);

          Appointment newAppointmentForBusiness = Appointment(
              userId: user.uid,
              startTime: startTime,
              endTime: endTime,
              cancelled: false,
              name: widget.userName as String,
              phone: widget.userPhone as String);

          // Save the new appointment to Realtime Database
          String? commonPushId = FirebaseDatabase.instance.ref().push().key;

          final DatabaseReference appointmentsRef = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(user.uid)
              .child('appointmentsByDate');
          DatabaseReference newAppointmentRef =
              appointmentsRef.child(commonPushId!);
          newAppointmentForUser.pushId = commonPushId; // Set the common push ID
          await newAppointmentRef.set(newAppointmentForUser.toJson());

          final DatabaseReference appointmentsRef2 = FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(widget.businessId)
              .child('appointmentsByDate');
          DatabaseReference newAppointmentRef2 =
              appointmentsRef2.child(commonPushId);
          newAppointmentForBusiness.pushId =
              commonPushId; // Set the common push ID
          await newAppointmentRef2.set(newAppointmentForBusiness.toJson());

          DateTime notificationTime =
              combinedDateTime.subtract(const Duration(hours: 5));
          DateTime currentTime = DateTime.now();
          Duration difference = notificationTime.difference(currentTime);
          int secondsUntilNotification = difference.inSeconds;

          startBackgroundTask(
            secondsUntilNotification,
            'Your appointment with $businessName is in 5 hours.',
          );

          // You might want to add logic to update the user's appointments list as well

          setState(() {
            selectedTimeSlotsNotifier.value.clear();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AppointmentConfirmationPopup(
                    businessName: businessName,
                    startTime: startTime,
                  );
                },
              );
            }
          });
        } catch (error) {
          // Handle errors
          // ignore: avoid_print
          print("Error: $error");
        }
      } else {
        // Handle the case when either selectedDate or selectedAppointmentTime is null

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please select both date and time before booking.')),
          );
        }
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

  Widget _buildProfile(String userId, String personalUserId) {
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

              // Check if the current user is blocked
              if (userProfile.blockedUserIds.contains(personalUserId)) {
                return Column(
                  children: [
                    Container(
                      height: 150,
                    ),
                    const Center(
                        child: Text(
                      'You are blocked by this business.',
                      style: TextStyle(color: Colors.white),
                    )),
                  ],
                );
              }

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
                              margin: const EdgeInsets.only(left: 10),
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
                                    IconButton(
                                      icon: const Icon(
                                        Icons.star,
                                        size: 25,
                                        color: Colors.yellow,
                                      ),
                                      onPressed: () {
                                        showRatingDialog(context, userProfile,
                                            personalUserId);
                                      },
                                    ),
                                    Text(
                                      userProfile.businessRating
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white),
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
                              margin: const EdgeInsets.only(left: 10, top: 40),
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
                              margin: const EdgeInsets.only(left: 10, top: 80),
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
                              margin: const EdgeInsets.only(left: 10, top: 140),
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

                                          launchWazeRoute(coordinates.latitude,
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
                                        Icons.chat,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HomePage(
                                                  pageNumber: 2,
                                                  businessId:
                                                      widget.businessId),
                                            ));
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
                    const SizedBox(height: 16),
                    _buildBusinessSchedule(
                        userProfile.slotAllowedAmount,
                        userProfile.businessSchedule,
                        userProfile.appointmentsByDate,
                        userProfile.slotDurationInMinutes),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: ElevatedButton(
                          onPressed: () {
                            // Call the function to handle the booking logic
                            bookAppointment(userProfile.businessName,
                                userProfile.phoneNumber);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF7B86E2), // Set your desired background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Book Appointment'),
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
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: userProfile.services.length,
                                  itemBuilder: (context, index) {
                                    Service service =
                                        userProfile.services[index];
                                    String currencySymbol =
                                        getCurrencySymbol(service.paymentType);
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
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
                              const Text('No services available.'),
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
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
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

  Future<void> showRatingDialog(
    BuildContext context,
    UserProfile userProfile,
    String userId,
  ) async {
    double userRating = 0.0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate the business'),
          content: RatingBar.builder(
            initialRating: userRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 30.0,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              userRating = rating;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save the rating to the business profile
                saveBusinessRating(userRating, userProfile, userId);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void saveBusinessRating(
      double rating, UserProfile userProfile, String currentUserUid) {
    DatabaseReference businessRef =
        FirebaseDatabase.instance.ref().child('users').child(widget.businessId);

    // Check if the current user has already rated the business
    if (userProfile.ratedUserIds.contains(currentUserUid)) {
      // User has already rated, update the existing rating
      double oldRating = userProfile.ratings[currentUserUid] ?? 0;
      int numberOfRatings = userProfile.ratedUserIds.length;

      double newBusinessRating =
          (userProfile.businessRating * numberOfRatings - oldRating + rating) /
              numberOfRatings.toDouble();

      setState(() {
        businessRef.update({
          'businessRating': newBusinessRating,
          'ratings/$currentUserUid': rating,
        });
      });
    } else {
      // Add the current user's ID to the ratedUserIds list
      userProfile.ratedUserIds.add(currentUserUid);

      // Update the rating for the current user
      userProfile.ratings[currentUserUid] = rating;

      double newBusinessRating =
          (userProfile.businessRating * (userProfile.ratedUserIds.length - 1) +
                  rating) /
              userProfile.ratedUserIds.length.toDouble();

      setState(() {
        businessRef.update({
          'businessRating': newBusinessRating,
          'ratedUserIds': userProfile.ratedUserIds,
          'ratings': userProfile.ratings,
        });
      });
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

  Widget _buildBusinessSchedule(
      int slotAllowedAmount,
      Map<String, Map<String, dynamic>> businessSchedule,
      Map<String, List<Appointment>>? appointmentsByDate,
      int slotDurationInMinutes) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          buildDaysRow(businessSchedule),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose time',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          buildTimeSlotsRow(slotAllowedAmount, businessSchedule,
              appointmentsByDate, slotDurationInMinutes),
        ],
      ),
    );
  }

  Widget buildTimeSlotsRow(
      int slotAllowedAmount,
      Map<String, Map<String, dynamic>> businessSchedule,
      Map<String, List<Appointment>>? appointmentsByDate,
      int slotDurationInMinutes) {
    // Assuming selectedDate is a DateTime object

// Specify the new year and month
    int newYear = DateTime.now().year; // Replace with the desired year

// Create a new DateTime object with the updated year and month
    DateTime updatedDate = DateTime(
        newYear,
        selectedDate.month,
        selectedDate.day,
        selectedDate.hour,
        selectedDate.minute,
        selectedDate.second,
        selectedDate.millisecond,
        selectedDate.microsecond);

    Map<String, dynamic> schedule = businessSchedule[getWeekdayString(
        updatedDate.weekday)]!; //there is problem with matching of the days

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            buildTimeSlotsListView(slotAllowedAmount, schedule,
                businessSchedule, appointmentsByDate, slotDurationInMinutes),
          ],
        ),
      ),
    );
  }

  String getWeekdayString(int weekdayNumber) {
    switch (weekdayNumber) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Invalid weekday number';
    }
  }

  List<DateTime> generateDateList() {
    DateTime selectedDate = DateTime.now();
    List<DateTime> dates = [];
    for (int i = 0; i < 30; i++) {
      dates.add(selectedDate.add(Duration(days: i)));
    }
    return dates;
  }

  Widget buildDaysRow(Map<String, Map<String, dynamic>> businessSchedule) {
    List<DateTime> dateList = generateDateList();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 120,
      child: ListView.builder(
        key: const PageStorageKey(0),
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          DateTime date = dateList[index];

          String formattedDate = DateFormat('MM/dd').format(date);

          return buildDayColumn(formattedDate, date, businessSchedule);
        },
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget buildDayColumn(String day, DateTime date,
      Map<String, Map<String, dynamic>> businessSchedule) {
    bool isSelected = isSameDay(date, selectedDate);
    bool isAvailable =
        businessSchedule[getWeekdayString(date.weekday)]?['available'] ?? true;

    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          setState(() {
            selectedDate = date;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          color: isAvailable ? Colors.white : Colors.grey,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(
              color: isSelected ? const Color(0xFF7B86E2) : Colors.grey,
              width: 2.0,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildDateText(
                  getWeekdayString(date.weekday),
                  isSelected,
                ),
                const SizedBox(height: 8),
                buildDayName(day, isSelected, isAvailable),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDateText(String day, bool isSelected) {
    return Text(
      day,
      style: TextStyle(
        color: isSelected ? const Color(0xFF7B86E2) : Colors.grey,
        fontSize: 12,
      ),
    );
  }

  Widget buildDayName(String day, bool isSelected, bool isAvailable) {
    return Text(
      day,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: isSelected
            ? const Color(0xFF7B86E2)
            : (isAvailable ? Colors.black : Colors.grey),
      ),
    );
  }

  Future<List<bool>> _getBookedStatusForTimeSlots(
    int slotAllowedAmount,
    List<TimeOfDay> timeSlots,
    DateTime selectedDate,
    Map<String, Map<String, dynamic>> businessSchedule,
  ) async {
    List<Future<bool>> futures = [];

    for (int i = 0; i < timeSlots.length; i++) {
      String timeSlot = _formatTimeOfDay(timeSlots[i]);
      futures.add(isTimeSlotBooked(
          slotAllowedAmount, timeSlot, selectedDate, businessSchedule));
    }

    List<bool> isBookedList = await Future.wait(futures);
    return isBookedList;
  }

  Widget buildTimeSlotsListView(
      int slotAllowedAmount,
      Map<String, dynamic> schedule,
      Map<String, Map<String, dynamic>> businessSchedule,
      Map<String, List<Appointment>>? appointmentsByDate,
      int selectedSlotDurationInMinutes) {
    TimeOfDay openingTime =
        schedule['opening'] ?? const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay closingTime =
        schedule['closing'] ?? const TimeOfDay(hour: 23, minute: 59);
    int slotDurationInMinutes =
        selectedSlotDurationInMinutes; // here need to change
    List<TimeOfDay> timeSlots = [];
    TimeOfDay currentTime = openingTime;

    while (currentTime.hour < closingTime.hour ||
        (currentTime.hour == closingTime.hour &&
            currentTime.minute <= closingTime.minute - slotDurationInMinutes)) {
      timeSlots.add(currentTime);

      int nextMinute = currentTime.minute + slotDurationInMinutes;
      currentTime = TimeOfDay(
        hour: currentTime.hour + nextMinute ~/ TimeOfDay.minutesPerHour,
        minute: nextMinute % TimeOfDay.minutesPerHour,
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: FutureBuilder<List<bool>>(
        future: _getBookedStatusForTimeSlots(
          slotAllowedAmount,
          timeSlots,
          selectedDate,
          businessSchedule,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading indicator or some placeholder while waiting for the result
            return Container();
          } else if (snapshot.hasError) {
            // Handle error case
            return Text('Error: ${snapshot.error}');
          } else {
            List<bool> isBookedList = snapshot.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.only(right: 40),
              key: const PageStorageKey(1),
              scrollDirection: Axis.horizontal,
              itemCount: timeSlots.length,
              itemBuilder: (context, timeIndex) {
                TimeOfDay currentTime = timeSlots[timeIndex];
                String timeSlot = _formatTimeOfDay(currentTime);
                bool isBooked = isBookedList[timeIndex];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: buildChoiceChip(
                    timeSlot,
                    businessSchedule,
                    appointmentsByDate,
                    isBooked,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget buildChoiceChip(
    String timeSlot,
    Map<String, Map<String, dynamic>> businessSchedule,
    Map<String, List<Appointment>>? appointmentsByDate,
    bool isBooked,
  ) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedTimeSlotsNotifier,
      builder: (context, selectedTimeSlots, child) {
        bool isSelected = selectedTimeSlots.contains(timeSlot);

        return ChoiceChip(
          label: Text(
            timeSlot,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF7B86E2)
                  : isBooked
                      ? Colors.grey
                      : Colors.black,
            ),
          ),
          color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                // Return the color for the disabled state
                return Colors.grey;
              }
              // Return the color for the default state
              return Colors.transparent;
            },
          ),
          selected: isSelected,
          selectedColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF7B86E2)
                  : isBooked
                      ? Colors.grey
                      : Colors.grey,
              width: 2.0,
            ),
          ),
          onSelected: isBooked
              ? null
              : (bool selected) {
                  List<String> newSelectedTimeSlots = [];
                  if (selected) {
                    newSelectedTimeSlots.add(timeSlot);
                    selectedAppointmentTime = timeSlot;
                  }
                  selectedTimeSlotsNotifier.value = newSelectedTimeSlots;
                },
        );
      },
    );
  }

  Future<bool> isTimeSlotBooked(
    int slotAllowedAmount,
    String timeSlot,
    DateTime selectedDate,
    Map<String, Map<String, dynamic>> businessSchedule,
  ) async {
    try {
      // Parse the selected time slot
      List<int> timeComponents = timeSlot
          .split(':')
          .map((component) => int.parse(component.split(' ')[0]))
          .toList();

      // Create the selected DateTime
      DateTime selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        timeComponents[0],
        timeComponents[1],
      );

      String amPm = timeSlot.substring(timeSlot.length - 2).toLowerCase();

      List<String> timeComponents2 = [
        timeSlot.substring(0, timeSlot.length - 2),
        amPm,
      ];

      List<int> hourMinuteComponents = timeComponents2[0]
          .split(':')
          .map((component) => int.parse(component))
          .toList();

      int hour = hourMinuteComponents[0];
      int minute = hourMinuteComponents[1];

      // Adjust the hour based on AM/PM
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }

      // Create a new DateTime for the check
      DateTime checkDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        minute,
      );

      // Get user appointments
      List<Appointment> userAppointments =
          await getAppointmentsForUser(widget.businessId);

      // Check if userAppointments is empty
      if (userAppointments.isEmpty) {
        // If there are no appointments, check if the slotAllowedAmount is exceeded
        return userAppointments.length >= slotAllowedAmount;
      }

      // Check if the selected date is available based on the business schedule
      bool isAvailable =
          businessSchedule[getWeekdayString(checkDateTime.weekday)]
                  ?['available'] ??
              false;

      if (!isAvailable) {
        // If the selected date is not available, the time slot is booked
        return true;
      }

      // Check if selectedDateTime is in the past and it's for today
      if (checkDateTime.isBefore(DateTime.now()) &&
          selectedDateTime.day == DateTime.now().day) {
        return true;
      }

      // Iterate through user appointments
      int appointmentsForSlot = 0;
      for (Appointment appointment in userAppointments) {
        // Convert appointment times to local DateTime
        DateTime appointmentStart = appointment.startTime.toLocal();

        // Adjust appointmentStart hours if it's in PM
        if (appointment.startTime.hour >= 12) {
          appointmentStart =
              appointmentStart.subtract(const Duration(hours: 12));
        }

        // Adjust selectedDateTime hours if it's in PM
        DateTime adjustedSelectedDateTime = selectedDateTime;
        if (selectedDateTime.hour >= 12) {
          adjustedSelectedDateTime =
              selectedDateTime.subtract(const Duration(hours: 12));
        }

        // Check if adjustedSelectedDateTime is within the appointment range
        if (adjustedSelectedDateTime.isAtSameMomentAs(appointmentStart)) {
          // Increment the count for appointments in the same time slot
          appointmentsForSlot++;
        }
      }

      // Check if the number of appointments exceeds the allowed slot amount
      return appointmentsForSlot >= slotAllowedAmount;
    } catch (error) {
      // Handle errors
      // ignore: avoid_print
      print('Error in isTimeSlotBooked: $error');
      // Return false in case of an error (consider handling errors more gracefully)
      return false;
    }
  }

//    Future<bool> isTimeSlotBooked(
//     int slotAllowedAmount,
//     String timeSlot,
//     DateTime selectedDate,
//     Map<String, Map<String, dynamic>> businessSchedule,
//   ) async {
//     try {
//       // Parse the selected time slot
//       List<int> timeComponents = timeSlot
//           .split(':')
//           .map((component) => int.parse(component.split(' ')[0]))
//           .toList();

//       // Create the selected DateTime
//       DateTime selectedDateTime = DateTime(
//         selectedDate.year, //need to fix
//         selectedDate.month,
//         selectedDate.day,
//         timeComponents[0],
//         timeComponents[1],
//       );

//       String amPm = timeSlot.substring(timeSlot.length - 2).toLowerCase();

//       List<String> timeComponents2 = [
//         timeSlot.substring(0, timeSlot.length - 2),
//         amPm,
//       ];

//       List<int> hourMinuteComponents = timeComponents2[0]
//           .split(':')
//           .map((component) => int.parse(component))
//           .toList();

//       int hour = hourMinuteComponents[0];
//       int minute = hourMinuteComponents[1];

// // Adjust the hour based on AM/PM
//       if (amPm == 'pm' && hour < 12) {
//         hour += 12;
//       } else if (amPm == 'am' && hour == 12) {
//         hour = 0;
//       }

// // Create a new DateTime for the check
//       DateTime checkDateTime = DateTime(
//         selectedDate.year, //need to fix
//         selectedDate.month,
//         selectedDate.day,
//         hour,
//         minute,
//       );

//       // Get user appointments
//       List<Appointment> userAppointments =
//           await getAppointmentsForUser(widget.businessId);

//       // Check if userAppointments is empty
//       if (userAppointments.isEmpty) {
//         // If there are no appointments, the time slot is not booked

//         return false;
//       }
//       // Check if the selected date is available based on the business schedule
//       bool isAvailable =
//           businessSchedule[getWeekdayString(checkDateTime.weekday)]
//                   ?['available'] ??
//               false;

//       if (!isAvailable) {
//         // If the selected date is not available, the time slot is booked
//         return true;
//       }

//       // Check if selectedDateTime is in the past and it's for today
//       if (checkDateTime.isBefore(DateTime.now()) &&
//           selectedDateTime.day == DateTime.now().day) {
//         return true;
//       }

//       // Iterate through user appointments
//       for (Appointment appointment in userAppointments) {
//         // Convert appointment times to local DateTime
//         DateTime appointmentStart = appointment.startTime.toLocal();

//         // Adjust appointmentStart hours if it's in PM
//         if (appointment.startTime.hour >= 12) {
//           appointmentStart =
//               appointmentStart.subtract(const Duration(hours: 12));
//         }

//         // Adjust selectedDateTime hours if it's in PM
//         DateTime adjustedSelectedDateTime = selectedDateTime;
//         if (selectedDateTime.hour >= 12) {
//           adjustedSelectedDateTime =
//               selectedDateTime.subtract(const Duration(hours: 12));
//         }

//         // Check if adjustedSelectedDateTime is within the appointment range
//         if (adjustedSelectedDateTime.isAtSameMomentAs(appointmentStart)) {
//           // The selected time slot is already booked
//           return true;
//         }
//       }

//       // If none of the conditions are met, the time slot is not booked

//       return false;
//     } catch (error) {
//       // Handle errors
//       // ignore: avoid_print
//       print('Error in isTimeSlotBooked: $error');
//       // Return false in case of an error (consider handling errors more gracefully)
//       return false;
//     }
//   }

  Future<List<Appointment>> getAppointmentsForUser(String userUid) async {
    try {
      final DatabaseReference appointmentsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userUid)
          .child('appointmentsByDate');

      final dataSnapshot = await appointmentsRef.get();

      // Check if there are any appointments for the user
      if (dataSnapshot.exists) {
        // Convert the data to a Map<String, dynamic>
        Map<dynamic, dynamic> appointmentsData =
            dataSnapshot.value as Map<dynamic, dynamic>;

        // Convert the Map to a List of Appointments
        List<Appointment> appointments = appointmentsData.entries.map((entry) {
          // Print the cancelled value for debugging

          return Appointment.fromJson({
            'userId': userUid,
            'name': entry.value['name'],
            'phone': entry.value['phone'],
            'cancelled': entry.value['cancelled'],
            'startTime': entry.value['startTime'],
            'endTime': entry.value['endTime'],
          });
        }).toList();

        // Print the original list for debugging

        // Filter out canceled appointments
        appointments = appointments
            .where((appointment) => !appointment.cancelled)
            .toList();

        // Print the filtered list for debugging
        // print('Filtered Appointments for user $userUid: $appointments');

        return appointments;
      } else {
        // If there are no appointments, return an empty list
        return [];
      }
    } catch (error) {
      // Handle errors
      // ignore: avoid_print
      print('Error fetching appointments: $error');
      // Optionally, you can throw an exception or handle the error in other ways
      return [];
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    return '${timeOfDay.hourOfPeriod}:${timeOfDay.minute.toString().padLeft(2, '0')} ${timeOfDay.period == DayPeriod.am ? 'AM' : 'PM'}';
  }
}
