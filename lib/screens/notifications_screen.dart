import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.management('/notifications');
      if (mounted) {
        setState(() {
          _items = r['data'] as List<dynamic>? ?? [];
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('You’re all caught up.'),
                  ),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        item['read_at'] == null
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                      ),
                      title: Text(item['title']?.toString() ?? ''),
                      subtitle: Text(item['message']?.toString() ?? ''),
                      trailing: item['read_at'] == null
                          ? IconButton(
                              tooltip: 'Mark read',
                              icon: const Icon(Icons.done),
                              onPressed: () async {
                                await ApiService.management(
                                  '/notifications/${item['id']}/read',
                                  method: 'PATCH',
                                );
                                await _load();
                              },
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
  );
}
