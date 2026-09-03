import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hopin/admin_panel/vehicle_registration_request.dart';
import 'package:hopin/admin_panel/admin_chat_support.dart';
import 'package:hopin/admin_panel/admin_review_and_rating.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  final String adminPhoneNumber;
  const AdminDashboard({Key? key, required this.adminPhoneNumber}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int todayUsers = 0;
  int weekUsers = 0;
  int monthUsers = 0;
  int totalUsers = 0;

  int ridesPostedCount = 0;
  int ridersParticipationCount = 0;

  List<int> ridesPerWeek = List.filled(8, 0);

  @override
  void initState() {
    super.initState();
    fetchUserStats();
    fetchRideStats();
    fetchRidersParticipation();
  }

  Future<void> fetchUserStats() async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child('Users');
    DateTime now = DateTime.now();
    DateTime weekAgo = now.subtract(const Duration(days: 7));
    DateTime monthAgo = now.subtract(const Duration(days: 30));

    final snapshot = await userRef.get();

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int totalCount = 0;

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        DateTime registeredDate = DateTime.tryParse(value['registered_date'] ?? '') ?? DateTime(2000);

        if (registeredDate.year == now.year &&
            registeredDate.month == now.month &&
            registeredDate.day == now.day) {
          todayCount++;
        }
        if (registeredDate.isAfter(weekAgo)) {
          weekCount++;
        }
        if (registeredDate.isAfter(monthAgo)) {
          monthCount++;
        }
        totalCount++;
      });
    }

    setState(() {
      todayUsers = todayCount;
      weekUsers = weekCount;
      monthUsers = monthCount;
      totalUsers = totalCount;
    });
  }

  Future<void> fetchRideStats() async {
    DatabaseReference ridesRef = FirebaseDatabase.instance.ref().child('Rides');
    final snapshot = await ridesRef.get();
    int count = 0;
    List<int> tempRidesPerWeek = List.filled(8, 0);

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      DateTime now = DateTime.now();

      data.forEach((key, value) {
        DateTime rideDate = DateTime.tryParse(value['startDate'] ?? '') ?? DateTime(2000);

        if (rideDate.isBefore(now) && rideDate.year == now.year) {
          count++;

          for (int i = 0; i < 8; i++) {
            DateTime startOfWeek = now.subtract(Duration(days: (i - 1) * 7));
            DateTime endOfWeek = now.subtract(Duration(days: i * 7));

            if (rideDate.isAfter(endOfWeek) && rideDate.isBefore(startOfWeek)) {
              tempRidesPerWeek[7 - i]++;
            }
          }
        }
      });
    }

    setState(() {
      ridesPostedCount = count;
      ridesPerWeek = tempRidesPerWeek;
    });
  }

  Future<void> fetchRidersParticipation() async {
    DatabaseReference ridersRef = FirebaseDatabase.instance.ref().child('passenger_ride_status');
    final snapshot = await ridersRef.get();
    int participationCount = 0;

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        if (value is Map) {
          value.forEach((phone, status) {
            String lowerStatus = status.toString().toLowerCase();
            if (lowerStatus == 'ended' || lowerStatus == 'picked up') {
              participationCount++;
            }
          });
        }
      });
    }

    setState(() {
      ridersParticipationCount = participationCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth >= 800;
        return Scaffold(
          backgroundColor: const Color(0xffefe5dc),
          appBar: AppBar(
            backgroundColor: const Color(0xff154314),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Admin Dashboard',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          drawer: isLargeScreen ? null : buildDrawer(context),
          body: Row(
            children: [
              if (isLargeScreen)
                Container(
                  width: 250,
                  color: const Color(0xffefe5dc),
                  child: buildDrawer(context),
                ),
              if (isLargeScreen)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            buildStatBox("Today's Users", todayUsers),
                            buildStatBox('This Week', weekUsers),
                            buildStatBox('This Month', monthUsers),
                            buildStatBox('Total Users', totalUsers),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(child: buildGraphCard('Rides (Last 8 weeks)', ridesPerWeek)),
                            const SizedBox(width: 20),
                            Expanded(child: buildBarGraphCard('Riders Participated', ridersParticipationCount)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard, color: Color(0xff154314)),
          title: const Text('Dashboard', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.directions_car, color: Color(0xff154314)),
          title: const Text('Vehicle Requests', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminRequests(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.map, color: Color(0xff154314)),
          title: const Text('Moitor Reviews', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminReviewsPage(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people, color: Color(0xff154314)),
          title: const Text('User Details', style: TextStyle(fontFamily: 'Poppins')),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.chat, color: Color(0xff154314)),
          title: const Text('Support Chats', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminChatPage(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }


  Widget buildStatBox(String title, int value) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        width: 160,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value.toString(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildGraphCard(String title, List<int> values) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (values.reduce((a, b) => a > b ? a : b) / 5).ceilToDouble() + 1,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text('W${value.toInt()}'),
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 1,
                  maxX: values.length.toDouble(),
                  minY: 0,
                  maxY: (values.reduce((a, b) => a > b ? a : b)).toDouble() + 5,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: const Color(0xff154314),
                      belowBarData: BarAreaData(show: true, color: const Color(0xff154314).withOpacity(0.3)),
                      spots: List.generate(values.length, (index) => FlSpot((index + 1).toDouble(), values[index].toDouble())),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBarGraphCard(String title, int value) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text(value.toInt().toString())),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text('Count')),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: value.toDouble(), color: const Color(0xff154314))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
