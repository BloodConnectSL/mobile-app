import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:blood_connect_sl/main.dart';
import 'package:blood_connect_sl/screens/donor_registration_screen.dart';
import 'package:blood_connect_sl/screens/registration_pending_screen.dart';
import 'package:blood_connect_sl/screens/login_screen.dart';
import 'package:blood_connect_sl/services/api_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('ApiService Base URL configuration', () async {
    expect(ApiService.baseUrl, isNotEmpty);
    await ApiService.setCustomBaseUrl('http://192.168.1.100:8080/');
    expect(ApiService.baseUrl, equals('http://192.168.1.100:8080'));
  });

  testWidgets('Navigation from Login to Donor Registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PranaApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Tap "Create account"
    final createAccountBtn = find.text('Create account');
    expect(createAccountBtn, findsOneWidget);
    await tester.tap(createAccountBtn);
    await tester.pumpAndSettle();

    // Verify Donor Registration Screen loaded
    expect(find.byType(DonorRegistrationScreen), findsOneWidget);
    expect(find.text('Section A: Personal & Demographic Info'), findsOneWidget);
    expect(
      find.text('Section B: Phone Verification & In-Line OTP'),
      findsOneWidget,
    );
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('Pending Screen shows status and back to login action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegistrationPendingScreen(
          phone: '+94771234567',
          qrRef: 'BC-D-2026-Kas-42B0',
        ),
      ),
    );

    expect(find.text('Account created!'), findsOneWidget);
    expect(find.text('+94771234567'), findsOneWidget);
    expect(find.text('BC-D-2026-Kas-42B0'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);

    // Tap "Back to Login"
    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
