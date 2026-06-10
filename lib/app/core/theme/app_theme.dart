import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colour Palette
  static const Color primaryNavy = Color(0xFF001F3F); // Deep Navy Blue
  static const Color frostBlue = Color(0xFFC4E0F9); // Frost Blue
  static const Color accentRed = Color(0xFFFF0000); // Bright Red
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure White

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryNavy, frostBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryNavy,
    scaffoldBackgroundColor: backgroundWhite,
    colorScheme: ColorScheme.light(
      primary: primaryNavy,
      secondary: frostBlue,
      error: accentRed,
    ),
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      displayMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      displaySmall: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      headlineLarge: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      headlineMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      headlineSmall: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      titleLarge: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      titleMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      titleSmall: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: primaryNavy),
      bodyLarge: GoogleFonts.roboto(fontWeight: FontWeight.normal, color: Colors.black87),
      bodyMedium: GoogleFonts.roboto(fontWeight: FontWeight.normal, color: Colors.black87),
      bodySmall: GoogleFonts.roboto(fontWeight: FontWeight.normal, color: Colors.black87),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryNavy,
      foregroundColor: backgroundWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: backgroundWhite,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNavy,
        foregroundColor: backgroundWhite,
        textStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
