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

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  static const int _pageSize = 15;

  // Date filtering state
  DateTime? _selectedDate;
  String _datePreset = 'all'; // 'all', 'today', 'yesterday', 'custom'

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

  String get _staffUserId {
    return widget.staffUserData['id']?.toString() ??
        widget.staffUserData['user_id']?.toString() ??
        '';
  }

  String get _staffRole {
    return widget.staffUserData['role']?.toString().toUpperCase() ?? 'STAFF';
  }

  Future<void> _fetchDonationHistory({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final q = _searchController.text.trim();
      String? dateParam;
      if (_selectedDate != null) {
        dateParam = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }

      final result = await ApiService.getStaffDonorHistory(
        search: q.isNotEmpty ? q : null,
        date: dateParam,
        page: _currentPage,
        limit: _pageSize,
        staffUserId: _staffUserId,
        staffRole: _staffRole,
      );

      final items = (result['items'] as List<dynamic>?) ?? [];
      final total = (result['total'] as int?) ?? items.length;
      final pages = (total / _pageSize).ceil();

      if (mounted) {
        setState(() {
          _donations = items;
          _totalCount = total;
          _totalPages = pages < 1 ? 1 : pages;
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

  void _setDatePreset(String preset) {
    DateTime? dt;
    final now = DateTime.now();

    if (preset == 'today') {
      dt = DateTime(now.year, now.month, now.day);
    } else if (preset == 'yesterday') {
      dt = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    } else if (preset == 'all') {
      dt = null;
    }

    setState(() {
      _datePreset = preset;
      _selectedDate = dt;
    });
    _fetchDonationHistory(page: 1);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
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
        _selectedDate = picked;
        _datePreset = 'custom';
      });
      _fetchDonationHistory(page: 1);
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

  // ─── Group Donations Day by Day ─────────────────────────────────────────────
  Map<String, List<Map<String, dynamic>>> _groupDonationsByDay() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final raw in _donations) {
      if (raw is! Map<String, dynamic>) continue;
      String dayKey = 'Unknown Date';
      if (raw['donation_date'] != null) {
        try {
          final dt = DateTime.parse(raw['donation_date']);
          dayKey = DateFormat('yyyy-MM-dd').format(dt);
        } catch (_) {}
      }

      grouped.putIfAbsent(dayKey, () => []).add(raw);
    }

    return grouped;
  }

  String _formatDayTitle(String dayKey) {
    if (dayKey == 'Unknown Date') return 'Undated Donations';
    try {
      final dt = DateTime.parse(dayKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(dt.year, dt.month, dt.day);

      final diffDays = today.difference(target).inDays;
      if (diffDays == 0) {
        return 'Today • ${DateFormat('EEEE, MMM dd, yyyy').format(dt)}';
      } else if (diffDays == 1) {
        return 'Yesterday • ${DateFormat('EEEE, MMM dd, yyyy').format(dt)}';
      } else {
        return DateFormat('EEEE, MMM dd, yyyy').format(dt);
      }
    } catch (_) {
      return dayKey;
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
            onPressed: () => _fetchDonationHistory(page: _currentPage),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Universal Search Bar & Date Filter Strip
            _buildSearchAndFilterHeader(),

            // 2. Donation Records Grouped Day by Day
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryCrimson))
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _donations.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              color: AppTheme.primaryCrimson,
                              onRefresh: () => _fetchDonationHistory(page: _currentPage),
                              child: _buildGroupedListView(),
                            ),
            ),

            // 3. Pagination Controls
            if (!_isLoading && _donations.isNotEmpty) _buildPaginationBar(),
          ],
        ),
      ),
    );
  }

  // ─── Search & Date Filter Header ───────────────────────────────────────────
  Widget _buildSearchAndFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Universal Search TextField
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by Pass ID (bcnt006), NIC, Name, or Date...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryCrimson),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _fetchDonationHistory(page: 1);
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
            onSubmitted: (_) => _fetchDonationHistory(page: 1),
          ),
          const SizedBox(height: 10),

          // Date Filter Pills (Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDatePill(
                  label: 'All Dates',
                  isActive: _datePreset == 'all',
                  onTap: () => _setDatePreset('all'),
                ),
                const SizedBox(width: 8),
                _buildDatePill(
                  label: 'Today',
                  isActive: _datePreset == 'today',
                  onTap: () => _setDatePreset('today'),
                ),
                const SizedBox(width: 8),
                _buildDatePill(
                  label: 'Yesterday',
                  isActive: _datePreset == 'yesterday',
                  onTap: () => _setDatePreset('yesterday'),
                ),
                const SizedBox(width: 8),
                _buildDatePill(
                  label: _datePreset == 'custom' && _selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                      : 'Pick Date 📅',
                  isActive: _datePreset == 'custom',
                  onTap: _pickCustomDate,
                  isCalendar: true,
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _setDatePreset('all'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryCrimson),
                          SizedBox(width: 4),
                          Text('Reset Date', style: TextStyle(fontSize: 11, color: AppTheme.primaryCrimson, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isCalendar = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryCrimson : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: AppTheme.primaryCrimson)
              : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCalendar && !isActive) ...[
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grouped Day-by-Day List View ──────────────────────────────────────────
  Widget _buildGroupedListView() {
    final grouped = _groupDonationsByDay();
    final dayKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: dayKeys.length,
      itemBuilder: (context, dayIndex) {
        final dayKey = dayKeys[dayIndex];
        final dayItems = grouped[dayKey] ?? [];

        int dayVolume = 0;
        for (final item in dayItems) {
          dayVolume += (item['volume_ml'] as num?)?.toInt() ?? 450;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day Header Section
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCrimson,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDayTitle(dayKey),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dayItems.length} records • $dayVolume mL',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Donation Cards for this day
            ...dayItems.map((item) => _buildDonationHistoryCard(item)),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  // ─── Single Donation History Card ──────────────────────────────────────────
  Widget _buildDonationHistoryCard(Map<String, dynamic> item) {
    final donorName = item['donor_name'] ?? 'Donor Name';
    final nic = item['donor_nic'] ?? 'NIC unlinked';
    final qrRef = item['qr_ref_id']?.toString() ?? '';
    final bloodGroup = item['blood_group'] ?? 'Unknown';
    final volume = item['volume_ml'] ?? 450;
    final status = item['status'] ?? 'COMPLETED';
    final locationName = item['location_name'] ?? 'Blood Transfusion Center';
    final locationType = item['location_type'] ?? 'Facility';
    final hb = item['hemoglobins_level'];
    final bp = item['blood_pressure'] ?? '';
    final component = item['component_type'] ?? 'Whole Blood';

    String timeStr = '';
    if (item['donation_date'] != null) {
      try {
        final dt = DateTime.parse(item['donation_date']);
        timeStr = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final statusColor = _getStatusColor(status);

    return InkWell(
      onTap: () => _openDonationDetailSheet(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'NIC: $nic',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            if (qrRef.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  qrRef,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4338CA),
                                  ),
                                ),
                              ),
                            ],
                          ],
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

              // Location Row
              Row(
                children: [
                  Icon(
                    locationType.contains('Camp')
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

              // Bottom Details Row: Time, Volume, Hb, BP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        timeStr.isNotEmpty ? timeStr : 'Recorded',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '$volume mL • $component',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // ─── Pagination Bar ────────────────────────────────────────────────────────
  Widget _buildPaginationBar() {
    final start = (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize) > _totalCount ? _totalCount : (_currentPage * _pageSize);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Range Indicator
          Text(
            'Showing $start-$end of $_totalCount',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),

          // Pagination Buttons
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: _currentPage > 1 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                  ),
                ),
                onPressed: _currentPage > 1
                    ? () => _fetchDonationHistory(page: _currentPage - 1)
                    : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: _currentPage > 1 ? AppTheme.textPrimary : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Prev',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentPage > 1 ? AppTheme.textPrimary : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: _currentPage < _totalPages ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                  ),
                ),
                onPressed: _currentPage < _totalPages
                    ? () => _fetchDonationHistory(page: _currentPage + 1)
                    : null,
                child: Row(
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentPage < _totalPages ? AppTheme.textPrimary : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _currentPage < _totalPages ? AppTheme.textPrimary : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Modal Sheet for Donation Details ──────────────────────────────────────
  void _openDonationDetailSheet(Map<String, dynamic> item) {
    final donorName = item['donor_name'] ?? 'Donor Name';
    final nic = item['donor_nic'] ?? '';
    final phone = item['donor_phone'] ?? '';
    final qrRef = item['qr_ref_id']?.toString() ?? '';
    final bg = item['blood_group'] ?? 'Unknown';
    final vol = item['volume_ml'] ?? 450;
    final status = item['status'] ?? 'COMPLETED';
    final locName = item['location_name'] ?? 'Facility';
    final hb = item['hemoglobins_level'];
    final bp = item['blood_pressure'] ?? 'Not Recorded';
    final comp = item['component_type'] ?? 'Whole Blood';
    final donId = item['id']?.toString() ?? '';

    String dateFull = 'Recorded Date';
    if (item['donation_date'] != null) {
      try {
        final dt = DateTime.parse(item['donation_date']);
        dateFull = DateFormat('MMMM dd, yyyy • hh:mm a').format(dt);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFEE2E2),
                  child: Text(
                    bg,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryCrimson, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donorName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIC: $nic ${qrRef.isNotEmpty ? '• Pass ID: $qrRef' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Date & Time', dateFull),
                  const Divider(height: 14),
                  _buildReceiptRow('Facility', locName),
                  const Divider(height: 14),
                  _buildReceiptRow('Volume', '$vol mL ($comp)'),
                  const Divider(height: 14),
                  _buildReceiptRow('Blood Pressure', bp.toString()),
                  const Divider(height: 14),
                  _buildReceiptRow('Hemoglobin (Hb)', hb != null ? '$hb g/dL' : '13.5 g/dL'),
                  const Divider(height: 14),
                  _buildReceiptRow('Status', status),
                  if (phone.isNotEmpty) ...[
                    const Divider(height: 14),
                    _buildReceiptRow('Donor Phone', phone),
                  ],
                  if (donId.isNotEmpty) ...[
                    const Divider(height: 14),
                    _buildReceiptRow('Donation ID', donId.length > 16 ? '${donId.substring(0, 12)}...' : donId),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCrimson,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ),
      ],
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
              'Try searching with another donor Pass ID, name, NIC, or clear the date filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _setDatePreset('all');
              },
              child: const Text('Clear Filters & View All'),
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
              onPressed: () => _fetchDonationHistory(page: _currentPage),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
