import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static const darkBackground = Color(0xFF090D14);
  static const lightBackground = Color(0xFFF4F7FB);

  static const darkScheme = ColorScheme.dark(
    primary: Color(0xFF65E0C2),
    secondary: Color(0xFFFFC26F),
    tertiary: Color(0xFF7E9DFF),
    surface: Color(0xFF111927),
    error: Color(0xFFFF6D7A),
    onPrimary: Color(0xFF04110D),
    onSecondary: Color(0xFF1C1200),
    onSurface: Color(0xFFE8ECF5),
    onError: Color(0xFF2D0208),
  );

  static const lightScheme = ColorScheme.light(
    primary: Color(0xFF0FA58A),
    secondary: Color(0xFFE08A00),
    tertiary: Color(0xFF4A6CF7),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A2433),
    onError: Color(0xFFFFFFFF),
  );

  static const birthdayPrimary = Color(0xFFFF8A3D);
  static const birthdaySecondary = Color(0xFFFFC857);
  static const birthdayTertiary = Color(0xFFFF6FCF);

  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      scheme: darkScheme,
      scaffoldBackground: darkBackground,
      baseTextTheme: ThemeData.dark().textTheme,
      inputFill: darkScheme.surface.withValues(alpha: 0.95),
      hintAlpha: 0.50,
      labelAlpha: 0.75,
      borderAlpha: 0.12,
      focusedBorderAlpha: 0.70,
      cardBorderAlpha: 0.10,
      chipBackground: darkScheme.surface.withValues(alpha: 0.90),
      chipSelectedAlpha: 0.20,
      chipDisabled: darkScheme.surface.withValues(alpha: 0.50),
      outlinedBorderAlpha: 0.20,
    );
  }

  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      scheme: lightScheme,
      scaffoldBackground: lightBackground,
      baseTextTheme: ThemeData.light().textTheme,
      inputFill: lightScheme.surface,
      hintAlpha: 0.45,
      labelAlpha: 0.72,
      borderAlpha: 0.15,
      focusedBorderAlpha: 0.80,
      cardBorderAlpha: 0.14,
      chipBackground: lightScheme.surface,
      chipSelectedAlpha: 0.16,
      chipDisabled: lightScheme.onSurface.withValues(alpha: 0.05),
      outlinedBorderAlpha: 0.24,
    );
  }

  static ThemeData birthday(BuildContext context) {
    final base = Theme.of(context);
    final birthdayScheme = base.colorScheme.copyWith(
      primary: birthdayPrimary,
      secondary: birthdaySecondary,
      tertiary: birthdayTertiary,
    );
    return base.copyWith(
      colorScheme: birthdayScheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: birthdayScheme.surface,
        foregroundColor: birthdayScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: birthdayScheme.primary,
          foregroundColor: birthdayScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: birthdayScheme.primary,
      ),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required TextTheme baseTextTheme,
    required Color inputFill,
    required double hintAlpha,
    required double labelAlpha,
    required double borderAlpha,
    required double focusedBorderAlpha,
    required double cardBorderAlpha,
    required Color chipBackground,
    required double chipSelectedAlpha,
    required Color chipDisabled,
    required double outlinedBorderAlpha,
  }) {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      baseTextTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final textTheme = GoogleFonts.spaceGroteskTextTheme(baseText).copyWith(
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: cardBorderAlpha),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.12),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: hintAlpha),
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: labelAlpha),
          fontWeight: FontWeight.w600,
        ),
        border: _inputBorder(scheme, borderAlpha),
        enabledBorder: _inputBorder(scheme, borderAlpha),
        focusedBorder: _inputBorder(scheme, focusedBorderAlpha, focused: true),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: scheme.primary.withValues(alpha: chipSelectedAlpha),
        disabledColor: chipDisabled,
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.15)),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onSurface),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(
            color: scheme.onSurface.withValues(alpha: outlinedBorderAlpha),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  static OutlineInputBorder _inputBorder(
    ColorScheme scheme,
    double alpha, {
    bool focused = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: (focused ? scheme.primary : scheme.onSurface).withValues(
          alpha: alpha,
        ),
      ),
    );
  }
}

extension AppThemeColors on ColorScheme {
  Color get cardSurface => surface.withValues(alpha: 0.74);
  Color get softSurface => surface.withValues(alpha: 0.72);
  Color get subtleBorder => onSurface.withValues(alpha: 0.13);
  Color get mutedText => onSurface.withValues(alpha: 0.68);
  Color get faintTrack => onSurface.withValues(alpha: 0.12);
  Color get chartAxis => onSurface.withValues(alpha: 0.24);
  Color get chartFill => primary.withValues(alpha: 0.14);
  Color get chartLine => primary;
  Color get chartPoint => secondary;
  List<Color> get barGradient => [
    primary.withValues(alpha: 0.85),
    tertiary.withValues(alpha: 0.75),
  ];
}
