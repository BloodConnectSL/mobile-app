import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
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

  // Provinces & Districts
  List<Map<String, dynamic>> _provinces = [];
  String? _selectedProvinceId;
  bool _isLoadingProvinces = true;

  List<Map<String, dynamic>> _allDistricts = [];
  List<Map<String, dynamic>> _filteredDistricts = [];
  String? _selectedDistrictId;
  bool _isLoadingDistricts = true;

  // Country & Silent GPS Location
  final TextEditingController _countryController =
      TextEditingController(text: 'Sri Lanka');
  double? _latitude;
  double? _longitude;

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

  // Fallback provinces with database UUIDs
  static const List<Map<String, String>> _fallbackProvinces = [
    {'id': '3ab2df10-1ba2-4b15-b0ae-3da27d7b93a4', 'province': 'Western'},
    {'id': 'd99a5eb8-9402-4b21-b133-f0bd1c0e8fe0', 'province': 'Central'},
    {'id': 'f14357ae-c4d4-4445-8629-6fcdff1c65ab', 'province': 'Southern'},
    {'id': 'c02b45c8-1b42-4757-9ecd-9951aca32b18', 'province': 'North Western'},
    {'id': 'f26b86b3-5579-44ad-b4c6-a692d5b23d02', 'province': 'Sabaragamuwa'},
    {'id': 'ad898830-f492-45f3-9cb8-1dac1e56e2f9', 'province': 'Northern'},
    {'id': 'b3010ec2-dcbf-40a0-8d6e-09acc75f68b4', 'province': 'Eastern'},
    {'id': '7463d1be-e9b9-4876-8a27-5f3860aa24a4', 'province': 'Uva'},
    {'id': '21f5872b-ed9e-4221-91a1-72cb5429833c', 'province': 'North Central'},
  ];

  // Fallback districts with database UUIDs & province linkages
  static const List<Map<String, String>> _fallbackDistricts = [
    {'id': 'a7687e78-4c89-41e2-aa2f-21c5b647b989', 'district': 'Colombo', 'province_id': '3ab2df10-1ba2-4b15-b0ae-3da27d7b93a4'},
    {'id': 'e193735e-66ab-4e73-b9ce-6d64c29c68e5', 'district': 'Gampaha', 'province_id': '3ab2df10-1ba2-4b15-b0ae-3da27d7b93a4'},
    {'id': '6f2d4af5-f6f1-4dad-8abe-8308b1032fe7', 'district': 'Kalutara', 'province_id': '3ab2df10-1ba2-4b15-b0ae-3da27d7b93a4'},
    {'id': '26f18c74-f304-419d-8e49-435cc1f34a25', 'district': 'Kandy', 'province_id': 'd99a5eb8-9402-4b21-b133-f0bd1c0e8fe0'},
    {'id': 'cd049c38-addf-4635-891b-9caf4e1e11c6', 'district': 'Matale', 'province_id': 'd99a5eb8-9402-4b21-b133-f0bd1c0e8fe0'},
    {'id': '724c47f2-5c3f-4b9c-b268-b2d59843e067', 'district': 'Nuwara Eliya', 'province_id': 'd99a5eb8-9402-4b21-b133-f0bd1c0e8fe0'},
    {'id': 'ca76e8a6-1a39-49fc-a9c5-e2094d7efa17', 'district': 'Galle', 'province_id': 'f14357ae-c4d4-4445-8629-6fcdff1c65ab'},
    {'id': 'be4b12c8-b0dd-4d74-979d-bed597ca5767', 'district': 'Matara', 'province_id': 'f14357ae-c4d4-4445-8629-6fcdff1c65ab'},
    {'id': '62bc5db8-189f-430a-9db8-a452bcfe73d2', 'district': 'Hambantota', 'province_id': 'f14357ae-c4d4-4445-8629-6fcdff1c65ab'},
    {'id': 'be45c72e-d1b5-4f48-97f2-844357fef592', 'district': 'Jaffna', 'province_id': 'ad898830-f492-45f3-9cb8-1dac1e56e2f9'},
    {'id': 'ff18b06b-4676-489d-a932-0b0f0a6bc6b8', 'district': 'Kilinochchi', 'province_id': 'ad898830-f492-45f3-9cb8-1dac1e56e2f9'},
    {'id': '4de0bf6b-caf7-403e-bd12-c30d5e88c5f2', 'district': 'Mannar', 'province_id': 'ad898830-f492-45f3-9cb8-1dac1e56e2f9'},
    {'id': '048b7da9-3f4e-47e5-bcbc-fe09192d102e', 'district': 'Vavuniya', 'province_id': 'ad898830-f492-45f3-9cb8-1dac1e56e2f9'},
    {'id': '47ca7ddc-6ae6-4fbc-a2a1-7c4619659fdf', 'district': 'Mullaitivu', 'province_id': 'ad898830-f492-45f3-9cb8-1dac1e56e2f9'},
    {'id': 'a2d24bc7-efc4-4a65-a5c5-1d6913c54650', 'district': 'Batticaloa', 'province_id': 'b3010ec2-dcbf-40a0-8d6e-09acc75f68b4'},
    {'id': 'b5c3d077-1256-46df-8390-d01b8d67bb82', 'district': 'Ampara', 'province_id': 'b3010ec2-dcbf-40a0-8d6e-09acc75f68b4'},
    {'id': 'd0f73908-b915-4229-929b-ca27c0d980d6', 'district': 'Trincomalee', 'province_id': 'b3010ec2-dcbf-40a0-8d6e-09acc75f68b4'},
    {'id': 'b4f919fa-ad18-449e-bd12-1c2eaad85a0b', 'district': 'Kurunegala', 'province_id': 'c02b45c8-1b42-4757-9ecd-9951aca32b18'},
    {'id': 'a921ec01-79e2-4245-b1e4-f0b9a65dd6c4', 'district': 'Puttalam', 'province_id': 'c02b45c8-1b42-4757-9ecd-9951aca32b18'},
    {'id': '336b7395-2761-41cf-a6c8-ec2cd6e7417f', 'district': 'Anuradhapura', 'province_id': '21f5872b-ed9e-4221-91a1-72cb5429833c'},
    {'id': '09b7f6d8-2809-4021-a3d8-3af321957608', 'district': 'Polonnaruwa', 'province_id': '21f5872b-ed9e-4221-91a1-72cb5429833c'},
    {'id': 'e17cf4d3-1f84-4b79-a3cb-a40a39a793a1', 'district': 'Badulla', 'province_id': '7463d1be-e9b9-4876-8a27-5f3860aa24a4'},
    {'id': 'f41d3893-0558-446a-afe4-0b10690a5b21', 'district': 'Monaragala', 'province_id': '7463d1be-e9b9-4876-8a27-5f3860aa24a4'},
    {'id': '3429ef62-6464-4956-b7a5-51fcd5f150d0', 'district': 'Ratnapura', 'province_id': 'f26b86b3-5579-44ad-b4c6-a692d5b23d02'},
    {'id': '60a420b1-2b28-403a-b611-1125bf5472da', 'district': 'Kegalle', 'province_id': 'f26b86b3-5579-44ad-b4c6-a692d5b23d02'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBloodTypes();
    _loadProvincesAndDistricts();
    _fetchDeviceLocationSilently();
  }

  @override
  void dispose() {
    _countryController.dispose();
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
      _bloodTypes =
          _fallbackBloodTypes.map((e) => Map<String, dynamic>.from(e)).toList();
      _isLoadingBloodTypes = false;
    });
  }

  Future<void> _loadProvincesAndDistricts() async {
    setState(() {
      _isLoadingProvinces = true;
      _isLoadingDistricts = true;
    });

    try {
      final pList = await ApiService.getProvinces();
      final dList = await ApiService.getDistricts();

      if (!mounted) return;
      setState(() {
        _provinces = pList.isNotEmpty
            ? pList
            : _fallbackProvinces.map((e) => Map<String, dynamic>.from(e)).toList();
        _allDistricts = dList.isNotEmpty
            ? dList
            : _fallbackDistricts.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoadingProvinces = false;
        _isLoadingDistricts = false;
      });
      return;
    } catch (_) {
      // Handled by fallback
    }

    if (!mounted) return;
    setState(() {
      _provinces =
          _fallbackProvinces.map((e) => Map<String, dynamic>.from(e)).toList();
      _allDistricts =
          _fallbackDistricts.map((e) => Map<String, dynamic>.from(e)).toList();
      _isLoadingProvinces = false;
      _isLoadingDistricts = false;
    });
  }

  void _onProvinceChanged(String? provinceId) {
    setState(() {
      _selectedProvinceId = provinceId;
      _selectedDistrictId = null;
      if (provinceId != null && provinceId.isNotEmpty) {
        _filteredDistricts = _allDistricts
            .where((d) => d['province_id']?.toString() == provinceId)
            .toList();
      } else {
        _filteredDistricts = [];
      }
    });
  }

  /// Silently acquires device GPS in background without showing UI indicator
  Future<void> _fetchDeviceLocationSilently() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _latitude = 6.9271;
        _longitude = 79.8612;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _latitude = 6.9271;
          _longitude = 79.8612;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _latitude = 6.9271;
        _longitude = 79.8612;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (_) {
      _latitude = 6.9271;
      _longitude = 79.8612;
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
    if (_selectedProvinceId == null) {
      setState(() {
        _errorMessage = 'Please select your province.';
      });
      return;
    }
    if (_selectedDistrictId == null) {
      setState(() {
        _errorMessage = 'Please select your district.';
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

      final result = await ApiService.completeDonorOnboarding(
        userId: userId,
        token: token,
        bloodTypeId: _selectedBloodTypeId!,
        ethnicity: _selectedEthnicity!,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : 'Sri Lanka',
        location: locationMap,
        cityId: null,
        districtId: _selectedDistrictId,
        provinceId: _selectedProvinceId,
      );

      if (!mounted) return;

      // Update user session map
      widget.userData['is_verified'] = false;
      widget.userData['profile_completed'] = true;
      widget.userData['blood_type_id'] = _selectedBloodTypeId;
      widget.userData['province_id'] = _selectedProvinceId;
      widget.userData['district_id'] = _selectedDistrictId;
      if (result['qr_ref'] != null) {
        widget.userData['qr_ref'] = result['qr_ref'];
      }
      if (result['qr_data'] != null) {
        widget.userData['qr_data'] = result['qr_data'];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete! Welcome to BloodConnect SL.'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update stored session with completed profile status
      widget.userData['profile_completed'] = true;
      await SessionService.saveSession(widget.userData);

      if (!mounted) return;

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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SessionService.clearSession();
              if (!mounted) return;
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
                      'Welcome ${firstName.isNotEmpty ? firstName : username}! Please complete your medical and residential location details so our blood bank network can connect you during emergency shortages.',
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
                          borderSide: BorderSide(color: AppTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderSubtle),
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

              // Section 2: Residential Location
              const Text(
                '2. Residential Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

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

              // Province Dropdown
              const Text(
                'Province *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _isLoadingProvinces
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
                          Text('Loading provinces...'),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedProvinceId,
                      decoration: InputDecoration(
                        hintText: 'Select your province',
                        prefixIcon: const Icon(Icons.map_rounded,
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
                      items: _provinces.map((p) {
                        final name = p['province']?.toString() ?? '';
                        final id = p['id']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: _onProvinceChanged,
                      validator: (val) =>
                          val == null ? 'Please select your province' : null,
                    ),
              const SizedBox(height: 16),

              // District Dropdown
              const Text(
                'District *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _isLoadingDistricts
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
                          Text('Loading districts...'),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedDistrictId,
                      decoration: InputDecoration(
                        hintText: _selectedProvinceId == null
                            ? 'First select a province above'
                            : 'Select your district',
                        prefixIcon: const Icon(Icons.location_city_rounded,
                            color: AppTheme.primaryCrimson),
                        filled: true,
                        fillColor: _selectedProvinceId == null
                            ? const Color(0xFFF1F5F9)
                            : AppTheme.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderSubtle),
                        ),
                      ),
                      items: _filteredDistricts.map((d) {
                        final name = d['district']?.toString() ?? '';
                        final id = d['id']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedProvinceId == null
                          ? null
                          : (val) {
                              setState(() => _selectedDistrictId = val);
                            },
                      validator: (val) =>
                          val == null ? 'Please select your district' : null,
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
