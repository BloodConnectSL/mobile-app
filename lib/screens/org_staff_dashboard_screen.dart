import '../widgets/prana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'account_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'staff_confirmed_donors_screen.dart';
import 'staff_donor_history_screen.dart';
import 'staff_reports_screen.dart';
import 'staff_scan_qr_screen.dart';

class OrgStaffDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OrgStaffDashboardScreen({super.key, required this.userData});

  @override
  State<OrgStaffDashboardScreen> createState() =>
      _OrgStaffDashboardScreenState();
}

class _OrgStaffDashboardScreenState extends State<OrgStaffDashboardScreen> {
  late Map<String, dynamic> _userData;
  Map<String, dynamic>? _ongoingCamp;
  bool _isLoadingCamp = true;
  String? _campError;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _loadOngoingCamp();
  }

  String get _staffUserId {
    return _userData['id']?.toString() ??
        _userData['user_id']?.toString() ??
        '';
  }

  Future<void> _loadOngoingCamp() async {
    final staffId = _staffUserId;
    if (staffId.isEmpty) {
      if (mounted) setState(() => _isLoadingCamp = false);
      return;
    }

    setState(() {
      _isLoadingCamp = true;
      _campError = null;
    });

    try {
      final duty = await ApiService.getActiveStaffDuty(
        staffUserId: staffId,
        staffRole: 'ORGANIZATION_STAFF',
      );
      if (mounted) {
        setState(() {
          _ongoingCamp = duty;
          _isLoadingCamp = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _campError = e.toString();
          _isLoadingCamp = false;
        });
      }
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.primaryCrimson),
            SizedBox(width: 8),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of the Organization Staff Portal?',
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
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
              if (!context.mounted) return;
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
    final userData = _userData;
    final username = userData['username'] ?? 'Staff Member';
    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final phone = userData['phone'] ?? '';
    final orgName = userData['org_name'] ?? 'Sri Lanka Red Cross Society';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          titleSpacing: 16,
          title: const Row(
            children: [
              PranaLogo(size: 36),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Prana · Camp staff',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Refresh Assignments',
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryCrimson,
                size: 24,
              ),
              onPressed: _loadOngoingCamp,
            ),
            IconButton(
              tooltip: 'My Profile',
              icon: const Icon(
                Icons.account_circle_outlined,
                color: AppTheme.primaryCrimson,
                size: 28,
              ),
              onPressed: () => _openProfile(context),
            ),
            IconButton(
              tooltip: 'Log Out',
              icon: const Icon(
                Icons.logout_rounded,
                color: AppTheme.primaryCrimson,
              ),
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadOngoingCamp,
            color: AppTheme.primaryCrimson,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. User Greeting Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFB71C1C,
                          ).withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : 'O',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
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
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@$username',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Phone',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    phone.isNotEmpty ? phone : 'Unlinked',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Affiliated Org',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    orgName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Ongoing Assigned Blood Camp Section (Dynamically loaded from assigned_staff_members)
                  _buildOngoingCampSection(),

                  const SizedBox(height: 24),

                  // 3. Four Quick Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      // Action 1: Scan QR
                      _buildQuickActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan QR',
                        subtitle: 'Verify donor pass & eligibility',
                        badgeColor: const Color(0xFFB71C1C),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StaffScanQrScreen(staffUserData: _userData),
                            ),
                          );
                        },
                      ),

                      // Action 2: Donor History
                      _buildQuickActionCard(
                        icon: Icons.history_rounded,
                        title: 'Donor History',
                        subtitle: 'Search past donation records',
                        badgeColor: const Color(0xFF0284C7),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StaffDonorHistoryScreen(
                                staffUserData: _userData,
                              ),
                            ),
                          );
                        },
                      ),

                      // Action 3: Report
                      _buildQuickActionCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Report',
                        subtitle: 'Turnout & units collected',
                        badgeColor: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StaffReportsScreen(staffUserData: _userData),
                            ),
                          );
                        },
                      ),

                      // Action 4: Confirmed Donors
                      _buildQuickActionCard(
                        icon: Icons.how_to_reg_rounded,
                        title: 'Confirmed Donors',
                        subtitle: 'Upcoming drive registrations',
                        badgeColor: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StaffConfirmedDonorsScreen(
                                staffUserData: _userData,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryCrimson,
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        backgroundColor: const Color(0xFFFEF2F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Log Out of Staff Portal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => _handleLogout(context),
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

  // ─── Ongoing Camp Card (Filtered from assigned_staff_members status = 'ongoing') ─
  Widget _buildOngoingCampSection() {
    if (_isLoadingCamp) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryCrimson,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading active camp assignment...',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_campError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Could not load camp assignment: $_campError',
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      );
    }

    final isOngoing =
        _ongoingCamp != null &&
        _ongoingCamp!['status']?.toString().toLowerCase() == 'ongoing' &&
        (_ongoingCamp!['facility_id']?.toString().isNotEmpty ?? false);

    if (!isOngoing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Ongoing Camp Assigned',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You currently have no ongoing blood donation camp assigned in assigned_staff_members. Active camps assigned to you by your Organization Administrator will appear here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Ongoing Active Camp Details
    final campName = _ongoingCamp!['facility_name'] ?? 'Active Blood Camp';
    final venue = _ongoingCamp!['venue_or_addr'] ?? '';
    final district = _ongoingCamp!['district'] ?? '';
    final startTime = _ongoingCamp!['start_time'] ?? '';
    final endTime = _ongoingCamp!['end_time'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with green ongoing indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ASSIGNED ONGOING BLOOD CAMP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF15803D),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE DRIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.25,
                  ),
                ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.primaryCrimson,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venue,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (district.isNotEmpty || startTime.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (district.isNotEmpty) ...[
                        const Icon(
                          Icons.map_rounded,
                          size: 15,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          district,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                      if (district.isNotEmpty && startTime.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      if (startTime.isNotEmpty) ...[
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$startTime - $endTime',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const Divider(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Scan Donors for this Camp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StaffScanQrScreen(staffUserData: _userData),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: badgeColor, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
