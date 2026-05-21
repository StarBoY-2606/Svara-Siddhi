import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0D0820);
  static const surface = Color(0xFF1A1235);
  static const card = Color(0xFF1A1235);
  static const border = Color(0xFF2D2050);
  static const primary = Color(0xFFC8A35F);
  static const primaryForeground = Color(0xFF0D0820);
  static const foreground = Color(0xFFF0E6D3);
  static const muted = Color(0xFF251B45);
  static const mutedForeground = Color(0xFF8A7A9B);

  static const sattva = Color(0xFF52C5A0);
  static const sattvaDim = Color(0xFF2D7A5F);
  static const sattvaBg = Color(0xFF0A2920);

  static const rajas = Color(0xFFE8875C);
  static const rajasDim = Color(0xFFA04A28);
  static const rajasBg = Color(0xFF2A1208);

  static const tamas = Color(0xFF9B7FCC);
  static const tamasDim = Color(0xFF5A3D9A);
  static const tamasBg = Color(0xFF150A2E);

  static const vata = Color(0xFF6CC9F3);
  static const pitta = Color(0xFFF29A4D);
  static const kapha = Color(0xFF7CC67E);

  static Color gunaColor(String guna) {
    switch (guna) {
      case 'Sattvic':
        return sattva;
      case 'Rajasic':
        return rajas;
      case 'Tamasic':
        return tamas;
      default:
        return primary;
    }
  }

  static Color gunaBg(String guna) {
    switch (guna) {
      case 'Sattvic':
        return sattvaBg;
      case 'Rajasic':
        return rajasBg;
      case 'Tamasic':
        return tamasBg;
      default:
        return background;
    }
  }
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        onSurface: AppColors.foreground,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: const Color.fromRGBO(240, 230, 211, 1),
        displayColor: AppColors.foreground,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF120D28),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppColors.border,
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
