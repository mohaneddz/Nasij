import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0C1222);
  static const Color darkSurface = Color(0xFF1A2235);
  static const Color darkSurfaceLight = Color(0xFF161E31);
  static const Color primaryOrange = Color(0xFFDF7E44);

  static const Color borderDark = Colors.white12;
  static final Color borderOrange = Colors.orange.withValues(alpha: 0.3);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE27C44), Color(0xFFC75A24)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFFE27C44).withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> subtleShadow = const [
    BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5)),
  ];

  /// Standard dark-theme input decoration used across worker screens.
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
        letterSpacing: 0.8,
      ),
      prefixIcon: Icon(icon, color: Colors.white24, size: 20),
      filled: true,
      fillColor: darkBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryOrange, width: 1.5),
      ),
    );
  }
}
