import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Les couleurs de BARRO, au même endroit pour toute l'app.
class BarroColors {
  static const bg = Color(0xFF0F1115);
  static const surface = Color(0xFF191C22);
  static const surfaceLow = Color(0xFF15181D);
  static const nav = Color(0xFF14171C);
  static const border = Color(0xFF262A32);
  static const text = Color(0xFFF4F1EA);
  static const muted = Color(0xFFA3A8B3);
  static const ink = Color(0xFF0B1220);

  static const green = Color(0xFF2BD67B);
  static const blue = Color(0xFF4C8DFF);
  static const deepBlue = Color(0xFF2563EB);
  static const orange = Color(0xFFFF8A3D);
  static const violet = Color(0xFFA78BFA);
  static const deepViolet = Color(0xFF5B21B6);
  static const teal = Color(0xFF2DD4BF);
  static const pink = Color(0xFFF472B6);
  static const emerald = Color(0xFF065F46);
  static const red = Color(0xFFFF6B6B);
}

/// Police des grands titres. Si elle n'est pas disponible, on garde Manrope.
TextStyle display(double size, {Color color = BarroColors.text, FontWeight weight = FontWeight.w800}) {
  try {
    return GoogleFonts.getFont(
      'Bricolage Grotesque',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.4,
      height: 1.15,
    );
  } catch (_) {
    return GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color, height: 1.15);
  }
}

/// Police du texte courant.
TextStyle body(double size, {Color color = BarroColors.text, FontWeight weight = FontWeight.w500, double height = 1.4}) {
  return GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color, height: height);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BarroColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BarroColors.green,
      brightness: Brightness.dark,
    ).copyWith(primary: BarroColors.green, surface: BarroColors.bg),
  );
  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: BarroColors.text,
      displayColor: BarroColors.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BarroColors.nav,
      indicatorColor: BarroColors.green.withValues(alpha: 0.18),
      height: 72,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? BarroColors.green : BarroColors.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return body(12,
            color: selected ? BarroColors.green : BarroColors.muted,
            weight: selected ? FontWeight.w800 : FontWeight.w600);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BarroColors.surface,
      contentTextStyle: body(14),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
