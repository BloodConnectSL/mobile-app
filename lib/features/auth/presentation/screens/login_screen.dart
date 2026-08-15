/*
Change made by: Nipuna Lakruwan
Date: 2026-08-15
Added: Placeholder Login Screen component.
How: Created this blank file as a target for the GoRouter '/login' route.
*/
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Text('Login Screen (Placeholder)'),
      ),
    );
  }
}
