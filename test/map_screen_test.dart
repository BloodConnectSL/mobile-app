import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_connect_sl/screens/donation_camp_map_screen.dart';

void main() {
  testWidgets('DonationCampMapScreen builds successfully', (WidgetTester tester) async {
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

    await tester.pump();
    expect(find.byType(DonationCampMapScreen), findsOneWidget);
    expect(find.text('Donation Camp Map View'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
