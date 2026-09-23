/*
Change made by: Nipuna Lakruwan
Date: 2026-08-15
Added: Centralized GoRouter configuration (app_router.dart).
How: Created the file from scratch to define the '/', '/login', and '/signup' routes for the new architecture.
*/
import 'package:go_router/go_router.dart';
import 'package:prana/features/splash/presentation/screens/splash_screen.dart';
import 'package:prana/features/auth/presentation/screens/login_screen.dart';
import 'package:prana/features/auth/presentation/screens/signup_screen.dart';
import 'package:prana/views/push_notifications_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const PushNotificationsView(),
    ),
  ],
);
