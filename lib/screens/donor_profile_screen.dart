import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DonorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DonorProfileScreen({super.key, required this.userData});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Profile data from backend
  Map<String, dynamic> _profile = {};

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Non-controller state
  String? _nic;
  String? _bloodType;
  String? _gender;
  DateTime? _selectedDob;

  String? _selectedProvinceId;
  String? _selectedDistrictId;

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  bool _isLoadingDistricts = false;

  // Track original phone to detect changes
  String _originalPhone = '';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    _loadInitialData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _resolveUserId() {
    final uid =
        _profile['user_id'] ??
        widget.userData['user_id'] ??
        widget.userData['id'] ??
        widget.userData['donor_id'] ??
        '';
    return uid.toString();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _resolveUserId();
      final donorId = (widget.userData['donor_id'] ?? '').toString();

      // Parallel fetch of profile and provinces
      final results = await Future.wait([
        ApiService.getDonorProfile(
          userId: userId.isNotEmpty ? userId : null,
          donorId: donorId.isNotEmpty ? donorId : null,
        ).catchError((_) => <String, dynamic>{}),
        ApiService.getProvinces().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final fetchedProfile = results[0] as Map<String, dynamic>;
      final fetchedProvinces = results[1] as List<Map<String, dynamic>>;

      // Merge widget.userData as fallback
      final merged = Map<String, dynamic>.from(widget.userData);
      fetchedProfile.forEach((key, value) {
        if (value != null) merged[key] = value;
      });

      _profile = merged;
      _provinces = fetchedProvinces;

      // Populate text fields
      _firstNameController.text = _profile['first_name']?.toString() ?? '';
      _lastNameController.text = _profile['last_name']?.toString() ?? '';
      _originalPhone = _profile['phone']?.toString().trim() ?? '';
      _phoneController.text = _originalPhone;
      _addressController.text = _profile['address']?.toString() ?? '';

      // Immutable values
      _nic = _profile['nic']?.toString();
      _bloodType = _profile['blood_type']?.toString();

      // Gender
      final rawGender = _profile['gender']?.toString().toUpperCase();
      if (rawGender == 'MALE' ||
          rawGender == 'FEMALE' ||
          rawGender == 'OTHER') {
        _gender = rawGender;
      } else {
        _gender = null;
      }

      // Date of Birth
      final dobStr = _profile['date_of_birth']?.toString();
      if (dobStr != null && dobStr.isNotEmpty) {
        try {
          _selectedDob = DateTime.parse(dobStr.substring(0, 10));
        } catch (_) {}
      }

      // Location IDs
      _selectedProvinceId = _profile['province_id']?.toString();
      _selectedDistrictId = _profile['district_id']?.toString();

      // If province selected, load its districts
      if (_selectedProvinceId != null && _selectedProvinceId!.isNotEmpty) {
        final provExists = _provinces.any(
          (p) => p['id']?.toString() == _selectedProvinceId,
        );
        if (provExists) {
          await _fetchDistricts(_selectedProvinceId!, preserveSelection: true);
        } else {
          _selectedProvinceId = null;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _fetchDistricts(
    String provinceId, {
    bool preserveSelection = false,
  }) async {
    setState(() {
      _isLoadingDistricts = true;
      if (!preserveSelection) {
        _selectedDistrictId = null;
      }
    });

    try {
      final list = await ApiService.getDistricts(provinceId: provinceId);
      if (mounted) {
        setState(() {
          _districts = list;
          _isLoadingDistricts = false;
          // Validate existing selection
          if (preserveSelection && _selectedDistrictId != null) {
            final exists = _districts.any(
              (d) => d['id']?.toString() == _selectedDistrictId,
            );
            if (!exists) _selectedDistrictId = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _districts = [];
          _isLoadingDistricts = false;
        });
      }
    }
  }

  bool get _isPhoneChanged {
    final current = _phoneController.text.trim();
    if (current.isEmpty && _originalPhone.isEmpty) return false;
    return current != _originalPhone;
  }

  Future<void> _selectDob(BuildContext context) async {
    final initialDate = _selectedDob ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 16),
      ), // At least 16 yrs
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryCrimson,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _handleSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = _resolveUserId();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User ID is missing. Please log in again.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final newPhone = _phoneController.text.trim();

    if (_isPhoneChanged) {
      // Phone changed: Send OTP and present verification sheet
      _initiatePhoneVerificationFlow(newPhone);
    } else {
      // Normal update without phone change
      await _executeUpdate(phone: null, otp: null);
    }
  }

  Future<void> _initiatePhoneVerificationFlow(String newPhone) async {
    setState(() => _isSaving = true);

    try {
      await ApiService.requestOTP(phone: newPhone, purpose: 'phone_change');

      if (!mounted) return;
      setState(() => _isSaving = false);

      // Open OTP Dialog
      _showOtpModal(newPhone);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showOtpModal(String newPhone) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    String? dialogError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sms_rounded,
                          color: AppTheme.primaryCrimson,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify New Phone Number',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Security verification required',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.primaryCrimson,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7F1D1D),
                                height: 1.3,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'A 6-digit verification code was sent to ',
                                ),
                                TextSpan(
                                  text: newPhone,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text: '. Enter it below to save changes.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.errorRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogError!,
                              style: const TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: AppTheme.primaryCrimson,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryCrimson,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isVerifying
                              ? null
                              : () => Navigator.pop(modalContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isVerifying
                              ? null
                              : () async {
                                  final code = otpController.text.trim();
                                  if (code.length != 6) {
                                    setModalState(() {
                                      dialogError =
                                          'Please enter all 6 digits of the OTP';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isVerifying = true;
                                    dialogError = null;
                                  });

                                  final success = await _executeUpdate(
                                    phone: newPhone,
                                    otp: code,
                                    onFail: (err) {
                                      setModalState(() {
                                        dialogError = err;
                                        isVerifying = false;
                                      });
                                    },
                                  );

                                  if (success && modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }
                                },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCrimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isVerifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Verify & Save',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _executeUpdate({
    String? phone,
    String? otp,
    void Function(String)? onFail,
  }) async {
    setState(() => _isSaving = true);

    try {
      final userId = _resolveUserId();
      final dobFormatted = _selectedDob != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
          : null;

      final res = await ApiService.updateDonorProfile(
        userId: userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: dobFormatted,
        gender: _gender,
        provinceId: _selectedProvinceId,
        districtId: _selectedDistrictId,
        phone: phone,
        otp: otp,
      );

      final updatedData = (res['data'] as Map<String, dynamic>?) ?? {};

      if (mounted) {
        setState(() {
          _isSaving = false;
          // Merge updated data
          updatedData.forEach((k, v) {
            if (v != null) _profile[k] = v;
          });
          if (phone != null) {
            _originalPhone = phone;
            _phoneController.text = phone;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final errText = e.toString();
        if (onFail != null) {
          onFail(errText);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errText),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _profile);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, _profile),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryCrimson,
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadInitialData,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Avatar & Badges Header
                        _buildHeaderCard(),
                        const SizedBox(height: 20),

                        // Clinically Locked Fields (NIC & Blood Group)
                        _buildImmutableInfoSection(),
                        const SizedBox(height: 24),

                        // Editable Personal Info
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // First Name & Last Name
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                icon: Icons.person_outline_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                icon: Icons.person_outline_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Phone Number with Change Warning
                        _buildPhoneField(),
                        const SizedBox(height: 16),

                        // Date of Birth & Gender
                        Row(
                          children: [
                            Expanded(child: _buildDatePickerField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildGenderDropdown()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Location & Address
                        const Text(
                          'Residential Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Province Dropdown
                        _buildProvinceDropdown(),
                        const SizedBox(height: 14),

                        // District Dropdown
                        _buildDistrictDropdown(),
                        const SizedBox(height: 14),

                        // Address
                        _buildTextField(
                          controller: _addressController,
                          label: 'Street Address',
                          icon: Icons.home_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSavePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCrimson,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Saving changes...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isPhoneChanged
                                            ? Icons.lock_clock_rounded
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isPhoneChanged
                                            ? 'Verify Phone & Save Profile'
                                            : 'Save Profile Changes',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final username =
        _profile['username'] ?? widget.userData['username'] ?? 'Donor';
    final qrRef = _profile['qr_ref'] ?? widget.userData['qr_ref'] ?? 'BC-SL';
    final livesSaved = _profile['saved_lives']?.toString() ?? '0';
    final isVerified =
        _profile['is_verified'] == true ||
        _profile['is_verified'] == 1 ||
        _profile['is_verified']?.toString().toLowerCase() == 'true';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryCrimson,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Donor Pass ID: $qrRef',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.shade600.withValues(alpha: 0.9)
                            : Colors.amber.shade700.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVerified
                            ? '✓ Verified Donor'
                            : '⏳ Pending Verification',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                'Blood Group',
                _bloodType ?? 'Not Set',
                Icons.water_drop_rounded,
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildHeaderStat(
                'Impact Score',
                '$livesSaved Impact score',
                Icons.health_and_safety_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImmutableInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF475569), size: 20),
              SizedBox(width: 8),
              Text(
                'Clinical & Identity Records (Immutable)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // NIC Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'National ID (NIC)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _nic != null && _nic!.isNotEmpty
                            ? _nic!
                            : 'Not Provided',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cannot be changed',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Blood Group Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.bloodtype_rounded,
                            size: 16,
                            color: AppTheme.primaryCrimson,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Blood Group',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _bloodType != null && _bloodType!.isNotEmpty
                            ? _bloodType!
                            : 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cannot be changed',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryCrimson,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Phone number is required';
            }
            if (val.trim().length < 9) {
              return 'Enter a valid phone number';
            }
            return null;
          },
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            suffixIcon: _isPhoneChanged
                ? Tooltip(
                    message: 'OTP verification required',
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Needs OTP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successGreen,
                    size: 20,
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isPhoneChanged
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFE2E8F0),
                width: _isPhoneChanged ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryCrimson,
                width: 1.8,
              ),
            ),
          ),
        ),
        if (_isPhoneChanged) ...[
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFFD97706),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Changing your phone number requires 6-digit SMS OTP verification before updating.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDatePickerField() {
    final formattedDate = _selectedDob != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
        : 'Select Date';

    return InkWell(
      onTap: () => _selectDob(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedDob != null
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          hint: const Text('Gender', style: TextStyle(fontSize: 12)),
          items: const [
            DropdownMenuItem(
              value: 'MALE',
              child: Text('Male', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'FEMALE',
              child: Text('Female', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'OTHER',
              child: Text('Other', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _gender = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvinceId,
          isExpanded: true,
          hint: const Row(
            children: [
              Icon(
                Icons.location_city_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Select Province',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          items: _provinces.map((prov) {
            final id = prov['id']?.toString() ?? '';
            final name =
                prov['province']?.toString() ??
                prov['name']?.toString() ??
                prov['province_name']?.toString() ??
                '';
            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedProvinceId = val;
              });
              _fetchDistricts(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _isLoadingDistricts
          ? const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDistrictId,
                isExpanded: true,
                hint: const Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Select District',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                items: _districts.map((dist) {
                  final id = dist['id']?.toString() ?? '';
                  final name =
                      dist['district']?.toString() ??
                      dist['name']?.toString() ??
                      dist['district_name']?.toString() ??
                      '';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDistrictId = val;
                  });
                },
              ),
            ),
    );
  }
}
