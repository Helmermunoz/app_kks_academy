import 'package:flutter/material.dart';

abstract final class AcademyColors {
  static const background = Color(0xff080f1d);
  static const surface = Color(0xff132238);
  static const border = Color(0xff34465f);
  static const text = Color(0xfff4f7fc);
  static const muted = Color(0xffb8c7dc);
  static const blue = Color(0xff96c4ff);
  static const red = Color(0xffc52e42);
  static const error = Color(0xffffa4ad);
  static const warning = Color(0xff3b2d18);
}

ThemeData academyTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff174b88),
        brightness: Brightness.dark,
      ).copyWith(
        primary: AcademyColors.blue,
        onPrimary: AcademyColors.background,
        secondary: const Color(0xffffa4ad),
        surface: AcademyColors.surface,
        onSurface: AcademyColors.text,
        onSurfaceVariant: AcademyColors.muted,
        outline: AcademyColors.border,
        error: AcademyColors.error,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AcademyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AcademyColors.background,
      foregroundColor: AcademyColors.text,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AcademyColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AcademyColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AcademyColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AcademyColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AcademyColors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AcademyColors.blue,
        side: const BorderSide(color: AcademyColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AcademyColors.background,
      labelStyle: const TextStyle(color: AcademyColors.muted),
      hintStyle: const TextStyle(color: AcademyColors.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AcademyColors.border),
      ),
    ),
    dividerColor: AcademyColors.border,
  );
}
