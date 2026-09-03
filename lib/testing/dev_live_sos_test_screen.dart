import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hopin/firebase_options.dart';
import 'package:hopin/tracking/live_tracking.dart'; // ✅ Correct path

class DevLiveSosOnlyTestScreen extends StatefulWidget {
  const DevLiveSosOnlyTestScreen({super.key});

  @override
  State<DevLiveSosOnlyTestScreen> createState() => _DevLiveSosOnlyTestScreenState();
}

class _DevLiveSosOnlyTestScreenState extends State<DevLiveSosOnlyTestScreen> {
  final String testPhone = "0771234567";
  final String testRideId = "-OP44uFp1TRMzbkXMp_0"; // Replace with your rideId if needed

  String _log = "🚀 Ready to test SOS Button inside LiveTrackingPage...\n";

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    setState(() {
      _log += "✅ Firebase initialized\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live SOS Test"), backgroundColor: Colors.red),
      body: Column(
        children: [
          Expanded(
            child: LiveTrackingPage(
              currentUserPhone: testPhone,
              rideId: testRideId,
            ),
          ),
          const Divider(height: 1),
          Container(
            height: 160,
            color: Colors.black,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                _log,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Courier',
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}