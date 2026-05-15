import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// NASSAJ text styles — Cairo for headings, Inter for body.
class AppTextStyles {
  AppTextStyles._();

  // ── Cairo (headings / labels) ────────────────────────────
  static TextStyle displayLarge = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
    height: 1.15,
  );

  static TextStyle headingLarge = GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    height: 1.2,
  );

  static TextStyle headingMedium = GoogleFonts.cairo(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    height: 1.25,
  );

  static TextStyle headingSmall = GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static TextStyle label = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
  );

  // ── Inter (body / metadata) ──────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textFaint,
    letterSpacing: 0.4,
  );

  static TextStyle captionAllCaps = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.textFaint,
    letterSpacing: 0.8,
  );

  static TextStyle buttonLabel = GoogleFonts.cairo(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static TextStyle buttonLabelSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );
}

/// Global ThemeData so MaterialApp picks up the brand colours automatically.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    dividerColor: AppColors.divider,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: GoogleFonts.inter(color: AppColors.textWhite),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
