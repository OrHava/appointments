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
  final Service service; // Include a Service property

  Appointment({
    required this.userId,
    required this.name,
    required this.phone,
    required this.cancelled,
    required this.startTime,
    required this.endTime,
    required this.service,
    this.pushId,
  });

  factory Appointment.fromJson(Map<dynamic, dynamic> json) {
    return Appointment(
      userId: json['userId'],
      name: json['name'],
      phone: json['phone'],
      cancelled: json['cancelled'],
      pushId: json['pushId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      service: json['service'] != null
          ? _parseService(json['service'])
          : Service('', 0, ''),
    );
  }

  static Service _parseService(dynamic serviceData) {
    if (serviceData is Map<dynamic, dynamic>) {
      return Service.fromJson(serviceData);
    } else {
      // Handle the case where the service data is not in the expected format
      // You might want to log an error or return a default Service instance
      return Service('', 0, '');
    }
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
      'service': service.toJson(), // Serialize the 'service' property
    };
  }
}

class Service {
  String name;
  double amount;
  String paymentType; // New property for payment type

  Service(this.name, this.amount, this.paymentType);

  // Convert Service object to JSON format
  Map<dynamic, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'paymentType': paymentType,
    };
  }

  // Create a Service object from JSON data
  factory Service.fromJson(Map<dynamic, dynamic> json) {
    return Service(
      json['name'] ?? "",
      (json['amount'] ?? 0).toDouble(),
      json['paymentType'] ?? "",
    );
  }
}
