import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Font family chính cho toàn ứng dụng
  static const String fontFamily = 'GoogleSans';

  // Theme Data cho toàn bộ ứng dụng
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily, // Thiết lập font mặc định cho toàn bộ ứng dụng
      
      // Primary color scheme
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // Text Theme - Tất cả Text styles sẽ sử dụng GoogleSans
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14),
        bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12),
        labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: 24,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(fontFamily: fontFamily),
        hintStyle: const TextStyle(fontFamily: fontFamily),
        helperStyle: const TextStyle(fontFamily: fontFamily),
        errorStyle: const TextStyle(fontFamily: fontFamily),
      ),
    );
  }
}
