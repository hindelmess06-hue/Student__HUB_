import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A two-colour accent the user can switch in their profile.
class Palette {
  const Palette(this.name, this.a, this.b);

  final String name;
  final Color a;
  final Color b;

  LinearGradient get gradient => LinearGradient(
        colors: [a, b],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const List<Palette> all = [
    Palette('Aurora', Color(0xFF7C5CFF), Color(0xFF22D3EE)),
    Palette('Sunset', Color(0xFFFF4D8D), Color(0xFFFFB84D)),
    Palette('Mint', Color(0xFF00D9A3), Color(0xFF3B82F6)),
    Palette('Orchid', Color(0xFFD946EF), Color(0xFF6366F1)),
  ];
}

class AppColors {
  static const Color bg = Color(0xFF07070E);
  static const Color surface = Color(0xFF13131F);
  static const Color surfaceHi = Color(0xFF1B1B2B);
  static const Color text = Color(0xFFF4F4FA);
  static const Color muted = Color(0xFF9393AB);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color warning = Color(0xFFFFB84D);
}

class AppText {
  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color color = AppColors.text,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle body(
    double size, {
    FontWeight w = FontWeight.w400,
    Color color = AppColors.text,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

ThemeData buildTheme(Palette p) {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.dark(
      primary: p.a,
      secondary: p.b,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHi,
      contentTextStyle: AppText.body(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
