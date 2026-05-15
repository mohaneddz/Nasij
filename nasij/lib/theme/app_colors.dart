import 'package:flutter/material.dart';

/// NASSAJ design system — single source of truth for all colours.
/// Extracted from the auth screen dark-navy identity.
class AppColors {
  AppColors._();

  // ── Backgrounds ─────────────────────────────────────────
  /// Deep navy — primary screen background
  static const Color background = Color(0xFF0C1222);

  /// Elevated surface — card / input fill
  static const Color surface = Color(0xFF161E31);

  /// Slightly lighter surface — hover / secondary card
  static const Color surfaceHigh = Color(0xFF1A2235);

  // ── Brand — Orange ───────────────────────────────────────
  /// Primary orange accent
  static const Color primary = Color(0xFFE27C44);

  /// Darker orange — gradient end / pressed
  static const Color primaryDeep = Color(0xFFC75A24);

  /// Subtle orange tint for backgrounds
  static const Color primarySubtle = Color(0x26E27C44);

  /// Orange border / separator
  static const Color primaryBorder = Color(0x4DE27C44);

  /// Orange glow (used in button shadows)
  static const Color primaryGlow = Color(0x66E27C44);

  // ── Text ─────────────────────────────────────────────────
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFFB0BAD0);   // white70 equivalent
  static const Color textFaint = Color(0xFF6B7A99);   // white38 equivalent
  static const Color textDisabled = Color(0xFF3D4A66);

  // ── Borders / Dividers ───────────────────────────────────
  static const Color borderSubtle = Color(0x1AFFFFFF);  // white/10
  static const Color borderMedium = Color(0x33FFFFFF);  // white/20
  static const Color divider = Color(0x0DFFFFFF);       // white/5

  // ── Status colours ───────────────────────────────────────
  static const Color success = Color(0xFF4ADE80);
  static const Color successBg = Color(0x1A4ADE80);
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorBg = Color(0x1AFF6B6B);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningBg = Color(0x1AFBBF24);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoBg = Color(0x1A60A5FA);

  // ── Legacy aliases kept for backward compat ─────────────
  static const Color primaryHover = Color(0xE6E27C44);
  static const Color cardBackground = Color(0x0DFFFFFF);
  static const Color cardBackgroundHover = Color(0x12FFFFFF);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color pendingBg = Color(0x2693C5FD);
  static const Color pendingText = Color(0xFF93C5FD);
  static const Color assignedBg = Color(0x1AFFFFFF);
  static const Color assignedText = Color(0x99FFFFFF);

  // ── Gradients ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF141C36), background, Color(0xFF090D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
