import 'package:flutter/material.dart';
import 'management_screen.dart';

class HospitalAdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const HospitalAdminDashboardScreen({super.key, required this.userData});
  @override
  Widget build(BuildContext context) => ManagementScreen(userData: userData);
}
