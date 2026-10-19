import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_connect_sl/main.dart';
import 'package:blood_connect_sl/screens/splash_screen.dart';
import 'package:blood_connect_sl/screens/login_screen.dart';

void main() {
  testWidgets('App smoke test - verifies initial splash screen and navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BloodConnectSLApp());

    // Verify SplashScreen is loaded
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);

    // Fast-forward animation & 2 second splash timer
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify transition to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to BloodConnectSL'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
