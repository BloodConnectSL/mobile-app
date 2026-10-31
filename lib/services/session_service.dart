import 'dart:convert';
import 'dart:io';
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

  // In-memory cache
  static Map<String, dynamic>? _cachedSession;
  static int? _cachedTimestamp;

  /// Pure-Dart filesystem backup file location on Android internal storage
  static File? _getBackupFile() {
    try {
      if (Platform.isAndroid) {
        final d1 = Directory('/data/user/0/com.bloodconnectsl.blood_connect_sl/files');
        if (!d1.existsSync()) {
          d1.createSync(recursive: true);
        }
        return File('${d1.path}/bloodconnect_session_backup.json');
      }
    } catch (e) {
      debugPrint('[SessionService] Backup file path check: $e');
    }
    return null;
  }

  /// Saves the user session along with the current timestamp
  static Future<void> saveSession(Map<String, dynamic> userData) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _cachedSession = Map<String, dynamic>.from(userData);
    _cachedTimestamp = nowMs;

    final jsonStr = jsonEncode(userData);

    // 1. Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, jsonStr);
      await prefs.setInt(_keyLoginTimestamp, nowMs);
      debugPrint('[SessionService] Session saved to SharedPreferences');
    } catch (e) {
      debugPrint('[SessionService] SharedPreferences save error: $e');
    }

    // 2. Save to filesystem backup file as a secondary fallback
    try {
      final file = _getBackupFile();
      if (file != null) {
        final payload = jsonEncode({
          'timestamp': nowMs,
          'userData': userData,
        });
        await file.writeAsString(payload, flush: true);
        debugPrint('[SessionService] Session backup written to ${file.path}');
      }
    } catch (e) {
      debugPrint('[SessionService] Filesystem backup save error: $e');
    }
  }

  /// Updates existing stored user data without resetting the original login timestamp
  static Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    _cachedSession = Map<String, dynamic>.from(updatedData);
    final jsonStr = jsonEncode(updatedData);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, jsonStr);
    } catch (e) {
      debugPrint('[SessionService] SharedPreferences update error: $e');
    }

    try {
      final file = _getBackupFile();
      if (file != null && _cachedTimestamp != null) {
        final payload = jsonEncode({
          'timestamp': _cachedTimestamp,
          'userData': updatedData,
        });
        await file.writeAsString(payload, flush: true);
      }
    } catch (_) {}
  }

  /// Retrieves the active session if it exists and is less than 24 hours old.
  /// If expired, invalid, or absent, clears the session and returns null.
  static Future<Map<String, dynamic>?> getActiveSession() async {
    if (_cachedSession != null && _cachedTimestamp != null) {
      final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(_cachedTimestamp!));
      if (elapsed <= sessionValidity && !elapsed.isNegative) {
        debugPrint('[SessionService] Returning in-memory active session');
        return _cachedSession;
      }
    }

    int? timestamp;
    Map<String, dynamic>? sessionData;

    // 1. Try reading from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyUserData);
      timestamp = prefs.getInt(_keyLoginTimestamp);

      if (jsonStr != null && timestamp != null) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          sessionData = Map<String, dynamic>.from(decoded);
          debugPrint('[SessionService] Session recovered from SharedPreferences');
        }
      }
    } catch (e) {
      debugPrint('[SessionService] SharedPreferences read error: $e');
    }

    // 2. Fallback to filesystem backup if SharedPreferences was empty or errored
    if (sessionData == null || timestamp == null) {
      try {
        final file = _getBackupFile();
        if (file != null && await file.exists()) {
          final content = await file.readAsString();
          final decoded = jsonDecode(content);
          if (decoded is Map && decoded['userData'] is Map && decoded['timestamp'] is int) {
            timestamp = decoded['timestamp'] as int;
            sessionData = Map<String, dynamic>.from(decoded['userData'] as Map);
            debugPrint('[SessionService] Session recovered from disk backup file');
          }
        }
      } catch (e) {
        debugPrint('[SessionService] Filesystem backup read error: $e');
      }
    }

    if (sessionData == null || timestamp == null) {
      debugPrint('[SessionService] No stored session found');
      return null;
    }

    // 3. Check 24-hour expiration
    final loginTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final elapsed = now.difference(loginTime);

    if (elapsed > sessionValidity || elapsed.isNegative) {
      debugPrint('[SessionService] Session expired (${elapsed.inHours}h old > 24h limit). Clearing.');
      await clearSession();
      return null;
    }

    debugPrint('[SessionService] Active session valid for ${sessionData['username'] ?? 'user'} (Remaining: ${24 - elapsed.inHours}h)');
    _cachedSession = sessionData;
    _cachedTimestamp = timestamp;
    return sessionData;
  }

  /// Clears the saved session on explicit logout or session expiration
  static Future<void> clearSession() async {
    _cachedSession = null;
    _cachedTimestamp = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyLoginTimestamp);
      debugPrint('[SessionService] SharedPreferences session cleared');
    } catch (e) {
      debugPrint('[SessionService] SharedPreferences clear error: $e');
    }

    try {
      final file = _getBackupFile();
      if (file != null && await file.exists()) {
        await file.delete();
        debugPrint('[SessionService] Backup session file deleted');
      }
    } catch (e) {
      debugPrint('[SessionService] File delete error: $e');
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
      default:
        return DonorDashboardScreen(userData: userData);
    }
  }
}
