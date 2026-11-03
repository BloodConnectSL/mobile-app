import '../widgets/prana_logo.dart';
import 'digital_pass_screen.dart';
import 'privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'blood_camps_screen.dart';
import 'donation_camp_map_screen.dart';
import 'donation_history_screen.dart';
import 'donor_profile_screen.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DonorDashboardScreen({super.key, required this.userData});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  late Map<String, dynamic> _userData;
  Map<String, dynamic> _impact = {};
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getImpact(),
        ApiService.getDigitalPass(),
      ]);
      if (!mounted) return;
      setState(() {
        _impact = results[0];
        _userData = {
          ..._userData,
          ...results[1],
          'qr_ref': results[1]['qr_ref_id'],
        };
        _loadError = null;
      });
      await SessionService.updateUserData(_userData);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => DonorProfileScreen(userData: _userData),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _userData = Map<String, dynamic>.from(updated);
      });
      SessionService.updateUserData(_userData);
    }
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
          'Are you sure you want to log out of your donor account?',
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
    final username = userData['username'] ?? 'Donor';
    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final phone = userData['phone'] ?? '';
    final qrRef = userData['qr_ref'] ?? userData['qr_ref_id'] ?? '';
    bool isTruthy(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 't' || s == 'yes';
      }
      return false;
    }

    final isVerified = isTruthy(userData['is_verified']);

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
                  'Prana · Donor',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh donor data',
              onPressed: _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Greeting Hero Card (At the very top)
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
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.22),
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
                                  : 'D',
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
                                    color: Colors.white.withValues(alpha: 0.85),
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
                                    color: Colors.white.withValues(alpha: 0.8),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
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
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Donor Pass ID',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                qrRef,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Pleasing Pending Verification Notice (Positioned after Welcome Card)
                if (!isVerified) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFEE2E2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFB71C1C,
                          ).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_outlined,
                            color: AppTheme.primaryCrimson,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Verification in Progress',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Complete your first donation at any registered camp or hospital drive to unlock your verified badge.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BloodCampsScreen(
                                        initialUserData: userData,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Find upcoming camps',
                                      style: TextStyle(
                                        color: AppTheme.primaryCrimson,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: AppTheme.primaryCrimson,
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
                ],
                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Donation readiness',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _impact['eligibility_message']?.toString() ??
                              'Loading screening status…',
                        ),
                        const Text(
                          'A Doctor makes the final decision at the donation site.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Impact Metrics
                const Text(
                  'My Impact Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetricTile(
                      title: 'Donations',
                      value: _impact['total_donations']?.toString() ?? '—',
                      subtitle: 'Completed',
                      color: AppTheme.primaryCrimson,
                      icon: Icons.favorite_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricTile(
                      title: 'Volume',
                      value: _impact['total_volume_ml']?.toString() ?? '—',
                      subtitle: 'ml donated',
                      color: const Color(0xFF0284C7),
                      icon: Icons.water_drop_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricTile(
                      title: 'Impact score',
                      value: _impact['lives_saved']?.toString() ?? '—',
                      subtitle: 'Impact score',
                      color: AppTheme.successGreen,
                      icon: Icons.health_and_safety_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Services & Options
                const Text(
                  'Quick Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.16,
                  children: [
                    _buildActionCard(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy & my data',
                      description: 'Export and account choices',
                      color: AppTheme.primaryCrimson,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.event_available_rounded,
                      label: 'Find Blood Camps',
                      description: 'Explore upcoming drives',
                      color: AppTheme.primaryCrimson,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BloodCampsScreen(initialUserData: userData),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.qr_code_rounded,
                      label: 'Digital Pass',
                      description: 'Fast check-in at hospitals',
                      color: const Color(0xFF4F46E5),
                      onTap: () {
                        if (qrRef.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _loadError ??
                                    'Your pass is loading. Please refresh.',
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DigitalPassScreen(
                                name: fullName,
                                reference: qrRef,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.history_rounded,
                      label: 'Donation History',
                      description: 'Records and eligibility',
                      color: const Color(0xFF059669),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DonationHistoryScreen(userData: userData),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.map_rounded,
                      label: 'Donation Camp Map View',
                      description: 'Explore live camps in Sri Lanka',
                      color: const Color(0xFF2563EB),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DonationCampMapScreen(userData: userData),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.person_rounded,
                      label: 'My Profile',
                      description: 'View & update profile',
                      color: const Color(0xFFD97706),
                      onTap: () => _openProfile(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(
                        color: Color(0xFFFCA5A5),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
