import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Low-luminance OLED Canvas & Surfaces (Precision Spectrum)
  static const Color surface0 = Color(0xFF0F1115); // Deepest Canvas
  static const Color surface1 = Color(0xFF161920); // Elevated Cards
  static const Color surface2 = Color(0xFF1E222B); // Interactive Toggles & Chips
  static const Color surface3 = Color(0xFF262B36); // Nested Panels
  static const Color borderHairline = Color(0xFF2A303C); // 1px borders

  // Semantic Signal Spectrum
  static const Color emerald = Color(0xFF10B981); // Optimal (-30 to -60 dBm)
  static const Color emeraldBright = Color(0xFF4EDEA3); // Accent highlight
  static const Color amber = Color(0xFFF59E0B); // Moderate (-67 to -75 dBm)
  static const Color amberLight = Color(0xFFFFB95F);
  static const Color rose = Color(0xFFF43F5E); // Critical (<-80 dBm, risks)
  static const Color roseLight = Color(0xFFFFB2B7);

  // Typography Contrast
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface0,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emerald,
        surface: AppColors.surface1,
      ),
      textTheme: TextTheme(
        // Inter for human-facing interface
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        // JetBrains Mono for machine telemetry
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.emeraldBright,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
