import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StaffDonorHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> staffUserData;
  final String? initialSearch;

  const StaffDonorHistoryScreen({
    super.key,
    required this.staffUserData,
    this.initialSearch,
  });

  @override
  State<StaffDonorHistoryScreen> createState() => _StaffDonorHistoryScreenState();
}

class _StaffDonorHistoryScreenState extends State<StaffDonorHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _donations = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
    }
    _fetchDonationHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonationHistory({String? query}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final q = query ?? _searchController.text.trim();
      final items = await ApiService.getStaffDonorHistory(search: q);
      if (mounted) {
        setState(() {
          _donations = items;
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
          _errorMessage = 'Could not load donation records. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'TRANSFUSED':
        return const Color(0xFF16A34A);
      case 'TESTED':
        return const Color(0xFF2563EB);
      case 'STORED':
        return const Color(0xFFD97706);
      case 'REJECTED':
      case 'DISCARDED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
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
          'Donor Donation History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCrimson),
            onPressed: () => _fetchDonationHistory(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar & Filter Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by NIC, Donor Name, Phone, or Pass ID...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryCrimson),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _fetchDonationHistory(query: '');
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
                    onSubmitted: (val) => _fetchDonationHistory(query: val),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Quick filter:',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('All Records', ''),
                      const SizedBox(width: 6),
                      _buildFilterChip('Raveen', 'Raveen'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Batticaloa', 'Batticaloa'),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Donation Records List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCrimson))
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _donations.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              color: AppTheme.primaryCrimson,
                              onRefresh: () => _fetchDonationHistory(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _donations.length,
                                itemBuilder: (context, index) {
                                  final item = _donations[index] as Map<String, dynamic>;
                                  return _buildDonationHistoryCard(item);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String q) {
    final isSelected = _searchController.text.trim().toLowerCase() == q.toLowerCase();
    return InkWell(
      onTap: () {
        _searchController.text = q;
        _fetchDonationHistory(query: q);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryCrimson : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDonationHistoryCard(Map<String, dynamic> item) {
    final donorName = item['donor_name'] ?? 'Donor Name';
    final nic = item['donor_nic'] ?? 'NIC unlinked';
    final bloodGroup = item['blood_group'] ?? 'Unknown';
    final volume = item['volume_ml'] ?? 450;
    final status = item['status'] ?? 'COMPLETED';
    final locationName = item['location_name'] ?? 'Blood Transfusion Center';
    final locationType = item['location_type'] ?? 'Facility';
    final hb = item['hemoglobins_level'];
    final bp = item['blood_pressure'] ?? '';
    final component = item['component_type'] ?? 'Whole Blood';

    String dateStr = 'Unknown Date';
    String timeStr = '';
    if (item['donation_date'] != null) {
      try {
        final dt = DateTime.parse(item['donation_date']);
        dateStr = DateFormat('MMM dd, yyyy').format(dt);
        timeStr = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            // Top Row: Blood Group, Donor Name & Status Badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      bloodGroup,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryCrimson,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'NIC: $nic',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Middle Row: Location & Type
            Row(
              children: [
                Icon(
                  locationType == 'Field Blood Camp'
                      ? Icons.campaign_rounded
                      : Icons.local_hospital_rounded,
                  size: 16,
                  color: AppTheme.primaryCrimson,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    locationName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Bottom Metrics Row: Date, Volume, Hb & BP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$dateStr${timeStr.isNotEmpty ? ' • $timeStr' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Text(
                  '$volume mL • $component',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            if (hb != null && hb > 0 || (bp is String && bp.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (hb != null && hb > 0) ...[
                      const Icon(Icons.biotech_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        'Hb: $hb g/dL',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(width: 14),
                    ],
                    if (bp is String && bp.isNotEmpty) ...[
                      const Icon(Icons.monitor_heart_rounded, size: 14, color: Color(0xFFE11D48)),
                      const SizedBox(width: 4),
                      Text(
                        'BP: $bp',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFBE123C)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.search_off_rounded, size: 36, color: AppTheme.primaryCrimson),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Donation Records Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with a different NIC, phone, or donor name.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _fetchDonationHistory(query: '');
              },
              child: const Text('Clear Search & View All'),
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
              _errorMessage ?? 'Failed to load records',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchDonationHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
