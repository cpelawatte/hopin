import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ added
import 'all_notifications.dart';

// ✅ Only import 'dart:io' if not on web
// Prevents Platform errors on web
// (you must ensure this file is not imported where `dart:io` is evaluated unguarded on web)
import 'dart:io' show Platform;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 [BG] Notification received: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifPlugin = FlutterLocalNotificationsPlugin();
  static final _dbRef = FirebaseDatabase.instance.ref();

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    print('✅ Permission: ${settings.authorizationStatus}');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _dbRef.child('Users/${user.uid}').update({'fcmToken': token});
        print('🔑 Token saved: $token');
      }
    }

    // ✅ Only run Android-specific notification code on non-web Android platforms
    if (!kIsWeb && Platform.isAndroid) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) async {
          final payload = response.payload;
          if (payload != null) {
            final data = jsonDecode(payload);
            final phone = data['driverPhone'];
            navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => NotificationsViewTab(phoneNumber: phone),
            ));
          }
        },
      );

      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Important Notifications',
        description: 'Used for ride alerts',
        importance: Importance.high,
      );

      await _localNotifPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // Show foreground notification (works for all platforms)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      final android = notif?.android;

      if (notif != null && android != null && !kIsWeb && Platform.isAndroid) {
        _localNotifPlugin.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Important Notifications',
              channelDescription: 'Used for ride alerts',
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle notification tapped when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final phone = message.data['driverPhone'];
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => NotificationsViewTab(phoneNumber: phone),
      ));
    });

    final initialMsg = await _messaging.getInitialMessage();
    if (initialMsg != null) {
      final phone = initialMsg.data['driverPhone'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => NotificationsViewTab(phoneNumber: phone),
        ));
      });
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
