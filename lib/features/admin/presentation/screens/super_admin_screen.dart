import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summaryCards = [
      _SummaryCard(
        title: 'Users',
        value: '2,456',
        color: const Color(0xFFB71C1C),
      ),
      _SummaryCard(
        title: 'Requests',
        value: '148',
        color: const Color(0xFFEF5350),
      ),
      _SummaryCard(
        title: 'Verified',
        value: '96%',
        color: const Color(0xFF7B1FA2),
      ),
      _SummaryCard(
        title: 'Alerts',
        value: '09',
        color: const Color(0xFF455A64),
      ),
    ];

    final roles = [
      _RoleRow(
        name: 'Super Admin',
        status: 'Active',
        color: const Color(0xFFB71C1C),
      ),
      _RoleRow(
        name: 'Operations Admin',
        status: 'Active',
        color: const Color(0xFFEF5350),
      ),
      _RoleRow(
        name: 'Medical Coordinator',
        status: 'Reviewing',
        color: const Color(0xFF6A1B9A),
      ),
      _RoleRow(
        name: 'Support Team',
        status: 'Online',
        color: const Color(0xFF2E7D32),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        actions: [
          IconButton(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.dashboard_customize_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System control center',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage users, requests, approvals, and operational health.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 22),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summaryCards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) => summaryCards[index],
              ),
              const SizedBox(height: 26),
              const Text(
                'Role management',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(children: roles),
              ),
              const SizedBox(height: 26),
              const Text(
                'Admin actions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _AdminActionChip(
                    label: 'Manage users',
                    icon: Icons.people_alt_rounded,
                  ),
                  _AdminActionChip(
                    label: 'Review requests',
                    icon: Icons.assignment_turned_in_rounded,
                  ),
                  _AdminActionChip(
                    label: 'Audit logs',
                    icon: Icons.history_rounded,
                  ),
                  _AdminActionChip(
                    label: 'Reports',
                    icon: Icons.bar_chart_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Priority notice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Three donor verification requests are waiting for approval and 2 emergency blood request cases require escalation.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final String name;
  final String status;
  final Color color;

  const _RoleRow({
    required this.name,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AdminActionChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB71C1C)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
