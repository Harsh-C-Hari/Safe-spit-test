// app_theme.dart — SAFE//SPIT
//
// Central design system that mirrors the website's design tokens as closely
// as Flutter/Material allows.
//
// Website tokens source: website/src/index.css :root
// Typography:
//   --font-editorial: Space Grotesk (editorial/heading text) → google_fonts
//   --font-technical: IBM Plex Mono → SpaceMono (already bundled, closest match)
//
// HUD-specific tactical colors (kTacticalGreen etc.) are intentionally kept
// in missile_lock_reticle_painter.dart to preserve PROVEN HUD constants.
// This file covers the non-HUD screens (onboarding, profile, result, gate).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────
// COLORS — exact hex values from website/src/index.css :root
// ──────────────────────────────────────────────────────────────

abstract final class AppColors {
  /// --color-bg: #F3F1EA — warm off-white background
  static const Color background = Color(0xFFF3F1EA);

  /// --color-black: #111111 — near-black primary text/border
  static const Color black = Color(0xFF111111);

  /// --color-gray: #8D8B84 — muted gray for labels / meta
  static const Color gray = Color(0xFF8D8B84);

  /// --color-light-gray: #D8D6CE — very light warm gray for subtle borders
  static const Color lightGray = Color(0xFFD8D6CE);

  /// --color-acid-green: #C7FF3D — the primary accent (website version)
  /// NOTE: The HUD uses kTacticalGreen (#39FF14). This is the website accent.
  static const Color acidGreen = Color(0xFFC7FF3D);

  /// --color-orange: #FF5C35 — secondary accent
  static const Color orange = Color(0xFFFF5C35);

  // ── Derived semantic aliases ──────────────────────────────────
  static const Color surface = background;
  static const Color onSurface = black;
  static const Color accent = acidGreen;
  static const Color accentOnDark = acidGreen;
}

// ──────────────────────────────────────────────────────────────
// BORDERS — mirrors --border-default / --border-strong / --border-heavy
// ──────────────────────────────────────────────────────────────

abstract final class AppBorders {
  /// --border-default: 1px solid rgba(17,17,17,0.15)
  static Border get defaultBorder => Border.all(
        color: AppColors.black.withValues(alpha: 0.15),
        width: 1.0,
      );

  /// --border-strong: 1px solid #111111
  static Border get strong => Border.all(
        color: AppColors.black,
        width: 1.0,
      );

  /// --border-heavy: 2px solid #111111
  static Border get heavy => Border.all(
        color: AppColors.black,
        width: 2.0,
      );

  /// Accent border using acid-green (for focused/active states)
  static Border accentBorder({double width = 1.5}) => Border.all(
        color: AppColors.acidGreen,
        width: width,
      );
}

// ──────────────────────────────────────────────────────────────
// SPACING — 8-point scale matching website rhythm
// ──────────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

// ──────────────────────────────────────────────────────────────
// TYPOGRAPHY — mirrors website font stack
// Editorial (Space Grotesk) + Technical (SpaceMono)
// ──────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  // ── Editorial / Space Grotesk ───────────────────────────────

  /// Large hero heading (website: h1 14vw, h2 6vw)
  static TextStyle heroHeading({double fontSize = 48}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        letterSpacing: -0.02 * fontSize,
        height: 1.0,
      );

  /// Section heading (maps to website h2 style)
  static TextStyle sectionHeading({double fontSize = 28}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        letterSpacing: -0.01 * fontSize,
        height: 1.1,
      );

  /// Body editorial text
  static TextStyle body({double fontSize = 16, Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.black,
        height: 1.5,
      );

  // ── Technical / SpaceMono ───────────────────────────────────

  /// Uppercase monospace label — the core "technical text" style
  /// Maps to website: font-family: var(--font-technical); text-transform: uppercase; letter-spacing: 0.1em
  static const TextStyle technicalLabel = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
    letterSpacing: 2.0,
    height: 1.2,
  );

  /// Technical label — large variant (for values / readouts)
  static const TextStyle technicalValue = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: 1.5,
    height: 1.2,
  );

  /// Technical label — small (meta text, sub-labels)
  static const TextStyle technicalMeta = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
    letterSpacing: 1.5,
    height: 1.4,
  );

  /// Accent technical label — acid-green on dark backgrounds
  static const TextStyle technicalAccent = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.acidGreen,
    letterSpacing: 2.0,
    height: 1.2,
  );

  /// Button label — uppercase mono with letter-spacing
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: 2.5,
  );
}

// ──────────────────────────────────────────────────────────────
// RESPONSIVE HELPERS
// ──────────────────────────────────────────────────────────────

/// Returns a clamped responsive font size based on screen width.
/// [base] = font size on a 360px-wide phone.
/// [scale] = how fast it grows (default 0.04 = 4% of width).
double responsiveFontSize(
  BuildContext context, {
  required double base,
  double scale = 0.04,
  double min = 10,
  double max = 72,
}) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * scale).clamp(min, max);
}

/// Responsive horizontal padding — 6% of screen width (minimum 16px).
double responsivePaddingH(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.06).clamp(16.0, 48.0);
}

/// Returns true if the device is tablet-sized (>= 600px wide).
bool isTablet(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= 600;
}

/// Returns true if in landscape orientation.
bool isLandscape(BuildContext context) {
  return MediaQuery.orientationOf(context) == Orientation.landscape;
}

// ──────────────────────────────────────────────────────────────
// MATERIAL THEME DATA
// ──────────────────────────────────────────────────────────────

abstract final class AppTheme {
  /// The root ThemeData for all non-HUD screens.
  /// HUD screen overrides its own local styles via the PROVEN constants.
  static ThemeData get themeData => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.acidGreen,
          onPrimary: AppColors.black,
          secondary: AppColors.orange,
          onSecondary: AppColors.black,
          surface: AppColors.background,
          onSurface: AppColors.black,
          outline: AppColors.black,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
          // Override specific slots to use SpaceMono for technical text
          labelSmall: AppTextStyles.technicalMeta,
          labelMedium: AppTextStyles.technicalLabel,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTextStyles.technicalLabel.copyWith(
            fontSize: 13,
            color: AppColors.black,
            letterSpacing: 3.0,
          ),
          iconTheme: const IconThemeData(color: AppColors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.background,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            textStyle: AppTextStyles.buttonLabel.copyWith(
              color: AppColors.background,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: const BorderSide(color: AppColors.black),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            textStyle: AppTextStyles.buttonLabel,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.black, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          hintStyle: AppTextStyles.technicalMeta.copyWith(color: AppColors.gray),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.black.withValues(alpha: 0.15),
          thickness: 1,
          space: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          titleTextStyle: AppTextStyles.technicalLabel.copyWith(
            fontSize: 13,
            color: AppColors.black,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.black,
          contentTextStyle: AppTextStyles.technicalLabel.copyWith(
            color: AppColors.background,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          behavior: SnackBarBehavior.floating,
        ),
      );
}

// ──────────────────────────────────────────────────────────────
// REUSABLE WIDGET HELPERS
// ──────────────────────────────────────────────────────────────

/// A thin horizontal rule matching --border-default
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: AppColors.black.withValues(alpha: 0.15),
      );
}

/// An uppercase technical label row (label + value) used in profile & result screens.
class TechnicalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const TechnicalRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = responsiveFontSize(context, base: 11, scale: 0.03, max: 14);
    final valFontSize = responsiveFontSize(context, base: 16, scale: 0.04, max: 22);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.technicalLabel.copyWith(fontSize: fontSize),
        ),
        Text(
          value,
          style: AppTextStyles.technicalValue.copyWith(
            fontSize: valFontSize,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// A bordered container matching the website's card style (border-strong or border-heavy).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = responsivePaddingH(context);
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: border ?? AppBorders.strong,
      ),
      child: child,
    );
  }
}

/// A tactical-styled button matching the website's flat bordered button language.
class AppTacticalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? borderColor;
  final Color? textColor;
  final Color? fillColor;

  const AppTacticalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = true,
    this.borderColor,
    this.textColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = borderColor ?? AppColors.black;
    final tColor = textColor ?? (filled ? AppColors.background : AppColors.black);
    final fColor = fillColor ?? (filled ? AppColors.black : Colors.transparent);
    final fontSize = responsiveFontSize(context, base: 11, scale: 0.03, max: 14);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: fColor,
          border: Border.all(color: bColor, width: filled ? 2.0 : 1.0),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              fontSize: fontSize,
              color: tColor,
            ),
          ),
        ),
      ),
    );
  }
}
