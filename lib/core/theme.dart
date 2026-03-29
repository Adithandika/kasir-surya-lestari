import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
  // --- PALETTE TOKENS ---
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);

  // --- RADIUS SYSTEM ---
  static const double radiusXL = 40.0;
  static const double radiusLG = 32.0;
  static const double radiusMD = 24.0;
  static const double radiusSM = 16.0;

  // --- SPACING SYSTEM ---
  /// Main horizontal padding for all screen content (left/right edges)
  static const double screenPaddingH = 28.0;
  /// Top padding for content below a header
  static const double contentPaddingTop = 24.0;
  /// Standard vertical gap between sections
  static const double sectionGap = 32.0;
  /// Tight gap used within cards or between small elements
  static const double itemGap = 16.0;
  /// Bottom padding for scrollable screens (avoid FAB/nav overlap)
  static const double bottomSafeArea = 80.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screenPaddingH);
  static const EdgeInsets screenPaddingWithTop = EdgeInsets.fromLTRB(screenPaddingH, contentPaddingTop, screenPaddingH, 0);
  static const EdgeInsets cardPadding = EdgeInsets.all(24.0);
  static const EdgeInsets cardPaddingLG = EdgeInsets.all(32.0);

  // --- BRAND COLORS ---
  static const Color defaultPrimary = Color(0xFF0EA5E9); // Sky blue
  static const Color accentColor = Color(0xFF38BDF8); // Lighter blue instead of purple
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444); // More standard Red instead of Rose-pink

  // --- SURFACE TOKENS ---
  static const Color backgroundLight = Color(0xFFF1F5F9); // Slate 100
  static const Color backgroundDark = Color(0xFF0F172A);  // Slate 900
  static const Color borderLight = Color(0xFFE2E8F0);     // Slate 200
  static const Color borderDark = Color(0xFF334155);     // Slate 700

  // --- MOTION & DEPTH ---
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 400);

  // Shadows removed per user request for "clean" look
  static List<BoxShadow> glowShadow(Color color) => [];

  static List<BoxShadow> get softShadow => [];

  static List<BoxShadow> get heavyShadow => [];

  static List<BoxShadow> premiumShadow(Color color) => [];

  static LinearGradient primaryGradient(Color primary) => LinearGradient(
    colors: [primary, primary.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ShadThemeData shadTheme(Color primary, bool isDark) {
    if (isDark) {
      return ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: ShadSlateColorScheme.dark(
          primary: primary,
          background: backgroundDark,
          card: const Color(0xFF1E293B), // Slate 800 for slightly lighter cards in dark mode
          border: borderDark,
        ),
        radius: BorderRadius.circular(radiusSM),
      );
    } else {
      return ShadThemeData(
        brightness: Brightness.light,
        colorScheme: ShadSlateColorScheme.light(
          primary: primary,
          background: backgroundLight,
          card: Colors.white,
          border: borderLight,
        ),
        radius: BorderRadius.circular(radiusSM),
      );
    }
  }

  static ThemeData themeData(Color primary, bool isDark) {
    final backgroundColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: surfaceColor,
        onSurface: isDark ? Colors.white : textDark,
        outline: isDark ? borderDark : borderLight,
        outlineVariant: (isDark ? borderDark : borderLight).withValues(alpha: 0.5),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: isDark ? borderDark.withValues(alpha: 0.2) : borderLight.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
