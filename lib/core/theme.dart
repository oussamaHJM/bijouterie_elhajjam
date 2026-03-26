import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8CC7A);
  static const Color goldDark = Color(0xFF9C7C2E);
  static const Color darkGreen = Color(0xFF1B3A2D);
  static const Color darkGreenLight = Color(0xFF2A5441);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F5EF);
  static const Color lightGrey = Color(0xFFEAE6DE);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF555555);
  static const Color textLight = Color(0xFF888888);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFF57F17);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: darkGreen,
        onPrimary: white,
        secondary: gold,
        onSecondary: white,
        error: error,
        onError: white,
        surface: white,
        onSurface: textDark,
        surfaceContainerHighest: offWhite,
        outline: lightGrey,
      ),
      scaffoldBackgroundColor: offWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: darkGreen,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: gold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: gold),
        actionsIconTheme: const IconThemeData(color: gold),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: darkGreen,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26, fontWeight: FontWeight.w700, color: darkGreen,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: darkGreen,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: darkGreen,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 18, fontWeight: FontWeight.w600, color: darkGreen,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 17, fontWeight: FontWeight.w700, color: textDark,
        ),
        titleMedium: GoogleFonts.lato(
          fontSize: 15, fontWeight: FontWeight.w600, color: textDark,
        ),
        titleSmall: GoogleFonts.lato(
          fontSize: 13, fontWeight: FontWeight.w600, color: textMedium,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16, fontWeight: FontWeight.w400, color: textDark,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14, fontWeight: FontWeight.w400, color: textDark,
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 12, fontWeight: FontWeight.w400, color: textMedium,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14, fontWeight: FontWeight.w700, color: white,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: darkGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.lato(
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkGreen,
          side: const BorderSide(color: darkGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.lato(
            fontSize: 14, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGrey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: GoogleFonts.lato(color: textMedium, fontSize: 14),
        hintStyle: GoogleFonts.lato(color: textLight, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: darkGreen,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkGreen,
        selectedItemColor: gold,
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      dividerColor: lightGrey,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGreen,
        contentTextStyle: GoogleFonts.lato(color: white, fontSize: 14),
        actionTextColor: gold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w700, color: darkGreen,
        ),
        contentTextStyle: GoogleFonts.lato(fontSize: 14, color: textDark),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: offWhite,
        selectedColor: gold.withOpacity(0.2),
        labelStyle: GoogleFonts.lato(fontSize: 13, color: textDark),
        side: const BorderSide(color: lightGrey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Custom decorations
  static BoxDecoration get goldGradientDecoration => const BoxDecoration(
    gradient: LinearGradient(
      colors: [goldDark, gold, goldLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration get greenGradientDecoration => const BoxDecoration(
    gradient: LinearGradient(
      colors: [darkGreen, darkGreenLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration get headerDecoration => const BoxDecoration(
    gradient: LinearGradient(
      colors: [darkGreen, darkGreenLight],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static BoxDecoration cardDecoration({
    Color? color,
    double radius = 12,
    bool withShadow = true,
  }) => BoxDecoration(
    color: color ?? white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: withShadow
        ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))]
        : null,
  );

  static InputDecoration goldSearchDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: textLight, fontSize: 14),
    prefixIcon: const Icon(Icons.search, color: gold),
    filled: true,
    fillColor: white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    suffixIcon: const Icon(Icons.filter_list, color: textLight),
  );
}
