import 'package:geocoding/geocoding.dart';

class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});
}

Future<LatLng?> getAddressCoordinates(String address) async {
  try {
    // Use the 'geocoding' API to get the coordinates
    List<Location> locations = await locationFromAddress(address);

    // Check if locations list is not empty
    if (locations.isNotEmpty) {
      // Access the first location (you can handle multiple results if needed)
      Location location = locations.first;

      // Get the latitude and longitude
      double latitude = location.latitude;
      double longitude = location.longitude;

      return LatLng(latitude: latitude, longitude: longitude);
    } else {
      // ignore: avoid_print
      print('No coordinates found for the address: $address');
      return null;
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error: $e');
    return null;
  }
}

class Appointment {
  final String userId;
  final String name;
  final String phone;
  final bool cancelled;
  final DateTime startTime;
  final DateTime endTime;
  String? pushId;

  Appointment({
    required this.userId,
    required this.name,
    required this.phone,
    required this.cancelled,
    required this.startTime,
    required this.endTime,
    this.pushId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      userId: json['userId'],
      name: json['name'],
      phone: json['phone'],
      cancelled: json['cancelled'],
      pushId: json['pushId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'cancelled': cancelled,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'pushId': pushId,
    };
  }
}

class Service {
  String name;
  double amount;
  String paymentType; // New property for payment type

  Service(this.name, this.amount, this.paymentType);

  // Convert Service object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'paymentType': paymentType,
    };
  }

  // Create a Service object from JSON data
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      json['name'] ?? "",
      (json['amount'] ?? 0).toDouble(),
      json['paymentType'] ?? "",
    );
  }
}
