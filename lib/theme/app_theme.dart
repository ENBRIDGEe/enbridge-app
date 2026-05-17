import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const bgPrimary    = Color(0xFF0A0A0A);
  static const bgSurface    = Color(0xFF141414);
  static const bgCard       = Color(0xFF1A1A1A);
  static const bgElevated   = Color(0xFF1E1E1E);

  static const textPrimary   = Color(0xFFF5F5F0);
  static const textSecondary = Color(0xFF888880);
  static const textTertiary  = Color(0xFF555550);

  static const accentGreen  = Color(0xFF4ADE80);
  static const accentOrange = Color(0xFFF97316);
  static const accentRed    = Color(0xFFE74C3C);

  static const border       = Color(0x10FFFFFF);
  static const borderMid    = Color(0x18FFFFFF);
  static const borderStrong = Color(0x15FFFFFF);

  static const navBg        = Color(0xFF111111);

  static const divider      = Color(0x10FFFFFF);
  static const overlay      = Color(0x80000000);

  static const focusGradientStart = accentGreen;
  static const focusGradientEnd   = accentOrange;
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // Serif display — Playfair Display
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 40, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );
  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );
  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25,
  );
  static TextStyle displayHeading = GoogleFonts.playfairDisplay(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );
  static TextStyle bodyQuote = GoogleFonts.playfairDisplay(
    fontSize: 14, fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
  );

  // Sans-serif — Inter
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle labelEyebrow = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 3.0,
  );
  static TextStyle numberLarge = GoogleFonts.inter(
    fontSize: 40, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle numberMedium = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle ctaButton = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.bgPrimary,
    letterSpacing: 0.3,
  );
  static TextStyle ctaButtonSecondary = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );
  static TextStyle navItem = GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 1.0,
  );
  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle cardSubtitle = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle timerLarge = GoogleFonts.inter(
    fontSize: 56, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle tagLabel = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
  static TextStyle greetingText = GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}

// ─── Decoration Helpers ───────────────────────────────────────────────────────
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({Color? color, double radius = 20, bool border = true}) =>
      BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: AppColors.border, width: 1) : null,
      );

  static BoxDecoration elevatedCard({double radius = 20}) =>
      BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      );

  static InputDecoration inputDecoration({required String hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inputHint,
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderStrong, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderStrong, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        suffixIcon: suffix,
      );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
ThemeData appTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentGreen,
      surface: AppColors.bgPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard,
    ),
    useMaterial3: true,
  );
}
