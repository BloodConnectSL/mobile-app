import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _topDonors = [
    {'rank': 1, 'name': 'Amaya Perera', 'donations': 18, 'points': 2700, 'bloodType': 'O+', 'badge': '🥇'},
    {'rank': 2, 'name': 'Nuwan Silva', 'donations': 15, 'points': 2250, 'bloodType': 'A+', 'badge': '🥈'},
    {'rank': 3, 'name': 'Dilini Fernando', 'donations': 13, 'points': 1950, 'bloodType': 'B+', 'badge': '🥉'},
    {'rank': 4, 'name': 'Kasun Jayawardena', 'donations': 11, 'points': 1650, 'bloodType': 'AB+', 'badge': ''},
    {'rank': 5, 'name': 'Sachini Rathnayake', 'donations': 10, 'points': 1500, 'bloodType': 'O−', 'badge': ''},
    {'rank': 6, 'name': 'Tharaka Weerasinghe', 'donations': 9, 'points': 1350, 'bloodType': 'A−', 'badge': ''},
    {'rank': 7, 'name': 'Maneesha Gunaratna', 'donations': 8, 'points': 1200, 'bloodType': 'B−', 'badge': ''},
    {'rank': 8, 'name': 'You (shashigew)', 'donations': 5, 'points': 750, 'bloodType': 'O+', 'badge': '', 'isMe': true},
  ];

  final List<Map<String, dynamic>> _rewards = [
    {'title': 'First Drop', 'desc': 'Complete your first donation', 'points': 100, 'icon': Icons.water_drop, 'earned': true},
    {'title': 'Life Saver', 'desc': 'Donate 3 times', 'points': 300, 'icon': Icons.favorite, 'earned': true},
    {'title': 'Hero Donor', 'desc': 'Reach 5 donations', 'points': 500, 'icon': Icons.emoji_events, 'earned': true},
    {'title': 'Champion', 'desc': 'Reach 10 donations', 'points': 1000, 'icon': Icons.military_tech, 'earned': false},
    {'title': 'Legend', 'desc': 'Reach 20 donations', 'points': 2000, 'icon': Icons.stars, 'earned': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: const Text('Leaderboard & Rewards',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🏆  Top Donors'),
            Tab(text: '🎖  My Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboard(),
          _buildRewards(),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topDonors.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildTopThreePodium();
        final donor = _topDonors[index - 1];
        if (donor['rank'] as int <= 3) return const SizedBox.shrink();
        final isMe = donor['isMe'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFFEBEE) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isMe ? AppTheme.primaryRed.withOpacity(0.4) : Colors.grey.shade100, width: isMe ? 1.5 : 1),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('#${donor['rank']}', style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? AppTheme.primaryRed : Colors.grey.shade500, fontSize: 14))),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundColor: isMe ? AppTheme.primaryRed : Colors.grey.shade200,
                child: Text(
                  (donor['name'] as String)[0],
                  style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : AppTheme.textDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(donor['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isMe ? AppTheme.primaryRed : AppTheme.textDark)),
                    Text('${donor['donations']} donations · ${donor['bloodType']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                child: Text('${donor['points']} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF9A825), fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopThreePodium() {
    final top = _topDonors.take(3).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryRed, Color(0xFFB71C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _podiumItem(top[1], 2, 70)),
          Expanded(child: _podiumItem(top[0], 1, 90)),
          Expanded(child: _podiumItem(top[2], 3, 60)),
        ],
      ),
    );
  }

  Widget _podiumItem(Map<String, dynamic> donor, int rank, double height) {
    return Column(
      children: [
        Text(donor['badge'] as String, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withOpacity(0.3),
          child: Text((donor['name'] as String)[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 6),
        Text(
          (donor['name'] as String).split(' ')[0],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        Text('${donor['points']} pts', style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          child: Center(child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
        ),
      ],
    );
  }

  Widget _buildRewards() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF9A825), Color(0xFFF57F17)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.stars, color: Colors.white, size: 36),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Points', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('750 pts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
                  Text('Rank #8 Nationwide', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Badges & Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        ..._rewards.map((r) {
          final earned = r['earned'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: earned ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: earned ? const Color(0xFF81C784) : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: earned ? const Color(0xFF388E3C) : Colors.grey.shade200, shape: BoxShape.circle),
                  child: Icon(r['icon'] as IconData, color: earned ? Colors.white : Colors.grey.shade400, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: earned ? const Color(0xFF1B5E20) : AppTheme.textDark)),
                      Text(r['desc'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('+${r['points']} pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: earned ? const Color(0xFF388E3C) : Colors.grey.shade400)),
                    const SizedBox(height: 4),
                    Icon(earned ? Icons.check_circle : Icons.lock_outline, size: 18, color: earned ? const Color(0xFF388E3C) : Colors.grey.shade300),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
