import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hopin/post_ride/setup_location.dart';
import 'package:hopin/my_rides/myrides.dart';
import 'package:hopin/book_a_ride/search_location.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/my_rides/myrides.dart';
import 'package:hopin/book_a_ride/search_location.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';
import 'package:hopin/user_home/user_profile.dart';

class PostRideSelectionPage extends StatelessWidget {
  final String phoneNumber;

  PostRideSelectionPage({required this.phoneNumber});

  final List<Map<String, dynamic>> rideTypes = const [
    {"type": "Standard Car", "icon": Icons.directions_car},
    {"type": "Premier Car", "icon": Icons.directions_car_filled},
    {"type": "Jeep", "icon": FontAwesomeIcons.carSide},
    {"type": "Minivan", "icon": Icons.airport_shuttle},
    {"type": "Van", "icon": Icons.directions_bus},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE5DC),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFFEFE5DC),
          selectedItemColor: Color(0xFF154314),
          unselectedItemColor: Color(0xFF154314).withOpacity(0.7),
          iconSize: 30,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Book Ride'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Post Ride'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Your Rides'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(phoneNumber: phoneNumber),
                ),
              );
            }
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostRideSelectionPage(phoneNumber: phoneNumber),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyRidesPage(phoneNumber: phoneNumber),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InboxPage(phoneNumber: phoneNumber),
                ),
              );
            } else if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileViewPage(phoneNumber: phoneNumber),
                ),
              );
            }
          },
        ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF154314),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white), // ← makes back arrow white
        title: Text(
          "Post a Ride",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600, // ← weight 600
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ← left align everything
          children: [
            Text(
              "Choose Vehicle Type",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF154314),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: rideTypes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final ride = rideTypes[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SetupLocation(
                            vehicleType: ride['type'],
                            phoneNumber: phoneNumber,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(ride['icon'], size: 36, color: const Color(0xFF154314)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              ride['type'],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF154314),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
