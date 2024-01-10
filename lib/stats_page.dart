import 'package:appointments/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  StatsPageState createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  late Future<Map<String, dynamic>> pageViewsData;

  @override
  void initState() {
    super.initState();
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    if (user != null) {
      String currentUserUid = user.uid;
      pageViewsData = loadPageViews(currentUserUid, null);
    }
  }

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
          title: const Text('Reports',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 25,
              ),
              FutureBuilder<List<Appointment>>(
                future: getAppointmentsForUser(currentUserUid),
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
                    List<Appointment> userAppointments =
                        snapshot.data as List<Appointment>;

                    // Get today's date
                    DateTime now = DateTime.now();

                    // Filter appointments for today
                    List<Appointment> appointmentsToday = userAppointments
                        .where((appointment) =>
                            appointment.startTime.year == now.year &&
                            appointment.startTime.month == now.month &&
                            appointment.startTime.day == now.day)
                        .toList();

                    // Filter appointments for today
                    List<Appointment> appointmentsMonth = userAppointments
                        .where((appointment) =>
                            appointment.startTime.year == now.year &&
                            appointment.startTime.month == now.month)
                        .toList();

                    // Filter appointments for today
                    List<Appointment> appointmentsYear = userAppointments
                        .where((appointment) =>
                            appointment.startTime.year == now.year)
                        .toList();

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(
                                    color: Color(0xFF7B86E2), width: 2.0)),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Booking Appointments Data",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ),
                          ),
                          Card(
                            elevation: 4,
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                color: Color(0xFF878493),
                                width: 2.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Total",
                                              style: TextStyle(
                                                color: Color(0xFF878493),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "${userAppointments.length}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            50, // Adjust this value based on your design
                                        width: 2.0,
                                        child: VerticalDivider(
                                          color: Color(0xFF878493),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Daily",
                                              style: TextStyle(
                                                color: Color(0xFF878493),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "${appointmentsToday.length}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  color: Color(0xFF878493),
                                  thickness: 2.0,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Monthly",
                                              style: TextStyle(
                                                color: Color(0xFF878493),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "${appointmentsMonth.length}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            50, // Adjust this value based on your design
                                        width: 2.0,
                                        child: VerticalDivider(
                                          color: Color(0xFF878493),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Yearly",
                                              style: TextStyle(
                                                color: Color(0xFF878493),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "${appointmentsYear.length}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
              FutureBuilder(
                future: pageViewsData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return Container(); // Add a placeholder or error message as needed
                  } else {
                    Map<String, dynamic> pageViews =
                        snapshot.data as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Card(
                              elevation: 4,
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(
                                      color: Color(0xFF7B86E2), width: 2.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Page Views",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      "Current Date: ${DateFormat('dd-MM-yyyy').format(pageViews['date'])}",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          buildPageViewCard(
                            'Daily',
                            pageViews['daily'] ?? 0,
                            Icons.access_time,
                            'daily',
                            pageViews['date'],
                            currentUserUid,
                          ),
                          buildPageViewCard(
                            'Monthly',
                            pageViews['monthly'] ?? 0,
                            Icons.calendar_today,
                            'monthly',
                            pageViews['date'],
                            currentUserUid,
                          ),
                          buildPageViewCard(
                            'Yearly',
                            pageViews['yearly'] ?? 0,
                            Icons.timeline,
                            'yearly',
                            pageViews['date'],
                            currentUserUid,
                          ),
                          buildPageViewCard(
                            'Total',
                            pageViews['total'] ?? 0,
                            Icons.insert_chart,
                            'total',
                            DateTime.now(),
                            currentUserUid,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              FutureBuilder<PageViewsData>(
                future: getPageViews2('daily', currentUserUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Container(); // Add a placeholder or error message as needed
                  } else {
                    PageViewsData pageViewsData = snapshot.data!;

                    // Parse the dates into DateTime objects
                    List<DateTime> dateObjects =
                        pageViewsData.dates.map((dateString) {
                      return DateTime.parse(dateString);
                    }).toList();

// Create a map to associate each date with its corresponding views
                    Map<DateTime, int> viewsByDate =
                        Map.fromIterables(dateObjects, pageViewsData.counts);

// Sort the list of DateTime objects
                    dateObjects.sort();

// Create a list of views corresponding to the sorted dates
                    List<int> sortedViews = dateObjects.map((dateTime) {
                      return viewsByDate[dateTime]!;
                    }).toList();

// Convert sorted DateTime objects back to strings
                    List<String> sortedDates = dateObjects.map((dateTime) {
                      return DateFormat('yyyy-MM-dd').format(dateTime);
                    }).toList();

// Use the data in your LineChart
                    return Column(
                      children: [
                        Container(
                          height: 30,
                        ),
                        Card(
                          elevation: 4,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: const BorderSide(
                                  color: Color(0xFF7B86E2), width: 2.0)),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  "Page Views Graph",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 300,
                            child: dynamicLineChart(
                              sortedViews.toList(),
                              sortedDates.toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<Map<String, dynamic>> loadPageViews(
      String userId, DateTime? date) async {
    if (date != null) {
      return {
        'date': date,
        'daily': await getPageViews('daily', _getCurrentDate2(date), userId),
        'monthly':
            await getPageViews('monthly', _getCurrentMonth2(date), userId),
        'yearly': await getPageViews('yearly', _getCurrentYear2(date), userId),
        'total': await getPageViews('total', 'total', userId),
      };
    } else {
      return {
        'date': DateTime.now(),
        'daily': await getPageViews('daily', _getCurrentDate(), userId),
        'monthly': await getPageViews('monthly', _getCurrentMonth(), userId),
        'yearly': await getPageViews('yearly', _getCurrentYear(), userId),
        'total': await getPageViews('total', 'total', userId),
      };
    }
  }

  Future<int> getPageViews(
      String interval, String date, String currentUserUid) async {
    int pageViewsCount = 0;
    DatabaseReference viewsRef = FirebaseDatabase.instance
        .ref()
        .child('statistics')
        .child(currentUserUid)
        .child('views');
    try {
      DatabaseEvent snapshot = await viewsRef.child(interval).once();

      Map<dynamic, dynamic> pageViews = {};

      if (snapshot.snapshot.value != null) {
        pageViews = Map<dynamic, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {},
        );

        if (interval != "total" && pageViews[date] != null) {
          pageViewsCount = pageViews[date].length;
        } else if (interval == "total") {
          pageViewsCount = pageViews.keys.length;
        } else {
          pageViewsCount = 0;
        }
      }

      return pageViewsCount;
    } catch (error) {
      // ignore: avoid_print
      print('Error fetching page views: $error');
      return 0;
    }
  }

  Future<PageViewsData> getPageViews2(
      String interval, String currentUserUid) async {
    List<int> pageViewsList = [];
    List<String> datesList = [];

    DatabaseReference viewsRef = FirebaseDatabase.instance
        .ref()
        .child('statistics')
        .child(currentUserUid)
        .child('views');

    try {
      DatabaseEvent snapshot = await viewsRef.child(interval).once();

      Map<dynamic, dynamic> pageViews = {};

      if (snapshot.snapshot.value != null) {
        pageViews = Map<dynamic, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {},
        );

        if (interval == "daily" && pageViews.isNotEmpty) {
          pageViewsList = pageViews.entries.map<int>((entry) {
            datesList.add(entry.key.toString()); // Add the date to the list
            if (entry.value is List) {
              // If entry.value is a list, return its length
              return (entry.value as List).length;
            } else if (entry.value is Map) {
              // If entry.value is a map, return the length of its values
              return (entry.value as Map).values.length;
            }
            return 0; // Default value if it's neither a list nor a map
          }).toList();
        }
      }

      return PageViewsData(pageViewsList, datesList);
    } catch (error) {
      // ignore: avoid_print
      print('Error fetching page views: $error');
      return PageViewsData([], []);
    }
  }

  String _getCurrentDate() {
    return DateTime.now().toUtc().toIso8601String().split('T').first;
  }

  String _getCurrentMonth() {
    return '${DateTime.now().year}-${DateTime.now().month}';
  }

  String _getCurrentYear() {
    return DateTime.now().year.toString();
  }

  String _getCurrentDate2(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String().split('T').first;
  }

  String _getCurrentMonth2(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month}';
  }

  String _getCurrentYear2(DateTime dateTime) {
    return dateTime.year.toString();
  }

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

  Widget buildPageViewCard(String title, int count, IconData icon,
      String interval, DateTime date, String userId) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: title != 'Total' ? Colors.white : const Color(0xFF161229),
            onPressed: title != 'Total'
                ? () {
                    _navigateToPreviousDate(interval, date, userId);
                  }
                : null,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 120,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: const BorderSide(color: Color(0xFF7B86E2), width: 2.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$title Page Views',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Icon(icon, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Count: $count',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            color: title != 'Total' ? Colors.white : const Color(0xFF161229),
            onPressed: title != 'Total'
                ? () {
                    _navigateToNextDate(interval, date, userId);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _navigateToPreviousDate(
      String interval, DateTime currentDate, String userId) {
    switch (interval) {
      case 'daily':
        currentDate = currentDate.subtract(const Duration(days: 1));
        break;
      case 'monthly':
        currentDate = DateTime.utc(
          currentDate.year,
          currentDate.month - 1,
          currentDate.day,
        );
        break;
      case 'yearly':
        currentDate = DateTime.utc(
          currentDate.year - 1,
          currentDate.month,
          currentDate.day,
        );
        break;
    }

    _refreshData(interval, currentDate, userId);
  }

  void _navigateToNextDate(
      String interval, DateTime currentDate, String userId) {
    switch (interval) {
      case 'daily':
        currentDate = currentDate.add(const Duration(days: 1));
        break;
      case 'monthly':
        currentDate = DateTime.utc(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
        break;
      case 'yearly':
        currentDate = DateTime.utc(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
        break;
    }

    _refreshData(interval, currentDate, userId);
  }

  Future<void> _refreshData(
      String interval, DateTime date, String userId) async {
    setState(() {
      pageViewsData = loadPageViews(userId, date);
    });
  }

  Widget dynamicLineChart(List<int> data, List<String> dates) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,

              interval: 1, // Adjust as needed
              getTitlesWidget: (value, _) {
                return Text(value.toString(),
                    style: const TextStyle(color: Colors.white));
              },
            )),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, _) {
                  if (dates.length >= 2) {
                    if (value == 0) {
                      // Show the first date
                      return Text(
                        dates.first.toString(),
                        style: const TextStyle(color: Colors.white),
                      );
                    } else if (value == dates.length - 1) {
                      // Show the last date
                      return Text(
                        dates.last.toString(),
                        style: const TextStyle(color: Colors.white),
                      );
                    }
                  }
                  return Container();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: false,
            horizontalInterval: 1,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return const FlLine(color: Colors.white, strokeWidth: 0.5);
            },
            getDrawingVerticalLine: (value) {
              return const FlLine(color: Colors.white, strokeWidth: 0.5);
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.toDouble());
              }).toList(),
              isCurved: true,
              color: const Color(0xFF7B86E2),
              belowBarData: BarAreaData(show: false),
              aboveBarData: BarAreaData(show: false),
              dotData: const FlDotData(show: true),
              barWidth: 8.0,
              isStrokeCapRound: true,
            ),
          ],
        ),
      ),
    );
  }
}

class PageViewsData {
  final List<int> counts;
  final List<String> dates;

  PageViewsData(this.counts, this.dates);
}
