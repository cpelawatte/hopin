import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hopin/authentication/login_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  // Disable debugPrint to avoid debug messages in the console
  debugPrint = (String? message, {int? wrapWidth}) {};

  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  as IntegrationTestWidgetsFlutterBinding;

  binding.convertFlutterSurfaceToImage();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  Future<void> takeScreenshot(String name) async {
    final screenshotBytes = await binding.takeScreenshot(name);
    final appDir = await getApplicationDocumentsDirectory();
    final appPath = path.join(appDir.path, '$name.png');
    final file = File(appPath);
    await file.writeAsBytes(screenshotBytes);

    // No debugPrint here to avoid console logs
    // print("✅ Screenshot saved: $appPath");

    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      final externalPath = path.join(downloadsDir.path, '$name.png');
      await file.copy(externalPath);
      // No debugPrint here to avoid console logs
      // print("✅ Copied to Downloads: $externalPath");
    } else {
      // No debugPrint here to avoid console logs
      // print("❌ Downloads directory not found!");
    }
  }

  testWidgets("✅ Valid login test", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('phone_email_field')), 'Nadine@gmail.com');
    await tester.enterText(find.byKey(Key('password_field')), 'nadine@143');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    await takeScreenshot('valid_login');
  });

  testWidgets("❌ Invalid login test", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('phone_email_field')), 'fakeuser@test.com');
    await tester.enterText(find.byKey(Key('password_field')), 'wrongpassword');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    await takeScreenshot('invalid_login');
  });

  testWidgets("⛔ Lockout after 3 failed attempts", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    for (int i = 1; i <= 3; i++) {
      await tester.enterText(find.byKey(Key('phone_email_field')), 'Nadine@gmail.com');
      await tester.enterText(find.byKey(Key('password_field')), 'wrongpassword$i');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
    }

    await takeScreenshot('locked_out_after_3_fails');
  });

  testWidgets("🔒 Already locked out user test", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('phone_email_field')), 'Nadine@gmail.com');
    await tester.enterText(find.byKey(Key('password_field')), 'anyPassword');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    await takeScreenshot('already_locked_out');
  });

  testWidgets("⚠️ Empty input fields test", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    await takeScreenshot('empty_fields');
  });

  testWidgets("🔁 Forgot password navigation", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('forgot_password_button')));
    await tester.pumpAndSettle();

    await takeScreenshot('forgot_password_screen');
  });

  testWidgets("🔙 Go back button test", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Login()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('go_back_button')));
    await tester.pumpAndSettle();

    await takeScreenshot('go_back_button_screen');
  });
}
