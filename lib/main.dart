// // import 'package:flutter/material.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'firebase_options.dart';
// // import 'package:flutter/foundation.dart' show kIsWeb;
// //
// // import 'package:hopin/app_open/splash_view.dart';
// // import 'package:hopin/admin_panel/websplash_screen.dart';
// // import 'package:hopin/authentication/login_view.dart';
// // import 'package:hopin/user_home/home_page.dart';
// //
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'inbox/push_notifications.dart';
// //
// // // 🚀 NEW: Import your test widget screen
// // import 'package:hopin/testing/dev_rating_test_screen.dart';
// //
// // final navigatorKey = GlobalKey<NavigatorState>();
// //
// // /// 🧪 Flags to change app entry
// // const bool isTesting = bool.fromEnvironment('IS_TESTING');
// // const bool isRatingTest = bool.fromEnvironment('IS_RATING_TEST'); // NEW 👈
// //
// // /// 🔐 Dummy test user phone number
// // const String testPhoneNumber = '0771234567';
// //
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //   // 🔥 Firebase initialization
// //   if (kIsWeb) {
// //     await Firebase.initializeApp(
// //       options: FirebaseOptions(
// //         apiKey: "AIzaSyCgGcWUQrPG5FH3uiOmRvFMtr3AIgh7Mis",
// //         authDomain: "hopin-146af.firebaseapp.com",
// //         databaseURL: "https://hopin-146af-default-rtdb.asia-southeast1.firebasedatabase.app",
// //         projectId: "hopin-146af",
// //         storageBucket: "hopin-146af.firebasestorage.app",
// //         messagingSenderId: "733726200712",
// //         appId: "1:733726200712:web:a37e3c7f4b82c6d638e03d",
// //       ),
// //     );
// //   } else {
// //     await Firebase.initializeApp(
// //       options: DefaultFirebaseOptions.currentPlatform,
// //     );
// //   }
// //
// //   // 📲 Push Notification Setup
// //   await PushNotificationService.initialize();
// //
// //   // 💀 Handle notification when app is terminated
// //   FirebaseMessaging.instance.getInitialMessage().then((message) {
// //     if (message != null) {
// //       navigatorKey.currentState?.push(MaterialPageRoute(
// //         builder: (_) => Login(), // You can customize this
// //       ));
// //     }
// //   });
// //
// //   // 🕵️‍♀️ Background notification taps
// //   FirebaseMessaging.onMessageOpenedApp.listen((message) {
// //     navigatorKey.currentState?.push(MaterialPageRoute(
// //       builder: (_) => Login(),
// //     ));
// //   });
// //
// //   runApp(MyApp(startScreen: getStartScreen()));
// // }
// //
// // Widget getStartScreen() {
// //   if (kIsWeb) return WebPanelSplashScreen();
// //   if (isRatingTest) {
// //     return const DevRatingTestScreen(); // 🚀 NEW test-only entry
// //   }
// //   if (isTesting) return HomePage(phoneNumber: testPhoneNumber);
// //   return SplashScreen(); // regular app
// // }
// //
// // class MyApp extends StatelessWidget {
// //   final Widget startScreen;
// //   const MyApp({super.key, required this.startScreen});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       navigatorKey: navigatorKey,
// //       title: 'Hopin App',
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
// //       ),
// //       home: startScreen,
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
//
// import 'package:hopin/app_open/splash_view.dart';
// import 'package:hopin/admin_panel/websplash_screen.dart';
// import 'package:hopin/authentication/login_view.dart';
// import 'package:hopin/user_home/home_page.dart';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'inbox/push_notifications.dart';
//
// // 🚀 Test Screens
// import 'package:hopin/testing/dev_rating_test_screen.dart';
// import 'package:hopin/testing/dev_notification_test_screen.dart';
//
// final navigatorKey = GlobalKey<NavigatorState>();
//
// // ✅ Dart-defined flags
// const bool isTesting = bool.fromEnvironment('IS_TESTING');
// const bool isRatingTest = bool.fromEnvironment('IS_RATING_TEST');
// const bool isNotificationTest = bool.fromEnvironment('TEST_MODE'); // NEW 🔥
//
// const String testPhoneNumber = '0771234567';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   if (kIsWeb) {
//     await Firebase.initializeApp(
//       options: FirebaseOptions(
//         apiKey: "AIzaSyCgGcWUQrPG5FH3uiOmRvFMtr3AIgh7Mis",
//         authDomain: "hopin-146af.firebaseapp.com",
//         databaseURL: "https://hopin-146af-default-rtdb.asia-southeast1.firebasedatabase.app",
//         projectId: "hopin-146af",
//         storageBucket: "hopin-146af.firebasestorage.app",
//         messagingSenderId: "733726200712",
//         appId: "1:733726200712:web:a37e3c7f4b82c6d638e03d",
//       ),
//     );
//   } else {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//   }
//
//   await PushNotificationService.initialize();
//
//   FirebaseMessaging.instance.getInitialMessage().then((message) {
//     if (message != null) {
//       navigatorKey.currentState?.push(MaterialPageRoute(
//         builder: (_) => Login(),
//       ));
//     }
//   });
//
//   FirebaseMessaging.onMessageOpenedApp.listen((message) {
//     navigatorKey.currentState?.push(MaterialPageRoute(
//       builder: (_) => Login(),
//     ));
//   });
//
//   runApp(MyApp(startScreen: getStartScreen()));
// }
//
// Widget getStartScreen() {
//   if (kIsWeb) return WebPanelSplashScreen();
//   if (isNotificationTest) return const DevNotificationTestScreen(); // 🧪 NEW
//   if (isRatingTest) return const DevRatingTestScreen();
//   if (isTesting) return HomePage(phoneNumber: testPhoneNumber);
//   return SplashScreen();
// }
//
// class MyApp extends StatelessWidget {
//   final Widget startScreen;
//   const MyApp({super.key, required this.startScreen});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'Hopin App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
//       ),
//       home: startScreen,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:hopin/app_open/splash_view.dart';
import 'package:hopin/admin_panel/websplash_screen.dart';
import 'package:hopin/authentication/login_view.dart';
import 'package:hopin/user_home/home_page.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'inbox/push_notifications.dart';

import 'package:hopin/testing/dev_rating_test_screen.dart';
import 'package:hopin/testing/dev_notification_test_screen.dart';
import 'package:hopin/testing/DevJoinedRidesTestScreen.dart';

final navigatorKey = GlobalKey<NavigatorState>();


const bool isTesting = bool.fromEnvironment('IS_TESTING');
const bool isRatingTest = bool.fromEnvironment('IS_RATING_TEST');
const bool isNotificationTest = bool.fromEnvironment('TEST_MODE');
const bool isJoinedRidesTest = bool.fromEnvironment('IS_JOINED_RIDES_TEST');

const String testPhoneNumber = '0771234567';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCgGcWUQrPG5FH3uiOmRvFMtr3AIgh7Mis",
        authDomain: "hopin-146af.firebaseapp.com",
        databaseURL: "https://hopin-146af-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "hopin-146af",
        storageBucket: "hopin-146af.appspot.com",
        messagingSenderId: "733726200712",
        appId: "1:733726200712:web:a37e3c7f4b82c6d638e03d",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await PushNotificationService.initialize();

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => Login(),
      ));
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => Login(),
    ));
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => Login(),
    ));
  });

  runApp(MyApp(startScreen: getStartScreen()));
}

Widget getStartScreen() {
  if (kIsWeb) return WebPanelSplashScreen();
  if (isJoinedRidesTest) return const DevJoinedRidesTestScreen();
  if (isNotificationTest) return const DevNotificationTestScreen();
  if (isRatingTest) return const DevRatingTestScreen();
  if (isTesting) return HomePage(phoneNumber: testPhoneNumber);
  return SplashScreen();
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Hopin App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      home: startScreen,
    );
  }
}
