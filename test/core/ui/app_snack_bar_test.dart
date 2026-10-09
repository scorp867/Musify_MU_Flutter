import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/ui/widgets/app_snack_bar.dart';

void main() {
  testWidgets('AppSnackBar renders with floating behavior and no retry button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppSnackBar.show(
                  context,
                  message: "You're offline. Content will update when connected.",
                );
              },
              child: const Text('Show SnackBar'),
            ),
          ),
        ),
      ),
    );

    // Tap button to trigger SnackBar
    await tester.tap(find.text('Show SnackBar'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300)); // Finish entrance

    // Verify text is present
    expect(
      find.text("You're offline. Content will update when connected."),
      findsOneWidget,
    );

    // Verify no Retry button exists
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(SnackBarAction), findsNothing);

    // Verify SnackBar styling
    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);
    final snackBar = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, const Color(0xFF282828));
    expect(snackBar.duration, const Duration(seconds: 3));
    expect(snackBar.margin, const EdgeInsets.only(left: 20, right: 20, bottom: 12));
    expect(snackBar.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 10));

    // Verify auto-dismiss after 3 seconds
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500)); // Finish exit animation
    expect(find.text("You're offline. Content will update when connected."), findsNothing);
  });

  testWidgets('AppSnackBar replaces previous snackbar instead of queueing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppSnackBar.show(context, message: 'First message'),
                  child: const Text('First'),
                ),
                ElevatedButton(
                  onPressed: () => AppSnackBar.show(context, message: 'Second message'),
                  child: const Text('Second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('First message'), findsOneWidget);

    // Trigger second immediately
    await tester.tap(find.text('Second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // First should be removed and Second should be shown
    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsOneWidget);
  });

  testWidgets('AppSnackBar.clear removes snackbar immediately', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppSnackBar.show(context, message: 'Showing'),
                  child: const Text('Show'),
                ),
                ElevatedButton(
                  onPressed: () => AppSnackBar.clear(context),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Showing'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Showing'), findsNothing);
  });
}
