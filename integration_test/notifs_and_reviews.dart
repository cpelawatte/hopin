import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hopin/main.dart' as app; // Assuming your entry point is main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("User submits a rating and review", (WidgetTester tester) async {
    await Firebase.initializeApp();
    app.main();
    await tester.pumpAndSettle();

    // 👇 Simulate navigation to joined rides tab
    // You might need to tap a bottom nav item or button
    final joinedTabFinder = find.text('Joined'); // Adjust based on your UI
    await tester.tap(joinedTabFinder);
    await tester.pumpAndSettle();

    // 👇 Find a completed ride with "Rate Driver" button
    final rateDriverButton = find.text('Rate Driver');
    expect(rateDriverButton, findsWidgets);

    await tester.tap(rateDriverButton.first);
    await tester.pumpAndSettle();

    // 👇 Select 4 stars (or any number)
    final starButton = find.byIcon(Icons.star).at(3);
    await tester.tap(starButton);
    await tester.pumpAndSettle();

    // 👇 Type in a review
    final reviewField = find.byType(TextField);
    await tester.enterText(reviewField, 'Awesome ride 🚗✨');
    await tester.pumpAndSettle();

    // 👇 Submit the review
    final submitButton = find.text('Submit');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // ✅ Assert confirmation
    expect(find.text('Rating submitted'), findsOneWidget);
  });
}
