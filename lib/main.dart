import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';
import 'package:mobile_app/screens/splash_screen.dart';
import 'package:mobile_app/screens/onboarding_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/sign_up_screen.dart';
import 'package:mobile_app/screens/main_layout.dart';
import 'package:mobile_app/screens/portals/all_portals.dart';
import 'package:mobile_app/screens/blood_request_screen.dart';
import 'package:mobile_app/screens/donation_history_screen.dart';
import 'package:mobile_app/screens/notifications_screen.dart';
import 'package:mobile_app/screens/emergency_sos_screen.dart';

void main() {
  runApp(const PranaApp());
}

class PranaApp extends StatelessWidget {
  const PranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prana (à¶´à·Šâ€à¶»à·à¶«)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainLayout(),
        '/portal/organizer': (context) => const OrganizerPortalScreen(),
        '/portal/hospital': (context) => const HospitalPortalScreen(),
        '/portal/admin': (context) => const AdminPortalScreen(),
        '/portal/super_admin': (context) => const SuperAdminPortalScreen(),
        '/blood-request': (context) => const BloodRequestScreen(),
        '/donation-history': (context) => const DonationHistoryScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/emergency-sos': (context) => const EmergencySOSScreen(),
      },
    );
  }
}
