import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CourseForge design system.
///
/// Palette chosen for a serious adult-learning / exam-prep product:
///   teal  -> trust, progress, focus
///   amber -> action / achievement (CTAs, streaks, certificates)
/// Professional and calm, not playful. WCAG AA contrast on key pairs.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0D9488); // teal-600
  static const Color primaryDark = Color(0xFF0F766E); // teal-700
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF0EA5A4);

  static const Color accent = Color(0xFFEA580C); // orange-600 (CTA / streak)
  static const Color onAccent = Color(0xFFFFFFFF);

  // Soft off-white, not pure #FFFFFF (premium-feel rule: avoid pure black/white).
  static const Color background = Color(0xFFF6F8F8);
  static const Color surface = Color(0xFFFCFDFC);
  static const Color surfaceAlt = Color(0xFFEDF4F4);

  static const Color foreground = Color(0xFF0F2A28); // near-black teal
  static const Color muted = Color(0xFF5B6B6A); // secondary text >= 3:1
  static const Color border = Color(0xFFD7E4E3);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color destructive = Color(0xFFDC2626);

  // Dark mode tonal variants (desaturated, not inverted).
  static const Color dBackground = Color(0xFF0B1413);
  static const Color dSurface = Color(0xFF132221);
  static const Color dSurfaceAlt = Color(0xFF1B2E2C);
  static const Color dForeground = Color(0xFFE6F2F0);
  static const Color dMuted = Color(0xFF9AB0AD);
  static const Color dBorder = Color(0xFF26403D);
  static const Color dPrimary = Color(0xFF2DD4BF); // brighter teal for dark
}

/// Theme-aware colors. Use these in widgets instead of the raw light-only
/// AppColors constants, so dark mode never renders text on a same-tone surface.
extension CFColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Secondary/label text — always readable on the current background.
  Color get muted => isDark ? AppColors.dMuted : AppColors.muted;

  /// Subtle filled-container background (cards, chips, callouts).
  Color get surfaceAlt => isDark ? AppColors.dSurfaceAlt : AppColors.surfaceAlt;

  /// Hairline borders/dividers.
  Color get border => isDark ? AppColors.dBorder : AppColors.border;

  /// Primary brand color tuned for the current theme.
  Color get brand => isDark ? AppColors.dPrimary : AppColors.primary;

  /// Main foreground text color.
  Color get fg => isDark ? AppColors.dForeground : AppColors.foreground;
}

/// 4/8pt spacing rhythm.
class Gap {
  Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class Radii {
  Radii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.dPrimary : AppColors.primary,
      onPrimary: isDark ? const Color(0xFF06302C) : AppColors.onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      error: AppColors.destructive,
      onError: Colors.white,
      surface: isDark ? AppColors.dSurface : AppColors.surface,
      onSurface: isDark ? AppColors.dForeground : AppColors.foreground,
      surfaceContainerHighest:
          isDark ? AppColors.dSurfaceAlt : AppColors.surfaceAlt,
      onSurfaceVariant: isDark ? AppColors.dMuted : AppColors.muted,
      outline: isDark ? AppColors.dBorder : AppColors.border,
    );

    final baseText = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.dBackground : AppColors.background,
      textTheme: baseText.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          textStyle: baseText.displaySmall,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          textStyle: baseText.headlineSmall,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseText.titleLarge,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseText.titleMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.dSurface : AppColors.surface,
        foregroundColor: isDark ? AppColors.dForeground : AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.dForeground : AppColors.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.dSurface : AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: isDark ? AppColors.dBorder : AppColors.border,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: BorderSide(color: isDark ? AppColors.dBorder : AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.dSurfaceAlt : AppColors.surfaceAlt,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: isDark ? AppColors.dForeground : AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.dSurfaceAlt : AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dBorder : AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
