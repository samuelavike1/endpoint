import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────── Color Palette ────────────────
// All colors are accessed via AppColors.* which checks the current mode.

class AppColors {
  static bool isDark = true;

  // ── Backgrounds ──
  static Color get background =>
      isDark ? const Color(0xFF0A0E17) : const Color(0xFFF5F7FA);
  static Color get surface => isDark ? const Color(0xFF131924) : Colors.white;
  static Color get surfaceLight =>
      isDark ? const Color(0xFF1A2235) : const Color(0xFFF0F2F5);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFE8ECF0);
  static Color get card => isDark ? const Color(0xFF162032) : Colors.white;

  // ── Accent ──
  // ── Accent ──
  static Color get primary => isDark
      ? const Color(0xFF6366F1)
      : const Color(0xFF4338CA); // Vivid Indigo / Deep Indigo
  static Color get primaryLight =>
      isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);
  static Color get primaryDark =>
      isDark ? const Color(0xFF4F46E5) : const Color(0xFF3730A3);
  static Color get secondary =>
      isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3);

  // ── Method colors ──
  static Color get getColor => isDark
      ? const Color(0xFF34D399)
      : const Color(0xFF059669); // Emerald 400 / 600
  static Color get postColor => isDark
      ? const Color(0xFFFBBF24)
      : const Color(0xFFD97706); // Amber 400 / 600
  static Color get putColor => isDark
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB); // Blue 400 / 600
  static Color get deleteColor => isDark
      ? const Color(0xFFF87171)
      : const Color(0xFFDC2626); // Red 400 / 600
  static Color get patchColor => isDark
      ? const Color(0xFFA78BFA)
      : const Color(0xFF7C3AED); // Violet 400 / 600
  static Color get headColor => isDark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF475569); // Slate 400 / 600
  static Color get optionsColor => isDark
      ? const Color(0xFFF472B6)
      : const Color(0xFFDB2777); // Pink 400 / 600

  // ── Status ──
  static Color get success => getColor;
  static Color get warning => postColor;
  static Color get error => deleteColor;
  static Color get info => putColor;

  // ── Text ──
  static Color get textPrimary => isDark
      ? const Color(0xFFF8FAFC)
      : const Color(0xFF0F172A); // Slate 50/900
  static Color get textSecondary => isDark
      ? const Color(0xFFCBD5E1)
      : const Color(0xFF475569); // Slate 300/600
  static Color get textTertiary => isDark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF64748B); // Slate 400/500

  // ── Borders ──
  static Color get border =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  static Color get borderLight =>
      isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
  static Color get divider =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)], // Deeper gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)], // Deeper background
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sendButtonGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
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

// ──────────────── Theme Data ────────────────

class AppTheme {
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0A0E17)
          : const Color(0xFFF5F7FA),
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: const Color(0xFF131924),
              onSurface: const Color(0xFFF1F5F9),
              outline: const Color(0xFF1E293B),
            )
          : ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: Colors.white,
              onSurface: const Color(0xFF1A1A2E),
              outline: const Color(0xFFE2E8F0),
            ),
      textTheme:
          GoogleFonts.interTextTheme(
            ThemeData(brightness: brightness).textTheme,
          ).copyWith(
            headlineLarge: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
              letterSpacing: -0.5,
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            labelLarge: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
            ),
            labelMedium: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            labelSmall: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent, // Remove whitish tint
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF131924) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF131924) : Colors.white,
        surfaceTintColor: Colors.transparent, // Remove whitish tint
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF131924) : Colors.white,
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF131924) : Colors.white,
      ),
      dividerColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        thickness: 1,
        space: 0,
      ),
    );
  }
}
