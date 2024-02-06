import 'dart:async';

import 'package:appointments/helpers/helpers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  final String userId; // Add any other necessary parameters

  const EarningsPage({Key? key, required this.userId}) : super(key: key);

  @override
  EarningsPageState createState() => EarningsPageState();
}

class EarningsPageState extends State<EarningsPage> {
  late int selectedYear;
  late int selectedMonth;
  double shekelsEarnings = 0.0;
  double dollarsEarnings = 0.0;
  double eurosEarnings = 0.0;
  Completer<void>? _calculateEarningsCompleter;

  @override
  void initState() {
    super.initState();

    // Initialize selectedYear with the current year
    selectedYear = DateTime.now().year;
    // Initialize selectedMonth with the current month
    selectedMonth = DateTime.now().month;
    _calculateAndShowEarnings2();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161229),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B86E2),
        title: const Text('Earnings Page',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            _buildDatePicker(),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
                ),
                minimumSize: const Size(150, 80.0),
              ),
              onPressed: () {
                _calculateAndShowEarnings2();
              },
              child: const Text(
                'Calculate Earnings',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            _buildEarningsInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          FontAwesomeIcons.calendarDays,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          dropdownColor: const Color(0xFF7B86E2),
          value: selectedYear,
          items: List.generate(10, (index) {
            return DropdownMenuItem<int>(
              value: DateTime.now().year - index,
              child: Text(
                '${DateTime.now().year - index}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }),
          onChanged: (value) {
            setState(() {
              selectedYear = value!;
            });
          },
        ),
        const SizedBox(width: 16),
        DropdownButton<int>(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          dropdownColor: const Color(0xFF7B86E2),
          value: selectedMonth,
          items: List.generate(12, (index) {
            return DropdownMenuItem<int>(
              value: index + 1,
              child: Text(
                _getMonthName(index + 1),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }),
          onChanged: (value) {
            setState(() {
              selectedMonth = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEarningsInfo() {
    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
        side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Earnings for ${_getMonthName(selectedMonth)}:',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const Divider(
            color: Color(0xFF878493),
          ),
          const SizedBox(height: 8),
          _buildEarningsRow(
              'Shekels', shekelsEarnings, FontAwesomeIcons.shekelSign),
          const SizedBox(height: 8),
          const Divider(
            color: Color(0xFF878493),
          ),
          const SizedBox(height: 8),
          _buildEarningsRow(
              'Dollars', dollarsEarnings, FontAwesomeIcons.dollarSign),
          const SizedBox(height: 8),
          const Divider(
            color: Color(0xFF878493),
          ),
          const SizedBox(height: 8),
          _buildEarningsRow('Euros', eurosEarnings, FontAwesomeIcons.euroSign),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(
      String currency, double earnings, IconData iconData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          iconData,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Text(
          '$currency: $earnings',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }

  Future<double> calculateEarningsForMonth(
    String userId,
    int year,
    int month,
    String selectedCurrency,
  ) async {
    try {
      if (_calculateEarningsCompleter != null &&
          !_calculateEarningsCompleter!.isCompleted) {
        _calculateEarningsCompleter!.completeError('Cancelled');
      }

      _calculateEarningsCompleter = Completer<void>();

      final DatabaseReference appointmentsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('appointmentsByDate');

      DatabaseEvent snapshot = await appointmentsRef.once();
      Map<dynamic, dynamic> earnings = {};

      if (snapshot.snapshot.value != null) {
        earnings = Map<dynamic, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {},
        );

        double totalEarnings = 0.0;

        // Loop through appointments and calculate earnings for the specified month
        earnings.forEach((key, appointmentData) {
          Appointment appointment = Appointment.fromJson(appointmentData);

          // Check if the appointment is in the specified month
          if (appointment.startTime.year == year &&
              appointment.startTime.month == month &&
              appointment.service.paymentType == selectedCurrency) {
            totalEarnings += appointment.service.amount;
          }
        });

        return totalEarnings;
      }

      return 0;
    } catch (e) {
      rethrow; // Rethrow the exception after completing the completer
    } finally {
      _completeCalculations(); // Complete calculations and trigger UI update
    }
  }

  void _completeCalculations() {
    if (!_calculateEarningsCompleter!.isCompleted) {
      _calculateEarningsCompleter!.complete();

      if (mounted) {
        setState(() {
          // Trigger a rebuild to update the UI with the calculated earnings
        });
      }
    }
  }

  void _calculateAndShowEarnings2() async {
    try {
      shekelsEarnings = await calculateEarningsForMonth(
        widget.userId,
        selectedYear,
        selectedMonth,
        'Shekels',
      );

      dollarsEarnings = await calculateEarningsForMonth(
        widget.userId,
        selectedYear,
        selectedMonth,
        'Dollars',
      );

      eurosEarnings = await calculateEarningsForMonth(
        widget.userId,
        selectedYear,
        selectedMonth,
        'Euros',
      );
    } catch (e) {
      // Handle cancellation or other errors here
    } finally {
      _completeCalculations(); // Complete calculations and trigger UI update
    }
  }

  // String _getMonthName(int month) {
  //   return DateTime(selectedYear, month).toString().split(' ')[0];
  // }

  String _getMonthName(int month) {
    DateTime dateTime = DateTime(selectedYear, month);
    return DateFormat('MM.yyyy').format(dateTime);
  }
}
