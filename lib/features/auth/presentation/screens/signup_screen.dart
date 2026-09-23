import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Create your donor account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF252022),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}