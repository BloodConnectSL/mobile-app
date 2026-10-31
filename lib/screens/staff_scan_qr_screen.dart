import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'staff_donor_history_screen.dart';

class StaffScanQrScreen extends StatefulWidget {
  final Map<String, dynamic> staffUserData;
  final String? initialIdentifier;

  const StaffScanQrScreen({
    super.key,
    required this.staffUserData,
    this.initialIdentifier,
  });

  @override
  State<StaffScanQrScreen> createState() => _StaffScanQrScreenState();
}

class _StaffScanQrScreenState extends State<StaffScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _manualInputController = TextEditingController();

  int _scannerKeyIndex = 0;
  bool _isCameraActive = true;
  bool _isTorchOn = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _scannedDonor;

  // Active Duty / Facility state
  bool _isLoadingDuty = false;
  Map<String, dynamic>? _activeDuty;
  String? _dutyError;

  @override
  void initState() {
    super.initState();
    _loadActiveDuty();

    if (widget.initialIdentifier != null && widget.initialIdentifier!.isNotEmpty) {
      _manualInputController.text = widget.initialIdentifier!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyIdentifier(widget.initialIdentifier!);
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  String get _staffUserId {
    return widget.staffUserData['id']?.toString() ??
        widget.staffUserData['user_id']?.toString() ??
        '';
  }

  String get _staffRole {
    return widget.staffUserData['role']?.toString().toUpperCase() ?? 'STAFF';
  }

  bool get _isOrgStaff {
    return _staffRole.contains('ORG');
  }

  bool _isBloodGroupValid(String? bg) {
    if (bg == null) return false;
    final clean = bg.trim().toUpperCase();
    if (clean.isEmpty ||
        clean.contains('UNKNOWN') ||
        clean.contains('NOT_SPECIFIED') ||
        clean.contains('UNSPECIFIED')) {
      return false;
    }
    return true;
  }

  Future<void> _loadActiveDuty() async {
    final staffId = _staffUserId;
    if (staffId.isEmpty) return;

    setState(() {
      _isLoadingDuty = true;
      _dutyError = null;
    });

    try {
      final duty = await ApiService.getActiveStaffDuty(
        staffUserId: staffId,
        staffRole: _staffRole,
      );
      if (mounted) {
        setState(() {
          _activeDuty = duty;
          _isLoadingDuty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dutyError = e.toString();
          _isLoadingDuty = false;
        });
      }
    }
  }

  Future<void> _verifyIdentifier(String identifier) async {
    final clean = identifier.trim();
    if (clean.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _scannerController.stop();
    } catch (_) {}

    try {
      final result = await ApiService.scanDonor(
        clean,
        staffUserId: _staffUserId,
        staffRole: _staffRole,
      );
      if (mounted) {
        setState(() {
          _scannedDonor = result;
          _isLoading = false;
          _isCameraActive = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
        try {
          _scannerController.start();
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not verify donor. Please check connection and try again.';
          _isLoading = false;
        });
        try {
          _scannerController.start();
        } catch (_) {}
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isLoading || _scannedDonor != null) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawVal = barcode.rawValue;
      if (rawVal != null && rawVal.trim().isNotEmpty) {
        _verifyIdentifier(rawVal.trim());
        break;
      }
    }
  }

  Future<void> _resetScanner() async {
    setState(() {
      _scannedDonor = null;
      _errorMessage = null;
      _isCameraActive = true;
      _scannerKeyIndex++;
      _manualInputController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        try {
          await _scannerController.stop();
          await _scannerController.start();
        } catch (_) {
          try {
            await _scannerController.start();
          } catch (_) {}
        }
      }
    });
  }

  // ─── Record Blood Donation Bottom Sheet ────────────────────────────────────
  void _openRecordDonationSheet() {
    if (_scannedDonor == null) return;

    // Check if duplicate donation is already recorded
    if (_scannedDonor!['already_recorded'] == true) {
      final msg = _scannedDonor!['already_recorded_message']?.toString() ??
          'Blood donation already recorded from this donor for this camp.';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Donation Already Recorded',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            msg,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryCrimson)),
            ),
          ],
        ),
      );
      return;
    }

    // Check if donor is ineligible (minimum donation interval not met)
    if (_scannedDonor!['is_eligible'] == false) {
      final msg = _scannedDonor!['eligibility_message']?.toString() ??
          'Donor does not meet the minimum donation interval criteria.';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Donor Ineligible',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            'Blood donation recording is locked for this donor.\n\n$msg\n\nRecording donations before the required recovery period is restricted to safeguard donor health.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryCrimson)),
            ),
          ],
        ),
      );
      return;
    }

    // For Org Staff, check if ongoing camp exists
    if (_isOrgStaff) {
      final status = _activeDuty?['status']?.toString().toLowerCase();
      final campId = _activeDuty?['facility_id']?.toString() ?? '';
      if (status != 'ongoing' || campId.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('No Ongoing Camp'),
              ],
            ),
            content: const Text(
              'You cannot record donations at this time because your account is not assigned to an ongoing blood camp in assigned_staff_members.\n\nPlease contact your Organization Administrator.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecordDonationModal(
        staffUserData: widget.staffUserData,
        scannedDonor: _scannedDonor!,
        activeDuty: _activeDuty,
        onSuccess: (donationResult) {
          Navigator.of(ctx).pop();
          if (mounted) {
            setState(() {
              if (_scannedDonor != null) {
                _scannedDonor = Map<String, dynamic>.from(_scannedDonor!)
                  ..['already_recorded'] = true
                  ..['already_recorded_message'] = _isOrgStaff
                      ? 'Blood donation already recorded from this donor for this camp.'
                      : 'Blood donation already recorded from this donor for today.';
              }
            });
          }
          _showDonationSuccessDialog(donationResult);
        },
      ),
    );
  }

  void _showDonationSuccessDialog(Map<String, dynamic> donation) {
    final donorName = donation['donor_name'] ?? _scannedDonor?['full_name'] ?? 'Donor';
    final vol = donation['volume_ml'] ?? 450;
    final bloodGroup = donation['blood_group'] ?? _scannedDonor?['blood_group'] ?? '';
    final hasValidBg = _isBloodGroupValid(bloodGroup);
    final donorDisplay = hasValidBg ? '$donorName ($bloodGroup)' : donorName;

    final facilityName = donation['camp_name'] ??
        donation['hospital_name'] ??
        (_activeDuty?['facility_name'] ?? 'Facility');
    final donationId = donation['donation_id'] ?? '';

    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: screenHeight * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF86EFAC), width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 38),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Donation Uploaded!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Blood donation records successfully committed to database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),

                // Details card (Fully responsive wrapping to prevent overflow)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Donor', donorDisplay),
                      const Divider(height: 14),
                      _buildReceiptRow('Volume', '$vol mL'),
                      const Divider(height: 14),
                      _buildReceiptRow('Facility', facilityName),
                      if (donationId.isNotEmpty) ...[
                        const Divider(height: 14),
                        _buildReceiptRow(
                          'Donation ID',
                          donationId.length > 14
                              ? '${donationId.substring(0, 10)}...'
                              : donationId,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Responsive Actions Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _resetScanner();
                        },
                        child: const Text(
                          'Scan Next',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StaffDonorHistoryScreen(
                                staffUserData: widget.staffUserData,
                                initialSearch: _scannedDonor?['nic'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'History',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: highlight ? const Color(0xFFB71C1C) : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isOrgStaff ? 'Org Staff: Scan & Record' : 'Hospital Staff: Scan & Record',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (_scannedDonor == null)
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? Colors.amber : AppTheme.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
                _scannerController.toggleTorch();
              },
            ),
          if (_scannedDonor != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCrimson),
              tooltip: 'Scan Again',
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Staff Active Duty & Assignment Badge
              _buildStaffDutyBanner(),

              // 2. Scanner View or Result View
              if (_scannedDonor != null)
                _buildDonorResultCard(_scannedDonor!)
              else
                _buildScannerSection(),

              const SizedBox(height: 16),

              // 3. Manual Search / ID Input Panel (Quick test chips removed)
              _buildManualInputPanel(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Active Duty Card ──────────────────────────────────────────────────────
  Widget _buildStaffDutyBanner() {
    if (_isLoadingDuty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Checking duty assignments...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_dutyError != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Duty status error: $_dutyError',
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      );
    }

    final isCamp = _isOrgStaff;
    final facilityName = _activeDuty?['facility_name'] ?? (isCamp ? 'No ongoing camp assigned' : 'Hospital Blood Bank');
    final venue = _activeDuty?['venue_or_addr'] ?? '';
    final status = _activeDuty?['status']?.toString().toLowerCase() ?? 'none';
    final hasOngoing = status == 'ongoing' || (!isCamp && status == 'active');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasOngoing ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasOngoing ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasOngoing ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCamp ? Icons.campaign_rounded : Icons.local_hospital_rounded,
              color: hasOngoing ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isCamp ? 'ONGOING BLOOD CAMP' : 'HOSPITAL BLOOD BANK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: hasOngoing ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasOngoing ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCamp ? (hasOngoing ? 'FIELD DRIVE' : 'INACTIVE') : 'HOSPITAL',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  facilityName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    venue,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isCameraActive)
            MobileScanner(
              key: ValueKey(_scannerKeyIndex),
              controller: _scannerController,
              onDetect: _onDetect,
            )
          else
            const Center(
              child: Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
            ),

          // Scanner Target Frame Overlay
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -2,
                  left: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                        left: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                      ),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                        right: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                      ),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                        left: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                      ),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                        right: BorderSide(color: AppTheme.primaryCrimson, width: 4),
                      ),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom scanner hint
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Align Donor QR / Pass within frame',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDonorResultCard(Map<String, dynamic> donor) {
    final name = donor['full_name'] ?? 'Donor Name';
    final nic = donor['nic'] ?? 'Unlinked';
    final phone = donor['phone'] ?? 'Unlinked';
    final rawBloodGroup = donor['blood_group']?.toString() ?? '';
    final hasValidBg = _isBloodGroupValid(rawBloodGroup);
    final bloodGroup = hasValidBg ? rawBloodGroup.trim() : '';

    final gender = donor['gender'] ?? 'Not Specified';
    final age = donor['age'] ?? 0;
    final totalDonations = donor['total_donations'] ?? 0;
    final qrRef = donor['qr_ref_id'] ?? '';
    final isEligible = donor['is_eligible'] == true;
    final eligibilityMsg = donor['eligibility_message'] ?? '';
    final isAlreadyRecorded = donor['already_recorded'] == true;
    final alreadyRecordedMsg = donor['already_recorded_message']?.toString() ??
        (_isOrgStaff
            ? 'Blood donation already recorded from this donor for this camp.'
            : 'Blood donation already recorded from this donor today.');
    final lastDonation = donor['last_donation_date'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(donor['last_donation_date'].toString()).toLocal())
        : 'Never Donated';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
              ),
            ),
            child: Row(
              children: [
                // Clean blood group or profile icon (NEVER shows "Unknown")
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: hasValidBg
                        ? Text(
                            bloodGroup,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryCrimson,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: AppTheme.primaryCrimson,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIC: $nic',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (qrRef.isNotEmpty)
                        Text(
                          'Pass ID: $qrRef',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Medical Status & Camp Recording Badges (Clean, rounded, pleasing to the eyes)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isAlreadyRecorded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFFE11D48),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Donation Already Recorded',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9F1239),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alreadyRecordedMsg,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF881337),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isEligible ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEligible ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isEligible ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                          color: isEligible ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEligible ? 'Eligible to Donate' : 'Donation Interval Notice',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isEligible ? const Color(0xFF166534) : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                eligibilityMsg.isNotEmpty
                                    ? eligibilityMsg
                                    : (isEligible ? 'Donor meets standard donation interval criteria.' : 'Medical check recommended.'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isEligible ? const Color(0xFF14532D) : const Color(0xFF78350F),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailTile(
                        icon: Icons.phone_android_rounded,
                        label: 'Phone',
                        value: phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDetailTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Gender / Age',
                        value: '$gender ($age yrs)',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailTile(
                        icon: Icons.bloodtype_outlined,
                        label: 'Total Donations',
                        value: '$totalDonations units',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDetailTile(
                        icon: Icons.history_rounded,
                        label: 'Last Donation',
                        value: lastDonation,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons: Primary Record Donation + History
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    final isLocked = isAlreadyRecorded || !isEligible;
                    String btnText = 'Record Blood Donation';
                    IconData btnIcon = Icons.water_drop_rounded;

                    if (isAlreadyRecorded) {
                      btnText = 'Donation Already Recorded';
                      btnIcon = Icons.lock_rounded;
                    } else if (!isEligible) {
                      btnText = 'Donor Ineligible (Interval Active)';
                      btnIcon = Icons.block_rounded;
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLocked ? const Color(0xFF94A3B8) : const Color(0xFFB71C1C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: isLocked ? 0 : 2,
                        ),
                        icon: Icon(btnIcon, color: Colors.white, size: 22),
                        label: Text(
                          btnText,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onPressed: _openRecordDonationSheet,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 18, color: AppTheme.textPrimary),
                        label: const Text(
                          'History',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StaffDonorHistoryScreen(
                                staffUserData: widget.staffUserData,
                                initialSearch: nic,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppTheme.primaryCrimson),
                        label: const Text(
                          'Scan Next',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryCrimson),
                        ),
                        onPressed: _resetScanner,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF1F5F9),
          child: Icon(icon, size: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Manual Input Panel (Clean, without quick test chips) ───────────────────
  Widget _buildManualInputPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Donor Lookup',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Type Donor Pass ID, NIC number, or phone number:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualInputController,
                  decoration: InputDecoration(
                    hintText: 'Enter NIC or Pass ID',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryCrimson),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primaryCrimson, width: 2),
                    ),
                  ),
                  onSubmitted: _verifyIdentifier,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  onPressed: () => _verifyIdentifier(_manualInputController.text),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORD BLOOD DONATION MODAL FORM
// ─────────────────────────────────────────────────────────────────────────────

class _RecordDonationModal extends StatefulWidget {
  final Map<String, dynamic> staffUserData;
  final Map<String, dynamic> scannedDonor;
  final Map<String, dynamic>? activeDuty;
  final void Function(Map<String, dynamic> donationResult) onSuccess;

  const _RecordDonationModal({
    required this.staffUserData,
    required this.scannedDonor,
    required this.activeDuty,
    required this.onSuccess,
  });

  @override
  State<_RecordDonationModal> createState() => _RecordDonationModalState();
}

class _RecordDonationModalState extends State<_RecordDonationModal> {
  int _selectedVolume = 450;
  final TextEditingController _hbController = TextEditingController(text: '13.5');
  final TextEditingController _bpController = TextEditingController(text: '120/80');
  final TextEditingController _storageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _componentType = 'Whole Blood';
  bool _isSubmitting = false;
  String? _modalError;

  @override
  void initState() {
    super.initState();
    final isCamp = (widget.staffUserData['role']?.toString().toUpperCase() ?? '').contains('ORG');
    if (isCamp) {
      _storageController.text = 'Field Cold Box Transport';
    } else {
      _storageController.text = 'Hospital Blood Bank Storage';
    }
  }

  @override
  void dispose() {
    _hbController.dispose();
    _bpController.dispose();
    _storageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _staffUserId {
    return widget.staffUserData['id']?.toString() ??
        widget.staffUserData['user_id']?.toString() ??
        '';
  }

  String get _staffRole {
    return widget.staffUserData['role']?.toString().toUpperCase() ?? 'STAFF';
  }

  bool get _isOrgStaff => _staffRole.contains('ORG');

  bool _isBloodGroupValid(String? bg) {
    if (bg == null) return false;
    final clean = bg.trim().toUpperCase();
    if (clean.isEmpty ||
        clean.contains('UNKNOWN') ||
        clean.contains('NOT_SPECIFIED') ||
        clean.contains('UNSPECIFIED')) {
      return false;
    }
    return true;
  }

  Future<void> _submitDonation() async {
    final donorId = widget.scannedDonor['donor_id']?.toString() ??
        widget.scannedDonor['id']?.toString() ??
        '';

    if (donorId.isEmpty) {
      setState(() => _modalError = 'Invalid donor ID');
      return;
    }

    final hb = double.tryParse(_hbController.text.trim()) ?? 13.5;
    final bp = _bpController.text.trim().isEmpty ? '120/80' : _bpController.text.trim();

    setState(() {
      _isSubmitting = true;
      _modalError = null;
    });

    try {
      final res = await ApiService.recordBloodDonation(
        staffUserId: _staffUserId,
        staffRole: _staffRole,
        donorId: donorId,
        volumeMl: _selectedVolume,
        hemoglobinsLevel: hb,
        bloodPressure: bp,
        componentType: _componentType,
        status: 'COMPLETED',
        storageLocation: _storageController.text.trim(),
        notes: _notesController.text.trim(),
      );

      widget.onSuccess(res);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _modalError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorName = widget.scannedDonor['full_name'] ?? 'Donor';
    final nic = widget.scannedDonor['nic'] ?? '';
    final rawBg = widget.scannedDonor['blood_group']?.toString() ?? '';
    final hasValidBg = _isBloodGroupValid(rawBg);
    final bg = hasValidBg ? rawBg.trim() : '';

    final facility = widget.activeDuty?['facility_name'] ?? (_isOrgStaff ? 'Field Camp' : 'Hospital Blood Bank');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Banner (No "Unknown" text, no isCamp: true)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: hasValidBg
                          ? Text(
                              bg,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryCrimson,
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 28,
                              color: AppTheme.primaryCrimson,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donorName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (nic.isNotEmpty)
                          Text(
                            'NIC: $nic',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          _isOrgStaff ? 'Assigned Camp: $facility' : 'Facility: $facility',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFD7D7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_modalError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _modalError!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Volume Section
                  const Text(
                    'Collected Blood Volume',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [350, 450, 500].map((vol) {
                      final isSelected = _selectedVolume == vol;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              '$vol mL',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFB71C1C),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (val) {
                              if (val) setState(() => _selectedVolume = vol);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 2. Hemoglobin & Blood Pressure
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hemoglobin (g/dL)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _hbController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.opacity_rounded, size: 18, color: Color(0xFFB71C1C)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Blood Pressure',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _bpController,
                              decoration: InputDecoration(
                                hintText: '120/80',
                                prefixIcon: const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFB71C1C)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Component Type
                  const Text(
                    'Component Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _componentType,
                        isExpanded: true,
                        items: ['Whole Blood', 'Red Blood Cells', 'Platelets', 'Plasma'].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _componentType = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Storage Location
                  const Text(
                    'Storage / Transport Destination',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _storageController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.ac_unit_rounded, size: 18, color: Color(0xFFB71C1C)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submitDonation,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Confirm & Upload Donation Details',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
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
}
