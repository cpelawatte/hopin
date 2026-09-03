// lib/dev_rating_test_screen.dart
import 'package:flutter/material.dart';
import 'package:hopin/my_rides/joined_rides.dart'; // adjust path if needed
import 'package:firebase_core/firebase_core.dart';
import 'package:hopin/firebase_options.dart'; // your Firebase setup
import 'package:google_fonts/google_fonts.dart';

class DevRatingTestScreen extends StatelessWidget {
  const DevRatingTestScreen({Key? key}) : super(key: key);

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    _initFirebase(); // Lazy init (fine for test)
    return Scaffold(
      appBar: AppBar(
        title: Text("Driver Rating Test", style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DriverRatingWidget(
          rideId: 'testRide_123',
          driverPhone: '+94701763993',
          driverName: 'Dev Test Driver',
        ),
      ),
    );
  }
}
