import 'dart:collection';

import 'package:appointments/home_page.dart';
import 'package:appointments/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'helpers.dart';
import 'home_page_business.dart';
import 'dart:async';
import 'main.dart';

class UserProfile {
  final String uid;
  final String userType;
  final String fullName;
  final String phoneNumber;
  final String businessName;
  final String businessFullAddress; //new
  final String businessAppointmentPolicies; //new
  final List<String> businessServicesOffered; //new
  final List<String> businessPhotos; //new
  final String businessInfo;
  final String ownerName;
  final String businessLocation;
  final String businessType;
  double businessRating;
  List<String> ratedUserIds;
  Map<String, double> ratings; // New field to store ratings for each user
  List<String> blockedUserIds;
  List<Service> services;
  final int slotDurationInMinutes;
  final int slotAllowedAmount;
  late final String? photoUrl;
  final Map<String, Map<String, dynamic>> businessSchedule;
  final Map<String, List<Appointment>>? appointmentsByDate;

  UserProfile({
    required this.uid,
    required this.userType,
    required this.fullName,
    required this.phoneNumber,
    required this.businessName,
    required this.businessInfo,
    required this.businessLocation,
    required this.businessType,
    required this.slotAllowedAmount,
    required this.businessFullAddress,
    required this.businessAppointmentPolicies,
    required this.businessServicesOffered,
    required this.businessPhotos,
    required this.ownerName,
    required this.businessSchedule,
    required this.slotDurationInMinutes,
    required this.businessRating,
    required this.ratedUserIds,
    required this.ratings,
    required this.blockedUserIds,
    required this.services,
    this.appointmentsByDate,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userType': userType,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'businessName': businessName,
      'businessInfo': businessInfo,
      'businessLocation': businessLocation,
      'businessType': businessType,
      'businessFullAddress': businessFullAddress,
      'businessAppointmentPolicies': businessAppointmentPolicies,
      'businessServicesOffered': businessServicesOffered,
      'businessPhotos': businessPhotos,
      'slotDurationInMinutes': slotDurationInMinutes,
      'businessRating': businessRating,
      'ratedUserIds': ratedUserIds,
      'ratings': ratings,
      'slotAllowedAmount': slotAllowedAmount,
      'blockedUserIds': blockedUserIds,
      'ownerName': ownerName,
      'photoUrl': photoUrl,
      'businessSchedule': _convertBusinessScheduleToJson(),
      'appointmentsByDate': appointmentsByDate,
      'services': services.map((service) => service.toJson()).toList(),
    };
  }

  factory UserProfile.fromJson(Map<dynamic, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? "",
      userType: json['userType'] ?? "",
      fullName: json['fullName'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      businessName: json['businessName'] ?? "",
      businessInfo: json['businessInfo'] ?? "",
      slotAllowedAmount: json['slotAllowedAmount'] ?? 1,
      businessLocation: json['businessLocation'] ?? "",
      slotDurationInMinutes: json['slotDurationInMinutes'] ?? 30,
      businessFullAddress: json['businessFullAddress'] ?? "",
      businessRating: (json['businessRating'] ?? 0).toDouble(),
      ratedUserIds: List<String>.from(json['ratedUserIds'] ?? []),
      ratings: Map<String, double>.from(json['ratings']
              ?.map((key, value) => MapEntry(key, (value ?? 0).toDouble())) ??
          {}),

      businessAppointmentPolicies: json['businessAppointmentPolicies'] ?? "",
      businessServicesOffered:
          List<String>.from(json['businessServicesOffered'] ?? []), // new
      businessPhotos: List<String>.from(json['businessPhotos'] ?? []), // new
      blockedUserIds: List<String>.from(json['blockedUserIds'] ?? []),

      businessType: json['businessType'] ?? "",
      ownerName: json['ownerName'] ?? "",
      photoUrl: json['photoUrl'],
      appointmentsByDate:
          _convertJsonToAppointments(json['appointmentsByDate']),
      businessSchedule:
          _convertJsonToBusinessSchedule(json['businessSchedule'] ?? {}),
      services: (json['services'] as List<dynamic>?)?.map((serviceJson) {
            return Service(serviceJson['name'],
                serviceJson['amount'].toDouble(), serviceJson['paymentType']);
          }).toList() ??
          [], // Populate services from JSON
    );
  }

  static Map<String, Map<String, dynamic>> _convertJsonToBusinessSchedule(
    Map<dynamic, dynamic> json,
  ) {
    Map<String, Map<String, dynamic>> result = {};

    json.forEach((day, schedule) {
      result[day.toString()] = {
        'opening': _convertJsonToTimeOfDay(schedule?['opening']),
        'closing': _convertJsonToTimeOfDay(schedule?['closing']),
        'available': schedule['available'] ?? true, // Add 'available' property
      };
    });

    return result;
  }

  static Map<String, List<Appointment>>? _convertJsonToAppointments(
    Map<dynamic, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }

    Map<String, List<Appointment>> result = {};

    json.forEach((day, appointments) {
      if (appointments is List) {
        result[day.toString()] = appointments
            .map((appointment) => Appointment.fromJson(appointment))
            .toList();
      }
    });

    return result;
  }

  static TimeOfDay _convertJsonToTimeOfDay(Object? json) {
    if (json == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    final Map<dynamic, dynamic> timeJson = json as Map<dynamic, dynamic>;
    final int hour = timeJson['hour'] as int;
    final int? minute = timeJson['minute'] as int?;

    // Ensure that minute is not null and within the valid range
    return TimeOfDay(hour: hour, minute: minute ?? 0);
  }

  Map<String, dynamic> _convertBusinessScheduleToJson() {
    Map<String, dynamic> result = {};

    businessSchedule.forEach((day, schedule) {
      result[day] = {
        'opening': _convertTimeOfDayToJson(schedule['opening']!),
        'closing': _convertTimeOfDayToJson(schedule['closing']!),
      };
    });

    return result;
  }

  Map<String, dynamic> _convertTimeOfDayToJson(TimeOfDay timeOfDay) {
    return {
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };
  }
}

class FirstTimeSignUpPage extends StatefulWidget {
  const FirstTimeSignUpPage({Key? key}) : super(key: key);

  @override
  FirstTimeSignUpPageState createState() => FirstTimeSignUpPageState();
}

class FirstTimeSignUpPageState extends State<FirstTimeSignUpPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessInfoController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController businessFullAddressController =
      TextEditingController();
  final TextEditingController businessAppointmentPoliciesController =
      TextEditingController();
  final TextEditingController businessAppointmentAmountAllowed =
      TextEditingController();

  final TextEditingController businessPhotosController =
      TextEditingController();

  List<Service> services = [];

  TextEditingController serviceNameController = TextEditingController();
  TextEditingController serviceAmountController = TextEditingController();
  String selectedPaymentType = 'Shekels'; // Default payment type

  final StreamController<double> _progressController =
      StreamController<double>();
  Stream<double> get uploadProgressStream => _progressController.stream;

  @override
  void initState() {
    super.initState();

    // Fetch user profile data when the page is created
    _loadUserProfile();
  }

  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }

  String userType = ""; // Default to user
  dynamic selectedImage;
  late List<dynamic> selectedImages = [];
  static const String defaultProfileImageAsset = 'images/background_image.jpg';
  String? selectedDay;
  String? selectedBusinessType = 'Salon';
  String? selectedBusinessLocation = 'Tel Aviv';
  int? selectedslotDurationInMinutes = 30;
  int? selectedslotAllowed = 1;
  LinkedHashMap<String, Map<String, dynamic>> businessSchedule =
      LinkedHashMap<String, Map<String, dynamic>>.from({
    "Monday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
    "Tuesday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
    "Wednesday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
    "Thursday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
    "Friday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
    "Saturday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
    "Sunday": {
      "available": true,
      "opening": const TimeOfDay(hour: 9, minute: 0),
      "closing": const TimeOfDay(hour: 19, minute: 0),
    },
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final key = UniqueKey();
                        runApp(MyApp(key: key));
                      },
                      icon: const Icon(
                        Icons
                            .home, // You can use Icons.clear for a slightly different icon
                        color: Color(0xFF878493), // Set the color as needed
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    IconButton(
                      onPressed: () {
                        if (context.mounted) {
                          // Redirect the user to the user page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInScreen()),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons
                            .login, // You can use Icons.clear for a slightly different icon
                        color: Color(0xFF878493), // Set the color as needed
                      ),
                    ),
                  ],
                ),
                if (userType.isEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Choose your role",
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRoleButton(
                            icon: FontAwesomeIcons.user,
                            label: 'User',
                            onPressed: () {
                              setState(() {
                                userType = "user";
                              });
                            },
                          ),
                          _buildRoleButton(
                            icon: FontAwesomeIcons.store,
                            label: 'Business',
                            onPressed: () {
                              setState(() {
                                userType = "business";
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 70),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image.asset(
                            'images/icon_app_cute_bigger.png',
                            width: 250.0,
                            height: 250.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (userType == "user")
                  _buildUserForm()
                else if (userType == "business")
                  _buildBusinessForm()
                else if (userType == "business+1")
                  _buildBusinessForm1(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
        ),
        minimumSize: const Size(150, 100.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            color: const Color(0xFF878493),
          ),
          const SizedBox(width: 25.0),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    InputDecoration buildInputDecoration(
        String labelText, IconData prefixIcon) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF878493),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF878493),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF878493), // Color of the line
            width: 1.0, // Thickness of the line
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF878493), // Color of the line when focused
            width: 1.0, // Thickness of the line when focused
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "User information",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Optional: Enter your user information so that the business can better know their clients.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.0,
            color: Color(0xFF878493),
          ),
        ),
        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Basic information",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: fullNameController,
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          decoration: buildInputDecoration('Full Name', FontAwesomeIcons.user),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneNumberController,
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          keyboardType: TextInputType.phone,
          decoration:
              buildInputDecoration('Phone Number', FontAwesomeIcons.phone),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: pickImage,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
              (states) => const Color(0xFF7B86E2),
            ),
          ),
          child: const Text("Pick User Photo"),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: selectedImage != null
                  ? _getImageProvider(selectedImage!)
                  : const NetworkImage(
                      'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=150&d=mp&r=pg'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _validateAndSaveUserProfile(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B86E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: const Text("Save"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userType = "";
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: const Text(
                "Back",
                style: TextStyle(color: Color(0xFF7B86E2)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _validateAndSaveUserProfile(BuildContext context) {
    // Check if the text controllers have non-empty values
    if (phoneNumberController.text.isEmpty || fullNameController.text.isEmpty) {
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both phone number and full name.'),
        ),
      );
    } else {
      // If both fields are not empty, proceed to save the user profile
      _saveUserProfile(context);
    }
  }

  Widget _buildBusinessForm() {
    InputDecoration buildInputDecoration(
        String labelText, IconData prefixIcon) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF878493),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF878493),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF878493), // Color of the line
            width: 1.0, // Thickness of the line
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF878493), // Color of the line when focused
            width: 1.0, // Thickness of the line when focused
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Customize your booking page",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Edit the page and what your clients see on the booking app/website.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.0,
            color: Color(0xFF878493),
          ),
        ),
        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Basic information",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          controller: businessNameController,
          decoration:
              buildInputDecoration('Business Name', FontAwesomeIcons.store),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: businessInfoController,
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          decoration:
              buildInputDecoration('Business Info', FontAwesomeIcons.info),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedBusinessType,
          onChanged: (String? value) {
            setState(() {
              selectedBusinessType = value!;
            });
          },
          items: businessTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: const TextStyle(
                  color: Colors.white, // Set the text color for selected item
                ),
              ),
            );
          }).toList(),
          style: const TextStyle(
            color: Colors.black, // Set the text color for the dropdown menu
          ),
          dropdownColor: Colors.black,
          decoration: buildInputDecoration(
              'Business Type', FontAwesomeIcons.businessTime),
        ),
        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Contact information",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: ownerNameController,
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          decoration: buildInputDecoration('Owner Name', FontAwesomeIcons.user),
        ),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          controller: phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration:
              buildInputDecoration('Phone Number', FontAwesomeIcons.phone),
        ),
        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Business Address",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          value: selectedBusinessLocation,
          onChanged: (String? value) {
            setState(() {
              selectedBusinessLocation = value!;
            });
          },
          items: businessLocations.map((String location) {
            return DropdownMenuItem<String>(
              value: location,
              child: Text(
                location,
                style: const TextStyle(
                  color: Colors.white, // Set the text color for selected item
                ),
              ),
            );
          }).toList(),
          style: const TextStyle(
            color: Colors.black, // Set the text color for the dropdown menu
          ),
          dropdownColor: Colors.black,
          decoration: buildInputDecoration(
              'Business Location', FontAwesomeIcons.locationDot),
        ),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          controller: businessFullAddressController,
          keyboardType: TextInputType.streetAddress,
          decoration: buildInputDecoration(
              'Business Full Address', FontAwesomeIcons.locationDot),
        ),
        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Business additional information",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        DropdownButtonFormField<int>(
          value: selectedslotDurationInMinutes,
          onChanged: (int? value) {
            setState(() {
              selectedslotDurationInMinutes = value!;
            });
          },
          items: businessSlotDurationInMinutes.map((int time) {
            return DropdownMenuItem<int>(
              value: time,
              child: Text(
                time.toString(),
                style: const TextStyle(
                  color: Colors.white, // Set the text color for selected item
                ),
              ),
            );
          }).toList(),
          style: const TextStyle(
            color: Colors.black, // Set the text color for the dropdown menu
          ),
          dropdownColor: Colors.black,
          decoration: buildInputDecoration(
              'Slot duration in minutes', FontAwesomeIcons.timeline),
        ),

        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          controller: businessAppointmentAmountAllowed,
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          decoration: buildInputDecoration(
              'Amount of appointmeants per time slot.',
              FontAwesomeIcons.peopleGroup),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: businessAppointmentPoliciesController,
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          decoration: buildInputDecoration(
              'Business Appointment Policies', FontAwesomeIcons.calendarCheck),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Business services",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Text fields for adding a new service
        TextField(
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          controller: serviceNameController,
          decoration: buildInputDecoration(
              'Service Name', FontAwesomeIcons.screwdriverWrench),
        ),
        TextField(
          style: const TextStyle(
            color: Colors.white, // Set the text color
          ),
          controller: serviceAmountController,
          decoration: buildInputDecoration(
              'Service Amount', FontAwesomeIcons.moneyBill),
        ),
        // Dropdown for selecting payment type
        DropdownButton<String>(
          value: selectedPaymentType,
          items: ['Shekels', 'Dollars', 'Euros'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedPaymentType = newValue!;
            });
          },
          dropdownColor:
              const Color(0xFF161229), // Set the dropdown menu background color
        ),

        // Button to add a new service
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
              (states) => const Color(0xFF7B86E2),
            ),
          ),
          onPressed: () {
            setState(() {
              final serviceName = serviceNameController.text;
              final serviceAmount =
                  _parseServiceAmount(serviceAmountController.text.trim());
              if (serviceAmount != null) {
                services.add(
                  Service(serviceName, serviceAmount, selectedPaymentType),
                );
              }

              // Clear the text fields after adding a service
              serviceNameController.clear();
              serviceAmountController.clear();
            });
          },
          child: const Text('Add Service'),
        ),

        SizedBox(
          width: double.infinity,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              String currencySymbol = getCurrencySymbol(service.paymentType);
              return Dismissible(
                key: UniqueKey(),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  // Remove the item from the data and rebuild the UI
                  setState(() {
                    services.removeAt(index);
                  });
                },
                child: ListTile(
                  trailing: Text('$currencySymbol${service.amount}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white)),
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

        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft, // Align the text to the left

          child: Text(
            "Pictures",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF878493),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
              (states) => const Color(0xFF7B86E2),
            ),
          ),
          onPressed: pickImage,
          child: const Text("Pick Business Logo"),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: selectedImage != null
                  ? _getImageProvider(selectedImage!)
                  : const NetworkImage(
                      'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=150&d=mp&r=pg'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(
              (states) => const Color(0xFF7B86E2),
            ),
          ),
          onPressed: pickImages,
          child: const Text("Pick Business Photos"),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          children: _getImagesWidgets(selectedImages),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userType = "business+1";
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B86E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: const Text("Next"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userType = "";
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: const Text(
                "Back",
                style: TextStyle(color: Color(0xFF7B86E2)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessForm1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Business schedule",
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // Add your input fields for days and hours here

        for (var day in businessSchedule.keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  // checkColor: const Color(0xFF7B86E2),
                  checkColor: Colors.black,
                  fillColor: MaterialStateColor.resolveWith(
                      (Set<MaterialState> states) {
                    // This is the color of the checkbox
                    return const Color(0xFF7B86E2);
                  }),
                  value: businessSchedule[day]!["available"] ?? true,
                  onChanged: (value) {
                    setState(() {
                      businessSchedule[day]!["available"] = value;
                    });
                  },
                ),
                SizedBox(
                  width: 100, // Set the desired width

                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                DropdownButton<TimeOfDay>(
                  dropdownColor: Colors.black,
                  value: businessSchedule[day]!["opening"],
                  onChanged: (value) {
                    setState(() {
                      businessSchedule[day]!["opening"] = value!;
                    });
                  },
                  items: _buildTimePickerItems(),
                ),
                const SizedBox(width: 16),
                const Text(
                  "-",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<TimeOfDay>(
                  dropdownColor: Colors.black,
                  value: businessSchedule[day]!["closing"],
                  onChanged: (value) {
                    setState(() {
                      businessSchedule[day]!["closing"] = value!;
                    });
                  },
                  items: _buildTimePickerItems(),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Column(
          children: [
            ElevatedButton(
              onPressed: () {
                userType = "business";
                _saveUserProfile(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B86E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userType = "business";
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
                ),
                minimumSize: const Size(150, 50),
              ),
              child: const Text(
                "Back",
                style: TextStyle(color: Color(0xFF7B86E2)),
              ),
            ),
          ],
        ),
      ],
    );
  }

// Function to pick multiple images
  Future<void> pickImages() async {
    List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();

    List<File> images = [];
    for (XFile file in pickedFiles) {
      images.add(File(file.path));
    }

    setState(() {
      selectedImages = images;
    });
  }

// Function to display selected images
  List<Widget> _getImagesWidgets(List<dynamic> images) {
    return images.map((image) {
      return Container(
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
      );
    }).toList();
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

  ImageProvider<Object> _getImageProvider(dynamic image) {
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

  List<DropdownMenuItem<TimeOfDay>> _buildTimePickerItems() {
    const int step = 15; // Step size for time picker (in minutes)
    final List<DropdownMenuItem<TimeOfDay>> items = [];

    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += step) {
        final time = TimeOfDay(hour: hour, minute: minute);
        items.add(DropdownMenuItem(
          value: time, // Use the 'time' variable directly
          child: Text(
            time.format(context),
            style: const TextStyle(
              color: Colors.white, // Set the text color for selected item
            ),
          ),
        ));
      }
    }
    return items;
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

  List<String> businessLocations = [
    'Tel Aviv',
    'Jerusalem',
    'Haifa',
    'Eilat',
    'Beersheba',
    'Netanya',
    'Herzliya',
    'Rishon LeZion',
    'Petah Tikva',
    'Other',
  ];

  List<int> businessSlotDurationInMinutes = [
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    110,
    120,
    130,
    140,
    150,
    160,
    170,
    180,
    190,
  ];
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      selectedImage = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  Future<void> _loadUserProfile() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      try {
        // Fetch user profile data from the database
        final userProfileData = await getUserProfile(user.uid);

        // Check if user profile data is available
        if (userProfileData != null) {
          // Populate the text fields with user profile data
          fullNameController.text = userProfileData['fullName'] ?? '';
          phoneNumberController.text = userProfileData['phoneNumber'] ?? '';
          businessNameController.text = userProfileData['businessName'] ?? '';
          businessInfoController.text = userProfileData['businessInfo'] ?? '';
          ownerNameController.text = userProfileData['ownerName'] ?? '';

          selectedBusinessLocation = userProfileData['businessLocation'] ?? '';
          selectedBusinessType = userProfileData['businessType'] ?? '';
          selectedslotDurationInMinutes =
              userProfileData['slotDurationInMinutes'] ?? '';

          businessFullAddressController.text =
              userProfileData['businessFullAddress'] ?? '';
          businessAppointmentPoliciesController.text =
              userProfileData['businessAppointmentPolicies'] ?? '';
          businessAppointmentAmountAllowed.text =
              userProfileData['slotAllowedAmount']?.toString() ?? '1';

          businessPhotosController.text =
              (userProfileData['businessPhotos'] as List<Object?>?)
                      ?.map((element) => element?.toString() ?? '')
                      .join(', ') ??
                  '';

          // If a photo URL is available, set the selectedImage
          if (userProfileData['photoUrl'] != null) {
            setState(() {
              selectedImage = null; // Clear the local image
            });

            // Use NetworkImage to load the image directly from the URL
            setState(() {
              selectedImage = userProfileData['photoUrl'];
            });
          }

          if (userProfileData['services'] != null) {
            List<dynamic> servicesData = userProfileData['services'];

            setState(() {
              services = servicesData
                  .map((data) => Service(
                        data['name'],
                        data['amount'].toDouble(),
                        data['paymentType'],
                      ))
                  .toList();
            });
          }
          // Use NetworkImage to load the images directly from the URLs

          if (userProfileData['businessPhotos'] is List<dynamic>) {
            List<dynamic> businessPhotos = userProfileData['businessPhotos'];

            for (String photoUrl in businessPhotos) {
              if (photoUrl.isNotEmpty) {
                setState(() {
                  selectedImages.add(photoUrl);
                });
              }
            }
          }

          // Load businessSchedule
          if (userProfileData['businessSchedule'] != null) {
            setState(() {
              businessSchedule =
                  LinkedHashMap<String, Map<String, dynamic>>.from(
                      UserProfile._convertJsonToBusinessSchedule(
                          userProfileData['businessSchedule']));
            });
          }
        }
      } catch (error) {
        // Handle errors
        // ignore: avoid_print
        print("Error aviv: $error");
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
        //   print("Received user data: ${snapshot.value}");

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
        print("User profile not found");
        return null;
      }
    } catch (error) {
      // Handle errors here
      // ignore: avoid_print
      print("Error retrieving user profile for user $userId: $error");
      return null;
    }
  }

  Map<String, dynamic> _convertBusinessScheduleToJson(
    LinkedHashMap<String, Map<dynamic, dynamic>> businessSchedule,
  ) {
    Map<String, dynamic> result = {};

    businessSchedule.forEach((day, schedule) {
      result[day] = {
        'opening': _convertTimeOfDayToJson(schedule['opening']!),
        'closing': _convertTimeOfDayToJson(schedule['closing']!),
        'available': schedule['available'] ?? true, // Add 'available' property
      };
    });

    return result;
  }

  Map<String, dynamic> _convertTimeOfDayToJson(TimeOfDay timeOfDay) {
    return {
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };
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

  Future<void> _saveUserProfile(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      try {
        // Inside _saveUserProfile function
        List<String> businessPhotoUrls = [];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ProgressDialog(
                uploadProgressStream: _progressController.stream);
          },
        );

        if (selectedImages is List<File> && selectedImages.isNotEmpty) {
          int totalImages = selectedImages.length;
          int uploadedImages = 0;

          for (File image in selectedImages) {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('users')
                .child(user.uid)
                .child('business_photos')
                .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

            final uploadTask = storageRef.putFile(image);

            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              double progress =
                  snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
              _progressController.add(progress);
            });

            await uploadTask;

            final imageUrl = await storageRef.getDownloadURL();
            businessPhotoUrls.add(imageUrl);

            uploadedImages++;

            // Calculate overall progress for all images
            double overallProgress = uploadedImages / totalImages.toDouble();
            _progressController.add(overallProgress);
          }

          businessPhotosController.text = businessPhotoUrls.join(',');
        }

        String? imageUrl; // Declare imageUrl variable

// Check if selectedImage is a File or a String
        if (selectedImage is File && selectedImage != null) {
          // Upload image to Firebase Storage if it's a File
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users')
              .child(user.uid)
              .child('profile_image.jpg');

          final uploadTask = storageRef.putFile(selectedImage!);

          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            double progress =
                snapshot.bytesTransferred / snapshot.totalBytes.toDouble();
            _progressController.add(progress);
          });

          await uploadTask;

          // Get the download URL of the uploaded image
          imageUrl = await storageRef.getDownloadURL();

          // Report the completion of the profile image upload
          _progressController.add(1.0);
        } else if (selectedImage is String) {
          // Use it directly as the URL if it's a String (URL)
          imageUrl = selectedImage;

          // No need to report progress for a URL, consider it as complete
          _progressController.add(1.0);
        }

        List<Map<String, dynamic>> servicesData = services
            .map((service) => {
                  'name': service.name,
                  'amount': service.amount,
                  'paymentType': service.paymentType,
                })
            .toList();

        Map<String, dynamic> updateData = {
          'uid': user.uid,
          'userType': userType,
          'fullName': fullNameController.text.trim(),
          'phoneNumber': phoneNumberController.text.trim(),
          'businessName': businessNameController.text.trim(),
          'businessInfo': businessInfoController.text.trim(),
          'businessLocation': selectedBusinessLocation!.trim(),
          'businessType': selectedBusinessType!.trim(),
          'ownerName': ownerNameController.text.trim(),
          'businessSchedule': _convertBusinessScheduleToJson(businessSchedule),
          'slotDurationInMinutes': selectedslotDurationInMinutes,
          'photoUrl': imageUrl,
          'businessFullAddress': businessFullAddressController.text.trim(),
          'businessAppointmentPolicies':
              businessAppointmentPoliciesController.text.trim(),
          'slotAllowedAmount': _parseSlotAllowedAmount(
              businessAppointmentAmountAllowed.text.trim()),
          'services': servicesData,
          'businessPhotos': businessPhotosController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
        };

        // Save UserProfile to Realtime Database
        final DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(user.uid);
        await userRef.update(updateData);

        // Navigate to the appropriate page based on userType
        if (context.mounted) {
          if (userType == "user") {
            // Redirect the user to the user page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomePage(pageNumber: 0)),
            );
          } else {
            // Redirect the user to the business page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomePageBusiness(pageNumber: 0)),
            );
          }
        }
      } catch (error) {
        // Handle errors
        // ignore: avoid_print
        print("Error: $error");
      }
    }
  }

  static double? _parseServiceAmount(String input) {
    if (input.isNotEmpty) {
      try {
        return double.parse(input);
      } catch (e) {
        // Handle the case where parsing fails (e.g., input is not a valid double)
        // ignore: avoid_print
        print('Error parsing serviceAmount: $e');
      }
    } else {
      // Handle the case where the input is empty
      // ignore: avoid_print
      print('Input for serviceAmount is empty');
    }

    // Return null if parsing fails or input is empty
    return 0;
  }

  int? _parseSlotAllowedAmount(String input) {
    if (input.isNotEmpty) {
      try {
        return int.parse(input);
      } catch (e) {
        // Handle the case where parsing fails (e.g., input is not a valid integer)
        // ignore: avoid_print
        print('Error parsing slotAllowedAmount: $e');
      }
    } else {
      // Handle the case where the input is empty
      // ignore: avoid_print
      print('Input for slotAllowedAmount is empty');
    }

    // Return null if parsing fails or input is empty
    return 1;
  }
}

class ProgressDialog extends StatelessWidget {
  final Stream<double> uploadProgressStream;

  const ProgressDialog({super.key, required this.uploadProgressStream});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<double>(
              stream: uploadProgressStream,
              builder: (context, snapshot) {
                double progress = snapshot.data ?? 0.0;
                int percentage = (progress * 100).round();

                // For simplicity, let's assume a constant upload speed
                int estimatedTimeInSeconds = ((1 - progress) * 60).round();

                return Column(
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text("Uploading the Pictures... $percentage%"),
                    Text("Estimated Time: $estimatedTimeInSeconds seconds"),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
