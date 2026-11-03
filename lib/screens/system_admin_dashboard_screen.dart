import 'package:flutter/material.dart';
import 'management_screen.dart';

class SystemAdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SystemAdminDashboardScreen({super.key, required this.userData});
  @override
  Widget build(BuildContext context) => ManagementScreen(userData: userData);
}
