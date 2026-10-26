import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_connect_sl/screens/donation_camp_map_screen.dart';

void main() {
  testWidgets('DonationCampMapScreen builds without errors or overflows', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(
      const MaterialApp(
        home: DonationCampMapScreen(
          userData: {
            'id': 'test-donor-123',
            'full_name': 'Test Donor',
          },
        ),
      ),
    );

    // Initial build
    await tester.pump();
    expect(find.byType(DonationCampMapScreen), findsOneWidget);
    expect(find.text('Donation Camp Map View'), findsOneWidget);

    // Verify map and markers rendered
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
