import 'package:flutter/material.dart';
import 'management_screen.dart';

class OrgAdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const OrgAdminDashboardScreen({super.key, required this.userData});
  @override
  Widget build(BuildContext context) => ManagementScreen(userData: userData);
}
