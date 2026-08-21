// Just Dance — end-to-end smoke test on a real device.
// Covers: catalog setup (fee, course, batch with duration, timing,
// plan), add member -> welcome popup -> home card, detail + payment,
// roll-call attendance, collections, home search.
//
// Run with: flutter test integration_test -d <device>
//
// NOTE: runs against a FRESH app install (clears any existing data) so the
// assertions are deterministic.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studio_crow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full studio flow', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 900));

    // ---- Home loads (fresh install) ----
    expect(find.text('No members yet — tap + to add'), findsOneWidget);

    // ---- Profile: catalog setup ----
    await _tapIcon(tester, Icons.person_outline);
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);

    // Open Schedule (formerly "Courses, Batches, Timings & Plans")
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    // Admission fee 500
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    // Add course
    await tester.tap(find.text('Add Course'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Strength Training'), 'Dance Studio');
    await tester.enterText(find.widgetWithText(TextField, 'e.g. 1000'), '1000');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(find.text('Dance Studio'), findsOneWidget);

    // Add interest
    await tester.tap(find.text('Add Interest').first);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Hip Hop, Kathak, Salsa, Beat Boxing'), 'Hip Hop');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(find.text('Hip Hop'), findsOneWidget);

    // Add plan
    await tester.tap(find.text('Add Plan'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Quarterly Plan'), 'Monthly');
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 3'), '1');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(find.text('Monthly'), findsWidgets);

    // Back to profile
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ---- Add member ----
    await tester.tap(find.byIcon(Icons.add).last); // center +
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo Later'));
    await tester.pumpAndSettle();

    // Form: name + mobile
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'Rahul Kumar');
    await tester.enterText(
        find.widgetWithText(TextFormField, '10-digit mobile'), '9876543210');
    await tester.ensureVisible(find.text('Save Member'));
    await tester.tap(find.text('Save Member'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ---- Welcome popup appears immediately (no detail screen) ----
    expect(find.textContaining('Admission Done'), findsOneWidget);
    expect(find.text('Send Welcome'), findsOneWidget);
    expect(find.text('Send ID Card'), findsOneWidget);
    expect(find.text('Send Invoice'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // ---- Home shows the new member card ----
    expect(find.text('Rahul Kumar'), findsOneWidget);

    // Tap the card to open detail
    await tester.tap(find.text('Rahul Kumar'));
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Payment History'), findsOneWidget);

    // ---- Payment: settle full cycle ₹1000 (+ admission 500) ----
    await tester.tap(find.text('Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Payment'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Payment-done sheet: reminder + PDF invoice actions, then Done
    expect(find.text('Payment saved!'), findsOneWidget);
    expect(find.textContaining('paid till'), findsOneWidget);
    expect(find.text('Send Reminder'), findsOneWidget);
    expect(find.text('Send Invoice (PDF)'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ---- Back home, then roll-call attendance ----
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Roll Call'));
    await tester.pumpAndSettle();

    // Roster (All students) — mark Rahul present
    await tester.tap(find.text('Rahul Kumar'));
    await tester.pumpAndSettle();
    expect(find.text('1 present'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Rahul Kumar'), findsOneWidget);
    expect(find.textContaining('marked'), findsWidgets);

    // ---- Collections ----
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Admission Fee Collection'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget); // admission collected
    expect(find.textContaining('₹1,000'), findsWidgets); // membership

    // ---- Home: member card + search ----
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Rahul Kumar'), findsOneWidget);
    expect(find.text('Active'), findsWidgets); // card status + filter chip

    // Search filters
    await tester.enterText(
        find.widgetWithText(TextField, 'Search by name, mobile or ID…'), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No members here'), findsOneWidget);
  });
}

Future<void> _tapIcon(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon).last);
}
