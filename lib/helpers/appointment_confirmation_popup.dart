import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class AppointmentConfirmationPopup extends StatelessWidget {
  final String businessName;
  final DateTime startTime;

  const AppointmentConfirmationPopup({
    super.key,
    required this.businessName,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    String formattedTime =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    String formattedDate = DateFormat('yyyy-MM-dd').format(startTime);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 66),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: const Color(0xFF161229),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Appointment Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B86E2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Business Name: $businessName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: $formattedDate',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time: $formattedTime',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the pop-up
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF878493),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  addToCalendar(businessName, startTime, context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B86E2),
                ),
                child: const Text(
                  'Add to Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Color(0xFF7B86E2),
            radius: 30,
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}

// Function to add the appointment to the user's calendar
void addToCalendar(
    String businessName, DateTime startTime, BuildContext context) {
  final Event event = Event(
    title: 'Appointment with $businessName',
    description: 'Business Name: $businessName',
    location: 'Appointment Location', // You can adjust this as needed
    startDate: startTime,
    endDate: startTime.add(const Duration(minutes: 30)), // Adjust as needed
  );

  Add2Calendar.addEvent2Cal(event).then((success) {
    if (success) {
      // Calendar event added successfully
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added to calendar.')),
        );
      }
    } else {
      // Error adding event to calendar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding event to calendar')),
        );
      }
    }
  });
}
