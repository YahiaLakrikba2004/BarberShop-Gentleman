import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Luxury Barber Shop Colors - White & Black (Monochrome)
  static const Color luxuryGold = Color(0xFFFFFFFF); // White
  static const Color darkGold = Color(0xFFBDBDBD); // Grey
  static const Color lightGold = Color(0xFFF5F5F5); // Off-white
  static const Color richBlack = Color(0xFF0A0A0A); // Rich black
  static const Color deepBlack = Color(0xFF1A1A1A); // Deep black
  static const Color charcoal = Color(0xFF2C2C2C); // Charcoal
  static const Color barberRed = Color(0xFFDC143C); // Accent red
  static const Color luxuryText = Color(0xFFFAFAFA); // Off-white for text
  
  // Compatibility colors
  static const Color barberWhite = Color(0xFFFAFAFA);
  static const Color barberBlack = Color(0xFF1A1A1A);
  static const Color barberGray = Color(0xFF757575);
  static const Color barberLightGray = Color(0xFFE0E0E0);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: luxuryGold,
      onPrimary: richBlack,
      primaryContainer: lightGold,
      onPrimaryContainer: deepBlack,
      secondary: barberRed,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFEBEE),
      onSecondaryContainer: barberRed,
      surface: Colors.white,
      onSurface: deepBlack,
      surfaceVariant: Color(0xFFFAF8F3),
      onSurfaceVariant: charcoal,
      outline: darkGold,
      error: barberRed,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.playfairDisplayTextTheme().apply(
      bodyColor: deepBlack,
      displayColor: deepBlack,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: richBlack,
      foregroundColor: luxuryGold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: luxuryGold,
        letterSpacing: 1.5,
      ),
      iconTheme: const IconThemeData(color: luxuryGold),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: barberLightGray, width: 1),
      ),
      color: barberWhite,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: luxuryGold,
        foregroundColor: richBlack,
        elevation: 2,
        shadowColor: darkGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: luxuryGold,
        foregroundColor: richBlack,
        elevation: 2,
        shadowColor: darkGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: luxuryGold,
        side: BorderSide(color: luxuryGold, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: barberGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: barberGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: barberBlack, width: 2),
      ),
      filled: true,
      fillColor: barberWhite,
    ),
    dividerColor: barberLightGray,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: barberWhite,
      onPrimary: barberBlack,
      primaryContainer: Color(0xFF2C2C2C),
      onPrimaryContainer: barberWhite,
      secondary: barberRed,
      onSecondary: barberWhite,
      secondaryContainer: Color(0xFF4A1A1A),
      onSecondaryContainer: barberRed,
      surface: barberBlack,
      onSurface: barberWhite,
      surfaceVariant: Color(0xFF2C2C2C),
      onSurfaceVariant: barberLightGray,
      outline: barberGray,
      error: barberRed,
      onError: barberWhite,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: barberWhite,
      displayColor: barberWhite,
    ),
    scaffoldBackgroundColor: barberBlack,
    appBarTheme: AppBarTheme(
      backgroundColor: barberBlack,
      foregroundColor: luxuryGold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: luxuryGold,
        letterSpacing: 1.5,
      ),
      iconTheme: const IconThemeData(color: luxuryGold),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Color(0xFF2C2C2C), width: 1),
      ),
      color: Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: barberWhite,
        foregroundColor: barberBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: barberWhite,
        foregroundColor: barberBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: barberWhite,
        side: BorderSide(color: barberWhite, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: barberGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: barberGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: barberWhite, width: 2),
      ),
      filled: true,
      fillColor: Color(0xFF1E1E1E),
    ),
    dividerColor: Color(0xFF2C2C2C),
  );
}
