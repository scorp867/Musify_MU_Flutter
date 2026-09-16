import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/app.dart';

void main() {
  testWidgets('builds the Musify application shell', (tester) async {
    await tester.pumpWidget(const MusifyApp());
    await tester.pumpAndSettle();

    // Default mode is offline — verify the header renders.
    expect(find.text('Jane Doe'), findsOneWidget);
  });
}
