import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colour Palette
  static const Color primaryNavy = Color(0xFF0F172A); // Slate 900
  static const Color secondaryBlue = Color(0xFF3B82F6); // Blue 500
  static const Color frostBlue = Color(0xFFE0F2FE); // Light Sky Blue
  static const Color accentRed = Color(0xFFEF4444); // Red 500
  static const Color accentGreen = Color(0xFF10B981); // Emerald 500
  static const Color backgroundWhite = Color(0xFFF8FAFC); // Slate 50
  static const Color cardWhite = Color(0xFFFFFFFF); // Pure White

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryNavy,
    scaffoldBackgroundColor: backgroundWhite,
    colorScheme: const ColorScheme.light(
      primary: primaryNavy,
      secondary: secondaryBlue,
      error: accentRed,
      surface: cardWhite,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryNavy),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryNavy),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryNavy),
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryNavy),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryNavy),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryNavy),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryNavy),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryNavy),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryNavy),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF334155)),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF334155)),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF64748B)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cardWhite,
      foregroundColor: primaryNavy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: primaryNavy,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
  );
}
