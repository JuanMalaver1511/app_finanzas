import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Tema global de la aplicación.
/// Define estilos generales para mantener un diseño consistente.
class AppTheme {

  static ThemeData lightTheme = ThemeData(

    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.black,
      centerTitle: true,
    ),

    // Estilo global de botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    // Estilo global para inputs
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),

  );
}