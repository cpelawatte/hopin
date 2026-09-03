import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/firebase_options.dart'; // Adjust this path if needed
import 'dart:async';

class DevJoinedRidesTestScreen extends StatefulWidget {
  const DevJoinedRidesTestScreen({super.key});

  @override
  State<DevJoinedRidesTestScreen> createState() => _DevJoinedRidesTestScreenState();
}

class _DevJoinedRidesTestScreenState extends State<DevJoinedRidesTestScreen> {
  final dbRef = FirebaseDatabase.instance.ref();
  final String testPhoneNumber = "+94785249713"; // Replace with a test number from your DB
  String _log = "🧪 Ready to test joined rides...\n";

  @override
  void initState() {
    super.initState();
    _initFirebaseAndFetchRides();
  }

  Future<void> _initFirebaseAndFetchRides() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _log += "✅ Firebase Initialized\n";
    setState(() {});
    await _testJoinedRides();
  }

  Future<void> _testJoinedRides() async {
    try {
      final passengersSnapshot = await dbRef.child('passenger_per_ride').get();

      for (var rideEntry in passengersSnapshot.children) {
        final rideId = rideEntry.key!;
        for (var passengerEntry in rideEntry.children) {
          final passengerPhone = passengerEntry.child('passenger_phone').value.toString();

          if (passengerPhone == testPhoneNumber) {
            final rideDetails = await dbRef.child('Rides/$rideId').get();
            if (!rideDetails.exists) continue;

            final destination = rideDetails.child('destinationAddress').value;
            final pickup = rideDetails.child('pickupAddress').value;
            final date = rideDetails.child('startDate').value;
            final price = rideDetails.child('pricePerPassenger').value;

            _log += "\n🛣️ Ride ID: $rideId\n";
            _log += "📍 From: $pickup ➡️ To: $destination\n";
            _log += "📅 Date: $date\n";
            _log += "💸 Price: Rs. $price\n";
          }
        }
      }

      if (_log.contains("🛣️") == false) {
        _log += "❌ No joined rides found for $testPhoneNumber\n";
      }
    } catch (e) {
      _log += "🔥 Error: $e\n";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Joined Rides Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("🧠 Debug Output:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontFamily: 'Courier')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
