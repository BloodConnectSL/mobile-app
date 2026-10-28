import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

class HospitalStaffDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const HospitalStaffDashboardScreen({
    super.key,
    required this.userData,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF0E7490)),
            SizedBox(width: 8),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to log out of the Hospital Staff Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7490),
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
    final username = userData['username'] ?? 'Hospital Staff';
    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;
    final phone = userData['phone'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA).withAlpha(100),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E7490),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hospital Staff Portal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Blood Bank & Lab Duty Station',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            tooltip: 'Pending Requests',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('4 Urgent Blood Requests awaiting cross-match')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Staff Info Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E7490), Color(0xFF155E75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E7490).withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: const Icon(Icons.medical_services_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HOSPITAL STAFF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                phone,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lab Duty Status & Cold Chain Monitor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF99F6E4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.thermostat_rounded, color: Color(0xFF0E7490), size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Cold Chain Monitor',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Color(0xFF15803D)),
                            SizedBox(width: 4),
                            Text(
                              '3.8°C OPTIMAL',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Main Blood Bank Storage Unit #1 (2°C - 6°C Range)',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DutyStat(label: 'Pending Tests', value: '4', color: const Color(0xFFDC2626)),
                      _DutyStat(label: 'In Lab', value: '7', color: const Color(0xFFD97706)),
                      _DutyStat(label: 'Ready to Issue', value: '18', color: const Color(0xFF059669)),
                      _DutyStat(label: 'Issued Today', value: '26', color: const Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hospital Staff Tasks
            const Text(
              'Lab & Shift Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _CapabilityCard(
                  icon: Icons.biotech_rounded,
                  title: 'Cross-Match Entry',
                  subtitle: 'Compatibility results & antibody screen',
                  color: const Color(0xFF0E7490),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Cross-match Entry screen')),
                    );
                  },
                ),
                _CapabilityCard(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Blood Intake Scan',
                  subtitle: 'Scan incoming units from NBTS / Drive',
                  color: const Color(0xFF059669),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scanning blood bag barcode...')),
                    );
                  },
                ),
                _CapabilityCard(
                  icon: Icons.output_rounded,
                  title: 'Issue Blood to Ward',
                  subtitle: 'Release cross-matched units with slips',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Blood Bag Issuing Log')),
                    );
                  },
                ),
                _CapabilityCard(
                  icon: Icons.notification_important_rounded,
                  title: 'Emergency Release',
                  subtitle: 'Immediate Uncross-matched O- release',
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Emergency O- Release Protocol triggered')),
                    );
                  },
                ),
                _CapabilityCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Reaction Reporting',
                  subtitle: 'Log transfusion adverse incidents',
                  color: const Color(0xFFD97706),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transfusion Reaction Reporting form')),
                    );
                  },
                ),
                _CapabilityCard(
                  icon: Icons.checklist_rounded,
                  title: 'Daily Handover',
                  subtitle: 'Shift turnover inventory checklist',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Duty Handover Checklist')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Log Out of Staff Portal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () => _handleLogout(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DutyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DutyStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CapabilityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha(30),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
