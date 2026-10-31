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

  bool _isCameraActive = true;
  bool _isTorchOn = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _scannedDonor;

  @override
  void initState() {
    super.initState();
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

  Future<void> _verifyIdentifier(String identifier) async {
    final clean = identifier.trim();
    if (clean.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.scanDonor(clean);
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
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not verify donor. Please check connection and try again.';
          _isLoading = false;
        });
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

  void _resetScanner() {
    setState(() {
      _scannedDonor = null;
      _errorMessage = null;
      _isCameraActive = true;
      _manualInputController.clear();
    });
    _scannerController.start();
  }

  void _checkinDonor() {
    if (_scannedDonor == null) return;
    final name = _scannedDonor!['full_name'] ?? 'Donor';
    final isEligible = _scannedDonor!['is_eligible'] == true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isEligible ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: isEligible ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
            const SizedBox(width: 8),
            Text(isEligible ? 'Confirm Check-In' : 'Eligibility Warning'),
          ],
        ),
        content: Text(
          isEligible
              ? 'Check-in $name for today\'s blood donation workflow?'
              : '$name is currently flagged as deferred. Are you sure staff wants to proceed with medical check-in?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEligible ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Donor $name checked-in successfully!'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Check-In'),
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
        title: const Text(
          'Scan Donor QR',
          style: TextStyle(
            fontSize: 18,
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
              // 1. Scanner View or Result View
              if (_scannedDonor != null)
                _buildDonorResultCard(_scannedDonor!)
              else
                _buildScannerSection(),

              const SizedBox(height: 16),

              // 2. Manual Search / ID Input Panel
              _buildManualInputPanel(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 320,
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
              controller: _scannerController,
              onDetect: _onDetect,
            )
          else
            const Center(
              child: Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
            ),

          // Scanner Target Frame Overlay
          Container(
            width: 220,
            height: 220,
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
    final bloodGroup = donor['blood_group'] ?? 'Unknown';
    final gender = donor['gender'] ?? 'Not Specified';
    final age = donor['age'] ?? 0;
    final totalDonations = donor['total_donations'] ?? 0;
    final qrRef = donor['qr_ref_id'] ?? '';
    final isEligible = donor['is_eligible'] == true;
    final eligibilityMsg = donor['eligibility_message'] ?? '';
    final lastDonation = donor['last_donation_date'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(donor['last_donation_date']))
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
                    child: Text(
                      bloodGroup,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryCrimson,
                      ),
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
                      ),
                      if (qrRef.isNotEmpty)
                        Text(
                          'Pass ID: $qrRef',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            color: isEligible ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            child: Row(
              children: [
                Icon(
                  isEligible ? Icons.verified_rounded : Icons.info_outline_rounded,
                  color: isEligible ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEligible ? 'ELIGIBLE TO DONATE' : 'DONATION DEFERRED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isEligible ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                      Text(
                        eligibilityMsg,
                        style: TextStyle(
                          fontSize: 12,
                          color: isEligible ? const Color(0xFF166534) : const Color(0xFF92400E),
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

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: const Text(
                      'Check-in Donor',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onPressed: _checkinDonor,
                  ),
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
                    hintText: 'e.g. bcnt001 or 200315810516',
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
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
          const SizedBox(height: 16),
          const Text(
            'Quick Test Chips:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSampleChip('bcnt001'),
              _buildSampleChip('bcnt005'),
              _buildSampleChip('200315810516'),
              _buildSampleChip('200315810517'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleChip(String code) {
    return ActionChip(
      label: Text(code),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryCrimson),
      backgroundColor: const Color(0xFFFEE2E2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () {
        _manualInputController.text = code;
        _verifyIdentifier(code);
      },
    );
  }
}
