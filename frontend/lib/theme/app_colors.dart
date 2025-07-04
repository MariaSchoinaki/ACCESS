import 'package:flutter/material.dart';

/// A collection of color constants used in the app.
class AppColors {

  static const Color background = Color(0xFFFFF9F3);

  static const MaterialColor primaryAccent = MaterialColor(0xFFEE8181, {
    50: Color(0xFFFFEBEE),
    100: Color(0xFFFFB3B3),
    200: Color(0xFFEE8181),
    300: Color(0xFFE89C9C),
    400: Color(0xFFE64D4D),
    500: Color(0xFFEE8181),
    600: Color(0xFFD75A5A),
    700: Color(0xFFCC0000),
    800: Color(0xFFB00000),
    900: Color(0xFF8B0000),
  });
  static const Color primary = Color(0xFFEE8181);
  static const Color secondary = Color(0xFFB1EE97);

  static const Color primaryLight = Colors.blueAccent;
  static const Color primaryDark = Colors.blueGrey;
  static const Color accent = Colors.amber;

  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;

  /// Dark theme colors
  static const Color backgroundDark = Colors.black38;

  static const Color primaryDarkk = Colors.blue;
  static const Color accentDark = Colors.amber;

  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;


  /// General colors
  static const Color error = Colors.red;

  static const MaterialColor errorAccent = MaterialColor(0xFFFF0000, {
    50: Color(0xFFFFEBEE),
    100: Color(0xFFFF8A80),
    200: Color(0xFFFF5252),
    300: Color(0xFFFF3D3D),
    400: Color(0xFFFF1744),
    500: Color(0xFFFF0000),
    600: Color(0xFFE60000),
    700: Color(0xFFD50000),
    800: Color(0xFFC51111),
    900: Color(0xFFB00020),
  });

  static const MaterialColor whiteAccent = MaterialColor(0xFFFFFFFF, {
    50: Color(0xFFFFFFFF),
    100: Color(0xFFFFFFFF),
    200: Color(0xFFF5F5F5),
    300: Color(0xFFEFEFEF),
    400: Color(0xFFDADADA),
    500: Color(0xFFFFFFFF),
    600: Color(0xFFE0E0E0),
    700: Color(0xFFBDBDBD),
    800: Color(0xFF9E9E9E),
    900: Color(0xFF757575),
  });

  static const MaterialColor blackAccent = MaterialColor(0xFF000000, {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF0F0F0),
    200: Color(0xFFD6D6D6),
    300: Color(0xFFAAAAAA),
    400: Color(0xFF7E7E7E),
    500: Color(0xFF4F4F4F),
    600: Color(0xFF2C2C2C),
    700: Color(0xFF1A1A1A),
    800: Color(0xFF0D0D0D),
    900: Color(0xFF000000),
  });

  static const MaterialColor creamAccent = MaterialColor(0xFFFFF9F3, {
    50: Color(0xFFFFFFFF),  // καθαρό λευκό
    100: Color(0xFFFFFCF9), // σχεδόν λευκό με υποψία warmth
    200: Color(0xFFFFF9F3), // base
    300: Color(0xFFFFE9D9), // πιο “βανίλια”
    400: Color(0xFFFFDBBF), // πολύ light ροδακινί
    500: Color(0xFFFFCFA3), // ανοιχτό apricot
    600: Color(0xFFFFBE88), // ζεστό ροδακινί
    700: Color(0xFFE6A671), // πιο muted
    800: Color(0xFFCC8F5D), // καραμελέ
    900: Color(0xFFB3774A), // σκούρο caramel peach
  });
  static const Color cream = Color(0xFFFFE9D9);
  static const Color white = Colors.white;
  static const Color black = Colors.black87;
  static const Color grey = Color(0xFF4E5153);

}