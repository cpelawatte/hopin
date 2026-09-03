import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/user_home/update_profile.dart';
import 'package:hopin/post_ride/add_vehicle.dart';
import 'package:hopin/app_open/auth_choose_view.dart';
import 'package:hopin/user_home/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopin/my_rides/myrides.dart';
import 'package:hopin/book_a_ride/search_location.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../support/support_chart.dart';

class SettingsPage extends StatelessWidget {
  final String phoneNumber;

  SettingsPage({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Settings", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Color(0xff154314),
        centerTitle: true,
      ),
      backgroundColor: Color(0xffefe5dc),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person, color: Color(0xff154314)),
              title: Text("Update Profile", style: GoogleFonts.poppins()),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xff154314)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProfilePage(phoneNumber: phoneNumber),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.directions_car, color: Color(0xff154314)),
              title: Text("Add a Vehicle", style: GoogleFonts.poppins()),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xff154314)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddVehiclePage(phoneNumber: phoneNumber),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.support_agent, color: Color(0xff154314)),
              title: Text("Customer Support", style: GoogleFonts.poppins()),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xff154314)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupportChatScreen(phoneNumber: phoneNumber),
                  ),
                );
              },
            ),
            Divider(),
            Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.logout),
              label: Text("Logout", style: GoogleFonts.poppins(fontSize: 16)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                await prefs.remove('phone');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => authHome()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
