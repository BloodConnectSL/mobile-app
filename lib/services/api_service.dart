import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Top-level default base URL configuration.
/// Defaults to 10.0.2.2:8080 for Android Emulator, and localhost:8080 for iOS / Web / Desktop.
String getDefaultBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  try {
    if (Platform.isAndroid) {
      // return 'http://localhost:8080';
      //  return 'http://10.0.2.2:8080';
      return 'http://10.15.99.69:8080';
    }
  } catch (_) {
    // Platform checking not supported on some platforms
  }
  return 'http://localhost:8080';
}

/// Custom exception for API errors with status code and server message
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? rawResponse;

  ApiException({
    required this.statusCode,
    required this.message,
    this.rawResponse,
  });

  bool get isPendingApproval => statusCode == 403;
  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}

class ApiService {
  static String baseUrl = getDefaultBaseUrl();

  /// Allows runtime override of API URL if testing on real devices (e.g. http://192.168.1.50:8080)
  static void setCustomBaseUrl(String url) {
    baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// 1. Request OTP via SMS
  /// POST /api/v1/auth/otp/request
  static Future<String> requestOTP({
    required String phone,
    String purpose = 'registration',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/otp/request');
    final payload = jsonEncode({
      'phone': phone,
      'purpose': purpose,
    });

    try {
      final response = await http
          .post(uri, headers: _defaultHeaders, body: payload)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = _parseResponse(response);
      return data['message'] ?? 'OTP sent successfully';
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Unable to connect to server at $baseUrl',
      );
    }
  }

  /// 2. Verify OTP & Obtain Verification Token
  /// POST /api/v1/auth/otp/verify
  static Future<String> verifyOTP({
    required String phone,
    required String otp,
    String purpose = 'registration',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/otp/verify');
    final payload = jsonEncode({
      'phone': phone,
      'otp': otp,
      'purpose': purpose,
    });

    try {
      final response = await http
          .post(uri, headers: _defaultHeaders, body: payload)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = _parseResponse(response);
      final token = data['verification_token'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Server did not return a valid verification token',
        );
      }
      return token;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Unable to connect to server at $baseUrl',
      );
    }
  }

  /// 3. Donor Registration
  /// POST /api/v1/donors/register
  static Future<Map<String, dynamic>> registerDonor({
    required String verificationToken,
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? username,
    String? nic,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? ethnicity,
    String? bloodTypeId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/donors/register');
    final Map<String, dynamic> body = {
      'verification_token': verificationToken,
      'phone': phone,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    };

    if (username != null && username.trim().isNotEmpty) {
      body['username'] = username.trim();
    }

    if (nic != null && nic.trim().isNotEmpty) body['nic'] = nic.trim();
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      body['date_of_birth'] = dateOfBirth;
    }
    if (gender != null && gender.isNotEmpty) body['gender'] = gender;
    if (address != null && address.trim().isNotEmpty) {
      body['address'] = address.trim();
    }
    if (ethnicity != null && ethnicity.trim().isNotEmpty) {
      body['ethnicity'] = ethnicity.trim();
    }
    if (bloodTypeId != null && bloodTypeId.isNotEmpty) {
      body['blood_type_id'] = bloodTypeId;
    }

    try {
      final response = await http
          .post(uri, headers: _defaultHeaders, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data = _parseResponse(response);
      return data['data'] as Map<String, dynamic>? ?? data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Unable to connect to server at $baseUrl',
      );
    }
  }

  /// 4. User Login
  /// POST /api/v1/auth/login
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/login');
    final payload = jsonEncode({
      'username': username,
      'password': password,
    });

    try {
      final response = await http
          .post(uri, headers: _defaultHeaders, body: payload)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = _parseResponse(response);
      return data['data'] as Map<String, dynamic>? ?? data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Unable to connect to server at $baseUrl',
      );
    }
  }

  /// 5. Check Username Availability
  /// GET /api/v1/auth/check-username?username=...
  static Future<bool> checkUsernameAvailability(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.parse(
        '$baseUrl/api/v1/auth/check-username?username=${Uri.encodeComponent(trimmed)}');

    try {
      final response = await http
          .get(uri, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = _parseResponse(response);
      return data['available'] == true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Unable to check username availability',
      );
    }
  }

  /// 6. Get Blood Types Reference List
  /// GET /api/v1/blood-types
  static Future<List<Map<String, dynamic>>> getBloodTypes() async {
    final uri = Uri.parse('$baseUrl/api/v1/blood-types');
    try {
      final response = await http
          .get(uri, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = _parseResponse(response);
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Unable to load blood types from server',
      );
    }
  }

  /// 7. Complete Donor Profile Onboarding (first-time login wizard)
  /// POST /api/v1/donors/complete-profile
  static Future<Map<String, dynamic>> completeDonorOnboarding({
    required String userId,
    String? token,
    required String bloodTypeId,
    required String ethnicity,
    required String country,
    Map<String, dynamic>? location,
    String? cityId,
    String? districtId,
    String? provinceId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/donors/complete-profile');
    final headers = Map<String, String>.from(_defaultHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = jsonEncode({
      'user_id': userId,
      'blood_type_id': bloodTypeId,
      'ethnicity': ethnicity,
      'country': country,
      if (location != null) 'location': location,
      if (cityId != null && cityId.isNotEmpty) 'city_id': cityId,
      if (districtId != null && districtId.isNotEmpty) 'district_id': districtId,
      if (provinceId != null && provinceId.isNotEmpty) 'province_id': provinceId,
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = _parseResponse(response);
      return data['data'] as Map<String, dynamic>? ?? data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: Failed to submit onboarding details to server',
      );
    }
  }

  /// Standard parser matching backend response envelopes
  static Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid server response: HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extract error message
    final errorMessage = body['error'] ??
        body['message'] ??
        'Request failed with status: ${response.statusCode}';

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage.toString(),
      rawResponse: body,
    );
  }
}
