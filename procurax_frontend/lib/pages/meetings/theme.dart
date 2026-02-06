import 'package:flutter/material.dart';

/// Primary blue used across the app
const primaryBlue = Color(0xFF1E40AF);

/// Light blue used for input backgrounds & FAB
const lightBlue = Color(0xFFE6EFF8);

/// Secondary text color
const greyText = Color(0xFF6B7280);

/// Global application theme
final appTheme = ThemeData(
  fontFamily: 'Inter', // Matches design font
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: primaryBlue,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: primaryBlue),
  ),
);
