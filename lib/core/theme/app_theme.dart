/*
Change made by: Nipuna Lakruwan
Date: 2026-08-15
Added: Global AppTheme using Google Fonts (Inter).
How: Created this file to ensure all contributors use the same design tokens and colors.
*/
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD32F2F), // Example brand red
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }
}
