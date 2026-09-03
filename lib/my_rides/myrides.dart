import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/my_rides/joined_rides.dart';
import 'package:hopin/my_rides/offered_rides.dart';

class MyRidesPage extends StatelessWidget {
  final String phoneNumber;

  const MyRidesPage({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xffefe5dc),
        appBar: AppBar(
          backgroundColor: const Color(0xffe154314),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Rides',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Offered Rides'),
              Tab(text: 'Joined Rides'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OfferedRidesTab(phoneNumber: phoneNumber),
            JoinedRidesTab(phoneNumber: phoneNumber),
          ],
        ),
      ),
    );
  }
}
