import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light, // Indicates this is a light theme
  primarySwatch: AppColors.primaryAccent, // Primary color of your app (can be customized)
  primaryColor: AppColors.primaryAccent.shade200, // Specific primary color
  hintColor: AppColors.grey, // Color for hint text in input fields
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background, // Background color of AppBar
    foregroundColor: AppColors.textPrimary, // Text color of AppBar title and actions
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: AppColors.black),
    titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.black),
    bodyMedium: TextStyle(fontSize: 16.0, color: AppColors.black),
  ),
  iconTheme: const IconThemeData(color: AppColors.black),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.grey),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.black),
      borderRadius: BorderRadius.circular(8.0),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.errorAccent.shade400),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.errorAccent.shade700),
      borderRadius: BorderRadius.circular(8.0),
    ),
    labelStyle: const TextStyle(color: AppColors.grey),
    hintStyle: TextStyle(color: AppColors.grey),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryAccent.shade300,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  hoverColor: AppColors.primaryAccent.shade100, /// for the 3 little buttons
  cardColor: AppColors.whiteAccent.shade200, ///for search bar background
  // You can customize other visual aspects here, like cardColor, iconTheme, etc.
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: AppColors.primaryAccent,
  primaryColor: AppColors.primaryAccent.shade200,
  hintColor: AppColors.white,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.black,
    foregroundColor: AppColors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: AppColors.white),
    titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.white),
    bodyMedium: TextStyle(fontSize: 16.0, color: AppColors.white),
  ),
  iconTheme: const IconThemeData(color: AppColors.white),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.white),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.errorAccent.shade400),
      borderRadius: BorderRadius.circular(8.0),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.errorAccent.shade700),
      borderRadius: BorderRadius.circular(8.0),
    ),
    labelStyle: const TextStyle(color: AppColors.white),
    hintStyle: TextStyle(color: AppColors.whiteAccent.shade700),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryAccent.shade600,
      foregroundColor: AppColors.whiteAccent.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  hoverColor: AppColors.blackAccent.shade600,/// for the 3 little buttons
  cardColor: AppColors.blackAccent.shade600, ///for search bar background
);
