import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:hopin/firebase_options.dart'; // Adjust to your file
import 'dart:convert';

class DevNotificationTestScreen extends StatefulWidget {
  const DevNotificationTestScreen({super.key});

  @override
  State<DevNotificationTestScreen> createState() => _DevNotificationTestScreenState();
}

class _DevNotificationTestScreenState extends State<DevNotificationTestScreen> {
  String? _fcmToken;
  String _log = "🚀 Ready to test notifications.";

  @override
  void initState() {
    super.initState();
    _initFirebaseAndFCM();
  }

  Future<void> _initFirebaseAndFCM() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final token = await messaging.getToken();
    setState(() {
      _fcmToken = token;
      _log += "\n✅ FCM Token: $token";
    });

    FirebaseMessaging.onMessage.listen((message) {
      setState(() {
        _log += "\n🔔 Received: ${message.notification?.title} - ${message.notification?.body}";
      });
    });
  }

  Future<void> _triggerTestNotification() async {
    if (_fcmToken == null) return;

    final url = Uri.parse("https://asia-southeast1-hopin-146af.cloudfunctions.net/sendTestNotification");
    final response = await http.post(url, body: {
      "token": _fcmToken!,
      "title": "🚀 Robot Test",
      "body": "This is an automated push test 🚧",
    });

    setState(() {
      _log += "\n📨 Test request sent. Response: ${response.statusCode}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Robot Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _triggerTestNotification,
              child: const Text("Send Test Notification"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
