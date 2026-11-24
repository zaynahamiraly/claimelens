import 'package:flutter/material.dart';

ThemeData claimLensTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff087f8c), brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? const Color(0xff101d25) : const Color(0xfff3f7f9),
    appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor:
            dark ? const Color(0xff101d25) : const Color(0xfff3f7f9),
        surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xff192c35) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: .45)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xff192c35) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)))),
    navigationBarTheme: const NavigationBarThemeData(height: 76),
  );
}
