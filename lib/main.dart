import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/auth_store.dart';
import 'services/api_service.dart';
import 'services/session_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/donor_registration_screen.dart';
import 'screens/registration_pending_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();

  // Set system UI overlay style to complement crimson theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PranaApp());
}

class PranaApp extends StatefulWidget {
  const PranaApp({super.key});

  @override
  State<PranaApp> createState() => _PranaAppState();
}

class _PranaAppState extends State<PranaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _expired;
  @override
  void initState() {
    super.initState();
    _expired = AuthStore.expired.stream.listen((_) async {
      await SessionService.clearSession(revoke: false);
      if (!mounted) return;
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _expired?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prana',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const DonorRegistrationScreen(),
        '/pending': (context) => const RegistrationPendingScreen(),
      },
    );
  }
}
