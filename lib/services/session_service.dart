import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/donor_dashboard_screen.dart';
import '../screens/donor_onboarding_wizard_screen.dart';
import '../screens/hospital_admin_dashboard_screen.dart';
import '../screens/hospital_staff_dashboard_screen.dart';
import '../screens/org_admin_dashboard_screen.dart';
import '../screens/org_staff_dashboard_screen.dart';
import '../screens/system_admin_dashboard_screen.dart';

/// Manages 24-hour auto-login session persistence across app restarts.
class SessionService {
  static const String _keyUserData = 'bloodconnect_user_session_data';
  static const String _keyLoginTimestamp = 'bloodconnect_login_timestamp';
  static const Duration sessionValidity = Duration(hours: 24);

  /// Saves the user session along with the current timestamp
  static Future<void> saveSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(userData);
      await prefs.setString(_keyUserData, jsonStr);
      await prefs.setInt(_keyLoginTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Updates existing stored user data without resetting the original login timestamp
  static Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(updatedData);
      await prefs.setString(_keyUserData, jsonStr);
    } catch (_) {}
  }

  /// Retrieves the active session if it exists and is less than 24 hours old.
  /// If expired, invalid, or absent, clears the session and returns null.
  static Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyUserData);
      final timestamp = prefs.getInt(_keyLoginTimestamp);

      if (jsonStr == null || timestamp == null) {
        return null;
      }

      final loginTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final diff = now.difference(loginTime);

      // Check if session has exceeded 24 hours
      if (diff > sessionValidity || diff.isNegative) {
        await clearSession();
        return null;
      }

      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      await clearSession();
    }
    return null;
  }

  /// Clears the saved session on explicit logout or session expiration
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyLoginTimestamp);
    } catch (_) {}
  }

  /// Determines the appropriate screen destination based on user role and onboarding status
  static Widget getDestinationScreen(Map<String, dynamic> userData) {
    bool isTruthy(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 't' || s == 'yes';
      }
      return false;
    }

    final rawRole = (userData['role'] as String? ?? '').toUpperCase().trim();
    final profileCompleted = isTruthy(userData['profile_completed']);

    // The onboarding wizard is shown ONLY when profile_completed is false for DONOR
    if ((rawRole == 'DONOR' || rawRole.isEmpty) && !profileCompleted) {
      return DonorOnboardingWizardScreen(userData: userData);
    }

    switch (rawRole) {
      case 'ORG_ADMIN':
        return OrgAdminDashboardScreen(userData: userData);
      case 'ORG_STAFF':
        return OrgStaffDashboardScreen(userData: userData);
      case 'SYSTEM_ADMIN':
        return SystemAdminDashboardScreen(userData: userData);
      case 'HOSPITAL_ADMIN':
        return HospitalAdminDashboardScreen(userData: userData);
      case 'HOSPITAL_STAFF':
        return HospitalStaffDashboardScreen(userData: userData);
      case 'DONOR':
      default:
        return DonorDashboardScreen(userData: userData);
    }
  }
}
