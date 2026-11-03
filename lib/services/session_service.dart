import '../screens/doctor_screen.dart';
import '../screens/management_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_store.dart';
import 'api_service.dart';
import '../screens/donor_dashboard_screen.dart';
import '../screens/donor_onboarding_wizard_screen.dart';
import '../screens/hospital_admin_dashboard_screen.dart';
import '../screens/hospital_staff_dashboard_screen.dart';
import '../screens/org_admin_dashboard_screen.dart';
import '../screens/org_staff_dashboard_screen.dart';
import '../screens/system_admin_dashboard_screen.dart';
import '../screens/login_screen.dart';

/// Manages 24-hour auto-login session persistence across app restarts.
class SessionService {
  static const String _keyUserData = 'bloodconnect_user_session_data';
  static const String _keyLoginTimestamp = 'bloodconnect_login_timestamp';
  static const Duration sessionValidity = Duration(hours: 24);

  // In-memory cache
  static Map<String, dynamic>? _cachedSession;

  static const _storage = FlutterSecureStorage();

  static Future<void> saveSession(Map<String, dynamic> userData) async {
    final token = userData['token']?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('No authentication token was returned');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _cachedSession = Map<String, dynamic>.from(userData);

    AuthStore.token = token;
    await _storage.write(key: _keyUserData, value: jsonEncode(userData));
    await _storage.write(key: _keyLoginTimestamp, value: now.toString());
  }

  static Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    final merged = {...?_cachedSession, ...updatedData};
    if (AuthStore.token != null) merged['token'] = AuthStore.token;
    _cachedSession = merged;
    await _storage.write(key: _keyUserData, value: jsonEncode(merged));
  }

  static Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final raw = await _storage
          .read(key: _keyUserData)
          .timeout(const Duration(seconds: 5));
      final timestamp = int.tryParse(
        await _storage
                .read(key: _keyLoginTimestamp)
                .timeout(const Duration(seconds: 5)) ??
            '',
      );
      if (raw == null || timestamp == null) return null;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final token = data['token']?.toString();
      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
      if (token == null || elapsed.isNegative || elapsed >= sessionValidity) {
        await clearSession(revoke: false);
        return null;
      }
      final parts = token.split('.');
      if (parts.length != 3) {
        await clearSession(revoke: false);
        return null;
      }
      final claims =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map;
      final exp = claims['exp'] as num?;
      if (exp == null || DateTime.now().millisecondsSinceEpoch >= exp * 1000) {
        await clearSession(revoke: false);
        return null;
      }
      AuthStore.token = token;
      // The API validates signature, account status, membership and token revocation.
      final current = await ApiService.getCurrentUser();
      final fresh = Map<String, dynamic>.from(current['user'] as Map);
      final merged = {
        ...data,
        ...fresh,
        'user_id': fresh['id'],
        'token': token,
      };
      _cachedSession = merged;
      return merged;
    } catch (_) {
      await clearSession(revoke: false);
      return null;
    }
  }

  static Future<void> clearSession({bool revoke = true}) async {
    if (revoke && AuthStore.token != null) {
      try {
        await ApiService.logout();
      } catch (_) {
        /* Local credentials must still be cleared offline. */
      }
    }
    AuthStore.token = null;
    _cachedSession = null;
    try {
      await _storage
          .delete(key: _keyUserData)
          .timeout(const Duration(seconds: 5));
      await _storage
          .delete(key: _keyLoginTimestamp)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Storage can be unavailable in a browser; in-memory access is already revoked.
    }
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
      case 'DOCTOR':
        return const DoctorScreen();
      case 'PLATFORM_ADMIN':
        return ManagementScreen(userData: userData);
      case 'ORG_ADMIN':
      case 'ORGANIZATION_ADMIN':
        return OrgAdminDashboardScreen(userData: userData);
      case 'ORG_STAFF':
      case 'ORGANIZATION_STAFF':
        return OrgStaffDashboardScreen(userData: userData);
      case 'SYSTEM_ADMIN':
        return SystemAdminDashboardScreen(userData: userData);
      case 'HOSPITAL_ADMIN':
        return HospitalAdminDashboardScreen(userData: userData);
      case 'HOSPITAL_STAFF':
        return HospitalStaffDashboardScreen(userData: userData);
      case 'DONOR':
        return DonorDashboardScreen(userData: userData);
      default:
        return const LoginScreen();
    }
  }
}
