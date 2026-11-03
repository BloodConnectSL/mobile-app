import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'registration_pending_screen.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({super.key});

  @override
  State<DonorRegistrationScreen> createState() =>
      _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Section A: Personal & Demographic Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _privacyConsent = false, _healthConsent = false;
  final _nicController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _gender = 'MALE';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDob;

  // Section B: Phone Verification & In-Line OTP
  final _phoneController = TextEditingController(text: '+94');
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isVerifyingOtp = false;
  bool _isPhoneVerified = false;
  String? _verificationToken;

  int _resendCountdown = 0;
  Timer? _countdownTimer;

  // Section C: Submission State
  bool _isSubmitting = false;
  String? _submissionError;

  // Username validation state
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameStatusMessage;
  Timer? _usernameDebounceTimer;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _nicController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();

    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    _usernameDebounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounceTimer?.cancel();
    final trimmed = value.trim();

    if (trimmed.length < 3) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameStatusMessage = null;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(trimmed)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameStatusMessage =
            'Only letters, numbers, dots, and underscores allowed';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameStatusMessage = null;
    });

    _usernameDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final available = await ApiService.checkUsernameAvailability(trimmed);
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
          _usernameStatusMessage = available
              ? 'Username is available'
              : 'Username is already taken';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
        });
      }
    });
  }

  // --- Normalizes and validates phone ---
  String _getFormattedPhone() {
    var text = _phoneController.text.trim();
    if (text.startsWith('0')) {
      text = '+94${text.substring(1)}';
    } else if (!text.startsWith('+')) {
      text = '+$text';
    }
    return text;
  }

  bool _isPhoneValid(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+94\d{9}$').hasMatch(cleaned) ||
        RegExp(r'^0\d{9}$').hasMatch(cleaned);
  }

  // --- Section B: OTP Logic ---
  Future<void> _handleSendOtp() async {
    final phone = _getFormattedPhone();
    if (!_isPhoneValid(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid Sri Lankan phone number (e.g. +94771234567 or 0771234567)',
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _submissionError = null;
    });

    try {
      final msg = await ApiService.requestOTP(
        phone: phone,
        purpose: 'registration',
      );

      if (!mounted) return;

      setState(() {
        _otpSent = true;
        _resendCountdown = 45;
      });

      _startCountdown();

      // Clear previous OTP entries and focus first box
      for (var c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _getFormattedPhone();
    final otp = _getOtpCode();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the OTP code'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _submissionError = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final token = await ApiService.verifyOTP(
        phone: phone,
        otp: otp,
        purpose: 'registration',
      );

      if (!mounted) return;

      _countdownTimer?.cancel();

      setState(() {
        _isPhoneVerified = true;
        _verificationToken = token;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully! ✓'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  // --- Section A: Date Picker ---
  Future<void> _pickDateOfBirth() async {
    final initialDate = _selectedDob ?? DateTime(2000, 1, 1);
    final firstDate = DateTime(1940);
    final lastDate = DateTime.now().subtract(
      const Duration(days: 365 * 16),
    ); // At least 16 yrs old

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
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
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- Section C: Final Registration Submission ---
  Future<void> _handleSubmitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted fields in the form'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isPhoneVerified || _verificationToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number via OTP first'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The chosen username is already taken. Please choose another.',
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_privacyConsent || !_healthConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please review and accept the privacy and health data consent choices.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final phone = _getFormattedPhone();
      final result = await ApiService.registerDonor(
        privacyConsent: _privacyConsent,
        healthConsent: _healthConsent,
        verificationToken: _verificationToken!,
        phone: phone,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        nic: _nicController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _gender,
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      // Navigate to Registration Status Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RegistrationPendingScreen(
            phone: phone,
            qrRef: result['qr_ref']?.toString(),
            donorId: result['donor_id']?.toString(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submissionError = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submissionError = 'Unexpected registration error. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneSendEnabled =
        !_isPhoneVerified && !_isSendingOtp && _resendCountdown == 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Donor Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Intro header
                const Text(
                  'Join the Blood Donor Registry',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Complete your personal details and verify your phone number to become an active blood donor.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Submission Error Card
                if (_submissionError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorRed, width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _submissionError!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ========================================================
                // SECTION A: Personal & Demographic Info
                // ========================================================
                _buildSectionCard(
                  title: 'Section A: Personal & Demographic Info',
                  icon: Icons.person_outline_rounded,
                  children: [
                    // First & Last Name
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              hintText: 'e.g. Kasun',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              hintText: 'e.g. Perera',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // NIC
                    TextFormField(
                      controller: _nicController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'NIC / National ID',
                        hintText:
                            '12 digits or 9 digits + V (e.g. 199512345678)',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return null; // Optional
                        }
                        final val = v.trim();
                        if (!RegExp(
                          r'^([0-9]{9}[vVxX]|[0-9]{12})$',
                        ).hasMatch(val)) {
                          return 'Enter a valid NIC (9 digits+V or 12 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth & Gender
                    Row(
                      children: [
                        // Date of Birth Picker
                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: _pickDateOfBirth,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              hintText: 'YYYY-MM-DD',
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: AppTheme.primaryCrimson,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Gender Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(
                                Icons.wc_outlined,
                                color: AppTheme.primaryCrimson,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'MALE',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'FEMALE',
                                child: Text('Female'),
                              ),
                              DropdownMenuItem(
                                value: 'OTHER',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _gender = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Residential Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Residential Address',
                        hintText: 'Street address, city, district',
                        prefixIcon: Icon(
                          Icons.home_outlined,
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      onChanged: _onUsernameChanged,
                      decoration: InputDecoration(
                        labelText: 'Username *',
                        hintText: 'Choose a unique username (e.g. kamal_p)',
                        prefixIcon: const Icon(
                          Icons.account_circle_outlined,
                          color: AppTheme.primaryCrimson,
                        ),
                        suffixIcon: _isCheckingUsername
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryCrimson,
                                  ),
                                ),
                              )
                            : _isUsernameAvailable == true
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.successGreen,
                              )
                            : _isUsernameAvailable == false
                            ? const Icon(Icons.cancel, color: AppTheme.errorRed)
                            : null,
                        helperText: _usernameStatusMessage,
                        helperStyle: TextStyle(
                          color: _isUsernameAvailable == true
                              ? AppTheme.successGreen
                              : _isUsernameAvailable == false
                              ? AppTheme.errorRed
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (v.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v.trim())) {
                          return 'Only letters, numbers, dots, and underscores allowed';
                        }
                        if (_isUsernameAvailable == false) {
                          return 'Username is already taken';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryCrimson,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          color: AppTheme.primaryCrimson,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ========================================================
                // SECTION B: Phone Verification & In-Line OTP
                // ========================================================
                _buildSectionCard(
                  title: 'Section B: Phone Verification & In-Line OTP',
                  icon: Icons.phonelink_ring_outlined,
                  children: [
                    // Phone input with integrated Send OTP button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_isPhoneVerified,
                            decoration: InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '+94771234567 or 0771234567',
                              prefixIcon: const Icon(
                                Icons.phone_android,
                                color: AppTheme.primaryCrimson,
                              ),
                              suffixIcon: _isPhoneVerified
                                  ? const Icon(
                                      Icons.verified,
                                      color: AppTheme.successGreen,
                                    )
                                  : null,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number required';
                              }
                              if (!_isPhoneValid(_getFormattedPhone())) {
                                return 'Invalid phone number format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Send OTP Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: _isPhoneVerified
                                  ? AppTheme.successGreen
                                  : AppTheme.primaryCrimson,
                            ),
                            onPressed: isPhoneSendEnabled
                                ? _handleSendOtp
                                : null,
                            child: _isSendingOtp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isPhoneVerified
                                        ? 'Verified ✓'
                                        : (_resendCountdown > 0
                                              ? '${_resendCountdown}s'
                                              : (_otpSent
                                                    ? 'Resend'
                                                    : 'Send OTP')),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Success Verified Banner if verified
                    if (_isPhoneVerified) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.successGreen,
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.successGreen,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Phone ownership verified! Single-use token securely attached.',
                                style: TextStyle(
                                  color: Color(0xFF14532D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // In-line OTP 6-digit boxes (only if OTP dispatched and not yet verified)
                    if (_otpSent && !_isPhoneVerified) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Enter 6-Digit OTP sent to your phone:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 6 Auto-advancing OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            height: 52,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.backspace) {
                                  if (_otpControllers[index].text.isEmpty &&
                                      index > 0) {
                                    _otpFocusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _otpFocusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryCrimson,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Colors.white,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryCrimson,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderSubtle,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    // Handle multi-character paste
                                    if (value.length > 1) {
                                      final digits = value.split('');
                                      for (
                                        int i = 0;
                                        i < digits.length && (index + i) < 6;
                                        i++
                                      ) {
                                        _otpControllers[index + i].text =
                                            digits[i];
                                      }
                                      final targetIndex = (index + value.length)
                                          .clamp(0, 5);
                                      _otpFocusNodes[targetIndex]
                                          .requestFocus();
                                      return;
                                    }
                                    if (index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    } else {
                                      _otpFocusNodes[index].unfocus();
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Verify OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
                          child: _isVerifyingOtp
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryCrimson,
                                    ),
                                  ),
                                )
                              : const Text('Verify OTP Code'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ========================================================
                // SECTION C: Submission
                // ========================================================
                const Text(
                  'Prana uses your identity and contact details to manage your account, and health records for donation screening and history. Location is optional. We do not sell donor data.',
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I agree to the privacy notice and account data processing.',
                  ),
                  value: _privacyConsent,
                  onChanged: (v) =>
                      setState(() => _privacyConsent = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I consent to health records being used for screening and shared with authorized clinical staff.',
                  ),
                  value: _healthConsent,
                  onChanged: (v) => setState(() => _healthConsent = v ?? false),
                ),
                ElevatedButton(
                  onPressed: (_isPhoneVerified && !_isSubmitting)
                      ? _handleSubmitRegistration
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isPhoneVerified
                              ? 'Register as Donor'
                              : 'Verify Phone Number to Register',
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryCrimson, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              height: 24,
              thickness: 1,
              color: AppTheme.borderSubtle,
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
