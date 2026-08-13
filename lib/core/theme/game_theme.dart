import 'package:flutter/material.dart';

abstract final class GamePalette {
  static const background = Color(0xff090b10);
  static const panel = Color(0xff14151a);
  static const gold = Color(0xffc49a54);
  static const navy = Color(0xff6b79a6);
  static const brassBorder = Color(0xff665536);
  static const danger = Color(0xff8f3f3b);
  static const ally = Color(0xff6484a9);
}

ThemeData buildGameTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'NotoSansKR',
    scaffoldBackgroundColor: GamePalette.background,
    colorScheme: const ColorScheme.dark(
      primary: GamePalette.gold,
      secondary: GamePalette.navy,
      surface: GamePalette.panel,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xff111319),
      surfaceTintColor: Colors.transparent,
      shape: const BeveledRectangleBorder(
        side: BorderSide(color: GamePalette.gold, width: 1.2),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        color: Color(0xffffd27c),
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        color: Color(0xffd5d5d8),
        fontSize: 12,
        height: 1.55,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xffffd27c),
        shape: const BeveledRectangleBorder(
          side: BorderSide(color: Color(0xff8b7045)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff263f5e),
        foregroundColor: Colors.white,
        shape: const BeveledRectangleBorder(
          side: BorderSide(color: Color(0xff7691ad)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      ),
    ),
  );
}
