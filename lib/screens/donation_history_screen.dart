import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DonationHistoryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const DonationHistoryScreen({super.key, this.userData});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 5;
  int _totalCount = 0;
  int _totalPages = 1;

  String? get _donorIdentifier {
    final user = widget.userData;
    if (user == null) return null;
    final donorId = user['donor_id']?.toString();
    if (donorId != null && donorId.isNotEmpty) return donorId;
    final userId = user['user_id']?.toString() ?? user['id']?.toString();
    if (userId != null && userId.isNotEmpty) return userId;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _currentPage = 1;
      });
      _fetchDonations(page: 1);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentPage = 1;
    });
    _fetchDonations(page: 1);
  }

  Future<void> _fetchDonations({int page = 1}) async {
    final donorId = _donorIdentifier;
    if (donorId == null || donorId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No donor profile identifier found. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final res = await ApiService.getDonations(
        donorId: donorId,
        search: _searchController.text.trim(),
        page: _currentPage,
        limit: _pageSize,
      );

      final rawData = res['data'] as List<dynamic>? ?? [];
      final total = res['total'] is int
          ? res['total'] as int
          : (res['total'] is num
                ? (res['total'] as num).toInt()
                : rawData.length);
      final totalPages = res['total_pages'] is int
          ? res['total_pages'] as int
          : (total > 0 ? (total / _pageSize).ceil() : 1);

      setState(() {
        _donations = rawData
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _totalCount = total;
        _totalPages = totalPages > 0 ? totalPages : 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load donation history: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Donation History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchDonations(page: _currentPage),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Header & Universal Search Bar ──────────────────────────────
          _buildSearchAndFilterHeader(),

          // ─── Content List ───────────────────────────────────────────────
          Expanded(child: _buildMainContent()),

          // ─── Page-wise Pagination Bar ───────────────────────────────────
          if (!_isLoading && _donations.isNotEmpty) _buildPaginationBar(),
        ],
      ),
    );
  }

  /// Universal Search Bar & Header
  Widget _buildSearchAndFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                setState(() => _currentPage = 1);
                _fetchDonations(page: 1);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by hospital, camp, date, blood type...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                  size: 21,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 19,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Record count indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isLoading
                    ? 'Loading records...'
                    : 'Found $_totalCount total donation${_totalCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (_searchController.text.trim().isNotEmpty)
                GestureDetector(
                  onTap: _clearSearch,
                  child: const Text(
                    'Clear Search',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryCrimson,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Main Content (List / Loading / Empty / Error)
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryCrimson,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading donation records...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorRed,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchDonations(page: _currentPage),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCrimson,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_donations.isEmpty) {
      final isFiltered = _searchController.text.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bloodtype_outlined,
                  size: 48,
                  color: AppTheme.primaryCrimson,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isFiltered
                    ? 'No Donations Match Your Search'
                    : 'No Donation History Yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? 'Try searching with different keywords like a hospital name, camp, month or blood group.'
                    : 'When you donate blood at a partner hospital or donation camp, your records will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Reset Search Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryCrimson,
                    side: const BorderSide(color: AppTheme.primaryCrimson),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchDonations(page: _currentPage),
      color: AppTheme.primaryCrimson,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: _donations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) {
          final item = _donations[i];
          return _buildDonationCard(item);
        },
      ),
    );
  }

  /// Donation Summary Card
  Widget _buildDonationCard(Map<String, dynamic> item) {
    final isHospital = item['is_hospital'] == true;
    final isCamp = item['is_camp'] == true;
    final hospital = item['hospital'] as Map<String, dynamic>?;
    final camp = item['camp'] as Map<String, dynamic>?;

    String facilityName = 'Blood Donation Facility';
    String facilityLocation = '';
    if (isHospital && hospital != null) {
      facilityName = hospital['name'] ?? 'Hospital';
      facilityLocation = hospital['city'] ?? hospital['address'] ?? '';
    } else if (isCamp && camp != null) {
      facilityName = camp['camp_name'] ?? 'Blood Donation Camp';
      facilityLocation = camp['venue_name'] ?? camp['city'] ?? '';
    }

    final volumeMl = item['volume_ml']?.toString() ?? '—';
    final componentType = (item['component_type'] ?? 'WHOLE_BLOOD')
        .toString()
        .replaceAll('_', ' ');
    final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();
    final hemoglobins = item['hemoglobins_level']?.toString() ?? '—';
    final bloodPressure = item['blood_pressure']?.toString() ?? 'Not recorded';

    // Parse date
    String dateStr = 'Unknown Date';
    String timeStr = '';
    final rawDate = item['donation_date']?.toString();
    if (rawDate != null) {
      try {
        final parsed = DateTime.parse(rawDate).toLocal();
        dateStr = DateFormat('EEE, dd MMM yyyy').format(parsed);
        timeStr = DateFormat('hh:mm a').format(parsed);
      } catch (_) {}
    }

    // Status colors
    Color statusBg = const Color(0xFFDCFCE7);
    Color statusColor = const Color(0xFF15803D);
    if (status == 'TRANSFUSED') {
      statusBg = const Color(0xFFE0F2FE);
      statusColor = const Color(0xFF0369A1);
    } else if (status == 'TESTED') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
    } else if (status == 'STORED') {
      statusBg = const Color(0xFFF3E8FF);
      statusColor = const Color(0xFF7E22CE);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDonationDetailsModal(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Location Tag & Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isHospital
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHospital
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFE9D5FF),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHospital
                              ? Icons.local_hospital_rounded
                              : Icons.campaign_rounded,
                          size: 14,
                          color: isHospital
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF9333EA),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isHospital ? 'HOSPITAL' : 'BLOOD CAMP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isHospital
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF9333EA),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Facility Name
              Text(
                facilityName,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              if (facilityLocation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        facilityLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // Date & Time
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr.isNotEmpty ? '$dateStr • $timeStr' : dateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 10),

              // Clinical Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem(
                    Icons.water_drop_rounded,
                    '$volumeMl ml',
                    componentType,
                  ),
                  _buildMetricItem(
                    Icons.monitor_heart_outlined,
                    '$hemoglobins g/dL',
                    'Hemoglobin',
                  ),
                  _buildMetricItem(
                    Icons.speed_rounded,
                    bloodPressure,
                    'BP Reading',
                  ),
                  IconButton(
                    tooltip: 'More Details',
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: AppTheme.primaryCrimson,
                    ),
                    onPressed: () => _showDonationDetailsModal(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryCrimson),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  /// Page-wise Pagination Controls (1, 2, 3...)
  Widget _buildPaginationBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 1
                  ? () => _fetchDonations(page: _currentPage - 1)
                  : null,
              color: AppTheme.primaryCrimson,
              disabledColor: Colors.grey.shade300,
            ),

            // Numbered Page Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_totalPages, (index) {
                final pageNum = index + 1;
                final isCurrent = pageNum == _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: isCurrent
                        ? null
                        : () => _fetchDonations(page: pageNum),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.primaryCrimson
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Next Button
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _currentPage < _totalPages
                  ? () => _fetchDonations(page: _currentPage + 1)
                  : null,
              color: AppTheme.primaryCrimson,
              disabledColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  /// Full Donation Details Bottom Sheet
  void _showDonationDetailsModal(Map<String, dynamic> item) {
    final isHospital = item['is_hospital'] == true;
    final isCamp = item['is_camp'] == true;
    final hospital = item['hospital'] as Map<String, dynamic>?;
    final camp = item['camp'] as Map<String, dynamic>?;
    final donor = item['donor'] as Map<String, dynamic>?;

    String facilityName = 'Blood Donation Facility';
    String facilityType = isHospital
        ? 'Hospital Walk-in'
        : 'Blood Donation Camp';
    String address = '';
    String city = '';
    String phone = '';
    String contactName = '';
    String contactEmail = '';

    if (isHospital && hospital != null) {
      facilityName = hospital['name'] ?? 'Hospital';
      address = hospital['address'] ?? '';
      city = hospital['city'] ?? '';
      final ph = hospital['phone'];
      if (ph is List && ph.isNotEmpty) {
        phone = ph.join(', ');
      } else if (ph != null) {
        phone = ph.toString();
      }
    } else if (isCamp && camp != null) {
      facilityName = camp['camp_name'] ?? 'Blood Donation Camp';
      address = camp['venue_name'] ?? camp['address'] ?? '';
      city = camp['city'] ?? '';
      final cp = camp['contact_person'];
      if (cp is Map) {
        contactName = cp['name']?.toString() ?? '';
        phone = cp['phone']?.toString() ?? '';
        contactEmail = cp['email']?.toString() ?? '';
      }
    }

    final donationId = item['id']?.toString() ?? '';
    final volumeMl = item['volume_ml']?.toString() ?? '—';
    final componentType = (item['component_type'] ?? 'WHOLE_BLOOD')
        .toString()
        .replaceAll('_', ' ');
    final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();
    final hemoglobins = item['hemoglobins_level']?.toString() ?? '—';
    final bloodPressure = item['blood_pressure']?.toString() ?? 'Not recorded';
    final storageLocation =
        item['storage_location']?.toString() ?? 'Cold Storage Unit';

    // Parse Dates
    String formattedDonationDate = 'Not specified';
    final rawDonationDate = item['donation_date']?.toString();
    if (rawDonationDate != null) {
      try {
        final d = DateTime.parse(rawDonationDate).toLocal();
        formattedDonationDate = DateFormat(
          'EEEE, dd MMMM yyyy • hh:mm a',
        ).format(d);
      } catch (_) {}
    }

    String formattedExpDate = 'Standard shelf period';
    final rawExpDate = item['expiration_date']?.toString();
    if (rawExpDate != null) {
      try {
        final d = DateTime.parse(rawExpDate).toLocal();
        formattedExpDate = DateFormat('dd MMMM yyyy').format(d);
      } catch (_) {}
    }

    // Blood type from donor object if present
    String bloodGroupDisplay = '';
    final btObj = donor?['blood_type'];
    if (btObj is Map) {
      bloodGroupDisplay = btObj['display_name'] ?? btObj['abo_group'] ?? '';
    }
    if (bloodGroupDisplay.isEmpty) {
      bloodGroupDisplay =
          widget.userData?['blood_type']?.toString() ?? 'Compatible';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: AppTheme.successGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                facilityName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                facilityType,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Modal Body
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Timing Section
                        _buildModalSection(
                          icon: Icons.calendar_month_rounded,
                          iconColor: AppTheme.primaryCrimson,
                          title: 'Donation Timing',
                          child: Text(
                            formattedDonationDate,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Clinical Metrics Grid
                        _buildModalSection(
                          icon: Icons.biotech_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Clinical & Blood Metrics',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModalStatCard(
                                      'Volume Donated',
                                      '$volumeMl ml',
                                      Icons.water_drop_rounded,
                                      AppTheme.primaryCrimson,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildModalStatCard(
                                      'Blood Group',
                                      bloodGroupDisplay,
                                      Icons.favorite_rounded,
                                      const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModalStatCard(
                                      'Hemoglobin Level',
                                      '$hemoglobins g/dL',
                                      Icons.monitor_heart_rounded,
                                      const Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildModalStatCard(
                                      'Blood Pressure',
                                      bloodPressure,
                                      Icons.speed_rounded,
                                      const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Component & Inventory
                        _buildModalSection(
                          icon: Icons.inventory_2_rounded,
                          iconColor: const Color(0xFF7E22CE),
                          title: 'Inventory & Processing',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Component Type', componentType),
                              const SizedBox(height: 8),
                              _buildInfoRow('Storage Unit', storageLocation),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Shelf Expiration',
                                formattedExpDate,
                              ),
                              if (donationId.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  'Donation Ref ID',
                                  donationId.substring(0, 8).toUpperCase(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location & Contact
                        _buildModalSection(
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFFEA580C),
                          title: 'Facility & Location Details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (address.isNotEmpty)
                                _buildInfoRow('Address / Venue', address),
                              if (city.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('City', city),
                              ],
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('Phone', phone),
                              ],
                              if (contactName.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('Coordinator', contactName),
                              ],
                              if (contactEmail.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildInfoRow('Email', contactEmail),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Close button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCrimson,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Close Details',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildModalStatCard(
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
