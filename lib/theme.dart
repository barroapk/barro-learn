import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette « Clarté » : fond blanc, un vert principal, quelques touches douces.
class BarroColors {
  static const bg = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF4F7F5);
  static const line = Color(0xFFE6ECE8);
  static const ink = Color(0xFF0F1A14);
  static const muted = Color(0xFF5B6B62);
  static const faint = Color(0xFF8A9A91);
  static const inkSoft = Color(0xFF3F5248);

  static const green = Color(0xFF0E9F5B);
  static const greenText = Color(0xFF0B7A46);
  static const greenDeep = Color(0xFF0E3B25);
  static const greenSoft = Color(0xFFE3F6EC);
  static const greenMid = Color(0xFFC6EBD7);
  static const wing = Color(0xFFBFE9D2);

  static const orange = Color(0xFFF97316);
  static const orangeText = Color(0xFFC2410C);
  static const orangeSoft = Color(0xFFFFEDDC);
  static const sun = Color(0xFFFFE3C7);

  static const blue = Color(0xFF1D4ED8);
  static const blueSoft = Color(0xFFE5EEFF);
  static const violet = Color(0xFF6D28D9);
  static const violetSoft = Color(0xFFEFE9FF);
  static const teal = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFDDF4F1);
  static const pink = Color(0xFFBE185D);
  static const pinkSoft = Color(0xFFFCE7F3);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFDECEC);

  static const comb = Color(0xFFEF4444);
  static const chick = Color(0xFFFDE68A);
}

/// Police des titres (Sora). Si elle n'est pas disponible, on garde Manrope.
TextStyle display(double size, {Color color = BarroColors.ink, FontWeight weight = FontWeight.w700, double height = 1.15}) {
  try {
    return GoogleFonts.getFont(
      'Sora',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.02 * size,
      height: height,
    );
  } catch (_) {
    return GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, color: color, height: height);
  }
}

/// Police du texte courant (Manrope).
TextStyle body(double size,
    {Color color = BarroColors.ink, FontWeight weight = FontWeight.w500, double height = 1.4, double letterSpacing = 0}) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Petit libellé en capitales (ex. « LE SAVAIS-TU ? »).
TextStyle eyebrow({Color color = BarroColors.greenText}) =>
    body(11, color: color, weight: FontWeight.w800, letterSpacing: 0.9, height: 1.2);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: BarroColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: BarroColors.green, brightness: Brightness.light).copyWith(
      primary: BarroColors.green,
      surface: BarroColors.bg,
      onSurface: BarroColors.ink,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: BarroColors.ink,
      displayColor: BarroColors.ink,
    ),
    dividerColor: BarroColors.line,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: BarroColors.greenSoft,
      height: 70,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? BarroColors.greenText : BarroColors.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return body(12,
            color: selected ? BarroColors.greenText : BarroColors.muted,
            weight: selected ? FontWeight.w800 : FontWeight.w600);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BarroColors.ink,
      contentTextStyle: body(14, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
