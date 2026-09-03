import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/tracking/live_tracking.dart';
import 'package:hopin/firebase_options.dart';

class DevLiveTrackingTestScreen extends StatefulWidget {
  const DevLiveTrackingTestScreen({super.key});

  @override
  State<DevLiveTrackingTestScreen> createState() => _DevLiveTrackingTestScreenState();
}

class _DevLiveTrackingTestScreenState extends State<DevLiveTrackingTestScreen> {
  final String testPhone = '0771234567';
  final String rideId = '-OP44uFp1TRMzbkXMp_0';

  String _log = '🚀 Ready to test Live Tracking & SOS...\n';
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    setState(() {
      _firebaseInitialized = true;
      _log += '✅ Firebase initialized successfully\n';
    });
  }

  void _appendLog(String message) {
    setState(() {
      _log += '📝 $message\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Live Tracking Dev Test'),
        backgroundColor: Colors.green.shade800,
      ),
      body: !_firebaseInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            flex: 3,
            child: LiveTrackingPage(
              currentUserPhone: testPhone,
              rideId: rideId,
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(8),
            height: 180,
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                _log,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
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