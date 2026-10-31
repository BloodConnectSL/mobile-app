import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'staff_scan_qr_screen.dart';

class StaffConfirmedDonorsScreen extends StatefulWidget {
  final Map<String, dynamic> staffUserData;

  const StaffConfirmedDonorsScreen({
    super.key,
    required this.staffUserData,
  });

  @override
  State<StaffConfirmedDonorsScreen> createState() => _StaffConfirmedDonorsScreenState();
}

class _StaffConfirmedDonorsScreenState extends State<StaffConfirmedDonorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _confirmedDonors = [];
  String _selectedStatus = 'confirmed'; // 'confirmed', 'all'

  @override
  void initState() {
    super.initState();
    _fetchConfirmedDonors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchConfirmedDonors({String? query}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final q = query ?? _searchController.text.trim();
      final donors = await ApiService.getConfirmedDonors(
        search: q,
        status: _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _confirmedDonors = donors;
          _isLoading = false;
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
          _errorMessage = 'Could not load confirmed donors. Please check connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number linked to this donor')),
      );
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer for $phone')),
        );
      }
    }
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
          'Confirmed Donors',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCrimson),
            onPressed: () => _fetchConfirmedDonors(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar & Status Filter Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search donor name, NIC, phone, or camp...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryCrimson),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _fetchConfirmedDonors(query: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _fetchConfirmedDonors(query: val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusFilterChip('Confirmed (${_confirmedDonors.length})', 'confirmed'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('All Visits', 'all'),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Confirmed Donors List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCrimson))
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _confirmedDonors.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              color: AppTheme.primaryCrimson,
                              onRefresh: () => _fetchConfirmedDonors(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _confirmedDonors.length,
                                itemBuilder: (context, index) {
                                  final item = _confirmedDonors[index] as Map<String, dynamic>;
                                  return _buildDonorCard(item);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String statusKey) {
    final isSelected = _selectedStatus == statusKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryCrimson,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppTheme.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = statusKey;
          });
          _fetchConfirmedDonors();
        }
      },
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor) {
    final name = donor['donor_name'] ?? 'Donor';
    final nic = donor['donor_nic'] ?? '';
    final phone = donor['donor_phone'] ?? '';
    final bloodGroup = donor['blood_group'] ?? 'Unknown';
    final gender = donor['gender'] ?? 'Not Specified';
    final campName = donor['camp_name'] ?? 'Blood Donation Drive';
    final campVenue = donor['camp_venue'] ?? '';
    final campDate = donor['camp_date'] ?? '';
    final startTime = donor['start_time'] ?? '';
    final endTime = donor['end_time'] ?? '';
    final status = (donor['status'] as String? ?? 'confirmed').toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar & Blood Group badge & Status
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFEE2E2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryCrimson,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bloodGroup,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIC: $nic • $gender',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 22),

            // Camp Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.campaign_rounded, size: 18, color: AppTheme.primaryCrimson),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (campVenue.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          campVenue,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time Slot Info
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '$campDate • $startTime - $endTime',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Buttons: Call & Check-In
            Row(
              children: [
                if (phone.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFF0F766E)),
                      label: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => _makePhoneCall(phone),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Verify & Check-In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffScanQrScreen(
                            staffUserData: widget.staffUserData,
                            initialIdentifier: nic.isNotEmpty ? nic : name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.people_outline_rounded, size: 36, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Confirmed Donors Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'No donors matching the current filter have confirmed attendance yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load confirmed donors',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchConfirmedDonors(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
