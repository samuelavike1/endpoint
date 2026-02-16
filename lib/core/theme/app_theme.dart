import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF131924);
  static const Color surfaceLight = Color(0xFF1A2235);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color card = Color(0xFF162032);

  // Accent colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4);

  // Status colors (method badges)
  static const Color getColor = Color(0xFF34D399);
  static const Color postColor = Color(0xFFFBBF24);
  static const Color putColor = Color(0xFF60A5FA);
  static const Color deleteColor = Color(0xFFF87171);
  static const Color patchColor = Color(0xFFC084FC);
  static const Color headColor = Color(0xFF94A3B8);
  static const Color optionsColor = Color(0xFFFB923C);

  // Response status
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Borders & dividers
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);
  static const Color divider = Color(0xFF1E293B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF131924), Color(0xFF0A0E17)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sendButtonGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return getColor;
      case 'POST':
        return postColor;
      case 'PUT':
        return putColor;
      case 'DELETE':
        return deleteColor;
      case 'PATCH':
        return patchColor;
      case 'HEAD':
        return headColor;
      case 'OPTIONS':
        return optionsColor;
      default:
        return textSecondary;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
