import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context),
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      decoration: const BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kasun Perera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0CC), // Light gold
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 14,
                          color: Color(0xFFB8860B), // Dark gold
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified Donor',
                          style: TextStyle(
                            color: Color(0xFF8B6508),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatCard(Icons.water_drop, '7', 'Donations')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.calendar_today, '18 Aug', 'Next eligible')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.favorite, '21', 'Lives saved')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction(context, Icons.bloodtype, 'Request', const Color(0xFFD32F2F), '/blood-request'),
              _buildQuickAction(context, Icons.emergency, 'SOS Alert', const Color(0xFFC62828), '/emergency-sos'),
              _buildQuickAction(context, Icons.leaderboard, 'Rankings', const Color(0xFFF57F17), '/leaderboard'),
              _buildQuickAction(context, Icons.history, 'History', const Color(0xFF1976D2), '/donation-history'),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Drives',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Row(
                children: [
                  _buildToggleButton('List', true),
                  _buildToggleButton('Map', false),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search events, hospitals...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textLight, size: 20),
              suffixIcon: Icon(Icons.filter_list, color: AppTheme.textLight, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          _buildDriveCard(
            type: 'Leo Club',
            typeColor: Colors.teal.shade700,
            typeBg: Colors.teal.shade50,
            isVerified: true,
            title: 'Leo Club Colombo Central',
            date: 'Sat, 2 Aug 2026',
            time: '8:00 AM – 1:00 PM',
            location: '57 Galle Road, Colombo 03',
            distance: '1.2 km',
            bloodTypes: ['A+', 'O+', 'B-'],
            donors: '34 donors',
          ),
          const SizedBox(height: 16),
          _buildDriveCard(
            type: 'Hospital',
            typeColor: AppTheme.primaryRed,
            typeBg: AppTheme.primaryRed.withOpacity(0.1),
            isVerified: false,
            title: 'Nawaloka Hospital',
            date: 'Mon, 4 Aug 2026',
            time: '9:00 AM – 3:00 PM',
            location: '23 Deshamanya H.K., Colombo 02',
            distance: '2.8 km',
            bloodTypes: ['O-', 'AB+'],
            donors: '18 donors',
          ),
          const SizedBox(height: 16),
          _buildDriveCard(
            type: 'School',
            typeColor: Colors.orange.shade700,
            typeBg: Colors.orange.shade50,
            isVerified: false,
            title: "St. Bridget's Convent",
            date: 'Wed, 6 Aug 2026',
            time: '7:30 AM – 12:00 PM',
            location: 'Alexandra Place, Colombo 07',
            distance: '4.1 km',
            bloodTypes: ['A+', 'A-', 'B+', 'O+'],
            donors: '52 donors',
          ),
           const SizedBox(height: 16),
          _buildDriveCard(
            type: 'Church',
            typeColor: Colors.blue.shade700,
            typeBg: Colors.blue.shade50,
            isVerified: false,
            title: "Church of Ceylon",
            date: 'Sat, 9 Aug 2026',
            time: '8:30 AM – 1:30 PM',
            location: '368 Bauddaloka Mawatha,\nColombo 07',
            distance: '5.6 km',
            bloodTypes: ['B+', 'AB-'],
            donors: '11 donors',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryRed : Colors.white,
        borderRadius: label == 'List'
            ? const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))
            : const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
        border: Border.all(color: isActive ? AppTheme.primaryRed : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textDark,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDriveCard({
    required String type,
    required Color typeColor,
    required Color typeBg,
    required bool isVerified,
    required String title,
    required String date,
    required String time,
    required String location,
    required String distance,
    required List<String> bloodTypes,
    required String donors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF0CC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, size: 12, color: Color(0xFFB8860B)),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified',
                            style: TextStyle(
                              color: Color(0xFF8B6508),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Text(
                '$date · $time',
                style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppTheme.textLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.navigation, size: 12, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: bloodTypes.map((bt) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bt,
                      style: const TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              Row(
                children: [
                  const Icon(Icons.favorite, size: 14, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(
                    donors,
                    style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, String route) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
