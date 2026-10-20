import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'donor_dashboard_screen.dart';
import 'login_screen.dart';

class DonorOnboardingWizardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DonorOnboardingWizardScreen({
    super.key,
    required this.userData,
  });

  @override
  State<DonorOnboardingWizardScreen> createState() =>
      _DonorOnboardingWizardScreenState();
}

class _DonorOnboardingWizardScreenState
    extends State<DonorOnboardingWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  // Blood types
  List<Map<String, dynamic>> _bloodTypes = [];
  String? _selectedBloodTypeId;
  bool _isLoadingBloodTypes = true;

  // Ethnicity
  final List<String> _ethnicities = [
    'Sinhalese',
    'Sri Lankan Tamil',
    'Indian Tamil',
    'Sri Lankan Moor',
    'Burgher',
    'Malay',
    'Other',
  ];
  String? _selectedEthnicity;

  // Country & Location
  final TextEditingController _countryController =
      TextEditingController(text: 'Sri Lanka');
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  String _locationStatus = 'Detecting GPS location...';

  // Inactive / Disabled fields
  final TextEditingController _provinceController =
      TextEditingController(text: 'Auto-assigned by Region');
  final TextEditingController _districtController =
      TextEditingController(text: 'Auto-assigned by District');
  final TextEditingController _cityController =
      TextEditingController(text: 'Auto-assigned by City');

  bool _isSubmitting = false;
  String? _errorMessage;

  // Fallback blood types with known database UUIDs
  static const List<Map<String, String>> _fallbackBloodTypes = [
    {'id': '5c050f96-5242-440b-86d7-efa9e7b4a172', 'display_name': 'A+'},
    {'id': '9387dcb1-62d7-4093-bb74-5193e6e23bb6', 'display_name': 'A-'},
    {'id': '2b33dc74-b4a9-41dc-97d4-ccc943bb3ade', 'display_name': 'B+'},
    {'id': '51d11fac-28e0-4ceb-97b3-fd2d85d168a8', 'display_name': 'B-'},
    {'id': '6d994ef1-389c-469a-9c76-1fcb5b030fd4', 'display_name': 'AB+'},
    {'id': 'c7d7c8e2-d934-4064-bc2d-e05e1dd2922f', 'display_name': 'AB-'},
    {'id': '5c3bff31-f699-4c10-ae0d-2490ad3f9449', 'display_name': 'O+'},
    {'id': '8f6ece0a-7f6d-4803-aafd-a5979e932137', 'display_name': 'O-'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBloodTypes();
    _fetchDeviceLocation();
  }

  @override
  void dispose() {
    _countryController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadBloodTypes() async {
    setState(() => _isLoadingBloodTypes = true);
    try {
      final list = await ApiService.getBloodTypes();
      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _bloodTypes = list;
          _isLoadingBloodTypes = false;
        });
        return;
      }
    } catch (_) {
      // Handled by fallback
    }

    if (!mounted) return;
    setState(() {
      _bloodTypes = _fallbackBloodTypes.map((e) => Map<String, dynamic>.from(e)).toList();
      _isLoadingBloodTypes = false;
    });
  }

  Future<void> _fetchDeviceLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationStatus = 'Requesting device GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _latitude = 6.9271;
          _longitude = 79.8612;
          _locationStatus = 'GPS disabled (Colombo default: 6.9271, 79.8612)';
          _isFetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _latitude = 6.9271;
            _longitude = 79.8612;
            _locationStatus = 'Permission denied (Default: 6.9271, 79.8612)';
            _isFetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _latitude = 6.9271;
          _longitude = 79.8612;
          _locationStatus = 'Permission permanently denied (Default: 6.9271, 79.8612)';
          _isFetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus =
            'GPS Acquired: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isFetchingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _latitude = 6.9271;
        _longitude = 79.8612;
        _locationStatus = 'GPS timed out (Colombo default: 6.9271, 79.8612)';
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodTypeId == null) {
      setState(() {
        _errorMessage = 'Please select your blood group.';
      });
      return;
    }
    if (_selectedEthnicity == null) {
      setState(() {
        _errorMessage = 'Please select your ethnicity.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userData['user_id']?.toString() ?? '';
      final token = widget.userData['token']?.toString();

      Map<String, dynamic>? locationMap;
      if (_latitude != null && _longitude != null) {
        locationMap = {
          'latitude': _latitude,
          'longitude': _longitude,
        };
      }

      await ApiService.completeDonorOnboarding(
        userId: userId,
        token: token,
        bloodTypeId: _selectedBloodTypeId!,
        ethnicity: _selectedEthnicity!,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : 'Sri Lanka',
        location: locationMap,
        cityId: null,
        districtId: null,
        provinceId: null,
      );

      if (!mounted) return;

      // Update user session map
      widget.userData['is_verified'] = true;
      widget.userData['profile_completed'] = true;
      widget.userData['blood_type_id'] = _selectedBloodTypeId;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete! Welcome to BloodConnect SL.'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Direct to Donor Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DonorDashboardScreen(userData: widget.userData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Setup?'),
        content: const Text(
          'You need to complete this setup to access your donor portal. Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCrimson,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.userData['username'] ?? 'Donor';
    final firstName = widget.userData['first_name'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donor Onboarding',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC0001A), Color(0xFFE8112D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryCrimson.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withAlpha(50),
                          child: const Icon(Icons.verified_user_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'One-Time Profile Setup',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome ${firstName.isNotEmpty ? firstName : username}! Please complete your medical and location details so our blood bank network can connect you during emergency shortages.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 1: Medical & Demographics
              const Text(
                '1. Medical & Blood Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Blood Type Dropdown
              const Text(
                'Blood Group *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _isLoadingBloodTypes
                  ? Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading blood groups from database...'),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedBloodTypeId,
                      decoration: InputDecoration(
                        hintText: 'Select your blood group (e.g. O+, A+)',
                        prefixIcon: const Icon(Icons.bloodtype_rounded,
                            color: AppTheme.primaryCrimson),
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.borderSubtle),
                        ),
                      ),
                      items: _bloodTypes.map((bt) {
                        final displayName =
                            bt['display_name'] ?? bt['displayName'] ?? '';
                        final id = bt['id']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedBloodTypeId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Please select your blood group' : null,
                    ),
              const SizedBox(height: 16),

              // Ethnicity Dropdown
              const Text(
                'Ethnicity *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedEthnicity,
                decoration: InputDecoration(
                  hintText: 'Select your ethnicity',
                  prefixIcon: const Icon(Icons.people_outline_rounded,
                      color: AppTheme.primaryCrimson),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
                items: _ethnicities.map((e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedEthnicity = val);
                },
                validator: (val) =>
                    val == null ? 'Please select your ethnicity' : null,
              ),
              const SizedBox(height: 24),

              // Section 2: Location Details
              const Text(
                '2. Location & Geocoding',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Device Geolocation Status Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryCrimson.withAlpha(25),
                      child: _isFetchingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryCrimson,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded,
                              color: AppTheme.primaryCrimson, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Geolocation (Auto)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Re-fetch GPS',
                      onPressed: _isFetchingLocation ? null : _fetchDeviceLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Country
              const Text(
                'Country',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  hintText: 'Sri Lanka',
                  prefixIcon: const Icon(Icons.public_rounded,
                      color: AppTheme.primaryCrimson),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inactive Province ID
              const Text(
                'Province ID (Auto-Assigned)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _provinceController,
                enabled: false,
                style: const TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  helperText:
                      'Managed by national registry — inactive until region tables seeded',
                  helperStyle: const TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(height: 14),

              // Inactive District ID
              const Text(
                'District ID (Auto-Assigned)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _districtController,
                enabled: false,
                style: const TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  helperText:
                      'Managed by national registry — inactive until district tables seeded',
                  helperStyle: const TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(height: 14),

              // Inactive City ID
              const Text(
                'City ID (Auto-Assigned)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cityController,
                enabled: false,
                style: const TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  helperText:
                      'Managed by national registry — inactive until city tables seeded',
                  helperStyle: const TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Complete Setup & Enter Dashboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
