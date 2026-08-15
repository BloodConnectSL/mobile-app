/*
Change made by: Nipuna Lakruwan
Date: 2026-08-15
Added: Placeholder Signup Screen component.
How: Created this blank file as a target for the GoRouter '/signup' route.
*/
import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const Center(
        child: Text('Sign Up Screen (Placeholder)'),
      ),
    );
  }
}
