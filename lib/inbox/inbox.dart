import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/inbox/notifications.dart';
import 'package:hopin/inbox/chat_tab.dart';
import 'package:hopin/inbox/all_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

class InboxPage extends StatelessWidget {
  final String phoneNumber;

  InboxPage({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(

        backgroundColor: Color(0xFFEFE5DC),
        appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          backgroundColor: Color(0xFFE154314),
          title: Text(
            "Inbox",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,  // Add this
              unselectedLabelColor: Colors.white70, // Add this
              labelStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: "Ride Requests"),
                Tab(text: "Chats"),
                Tab(text: "Notifications")
              ],
            ),

        ),
        body: TabBarView(
          children: [
            NotificationsTab(phoneNumber: phoneNumber),
            ChatsTab(phoneNumber: phoneNumber),
            NotificationsViewTab(phoneNumber: phoneNumber),
          ],
        ),
      ),
    );
  }
}
