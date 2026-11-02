import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'urgent',
      'title': 'Urgent: B+ Blood Needed',
      'body': 'National Hospital Colombo needs B+ donors urgently. 2 km away.',
      'time': '5 min ago',
      'read': false,
      'icon': Icons.emergency,
    },
    {
      'id': 2,
      'type': 'event',
      'title': 'Upcoming Drive: Nugegoda',
      'body': 'BloodConnectSL Drive on Nov 10 at Town Hall, Nugegoda. Register now!',
      'time': '1 hr ago',
      'read': false,
      'icon': Icons.event,
    },
    {
      'id': 3,
      'type': 'success',
      'title': 'Donation Confirmed 🎉',
      'body': 'Your Oct 28 donation at National Blood Bank has been recorded. +150 points earned!',
      'time': '3 days ago',
      'read': true,
      'icon': Icons.check_circle_outline,
    },
    {
      'id': 4,
      'type': 'reminder',
      'title': 'Donation Eligibility Reminder',
      'body': 'You\'ll be eligible to donate blood again in 56 days. Stay healthy!',
      'time': '5 days ago',
      'read': true,
      'icon': Icons.schedule,
    },
    {
      'id': 5,
      'type': 'urgent',
      'title': 'O− Blood Emergency',
      'body': 'Teaching Hospital Kandy needs O− blood. This blood type is rare — every donor counts.',
      'time': '1 week ago',
      'read': true,
      'icon': Icons.warning_amber,
    },
    {
      'id': 6,
      'type': 'event',
      'title': 'BloodConnectSL Anniversary Drive',
      'body': 'Join our 3rd anniversary donation drive at Viharamahadevi Park on Dec 1.',
      'time': '2 weeks ago',
      'read': true,
      'icon': Icons.celebration,
    },
  ];

  Color _typeColor(String type) {
    switch (type) {
      case 'urgent': return const Color(0xFFD32F2F);
      case 'event': return const Color(0xFF1565C0);
      case 'success': return const Color(0xFF388E3C);
      case 'reminder': return const Color(0xFFF57C00);
      default: return Colors.grey;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'urgent': return const Color(0xFFFFEBEE);
      case 'event': return const Color(0xFFE3F2FD);
      case 'success': return const Color(0xFFE8F5E9);
      case 'reminder': return const Color(0xFFFFF3E0);
      default: return Colors.grey.shade100;
    }
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !(n['read'] as bool)).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text('$unread', style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final isRead = n['read'] as bool;
                final color = _typeColor(n['type'] as String);
                final bg = _typeBg(n['type'] as String);

                return Dismissible(
                  key: ValueKey(n['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => _notifications.removeAt(index));
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() => n['read'] = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : bg.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRead ? Colors.grey.shade100 : color.withOpacity(0.3),
                          width: isRead ? 1 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isRead ? 0.02 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                            child: Icon(n['icon'] as IconData, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'] as String,
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['body'] as String,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  n['time'] as String,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
