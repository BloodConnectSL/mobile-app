import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My account')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getCurrentUser(),
      builder: (context, s) {
        if (s.hasError) return Center(child: Text(s.error.toString()));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final user = s.data!['user'] as Map;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final key in [
              'username',
              'first_name',
              'last_name',
              'phone',
              'role',
              'status',
            ])
              ListTile(
                title: Text(key.replaceAll('_', ' ')),
                subtitle: Text(user[key]?.toString() ?? 'Not provided'),
              ),
          ],
        );
      },
    ),
  );
}
