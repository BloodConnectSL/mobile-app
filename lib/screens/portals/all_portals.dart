import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class OrganizerPortalScreen extends StatelessWidget {
  const OrganizerPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPortalLayout(
      context: context,
      title: 'Organizer Portal',
      subtitle: 'Manage your blood donation drives.',
      stats: [
        _buildStatCard(Icons.campaign, '12', 'Total Drives'),
        _buildStatCard(Icons.group, '850', 'Total Donors'),
      ],
      actions: [
        _buildActionButton(Icons.add, 'Create New Drive', AppTheme.primaryRed),
        _buildActionButton(Icons.list_alt, 'View Past Drives', Colors.grey.shade800),
      ],
    );
  }
}

class HospitalPortalScreen extends StatelessWidget {
  const HospitalPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPortalLayout(
      context: context,
      title: 'Hospital Portal',
      subtitle: 'Manage blood requests and verify donors.',
      stats: [
        _buildStatCard(Icons.bloodtype, '45', 'Units Needed'),
        _buildStatCard(Icons.verified, '120', 'Verified Today'),
      ],
      actions: [
        _buildActionButton(Icons.local_hospital, 'Request Blood', AppTheme.primaryRed),
        _buildActionButton(Icons.qr_code_scanner, 'Scan Donor QR', Colors.grey.shade800),
      ],
    );
  }
}

class AdminPortalScreen extends StatelessWidget {
  const AdminPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPortalLayout(
      context: context,
      title: 'Admin Portal',
      subtitle: 'Review and approve registrations.',
      stats: [
        _buildStatCard(Icons.pending_actions, '5', 'Pending Orgs'),
        _buildStatCard(Icons.local_pharmacy, '2', 'Pending Hospitals'),
      ],
      actions: [
        _buildActionButton(Icons.rule, 'Review Registrations', AppTheme.primaryRed),
        _buildActionButton(Icons.manage_accounts, 'Manage Users', Colors.grey.shade800),
      ],
    );
  }
}

class SuperAdminPortalScreen extends StatelessWidget {
  const SuperAdminPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPortalLayout(
      context: context,
      title: 'Super Admin Panel',
      subtitle: 'System overview and configurations.',
      stats: [
        _buildStatCard(Icons.health_and_safety, '99.9%', 'System Uptime'),
        _buildStatCard(Icons.storage, '12TB', 'DB Usage'),
      ],
      actions: [
        _buildActionButton(Icons.analytics, 'View Analytics', Colors.teal.shade700),
        _buildActionButton(Icons.bug_report, 'System Logs', Colors.grey.shade800),
      ],
    );
  }
}

// Shared layout builder for all portals to keep code DRY in this prototype
Widget _buildPortalLayout({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<Widget> stats,
  required List<Widget> actions,
}) {
  return Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      backgroundColor: AppTheme.primaryRed,
      elevation: 0,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: stats[0]),
                const SizedBox(width: 16),
                Expanded(child: stats[1]),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            ...actions.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: action,
                )),
          ],
        ),
      ),
    ),
  );
}

Widget _buildStatCard(IconData icon, String value, String label) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 28),
        const SizedBox(height: 16),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ],
    ),
  );
}

Widget _buildActionButton(IconData icon, String label, Color color) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
      ),
    ),
  );
}
