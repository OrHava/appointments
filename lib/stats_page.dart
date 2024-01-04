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
          title: const Text('Page Views'),
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
              const Hero(
                tag: 'stats_icon',
                child: Icon(
                  Icons.insert_chart,
                  size: 100,
                  color: Color(0xFF7B86E2),
                ),
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
                            child: Text(
                              "Current Date: ${DateFormat('dd-MM-yyyy').format(pageViews['date'])}",
                              style: const TextStyle(color: Colors.white),
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

                    // Use the data in your LineChart
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 300,
                        child: dynamicLineChart(
                          pageViewsData.counts.reversed.toList(),
                          pageViewsData.dates.reversed.toList(),
                        ),
                      ),
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
                color: const Color(0xFF7B86E2),
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
