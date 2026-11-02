import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  static const List<Map<String, dynamic>> _donations = [
    {
      'date': 'Oct 28, 2026',
      'location': 'National Blood Bank, Colombo',
      'bloodType': 'O+',
      'units': 1,
      'status': 'Completed',
      'recipient': 'Emergency Ward',
      'points': 150,
    },
    {
      'date': 'Aug 10, 2026',
      'location': 'Teaching Hospital, Kandy',
      'bloodType': 'O+',
      'units': 1,
      'status': 'Completed',
      'recipient': 'Maternity Ward',
      'points': 150,
    },
    {
      'date': 'May 3, 2026',
      'location': 'District Hospital, Galle',
      'bloodType': 'O+',
      'units': 1,
      'status': 'Completed',
      'recipient': 'Surgery Dept.',
      'points': 150,
    },
    {
      'date': 'Jan 15, 2026',
      'location': 'BloodConnectSL Drive, Nugegoda',
      'bloodType': 'O+',
      'units': 1,
      'status': 'Completed',
      'recipient': 'Blood Bank Reserve',
      'points': 100,
    },
    {
      'date': 'Sep 22, 2025',
      'location': 'Nawaloka Hospital, Colombo',
      'bloodType': 'O+',
      'units': 1,
      'status': 'Completed',
      'recipient': 'Pediatric Ward',
      'points': 150,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalDonations = _donations.length;
    final totalPoints = _donations.fold<int>(0, (sum, d) => sum + (d['points'] as int));
    final totalUnits = _donations.fold<int>(0, (sum, d) => sum + (d['units'] as int));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: const Text(
          'Donation History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Summary stats banner
          Container(
            color: AppTheme.primaryRed,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                _statBadge('$totalDonations', 'Donations'),
                const SizedBox(width: 12),
                _statBadge('${totalUnits}L', 'Blood Given'),
                const SizedBox(width: 12),
                _statBadge('$totalPoints', 'Points'),
              ],
            ),
          ),

          // Next eligible
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFFF57C00), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Eligible Donation',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text('You can donate again on Jan 26, 2027', style: TextStyle(color: Color(0xFFBF360C), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _donations.length,
              itemBuilder: (context, index) {
                final donation = _donations[index];
                final isLast = index == _donations.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline line + dot
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 8)],
                            ),
                            child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(width: 2, color: Colors.grey.shade200),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Card
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(bottom: isLast ? 24 : 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryRed,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      donation['bloodType'] as String,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${donation['points']} pts',
                                      style: const TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                donation['location'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(donation['date'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(width: 14),
                                  Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(donation['recipient'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
