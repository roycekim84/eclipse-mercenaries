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
  );
}
