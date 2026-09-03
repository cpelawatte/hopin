import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

Future<void> sendRideRequestNotificationToDriver(String driverPhone) async {
  final dbRef = FirebaseDatabase.instance.ref();

  DataSnapshot snapshot = await dbRef.child('Users').orderByChild('phone').equalTo(driverPhone).get();

  if (snapshot.exists) {
    final userData = snapshot.children.first.value as Map;
    final token = userData['fcmToken'];

    if (token != null && token != "") {
      const serverKey = '733726200712'; // Replace with your real FCM server key

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': 'New Ride Request',
            'body': 'You got a new ride request!',
          },
          'data': {
            'phoneNumber': driverPhone,
          },
        }),
      );

      print('🔔 Notification sent to driver. Response: ${response.body}');
    }
  }
}
